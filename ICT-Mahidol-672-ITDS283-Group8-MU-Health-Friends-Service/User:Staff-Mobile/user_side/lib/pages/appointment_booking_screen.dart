import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppointmentBookingScreen extends StatefulWidget {
  const AppointmentBookingScreen({super.key});

  @override
  State<AppointmentBookingScreen> createState() => _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoadingUserData = true;
  bool _isSubmitting = false;
  String _userName = 'User';
  String? _profilePicUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_currentUser == null) {
      if (mounted) setState(() => _isLoadingUserData = false);
      return;
    }

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (!mounted) return;

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        setState(() {
          _userName = "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}".trim();
          if (_userName.isEmpty) _userName = _currentUser?.email ?? 'User';
          _profilePicUrl = data['profilePictureUrl'];
          _isLoadingUserData = false;
        });
      } else {
        setState(() => _isLoadingUserData = false);
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
      if (mounted) setState(() => _isLoadingUserData = false);
    }
  }

  Future<void> _requestService(String serviceType) async {
    if (_currentUser == null || _isLoadingUserData || _isSubmitting) {
      if (mounted && !_isSubmitting) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please wait while we load your data')),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      debugPrint("Attempting to add service request for user: ${_currentUser!.uid}");
      
      await FirebaseFirestore.instance.collection('serviceQueue').add({
        'userId': _currentUser!.uid,
        'userName': _userName,
        'profilePictureUrl': _profilePicUrl,
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'waiting',
        'serviceTypeRequested': serviceType,
        'updatedAt': FieldValue.serverTimestamp(), // Added for tracking updates
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$serviceType request submitted!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e, stackTrace) {
      debugPrint("Error submitting request: $e\n$stackTrace");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildServiceButton({
    required String label,
    required IconData icon,
    required String serviceTypeInternal,
    required Color color,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 28),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(label, style: const TextStyle(fontSize: 18)),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.8),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 3,
        minimumSize: const Size(double.infinity, 60), // Consistent button height
      ),
      onPressed: _isSubmitting ? null : () => _requestService(serviceTypeInternal),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Service'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: _isLoadingUserData
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Hi $_userName, please select a service:',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  
                  _buildServiceButton(
                    label: 'Medicine',
                    icon: Icons.medical_services_outlined,
                    serviceTypeInternal: 'Medicine',
                    color: Colors.orange.shade600,
                  ),
                  const SizedBox(height: 20),
                  
                  _buildServiceButton(
                    label: 'See Doctor',
                    icon: Icons.person_search_outlined,
                    serviceTypeInternal: 'Doctor Visit',
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(height: 20),
                  
                  _buildServiceButton(
                    label: 'Wound Dressing',
                    icon: Icons.health_and_safety_outlined,
                    serviceTypeInternal: 'Wound Dressing',
                    color: Colors.red.shade500,
                  ),
                  const SizedBox(height: 40),
                  
                  if (_isSubmitting)
                    const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Submitting your request...'),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}