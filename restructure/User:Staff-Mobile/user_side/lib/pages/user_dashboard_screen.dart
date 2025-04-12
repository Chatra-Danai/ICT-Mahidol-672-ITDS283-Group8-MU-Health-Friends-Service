import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Firebase imports
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Keep if needed elsewhere

// Import the screen files
import 'nortification.dart';          // Screen for students
import 'staff_notification_sender.dart'; // Screen for staff
import 'settings_screen.dart';         // Settings screen

// In user_dashboard_screen.dart
import 'appointment_booking_screen.dart'; // Import the new booking screen

// In user_dashboard_screen.dart
import 'appointment_booking_screen.dart'; // For students
import 'staff_queue_screen.dart';       // For staff
// ... other imports ...

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  int _bottomNavIndex = 0;
  Timer? _timer;
  String _currentTime = '';
  String _currentDate = '';
  bool _isLoadingAQI = true;
  String _aqiInfo = 'Loading AQI...';
  Color _aqiColor = Colors.grey;

  // User data variables
  String _userName = "Loading...";
  String _userDisplayId = "";
  String _organization = "Puenjai Clinic, MU HEALTH";
  String? _profilePicUrl;
  bool _isLoadingUserData = true;
  String? _userType; // For storing user type (student or staff)

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
    _fetchAQI();
    _fetchCurrentUserData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = DateFormat('HH:mm:ss').format(now);
      _currentDate = DateFormat('EEEE, MMMM d').format(now);
    });
  }

  Future<void> _fetchAQI() async {
    setState(() => _isLoadingAQI = true);
    try {
      final response = await http.get(Uri.parse('https://api.waqi.info/feed/bangkok/?token=demo'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final aqi = data['data']['aqi'] as int? ?? 0;
        _updateAQIDisplay(aqi);
        setState(() {
          _aqiInfo = 'AQI: $aqi';
        });
      }
    } catch (e) {
      debugPrint("AQI fetch error: $e");
      setState(() {
        _aqiInfo = 'AQI: --';
        _aqiColor = Colors.grey;
      });
    } finally {
      setState(() => _isLoadingAQI = false);
    }
  }

  void _updateAQIDisplay(int aqi) {
    setState(() {
      _aqiColor = aqi < 50
          ? Colors.green
          : aqi < 100
              ? Colors.yellow
              : aqi < 150
                  ? Colors.orange
                  : Colors.red;
    });
  }

  Future<void> _fetchCurrentUserData() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _userName = "Not Logged In";
          _isLoadingUserData = false;
        });
      }
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && mounted) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _userName = "${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}".trim();
          _userDisplayId = userData['studentOrStaffId']?.toString() ?? '';
          _profilePicUrl = userData['profilePictureUrl'];
          _userType = userData['userType'] as String?; // Store user type
          _isLoadingUserData = false;
        });
      } else if (mounted) {
        setState(() {
          _userName = "User Data Not Found";
          _isLoadingUserData = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      if (mounted) {
        setState(() {
          _userName = "Error Loading Data";
          _isLoadingUserData = false;
        });
      }
    }
  }

  Widget _buildProfileAvatar() {
    return CircleAvatar(
      radius: 25,
      backgroundColor: Colors.grey[200],
      child: _profilePicUrl != null && _profilePicUrl!.isNotEmpty
          ? ClipOval(
              child: Image.network(
                _profilePicUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const CircularProgressIndicator();
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.person, size: 30, color: Colors.grey);
                },
              ),
            )
          : const Icon(Icons.person, size: 30, color: Colors.grey),
    );
  }

  Widget _buildAQIChip() {
    if (_isLoadingAQI) {
      return const SizedBox(
        width: 60,
        child: LinearProgressIndicator(),
      );
    }
    return Chip(
      label: Text(
        _aqiInfo,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: _aqiColor,
    );
  }

  void _handleNotificationIconTap() {
    if (_isLoadingUserData || _userType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading user data...'), duration: Duration(seconds: 1)),
      );
      return;
    }

    if (_userType == 'student') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NotificationScreen()),
      );
    } else if (_userType == 'staff') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const StaffNotificationSenderScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification action not available for your user type.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0, top: 4.0, bottom: 4.0),
          child: _buildProfileAvatar(),
        ),
        title: _isLoadingUserData
            ? const SizedBox(
                height: 20,
                width: 100,
                child: LinearProgressIndicator(),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _organization,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_userDisplayId.isNotEmpty)
                    Text(
                      _userDisplayId,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
              ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _buildAQIChip(),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 28),
            onPressed: _handleNotificationIconTap,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 28),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Add your dashboard content here
            // Appointment cards, services, etc.
          ],
        ),
      ),
// In _UserDashboardScreenState -> build() -> Scaffold -> BottomNavigationBar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTap: (index) {
          // --- MODIFIED onTap Logic for Role-Based Navigation ---

          // Prevent action if user data (including type) is still loading
          if (_isLoadingUserData) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Loading user data...'), duration: Duration(seconds: 1)),
            );
            return;
          }

          // Handle navigation based on index and user type
          if (index == 1) { // Appointments Tab Tapped
            if (_userType == 'student') {
              // Navigate Student to Booking Screen
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const AppointmentBookingScreen(),
              ));
            } else if (_userType == 'staff') {
              // Navigate Staff to Queue Screen
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const StaffQueueScreen(),
              ));
            } else {
              // Handle unknown or missing user type
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cannot determine user role for appointments.')),
              );
            }
            // Optional: Don't change the _bottomNavIndex visually when pushing a new screen
            // If you want the 'Home' icon to remain selected after pushing,
            // simply don't call setState here for index 1.
            // setState(() => _bottomNavIndex = index); // <-- Remove or comment this out for index 1 if desired

          } else {
            // Handle other tabs (Home, Analytics, Chat) - Just update index for now
            // or implement their navigation/body change
            if (index != _bottomNavIndex) { // Avoid unnecessary rebuild if tapping current tab
              setState(() {
                _bottomNavIndex = index;
                // TODO: Implement navigation/body change for Home(0), Analytics(2), Chat(3)
              });
            }
          }
          // --- End of MODIFIED onTap Logic ---
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Appointments'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}