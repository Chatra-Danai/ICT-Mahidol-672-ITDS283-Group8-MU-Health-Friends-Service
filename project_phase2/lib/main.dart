import 'package:flutter/material.dart';
 //import 'package:firebase_core/firebase_core.dart';
 //import 'firebase_options.dart';
 import 'package:project_phase2/pages/home_content.dart';
 import 'package:project_phase2/pages/booking_page.dart';
 import 'package:project_phase2/pages/analytics_page.dart';
 import 'package:project_phase2/pages/scan_page.dart'; // Uncomment บรรทัดนี้
 import 'package:project_phase2/pages/feedback_page.dart';
 //import 'package:project_phase2/input_data_screen.dart'; // Import ไฟล์ InputDataScreen ที่เราสร้าง

 void main() {
   runApp(const MyApp());
 }

 class MyApp extends StatelessWidget {
   const MyApp({super.key});

   @override
   Widget build(BuildContext context) {
     return MaterialApp(
       title: 'MU HEALTH',
       debugShowCheckedModeBanner: false,
       theme: ThemeData(
         primarySwatch: Colors.blue,
       ),
       home: const HomeScreen(),
     );
   }
 }

 class HomeScreen extends StatefulWidget {
   const HomeScreen({super.key});

   @override
   State<HomeScreen> createState() => _HomeScreenState();
 }

 class _HomeScreenState extends State<HomeScreen> {
   int _selectedIndex = 0;

   final List<Widget> _pages = [
     const HomeContent(),
     const BookingPage(),
     const AnalyticsPage(),
     const ScanPage(), // เปลี่ยนตรงนี้ให้ไปที่ ScanPage
     // const FeedbackPage(), // เอาออกถ้าไม่ต้องการแสดงที่ Tab นี้
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
         title: const Row(
           children: [
             CircleAvatar(
               backgroundImage: AssetImage('assets/images/profile.png'),
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
         items: const [
           BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
           BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Booking'),
           BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analytics'),
           BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: 'Scan'),
         ],
       ),
     );
   }
 }