import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Firebase imports
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Geolocator import
import 'package:geolocator/geolocator.dart';

// Import the screen files
import 'nortification.dart'; // Renamed from nortification.dart
import 'staff_notification_sender.dart';
import 'settings_screen.dart';
import 'appointment_booking_screen.dart';
import 'staff_queue_screen.dart';

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
String _aqiLocationName = "Loading Location...";

// User data variables
String _userName = "Loading...";
String _userDisplayId = "";
String _organization = "Puenjai Clinic, MU HEALTH";
String? _profilePicUrl;
bool _isLoadingUserData = true;
String? _userType;

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

Future<Position?> _getCurrentLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    debugPrint('Location services are disabled.');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location services are disabled. Please enable them.')),
    );
    return null;
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      debugPrint('Location permissions are denied');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions are denied.')),
      );
      return null;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    debugPrint('Location permissions are permanently denied');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location permissions are permanently denied. Please enable them in settings.')),
    );
    return null;
  }

  try {
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
  } catch (e) {
    debugPrint("Error getting location: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not get location: $e')),
    );
    return null;
  }
}

Future<void> _fetchAQI() async {
  if (!mounted) return;
  setState(() {
    _isLoadingAQI = true;
    _aqiInfo = 'Getting Location...';
    _aqiLocationName = "";
  });

  Position? position = await _getCurrentLocation();
  String apiUrl;
  const String token = "ef9ee7049ac9cdfedd05c4196f3b46122dc452e4";

  if (position != null && mounted) {
    final lat = position.latitude;
    final lon = position.longitude;
    apiUrl = "https://api.waqi.info/feed/geo:$lat;$lon/?token=$token";
    setState(() => _aqiInfo = 'Fetching AQI...');
  } else if (mounted) {
    setState(() => _aqiInfo = 'Location Failed. Using Default.');
    apiUrl = "https://api.waqi.info/feed/bangkok/?token=$token";
  } else {
    return;
  }

  try {
    final response = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200 && mounted) {
      final data = json.decode(response.body);
      if (data['status'] == 'ok') {
        final aqi = data['data']['aqi'] as int? ?? 0;
        final locationName = data['data']['city']?['name'] as String? ?? (position == null ? "Bangkok" : "Current Location");
        _updateAQIDisplay(aqi);
        setState(() {
          _aqiInfo = 'AQI: $aqi';
          _aqiLocationName = locationName;
        });
      } else {
        debugPrint("AQI API Error Status: ${data['status']}");
        setState(() {
          _aqiInfo = 'AQI: N/A';
          _aqiLocationName = "API Error";
          _aqiColor = Colors.grey;
        });
      }
    } else if (mounted) {
      debugPrint("AQI HTTP Error: ${response.statusCode}");
      setState(() {
        _aqiInfo = 'AQI: HTTP Error';
        _aqiLocationName = "";
        _aqiColor = Colors.grey;
      });
    }
  } catch (e) {
    debugPrint("AQI fetch exception: $e");
    if (mounted) {
      setState(() {
        _aqiInfo = 'AQI: Error';
        _aqiLocationName = "";
        _aqiColor = Colors.grey;
      });
    }
  } finally {
    if (mounted) {
      setState(() => _isLoadingAQI = false);
    }
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
        _userType = userData['userType'] as String?;
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
    return Chip(
      label: Text(
        _aqiInfo,
        style: const TextStyle(fontSize: 10),
      ),
      avatar: const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }

  String displayLabel = _aqiInfo;
  if (_aqiLocationName.isNotEmpty && !_aqiInfo.contains('Error') && !_aqiInfo.contains('N/A')) {
    displayLabel = "$_aqiLocationName: ${_aqiInfo.replaceFirst('AQI: ', '')}";
  } else if (_aqiInfo.contains('Error') || _aqiInfo.contains('N/A')) {
    displayLabel = _aqiInfo;
  }

  return Chip(
    label: Text(
      displayLabel,
      style: TextStyle(
        color: _aqiColor == Colors.yellow ? Colors.black87 : Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
      overflow: TextOverflow.ellipsis,
    ),
    backgroundColor: _aqiColor,
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    labelPadding: const EdgeInsets.only(left: 4, right: 4),
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
          padding: const EdgeInsets.only(right: 4.0),
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
        ],
      ),
    ),
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _bottomNavIndex,
      onTap: (index) {
        if (_isLoadingUserData) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Loading user data...'), duration: Duration(seconds: 1)),
          );
          return;
        }

        if (index == 1) {
          if (_userType == 'student') {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const AppointmentBookingScreen(),
            ));
          } else if (_userType == 'staff') {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const StaffQueueScreen(),
            ));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cannot determine user role for appointments.')),
            );
          }
        } else {
          if (index != _bottomNavIndex) {
            setState(() {
              _bottomNavIndex = index;
            });
          }
        }
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