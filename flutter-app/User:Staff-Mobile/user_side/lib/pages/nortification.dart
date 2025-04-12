import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore stream
import 'package:firebase_auth/firebase_auth.dart'; // To get current user UID
import 'package:intl/intl.dart'; // For formatting timestamps

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  Stream<QuerySnapshot>? _notificationStream;

  @override
  void initState() {
    super.initState();
    _setupNotificationStream();
  }

  void _setupNotificationStream() {
    if (_currentUser != null) {
      // Listen to the 'notifications' subcollection for the current user
      // Order by 'timestamp' in descending order (newest first)
      _notificationStream = FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .snapshots(); // snapshots() provides the real-time stream
    } else {
      // Handle case where user is not logged in (though ideally this screen
      // wouldn't be accessible if not logged in)
      debugPrint("NotificationScreen: No user logged in.");
    }
     // Trigger a rebuild in case _currentUser was initially null but becomes available
     // shortly after initState (less common but possible in complex flows)
     // Alternatively, pass User object or use an Auth state listener higher up.
     if(mounted) setState(() {});
  }

  // Helper to format timestamp
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'No date';
    // Example format: "Apr 12, 5:31 PM" or relative time "5 minutes ago"
    // Using intl package for nice formatting
    final DateTime dateTime = timestamp.toDate();
     // Simple relative time logic (can be improved)
    final Duration difference = DateTime.now().difference(dateTime);
     if (difference.inMinutes < 60) {
         return '${difference.inMinutes}m ago';
     } else if (difference.inHours < 24) {
          return '${difference.inHours}h ago';
     } else {
         return DateFormat('MMM d, hh:mm a').format(dateTime); // e.g., Apr 12, 05:31 PM
     }

  }

  // TODO: Implement function to mark notification as read
  // Future<void> _markAsRead(String notificationId) async {
  //   if (_currentUser == null) return;
  //   try {
  //     await FirebaseFirestore.instance
  //         .collection('users')
  //         .doc(_currentUser!.uid)
  //         .collection('notifications')
  //         .doc(notificationId)
  //         .update({'isRead': true});
  //   } catch (e) {
  //      debugPrint("Error marking notification as read: $e");
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
      ),
      body: _currentUser == null
          ? const Center(child: Text('Please log in to see notifications.'))
          : StreamBuilder<QuerySnapshot>(
              stream: _notificationStream,
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                // --- Handle Stream States ---
                if (snapshot.hasError) {
                  debugPrint("Error in notification stream: ${snapshot.error}");
                  return const Center(child: Text('Something went wrong loading notifications.'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No notifications yet.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                // --- Display Notifications ---
                final notifications = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final doc = notifications[index];
                    // Access data safely using .data() which returns Object?
                    // then cast to Map<String, dynamic>
                    final data = doc.data() as Map<String, dynamic>?;

                    // Use null-aware operators and provide defaults
                    final String title = data?['title'] as String? ?? 'No Title';
                    final String body = data?['body'] as String? ?? 'No Content';
                    final Timestamp? timestamp = data?['timestamp'] as Timestamp?;
                    final bool isRead = data?['isRead'] as bool? ?? false; // Assume unread if field missing
                    // final String type = data?['type'] as String? ?? 'general'; // Example type field

                    // Determine visual style based on read status
                    final fontWeight = isRead ? FontWeight.normal : FontWeight.bold;
                    final tileColor = isRead ? Colors.white : Colors.blue.shade50; // Subtle highlight for unread

                    return Card( // Wrap ListTile in Card for better visual separation
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      elevation: isRead ? 1 : 2,
                      color: tileColor,
                      child: ListTile(
                        leading: Icon( // Choose icon based on type or read status
                          isRead ? Icons.notifications_none_outlined : Icons.notifications_active,
                          color: isRead ? Colors.grey : Theme.of(context).primaryColor,
                        ),
                        title: Text(title, style: TextStyle(fontWeight: fontWeight)),
                        subtitle: Text(body),
                        trailing: Text(
                          _formatTimestamp(timestamp),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        onTap: () {
                          // TODO: Handle tap action
                          // 1. Mark as read: _markAsRead(doc.id);
                          // 2. Potentially navigate based on notification content/type
                          debugPrint("Tapped notification: ${doc.id}");
                           ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Mark as read / navigation not implemented yet.'), duration: Duration(seconds: 1)),
                           );
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}