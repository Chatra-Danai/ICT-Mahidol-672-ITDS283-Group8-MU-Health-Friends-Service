import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StaffNotificationSenderScreen extends StatefulWidget {
  const StaffNotificationSenderScreen({super.key});

  @override
  State<StaffNotificationSenderScreen> createState() =>
      _StaffNotificationSenderScreenState();
}

class _StaffNotificationSenderScreenState
    extends State<StaffNotificationSenderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isSending = false;

  // Authentication and user state
  User? _loggedInUser;
  bool _isStaffUser = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _studentList = [];
  String? _selectedStudentUid;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    _loggedInUser = FirebaseAuth.instance.currentUser;
    if (_loggedInUser == null) {
      debugPrint("Staff Sender: No user logged in.");
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // Check if the logged-in user is staff
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_loggedInUser!.uid)
          .get();

      if (docSnapshot.exists && docSnapshot.data()?['userType'] == 'staff') {
        if (mounted) {
          setState(() => _isStaffUser = true);
          await _fetchStudentList();
        }
      } else {
        debugPrint("Staff Sender: Logged-in user is not staff or data missing.");
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error checking staff role: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchStudentList() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userType', isEqualTo: 'student')
          .orderBy('firstName')
          .get();

      final students = querySnapshot.docs.map((doc) {
        final data = doc.data();
        final displayName =
            "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}".trim();
        return {
          'uid': doc.id,
          'displayName': displayName.isNotEmpty ? displayName : 'Unnamed Student',
        };
      }).toList();

      if (mounted) {
        setState(() {
          _studentList = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching students: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching students: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    if (!_isStaffUser || _loggedInUser == null || _selectedStudentUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Staff login and target student selection required.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSending = true);

    final String targetUserId = _selectedStudentUid!;
    final String title = _titleController.text.trim();
    final String body = _bodyController.text.trim();
    bool success = false;

    try {
      CollectionReference userNotifications = FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .collection('notifications');

      await userNotifications.add({
        'title': title,
        'body': body,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'staff_message',
        'sentBy': _loggedInUser!.uid,
        'senderName': _loggedInUser!.email,
      });

      success = true;
      debugPrint(
          "Notification sent successfully to user $targetUserId by ${_loggedInUser!.email}");
      _titleController.clear();
      _bodyController.clear();
    } catch (e) {
      debugPrint("Error sending notification: $e");
      success = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Notification sent to student!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Notification (Staff)'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20.0),
          child: Text(
            _isLoading
                ? 'Loading...'
                : _isStaffUser
                    ? 'Logged in as Staff: ${_loggedInUser?.email}'
                    : 'Access Denied: Staff Login Required',
            style: TextStyle(
              fontSize: 12,
              color: _isStaffUser ? Colors.green[800] : Colors.red[800],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_isStaffUser
              ? const Center(
                  child: Text(
                    'Access Denied. Please log in with a staff account.',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Student Selection Dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedStudentUid,
                          isExpanded: true,
                          hint: const Text('Select Target Student'),
                          decoration: InputDecoration(
                            labelText: 'Send To Student',
                            prefixIcon: const Icon(Icons.person_pin_outlined),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0)),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          items: _studentList
                              .map<DropdownMenuItem<String>>((student) {
                            return DropdownMenuItem<String>(
                              value: student['uid'],
                              child: Text(
                                student['displayName'],
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedStudentUid = newValue;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a student';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Notification Title',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.title),
                          ),
                          validator: (value) => (value == null || value.trim().isEmpty)
                              ? 'Please enter a title'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _bodyController,
                          decoration: const InputDecoration(
                            labelText: 'Notification Body',
                            hintText: 'Enter the message content',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.message),
                          ),
                          maxLines: 3,
                          validator: (value) => (value == null || value.trim().isEmpty)
                              ? 'Please enter a body message'
                              : null,
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton.icon(
                          icon: _isSending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send),
                          label: Text(_isSending
                              ? 'Sending...'
                              : 'Send Notification to Student'),
                          onPressed: (_isSending || !_isStaffUser || _selectedStudentUid == null)
                              ? null
                              : _sendNotification,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}