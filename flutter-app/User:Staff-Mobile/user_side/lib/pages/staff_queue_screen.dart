import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class StaffQueueScreen extends StatefulWidget {
  const StaffQueueScreen({super.key});

  @override
  State<StaffQueueScreen> createState() => _StaffQueueScreenState();
}

class _StaffQueueScreenState extends State<StaffQueueScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  Stream<QuerySnapshot>? _queueStream;

  // State for managing selection and actions
  String? _selectedQueueDocId;
  String? _selectedUserId;
  String? _selectedUserName;
  String? _selectedServiceTypeRequested;
  bool _isProcessingAction = false;

  @override
  void initState() {
    super.initState();
    _setupQueueStream();
  }

  void _setupQueueStream() {
    if (_currentUser == null) {
      debugPrint("StaffQueueScreen: No staff user logged in.");
      return;
    }
    
    _queueStream = FirebaseFirestore.instance
        .collection('serviceQueue')
        .where('status', isEqualTo: 'waiting')
        .orderBy('requestedAt', descending: false)
        .snapshots();
     
     if(mounted) setState((){});
  }

  Future<void> _assignToTable(int tableNumber) async {
    if (_selectedQueueDocId == null || _selectedUserId == null || _currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a user from the queue first.'), 
        backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (tableNumber == 3 && _selectedServiceTypeRequested != 'Doctor Visit') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Table 3 is reserved for Doctor Visits only.'), 
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (_isProcessingAction) return;

    setState(() => _isProcessingAction = true);

    final String queueDocId = _selectedQueueDocId!;
    final String targetUserId = _selectedUserId!;
    final String staffId = _currentUser!.uid;
    final String staffEmail = _currentUser!.email ?? 'Unknown Staff';

    try {
      await FirebaseFirestore.instance.collection('serviceQueue').doc(queueDocId).update({
        'status': 'called',
        'calledAt': FieldValue.serverTimestamp(),
        'staffId': staffId,
        'assignedTable': tableNumber,
      });

      await _sendNotificationToUser(
        targetUserId: targetUserId,
        title: "Your Turn!",
        body: "Please proceed to Table $tableNumber for your service.",
        staffName: staffEmail,
      );

      debugPrint("Assigned user $targetUserId to Table $tableNumber.");

      setState(() {
        _selectedQueueDocId = null;
        _selectedUserId = null;
        _selectedUserName = null;
        _selectedServiceTypeRequested = null;
      });

    } catch (e) {
      debugPrint("Error assigning to table: $e");
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error assigning to table: $e'), 
          backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if(mounted) {
        setState(() => _isProcessingAction = false);
      }
    }
  }

  Future<void> _sendNotificationToUser({
    required String targetUserId,
    required String title,
    required String body,
    String? staffName,
  }) async {
    if (targetUserId.isEmpty) return;
    debugPrint("Attempting to send notification to $targetUserId");
    
    try {
      CollectionReference userNotifications = FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .collection('notifications');

      await userNotifications.add({
        'title': title,
        'body': body,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'queue_call',
        'sentBy': FirebaseAuth.instance.currentUser?.uid ?? 'system',
        if (staffName != null) 'senderName': staffName,
      });
      debugPrint("Notification DB entry created for user $targetUserId");
    } catch (e) {
      debugPrint("Error creating notification DB entry for user $targetUserId: $e");
      throw Exception("Could not send notification: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool canAssignToTable3() {
      return _selectedQueueDocId != null && _selectedServiceTypeRequested == 'Doctor Visit';
    }
    
    bool canAssignToOtherTables() {
      return _selectedQueueDocId != null;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Queue'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20.0),
          child: Text(
            _currentUser != null ? 'Staff: ${_currentUser?.email}' : 'Not Logged In',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _queueStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading queue.'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Queue is currently empty.'));
                }

                final queueDocs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: queueDocs.length,
                  itemBuilder: (context, index) {
                    final doc = queueDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final userId = data['userId'] as String? ?? '';
                    final userName = data['userName'] as String? ?? 'Unknown User';
                    final profilePicUrl = data['profilePictureUrl'] as String?;
                    final requestedAt = data['requestedAt'] as Timestamp?;
                    final serviceTypeReq = data['serviceTypeRequested'] as String? ?? 'Unknown';
                    final isSelected = doc.id == _selectedQueueDocId;

                    return Card(
                      color: isSelected ? Colors.blue.shade100 : null,
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: (profilePicUrl != null && profilePicUrl.isNotEmpty)
                              ? NetworkImage(profilePicUrl)
                              : null,
                          child: (profilePicUrl == null || profilePicUrl.isEmpty)
                              ? const Icon(Icons.person_outline, color: Colors.white)
                              : null,
                        ),
                        title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Requested: $serviceTypeReq at ${requestedAt != null ? DateFormat('HH:mm:ss').format(requestedAt.toDate()) : 'N/A'}'),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedQueueDocId = null;
                              _selectedUserId = null;
                              _selectedUserName = null;
                              _selectedServiceTypeRequested = null;
                            } else {
                              _selectedQueueDocId = doc.id;
                              _selectedUserId = userId;
                              _selectedUserName = userName;
                              _selectedServiceTypeRequested = serviceTypeReq;
                            }
                          });
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),

          if (_selectedQueueDocId != null)
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
              ),
              child: Column(
                children: [
                  Text(
                    "Assign '${_selectedUserName ?? 'Selected User'}' to Table:",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: (_isProcessingAction || !canAssignToOtherTables()) 
                            ? null 
                            : () => _assignToTable(1),
                        child: const Text('Table 1'),
                      ),
                      ElevatedButton(
                        onPressed: (_isProcessingAction || !canAssignToOtherTables()) 
                            ? null 
                            : () => _assignToTable(2),
                        child: const Text('Table 2'),
                      ),
                      ElevatedButton(
                        onPressed: (_isProcessingAction || !canAssignToTable3()) 
                            ? null 
                            : () => _assignToTable(3),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canAssignToTable3() ? Colors.indigo : Colors.grey.shade400,
                        ),
                        child: const Text('Table 3 (Doctor)'),
                      ),
                    ],
                  ),
                  if (_isProcessingAction) ...[
                    const SizedBox(height: 10),
                    const LinearProgressIndicator(),
                  ]
                ],
              ),
            ),
        ],
      ),
    );
  }
}