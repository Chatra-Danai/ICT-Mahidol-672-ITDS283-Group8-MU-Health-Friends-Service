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
import 'staff_queue_screen.dart';
// New imports for booking and feedback pages
import 'booking_page.dart';
import 'feedback_page.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
// Import Firebase Messaging types
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  int _bottomNavIndex = 0;
  Timer? _timer;
  String _currentTime = ''; // Will hold HH:mm:ss
  String _currentDateDisplay = ''; // Will hold Day number e.g., "17"
  String _currentDayName = ''; // Will hold Day name e.g., "Thursday"
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
    _updateTime(); // Initial call
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
    _fetchAQI();
    _fetchCurrentUserData();
    _initFcm(); // <-- Add this call
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    final DateTime now = DateTime.now();
    final String formattedTime = DateFormat('HH:mm:ss').format(now); // Time with seconds
    final String formattedDateNum = DateFormat('d').format(now);    // Day number
    final String formattedDayName = DateFormat('EEEE').format(now); // Full day name

    // Update state only if needed
    if (formattedTime != _currentTime || formattedDateNum != _currentDateDisplay || formattedDayName != _currentDayName) {
      if (mounted) {
        setState(() {
          _currentTime = formattedTime;
          _currentDateDisplay = formattedDateNum;
          _currentDayName = formattedDayName;
        });
      }
    }
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

  // Inside _UserDashboardScreenState class

  // Gets the current FCM token
  Future<String?> _getFcmToken() async {
      try {
          // For specific platforms or VAPID key for web, pass arguments here
          String? token = await FirebaseMessaging.instance.getToken();
          debugPrint("Current FCM Token: $token");
          return token;
      } catch(e) {
          debugPrint("Error getting FCM token: $e");
          return null;
      }
  }

  // Saves or updates the token in Firestore
  Future<void> _saveFcmToken(String? token) async {
      final user = FirebaseAuth.instance.currentUser;
      if (token == null || user == null) return; // Need token and logged-in user

      try {
          // Use .set with merge: true OR .update
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({'fcmToken': token}, SetOptions(merge: true)); // merge:true adds/updates field without overwriting doc
          // OR use update:
          // .update({'fcmToken': token}); // update fails if doc/field doesn't exist

          debugPrint("FCM token saved to Firestore for user ${user.uid}");
      } catch (e) {
          debugPrint("Error saving FCM token to Firestore: $e");
      }
  }

  // Helper function called from _initFcm
  Future<void> _getAndSaveFcmToken() async {
      String? currentToken = await _getFcmToken();
      await _saveFcmToken(currentToken);
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

  // --- MODIFIED: _buildAQIChip to be shorter and use Tooltip ---
  Widget _buildAQIChip() {
    String displayLabel = _aqiInfo; // Start with the full info/status
    String tooltipMessage = _aqiInfo; // Tooltip will show full info

    if (_isLoadingAQI) {
      // Display loading state concisely
      displayLabel = 'AQI...';
      tooltipMessage = 'Loading AQI data...';
    } else if (!_aqiInfo.contains('Error') && !_aqiInfo.contains('N/A') && !_aqiInfo.contains('Token Required')) {
      // --- Extract only the core AQI value and status text ---
      // Example: If _aqiInfo is "AQI: 75 (Moderate)"
      RegExp regExp = RegExp(r"AQI: (\d+)\s?\((.*?)\)");
      var match = regExp.firstMatch(_aqiInfo);
      if (match != null) {
          String aqiValue = match.group(1) ?? '--';
          String statusText = match.group(2) ?? '';
          // --- Construct the shorter label ---
          displayLabel = 'AQI: $aqiValue'; // Show only "AQI: 75"
          // Keep full details for tooltip
          tooltipMessage = "${_aqiLocationName.isNotEmpty ? _aqiLocationName + ': ' : ''}AQI: $aqiValue ($statusText)";
      } else {
           // Fallback if regex fails, show original info
           displayLabel = _aqiInfo;
           tooltipMessage = "$_aqiLocationName: $_aqiInfo";
      }

    } else {
        // Handle error states concisely
        if (_aqiInfo.contains('Token Required')) displayLabel = 'AQI: Token?';
        else if (_aqiInfo.contains('Unavailable')) displayLabel = 'AQI: N/A';
        else if (_aqiInfo.contains('Error')) displayLabel = 'AQI: Error';
        else displayLabel = 'AQI: --'; // Default fallback
        tooltipMessage = _aqiInfo; // Tooltip shows the error state
    }


    // Wrap the Chip in a Tooltip
    return Tooltip(
      message: tooltipMessage, // Show full details on long press/hover
      preferBelow: true, // Suggest tooltip position
      child: Chip(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), // Reduce padding slightly
        labelPadding: const EdgeInsets.only(left: 2, right: 4), // Reduce label padding
        avatar: _isLoadingAQI // Keep avatar only for loading? Optional.
            ? const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white70,))
            // Or remove avatar entirely to save more space:
            // : null,
            // Or keep icon based on color:
            : Icon(Icons.air, size: 14, color: _aqiColor == Colors.yellow.shade700 ? Colors.black54 : Colors.white70), // Adjust icon color for yellow
        label: Text(
          displayLabel, // Display the shorter label
          style: TextStyle(
            color: _aqiColor == Colors.yellow.shade700 ? Colors.black87 : Colors.white, // Adjust text color for yellow
            fontSize: 11, // Keep font size small
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: _aqiColor.withOpacity(0.85), // Use the status color
        side: BorderSide.none, // Remove border to save space
      ),
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

  Future<void> _initFcm() async {
  // Request permission from the user
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  debugPrint('User granted notification permission: ${settings.authorizationStatus}');

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    // Get the FCM token and save it
    await _getAndSaveFcmToken();

    // Listen for token refresh (tokens can change)
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      debugPrint("FCM Token Refreshed: $newToken");
      _saveFcmToken(newToken); // Save the new token if it refreshes
    }).onError((err) {
       debugPrint("Error listening to token refresh: $err");
    });

    // --- Handle Incoming Messages ---

    // Listener for messages received WHILE the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground FCM message received!');
      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification?.title} - ${message.notification?.body}');
        // Optional: Show a local notification using flutter_local_notifications
        // Or show an in-app dialog/snackbar
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Notification: ${message.notification?.title ?? ""}'),
            duration: Duration(seconds: 5),
        ));
      }
    });

    // Listener for when a user taps a notification which opened the app from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Message clicked! Navigating to notifications...');
      // Example: Navigate to NotificationScreen when notification is tapped
       Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const NotificationScreen(),
       ));
      // You could also extract data from message.data and navigate specifically
    });

  } else {
    debugPrint('User declined or has not accepted notification permissions');
    // Optionally inform the user they need permissions for alerts
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time and Date Cards
            Row(
              children: [
                // Display Time
                Expanded(
                  child: _QuickAccessCard(
                    Icons.access_time_outlined,
                    'Time',
                    _currentTime.isEmpty ? '--:--:--' : _currentTime,
                  ),
                ),
                const SizedBox(width: 8),
                // Display Date
                Expanded(
                  child: _QuickAccessCard(
                    Icons.calendar_today_outlined,
                    _currentDayName.isEmpty ? 'Date' : _currentDayName,
                    _currentDateDisplay.isEmpty ? '--' : _currentDateDisplay,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Services Section
            const Text('การให้บริการ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ServiceCard(
                    'โทรหาคุณหมอ (MU FRIENDS)',
                    'Book Now',
                    'assets/images/doctor.jpg',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BookingPage()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ServiceCard(
                    'เข้ารับบริการ',
                    'Schedule',
                    'assets/images/stethoscope.jpg',
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Schedule action TBD')),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Health Stats Section
            const Text('สถิติสุขภาพของฉัน', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _StatCard('ก้าว', '8,500', '+10%')),
                const SizedBox(width: 12),
                Expanded(child: _StatCard('แคลอรี่', '900', '-5%')),
              ],
            ),
            const SizedBox(height: 20),

            // Feedback Button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FeedbackPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Feedback Survey', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      
      // Inside _UserDashboardScreenState -> build() -> Scaffold -> BottomNavigationBar

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTap: (index) {
          // --- Role-Based Navigation Logic ---

          // Prevent action if user data (including type) is still loading
          if (_isLoadingUserData && index != 0) { // Allow navigating home even if loading
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Loading user data...'), duration: Duration(seconds: 1)),
            );
            return;
          }

          // Don't rebuild if tapping the currently active item
          if (index == _bottomNavIndex && index != 1 && index != 2) return; // Allow re-tapping appointments/profile to push screen again if needed


          // Handle navigation/action based on the tapped index
          switch (index) {
            case 0: // Home
              // If your dashboard body changes based on index, handle state update here.
              // For now, just visually select the Home tab if it's not already selected.
              if (index != _bottomNavIndex) {
                setState(() {
                  _bottomNavIndex = index;
                });
              }
              break;

            case 1: // Appointments
              // --- THIS IS THE LOGIC YOU ASKED ABOUT ---
              if (_userType == 'student') {
                // Navigate Student to the renamed Booking Screen
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const BookingPage(), // Already uses the correct class name
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
              // --- END OF APPOINTMENTS LOGIC ---
              break; // Don't update _bottomNavIndex visually when pushing a new screen

            case 2: // Profile -> Navigate to Settings
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const SettingsScreen(),
              ));
              break; // Don't update _bottomNavIndex visually when pushing a new screen
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey[600],
        // --- Correct items list ---
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined), // Icon for the tab
            activeIcon: Icon(Icons.home),    // Optional: Icon when tab is selected
            label: 'Home',                   // Text label for the tab
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        // --- End of correct items list ---
      ),
    );
  }
}

// Helper Widgets
class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _QuickAccessCard(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: 110,
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.grey[700]),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String title;
  final String buttonText;
  final String imagePath;
  final VoidCallback? onPressed;

  const _ServiceCard(this.title, this.buttonText, this.imagePath, [this.onPressed, Key? key]) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            imagePath,
            height: 120,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 120,
                color: Colors.grey[200],
                child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: onPressed,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: Colors.blue,
                  ),
                  child: Text(buttonText, style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String change;

  const _StatCard(this.label, this.value, this.change, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              change,
              style: TextStyle(
                fontSize: 12,
                color: change.startsWith('+') ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}