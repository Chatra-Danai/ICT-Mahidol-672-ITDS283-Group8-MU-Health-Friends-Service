import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // สำหรับ DateFormat ถ้าต้องการแสดงเวลา

class ActiveServiceScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String queueDocId; // ID ของเอกสารใน serviceQueue
  final int tableNumber;
  final String serviceTypeCalled; // ประเภทบริการที่เรียกไป

  const ActiveServiceScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.queueDocId,
    required this.tableNumber,
    required this.serviceTypeCalled,
  });

  @override
  State<ActiveServiceScreen> createState() => _ActiveServiceScreenState();
}

class _ActiveServiceScreenState extends State<ActiveServiceScreen> {
  final _notesController = TextEditingController();
  final User? _currentStaffUser = FirebaseAuth.instance.currentUser;
  bool _isSaving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // --- Logic to complete service and save history ---
  Future<void> _completeAndSaveHistory() async {
    if (_currentStaffUser == null) {
       ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Error: Staff user not found.'), backgroundColor: Colors.red),
       );
       return;
    }
    if (_isSaving) return; // Prevent double saving

    setState(() => _isSaving = true);
    bool success = false;

    final String notes = _notesController.text.trim();

    try {
      // Get Firestore instance
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      // Get a batch write object for atomic operations
      WriteBatch batch = firestore.batch();

      // 1. Reference to the new health history document
      DocumentReference historyRef = firestore
          .collection('users')
          .doc(widget.userId) // Use userId passed to screen
          .collection('healthHistory')
          .doc(); // Let Firestore generate ID

      // Data for health history
      Map<String, dynamic> historyData = {
        'timestamp': FieldValue.serverTimestamp(),
        'serviceType': widget.serviceTypeCalled,
        'notes': notes.isEmpty ? null : notes, // Store null if notes are empty
        'staffId': _currentStaffUser!.uid,
        'staffName': _currentStaffUser!.email, // Or fetch staff name from their profile
        'assignedTable': widget.tableNumber,
        'queueDocId': widget.queueDocId, // Link back to the queue document
      };

      // Add the create operation to the batch
       batch.set(historyRef, historyData);


      // 2. Reference to the original queue document
      DocumentReference queueRef = firestore
          .collection('serviceQueue')
          .doc(widget.queueDocId); // Use queueDocId passed

      // Add the update operation to the batch
       batch.update(queueRef, {
          'status': 'completed', // Mark queue item as completed
          'completedAt': FieldValue.serverTimestamp(), // Optional: record completion time
       });

       // 3. Commit the batch write
       await batch.commit();

       success = true;
       debugPrint("Health history saved and queue updated for user ${widget.userId}");

    } catch (e) {
        success = false;
        debugPrint("Error saving history/updating queue: $e");
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Error saving data: $e'), backgroundColor: Colors.red),
           );
        }
    } finally {
        if (mounted) {
           setState(() => _isSaving = false);
           if (success) {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Service completed and history saved!'), backgroundColor: Colors.green),
               );
               Navigator.of(context).pop(); // Go back to Queue screen
           }
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Service for ${widget.userName}'),
        // Optionally add table number: title: Text('Service for ${widget.userName} - Table ${widget.tableNumber}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patient:', style: Theme.of(context).textTheme.labelLarge),
            Text(widget.userName, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text('Service Type:', style: Theme.of(context).textTheme.labelLarge),
            Text(widget.serviceTypeCalled, style: Theme.of(context).textTheme.titleMedium),
             const SizedBox(height: 16),
            Text('Assigned Table:', style: Theme.of(context).textTheme.labelLarge),
            Text(widget.tableNumber.toString(), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
             const Divider(),
             const SizedBox(height: 16),

            Text('Service Notes:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Enter any notes about the service provided...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                icon: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline),
                label: Text(_isSaving ? 'Saving...' : 'Complete Service & Save History'),
                onPressed: _isSaving ? null : _completeAndSaveHistory,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                   backgroundColor: Colors.green[700],
                   foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}