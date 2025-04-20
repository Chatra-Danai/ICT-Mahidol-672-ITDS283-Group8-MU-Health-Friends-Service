import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // สำหรับจัดรูปแบบวันที่

// ไม่จำเป็นต้อง import appointment_booking_screen หรือ user_dashboard_screen ที่นี่
// เพราะการนำทางกลับจะใช้ Navigator.pop()

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final _commentController = TextEditingController();

  // State สำหรับการให้คะแนน
  int? _selectedRating;
  String? _ratingError;
  int _ratingScale = 5;

  // State สำหรับประวัติการรักษาและการเลือก
  bool _isLoadingHistory = true;
  List<Map<String, dynamic>> _historyItems = []; // เก็บรายการประวัติ {id: '...', data: {...}}
  String? _selectedHistoryDocId; // ID ของประวัติที่เลือก
  Map<String, dynamic>? _selectedHistoryData; // ข้อมูลของประวัติที่เลือก

  bool _isSubmitting = false; // สถานะกำลังบันทึก Feedback

  @override
  void initState() {
    super.initState();
    _fetchHealthHistory();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // --- ดึงข้อมูลประวัติการรักษา ---
  Future<void> _fetchHealthHistory() async {
    if (_currentUser == null) {
      if (mounted) setState(() => _isLoadingHistory = false);
      return;
    }
    setState(() => _isLoadingHistory = true);
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('healthHistory')
          .orderBy('timestamp', descending: true) // เรียงล่าสุดขึ้นก่อน
          .limit(20) // จำกัดจำนวนรายการที่ดึงมา (ปรับตามความเหมาะสม)
          .get();

      final List<Map<String, dynamic>> fetchedItems = [];
      for (var doc in querySnapshot.docs) {
        fetchedItems.add({
          'id': doc.id, // เก็บ Document ID ไว้ด้วย
          'data': doc.data(), // เก็บข้อมูลทั้งหมด
        });
      }

      if (mounted) {
        setState(() {
          _historyItems = fetchedItems;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching health history: $e");
      if (mounted) setState(() => _isLoadingHistory = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading history: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // --- บันทึก Feedback ลง Firestore ---
  Future<void> _submitFeedback() async {
    // Reset และตรวจสอบ Error
    setState(() => _ratingError = null);
    if (_selectedHistoryDocId == null) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Please select a service encounter to rate.'), backgroundColor: Colors.orange),
       );
       return;
    }
    if (_selectedRating == null) {
       setState(() => _ratingError = 'Please provide a rating.');
       return;
    }

    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final String comment = _commentController.text.trim();
    bool success = false;

    try {
      // เตรียมข้อมูลที่จะ update
      Map<String, dynamic> feedbackData = {
        'feedbackRating': _selectedRating,
        'feedbackComment': comment.isEmpty ? null : comment, // เก็บ null ถ้าไม่มี comment
        'feedbackTimestamp': FieldValue.serverTimestamp(), // เวลาที่ให้ feedback
      };

      // Update document ใน healthHistory ที่ user เลือกไว้
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('healthHistory')
          .doc(_selectedHistoryDocId!) // ใช้ ID ที่ user เลือก
          .update(feedbackData); // ใช้ update เพื่อเพิ่ม field หรือแก้ไข field เดิม

      success = true;
      print('Feedback saved for history item: $_selectedHistoryDocId');

    } catch (e) {
      success = false;
      print('Error saving feedback: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving feedback: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }

    if (success && mounted) {
      // แสดง Dialog ขอบคุณ
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('ขอบคุณสำหรับความคิดเห็น!'),
            content: const Column( /* ... ไอคอนและข้อความขอบคุณ ... */ ),
            actions: <Widget>[
              TextButton(
                child: const Text('ตกลง'),
                onPressed: () {
                  Navigator.of(context).pop(); // ปิด Dialog
                  setState(() { // เคลียร์ค่าต่างๆ
                    _selectedRating = null;
                    _commentController.clear();
                    _selectedHistoryDocId = null;
                    _selectedHistoryData = null;
                    _ratingError = null;
                    // ไม่ต้องแก้ _selectedIndex เพราะไม่มีแล้ว
                  });
                  if (mounted) Navigator.of(context).pop(); // กลับไปหน้าก่อนหน้า (Dashboard)
                },
              ),
            ],
          );
        },
      );
    }
  }

  // --- Widget สำหรับสร้างตัวเลือก Rating --- (เหมือนเดิม)
  Widget _buildRatingOptions() {
    // ... โค้ดเดิมสำหรับสร้างปุ่ม rating circle ...
     return Row( /* ... */ );
  }

  // --- จัดรูปแบบวันที่สำหรับ Dropdown ---
  String _formatHistoryItem(Map<String, dynamic> historyData) {
     String service = historyData['serviceType'] as String? ?? 'Unknown Service';
     Timestamp? ts = historyData['timestamp'] as Timestamp?;
     String dateStr = 'Unknown Date';
     if (ts != null) {
        dateStr = DateFormat('d MMM yyyy, HH:mm').format(ts.toDate()); // e.g., 17 Apr 2025, 15:30
     }
     return "$service - $dateStr"; // ข้อความที่จะแสดงใน Dropdown
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback Survey'),
      ),
      body: _isLoadingHistory // แสดง Loading ขณะดึงประวัติ
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- ส่วนเลือกประวัติการรักษา ---
                  const Text(
                    'Select service encounter to rate:', // เลือกรายการที่จะให้คะแนน
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  if (_historyItems.isEmpty) // กรณีไม่มีประวัติ
                     const Text('No past service history found.', style: TextStyle(color: Colors.grey))
                  else // กรณีมีประวัติ ให้แสดง Dropdown
                     DropdownButtonFormField<String>(
                        value: _selectedHistoryDocId,
                        isExpanded: true,
                        hint: const Text('Select from your history...'),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.history_edu_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                        ),
                        items: _historyItems.map<DropdownMenuItem<String>>((item) {
                          return DropdownMenuItem<String>(
                            value: item['id'], // ใช้ Document ID เป็น value
                            child: Text(
                               _formatHistoryItem(item['data']), // แสดง Service Type และ Date
                               overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedHistoryDocId = newValue;
                            // หาข้อมูลของ item ที่เลือกเก็บไว้ (ถ้าต้องการใช้แสดงผลส่วนอื่น)
                             _selectedHistoryData = _historyItems
                                .firstWhere((item) => item['id'] == newValue, orElse: () => {})['data'];
                            _selectedRating = null; // Reset rating เมื่อเลือกประวัติใหม่
                            _ratingError = null;
                          });
                        },
                        validator: (value) => value == null ? 'Please select an item' : null,
                     ),
                   const SizedBox(height: 24),


                  // --- ส่วนให้คะแนน (จะแสดงเมื่อเลือกประวัติแล้ว) ---
                  if (_selectedHistoryDocId != null) ...[ // ใช้ ... (spread operator)
                      const Text(
                        'Please rate this service:', // ให้คะแนนบริการนี้
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      Row( // ส่วนเลือก Scale (1-5 or 1-10)
                         children: [ /* ... Dropdown เลือก scale ... */ ],
                      ),
                      const SizedBox(height: 12),
                      _buildRatingOptions(), // ปุ่ม Rating
                      if (_ratingError != null) // แสดง Error ถ้ายังไม่ได้ให้คะแนน
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Center( // Center error message
                              child: Text(
                                  _ratingError!,
                                  style: const TextStyle(color: Colors.red, fontSize: 12)
                              )
                          ),
                        ), // --- End Fix ---
                      const SizedBox(height: 24),

                      // รูปภาพ Placeholder (เหมือนเดิม)
                      Center( child: Image.asset(
                        // --- FIX: Added asset path ---
                          'assets/images/feedback_body.jpg', // Specify the asset path again
                          height: 180,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // ช่อง Comment (เหมือนเดิม)
                      const Text( 'Additional Comments (Optional):', /* ... */ ),
                      const SizedBox(height: 8),
                      TextField( controller: _commentController, /* ... */ ),
                      const SizedBox(height: 30),

                      // ปุ่ม Submit (จะกดได้เมื่อให้คะแนนแล้ว)
                      Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.send),
                          label: Text(_isSubmitting ? 'Submitting...' : 'Submit Feedback'),
                          // ปุ่มจะกดได้เมื่อ มีการเลือกประวัติ, ให้คะแนนแล้ว, และไม่กำลัง submitting
                          onPressed: (_selectedHistoryDocId == null || _selectedRating == null || _isSubmitting)
                                     ? null
                                     : _submitFeedback,
                          style: ElevatedButton.styleFrom( /* ... */ ),
                        ),
                      ),
                   ] else ...[ // กรณีที่ยังไม่ได้เลือกประวัติ
                      const Center(child: Text('Please select a service encounter from the list above to provide feedback.'))
                   ],
                   const SizedBox(height: 16),
                ],
              ),
            ),
      // --- ลบ BottomNavigationBar ทิ้ง ---
    );
  }
}