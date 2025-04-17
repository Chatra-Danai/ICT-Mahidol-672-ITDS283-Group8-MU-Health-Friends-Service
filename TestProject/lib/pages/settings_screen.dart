import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added Firestore import

// Import your login screen (adjust path if needed)
import 'authen.dart';
// Import your edit profile screen (create this file next)
import 'edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSetting();
  }

  Future<void> _loadNotificationSetting() async {
    if (_currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (docSnapshot.exists && mounted) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _notificationsEnabled = data['pushNotificationsEnabled'] as bool? ?? true;
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error loading notification setting: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateNotificationSetting(bool newValue) async {
    if (_currentUser == null) return;

    setState(() {
      _notificationsEnabled = newValue;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .update({'pushNotificationsEnabled': newValue});
    } catch (e) {
      debugPrint("Error updating notification setting: $e");
      if (mounted) {
        setState(() {
          _notificationsEnabled = !newValue;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update setting: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthenticationScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      debugPrint("Error logging out: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error logging out: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Edit Profile'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    );
                  },
                ),
                const Divider(),

                // Replaced Notifications ListTile with SwitchListTile
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Push Notifications'),
                  subtitle: const Text('Receive alerts about queues and appointments'),
                  value: _notificationsEnabled,
                  onChanged: (bool newValue) {
                    _updateNotificationSetting(newValue);
                  },
                  activeColor: Theme.of(context).primaryColor,
                ),
                const Divider(),

                // Kept Account Security option (unchanged)
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Account Security'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // TODO: Implement Account Security options
                  },
                ),
                const Divider(),

                // Logout option with confirmation dialog
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.red[700]),
                  title: Text(
                    'Logout',
                    style: TextStyle(color: Colors.red[700]),
                  ),
                  onTap: () async {
                    final bool? confirmLogout = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Confirm Logout'),
                          content: const Text('Are you sure you want to log out?'),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () {
                                Navigator.of(context).pop(false);
                              },
                            ),
                            TextButton(
                              child: Text('Logout', style: TextStyle(color: Colors.red[700])),
                              onPressed: () {
                                Navigator.of(context).pop(true);
                              },
                            ),
                          ],
                        );
                      },
                    );

                    if (confirmLogout == true) {
                      await _logout(context);
                    }
                  },
                ),
                const Divider(),
              ],
            ),
    );
  }
}