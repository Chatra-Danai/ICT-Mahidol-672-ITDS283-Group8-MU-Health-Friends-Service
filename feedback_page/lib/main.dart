import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Feedback Page',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FeedbackPage(),
    );
  }
}

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _ratingController = TextEditingController();
  final _commentController = TextEditingController();
  String _ratingError = '';

  void _submitFeedback() {
    setState(() {
      if (_ratingController.text.isEmpty) {
        _ratingError = 'กรุณาใส่คะแนน';
      } else {
        try {
          int rating = int.parse(_ratingController.text);
          if (rating < 1 || rating > 5) {
            _ratingError = 'คะแนนต้องอยู่ระหว่าง 1-5';
          } else {
            _ratingError = '';
            String comment = _commentController.text;
            //ส่งข้อมูล rating และ comment ไปยังเซิร์ฟเวอร์หรือจัดการข้อมูล
            print('Rating: $rating');
            print('Comment: $comment');

            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('ขอบคุณสำหรับความคิดเห็น!'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 60, color: Colors.green),
                      SizedBox(height: 16),
                      Text('ส่งข้อมูลสำเร็จ', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: Text('ตกลง'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _ratingController.clear();
                        _commentController.clear();
                      },
                    ),
                  ],
                );
              },
            );
          }
        } catch (e) {
          _ratingError = 'กรุณาใส่ตัวเลข';
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('feedbackpage'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  
                  backgroundImage: AssetImage('assets/images/profile.png'),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'คุณ วินีธา, 6687001',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text('สถานที่ใกล้คุก, MU HEALTH'),
                  ],
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.notifications),
                  onPressed: () {
                    // ฟังก์ชันการทำงานเมื่อกดปุ่มแจ้งเตือน
                    print('Notification button pressed');
                  },
                ),
              ],
            ),
            SizedBox(height: 24),
            Text('ให้คะแนนเรา', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            TextField(
              controller: _ratingController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Rating scale: 1-5',
                border: OutlineInputBorder(),
                errorText: _ratingError.isNotEmpty ? _ratingError : null,
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: Image.asset('assets/images/feedback_body.jpg', height: 200),
            ),
            SizedBox(height: 24),
            Text('ความคิดเห็นเพิ่มเติม', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'ใส่ความคิดเห็นของคุณที่นี่',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _submitFeedback,
                child: Text('ส่งความคิดเห็น'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.grey),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today, color: Colors.grey),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics, color: Colors.grey),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner, color: Colors.grey),
            label: 'Scan',
          ),
        ],
        currentIndex: 0, 
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: (int index) {
        
          print('Bottom navigation item tapped: $index');
        },
      ),
    );
  }
}