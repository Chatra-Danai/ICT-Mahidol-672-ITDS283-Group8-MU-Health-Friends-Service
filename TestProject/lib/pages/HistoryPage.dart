// pages/history_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // Helper function to get an icon based on service type
  IconData _getServiceIcon(String serviceType) {
    switch (serviceType) {
      case 'Medicine':
        return Icons.medical_services_outlined;
      case 'Doctor Visit':
        return Icons.person_search_outlined;
      case 'Wound Dressing':
        return Icons.health_and_safety_outlined;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Service History')),
        body: const Center(child: Text('Please log in to view history.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Service History')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .collection('healthHistory')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            debugPrint("Error reading history: ${snapshot.error}");
            return Center(child: Text('Error loading history: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No service history found.'));
          }

          final historyDocs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: historyDocs.length,
            itemBuilder: (context, index) {
              final historyData = historyDocs[index].data() as Map<String, dynamic>;

              final Timestamp timestamp = historyData['timestamp'] ?? Timestamp.now();
              final DateTime dateTime = timestamp.toDate();
              final String formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
              final serviceType = historyData['serviceType'] ?? 'Unknown Service';
              final notes = historyData['notes'] as String?;
              final staffName = historyData['staffName'] as String? ?? 'Unknown Staff';
              final table = historyData['assignedTable']?.toString();

              // Build subtitle string
              List<String> details = [];
              details.add('Staff: $staffName');
              if (table != null) {
                details.add('Table: $table');
              }
              if (notes != null && notes.isNotEmpty) {
                String shortNotes = notes.length > 50 ? "${notes.substring(0, 50)}..." : notes;
                details.add('Notes: $shortNotes');
              }
              details.add('Date: $formattedDate');

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                elevation: 2.0,
                child: ListTile(
                  leading: Icon(_getServiceIcon(serviceType), size: 30),
                  title: Text(serviceType, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    details.join('\n'),
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  isThreeLine: (notes != null && notes.isNotEmpty),
                ),
              );
            },
          );
        },
      ),
    );
  }
}