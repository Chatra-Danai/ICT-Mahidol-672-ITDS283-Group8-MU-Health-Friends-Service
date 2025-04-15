import 'package:flutter/material.dart';
import 'home_content.dart'; // Import the home content page
import 'booking_page.dart'; // Import the booking page

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  int? _selectedRating;
  String? _ratingError;
  final _commentController = TextEditingController();
  int _ratingScale = 5; // Default rating scale is 1-5
  int _selectedIndex = 0; // To manage the selected bottom navigation item

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (_selectedIndex == 0) {
        Navigator.pop(context); // Go back to HomeContent
      } else if (_selectedIndex == 1) {
        // Navigate to Booking Page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BookingPage()),
        );
      }
      // You can add navigation for other items if needed
    });
  }

  void _submitFeedback() {
    setState(() {
      if (_selectedRating == null) {
        _ratingError = 'กรุณาใส่คะแนน';
      } else {
        _ratingError = '';
        String comment = _commentController.text;
        // ส่งข้อมูล _selectedRating และ comment ไปยังเซิร์ฟเวอร์หรือจัดการข้อมูล
        print('Rating: $_selectedRating');
        print('Comment: $comment');

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('ขอบคุณสำหรับความคิดเห็น!'),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 60, color: Colors.green),
                  SizedBox(height: 16),
                  Text('ส่งข้อมูลสำเร็จ', style: TextStyle(fontSize: 18)),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('ตกลง'),
                  onPressed: () {
                    Navigator.of(context).pop(); // ปิด Dialog
                    setState(() {
                      _selectedRating = null;
                      _commentController.clear();
                      _selectedIndex = 0; // Set selected index back to Home
                      Navigator.pop(context); // Go back to HomeContent
                    });
                  },
                ),
              ],
            );
          },
        );
      }
    });
  }

  Widget _buildRatingOptions() {
    List<Widget> options = [];
    for (int i = 1; i <= _ratingScale; i++) {
      options.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedRating = i;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _selectedRating == i ? Colors.blue : Colors.grey[300],
            ),
            child: Text(
              '$i',
              style: TextStyle(
                color: _selectedRating == i ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
      if (i < _ratingScale) {
        options.add(const SizedBox(width: 8));
      }
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: options,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // กลับไปยัง HomeContent เมื่อกดปุ่มย้อนกลับที่ AppBar
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundImage: AssetImage('assets/images/profile.png'),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'คุณ วินีธา, 6687001',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text('สถานที่ใกล้คุก, MU HEALTH'),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () {
                    // ฟังก์ชันการทำงานเมื่อกดปุ่มแจ้งเตือน
                    print('Notification button pressed');
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('ให้คะแนนเรา', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Rating Scale:'),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _ratingScale,
                  items: const [
                    DropdownMenuItem(value: 5, child: Text('1-5')),
                    DropdownMenuItem(value: 10, child: Text('1-10')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _ratingScale = value!;
                      _selectedRating = null; // Reset selected rating when scale changes
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildRatingOptions(),
            if (_ratingError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _ratingError!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 16),
            Center(
              child: Image.asset('assets/images/feedback_body.jpg', height: 200),
            ),
            const SizedBox(height: 24),
            const Text('ความคิดเห็นเพิ่มเติม', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'ใส่ความคิดเห็นของคุณที่นี่',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _submitFeedback,
                child: const Text('ส่งความคิดเห็น'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'หน้าหลัก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'เมนู',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}