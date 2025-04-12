import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomeContent(),
    AppointmentsPage(),
    AnalyticsPage(),
    ScanPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage('assets/profile.jpg'),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'คุณวิทธา, 6687001',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
                Text(
                  'สถานที่ใกล้คุณ, MU HEALTH',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            Spacer(),
            Icon(Icons.notifications, color: Colors.black),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Appointments'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
        ],
      ),
    );
  }
}

// ================== Home Content ==================
class HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuickAccessCard(Icons.access_time, 'จำนวนครั้ง'),
              _buildQuickAccessCard(Icons.calendar_today, 'นัดหมาย'),
            ],
          ),
          SizedBox(height: 20),
          Text('การให้บริการ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildServiceCard('โทรหาคุณหมอ (MU FRIENDS)', 'Book Now', 'assets/images/doctor.jpg')),
              SizedBox(width: 10),
              Expanded(child: _buildServiceCard('เข้ารับบริการ', 'Schedule', 'assets/images/stethoscope.jpg')),
            ],
          ),
          SizedBox(height: 20),
          Text('สถิติสุขภาพของฉัน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Row(
            children: [
              _buildStatCard('ก้าว', '8,500', '+10%'),
              SizedBox(width: 10),
              _buildStatCard('แคลอรี่', '900', '-5%'),
            ],
          ),
          Spacer(),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              minimumSize: Size(double.infinity, 50),
            ),
            child: Text('Feedback Survey', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessCard(IconData icon, String label) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 30),
              SizedBox(height: 10),
              Text(label, style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(String title, String buttonText, String imagePath) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(imagePath, height: 100, width: double.infinity, fit: BoxFit.cover),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                TextButton(onPressed: () {}, child: Text(buttonText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String change) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              Text(label, style: TextStyle(fontSize: 14, color: Colors.grey)),
              SizedBox(height: 5),
              Text(change, style: TextStyle(fontSize: 14, color: change.contains('+') ? Colors.green : Colors.red)),
            ],
          ),
        ),
      ),
    );
  }
}

// ================== Dummy Pages for Navigation ==================
class AppointmentsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Appointments Page"));
  }
}

class AnalyticsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Analytics Page"));
  }
}

class ScanPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Scan Page"));
  }
}
