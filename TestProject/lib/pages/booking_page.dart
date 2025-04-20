import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'HistoryPage.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  // Wound image and description
  XFile? _woundImage;
  final _descriptionController = TextEditingController();

  // Map related state
  final Map<String, LatLng> _serviceLocationsCoords = {
    "MU Health": const LatLng(13.7940, 100.3212),
    "MU Friends": const LatLng(13.7950, 100.3222),
  };
  final double _zoomLevel = 15.0;
  final MapController _mapController = MapController();
  List<Marker> _markers = [];

  // User data
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoadingUserData = true;
  bool _isSubmitting = false;
  String _userName = 'User';
  String? _profilePicUrl;

  // Location selection
  final List<String> _serviceLocations = ["MU Health", "MU Friends"];
  String? _selectedServiceLocation;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    if (_currentUser == null) {
      setState(() {
        _userName = 'User';
        _isLoadingUserData = false;
      });
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (userDoc.exists && mounted) {
        final data = userDoc.data();
        if (data != null) {
          final firstName = data['firstName'] as String? ?? '';
          final lastName = data['lastName'] as String? ?? '';
          final fetchedUserName = "$firstName $lastName".trim();

          setState(() {
            _userName = fetchedUserName.isEmpty 
                ? (_currentUser?.email ?? 'User') 
                : fetchedUserName;
            _profilePicUrl = data['profilePictureUrl'] as String?;
            _isLoadingUserData = false;
          });
        } else {
          if (mounted) {
            setState(() {
              _userName = _currentUser?.email ?? 'User';
              _profilePicUrl = null;
              _isLoadingUserData = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _userName = _currentUser?.email ?? 'User';
            _profilePicUrl = null;
            _isLoadingUserData = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading user data in BookingPage: $e");
      if (mounted) {
        setState(() {
          _userName = 'User';
          _isLoadingUserData = false;
        });
      }
    }
  }

  void _updateMapMarker(LatLng newCenter) {
    setState(() {
      _markers = [
        Marker(
          width: 80.0,
          height: 80.0,
          point: newCenter,
          child: const Icon(
            Icons.location_pin,
            color: Colors.blue,
            size: 40.0,
          ),
        ),
      ];
    });
  }

  Future<void> _requestService(String serviceType) async {
    if (_selectedServiceLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service location')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      String? woundImageUrl;
      if (_woundImage != null && _currentUser != null) {
        woundImageUrl = await _uploadWoundImage(_currentUser!.uid);
      }

      await FirebaseFirestore.instance.collection('serviceQueue').add({
        'userId': _currentUser?.uid,
        'userName': _userName,
        'profilePictureUrl': _profilePicUrl,
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'waiting',
        'serviceTypeRequested': serviceType,
        'requestedLocation': _selectedServiceLocation,
        'woundImageUrl': woundImageUrl,
        'description': _descriptionController.text.isNotEmpty 
            ? _descriptionController.text 
            : null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$serviceType request submitted successfully')),
        );
        
        setState(() {
          _woundImage = null;
        });
        _descriptionController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting request: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<String?> _uploadWoundImage(String userId) async {
    if (_woundImage == null) return null;

    try {
      String fileExtension = _woundImage!.path.split('.').last;
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('wound_images')
          .child(userId)
          .child(fileName);

      await storageRef.putFile(File(_woundImage!.path));
      return await storageRef.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading wound image: $e');
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to upload wound image'), 
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  Future<void> _showWoundImageSourceActionSheet() async {
    final ImagePicker picker = ImagePicker();
    
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera),
                title: const Text('Take a Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? photo = await picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 80,
                    maxWidth: 1000,
                  );
                  if (photo != null && mounted) {
                    setState(() {
                      _woundImage = photo;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80,
                    maxWidth: 1000,
                  );
                  if (image != null && mounted) {
                    setState(() {
                      _woundImage = image;
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServiceButton({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return ElevatedButton.icon(
      icon: _isSubmitting ? const SizedBox.shrink() : Icon(icon),
      label: _isSubmitting
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(double.infinity, 50),
      ),
      onPressed: _isSubmitting ? null : () => _requestService(label),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Service'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Service History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryPage()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoadingUserData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location Dropdown
                    const Text(
                      'Select Service Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedServiceLocation,
                      isExpanded: true,
                      hint: const Text('Choose location...'),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.location_city_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a service location';
                        }
                        return null;
                      },
                      items: _serviceLocations
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedServiceLocation = newValue;
                          if (newValue != null && 
                              _serviceLocationsCoords.containsKey(newValue)) {
                            LatLng newCenter = _serviceLocationsCoords[newValue]!;
                            _mapController.move(newCenter, _zoomLevel);
                            _updateMapMarker(newCenter);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Dynamic Map Display (only shown when location is selected)
                    if (_selectedServiceLocation != null &&
                        _serviceLocationsCoords.containsKey(_selectedServiceLocation))
                      SizedBox(
                        height: 200,
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _serviceLocationsCoords[_serviceLocations[0]]!,
                            initialZoom: _zoomLevel,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                            ),
                            MarkerLayer(
                              markers: _markers,
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Service Selection
                    Text(
                      'Hi $_userName, please select a service:',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildServiceButton(
                      label: 'Medicine',
                      icon: Icons.medical_services,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildServiceButton(
                      label: 'See Doctor',
                      icon: Icons.people,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildServiceButton(
                      label: 'Wound Dressing',
                      icon: Icons.healing,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 24),

                    // Optional Wound Image and Description Section
                    const Divider(height: 30, thickness: 1),
                    const Text(
                      'Add Photo & Description (Optional)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[100],
                          ),
                          child: _woundImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.file(
                                    File(_woundImage!.path), 
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.image_outlined, 
                                    size: 40, 
                                    color: Colors.grey,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: Text(_woundImage == null 
                                ? 'Upload Photo' 
                                : 'Change Photo'),
                            onPressed: _showWoundImageSourceActionSheet,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Describe your symptoms or the wound here...\n(อธิบายอาการหรือลักษณะแผลที่นี่...)',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}