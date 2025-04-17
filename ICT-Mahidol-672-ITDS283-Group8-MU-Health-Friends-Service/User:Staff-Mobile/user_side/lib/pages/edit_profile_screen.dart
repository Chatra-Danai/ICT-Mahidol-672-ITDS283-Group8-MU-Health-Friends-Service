import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Firebase imports
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoadingData = true; // Loading indicator for initial fetch
  bool _isSaving = false; // Loading indicator for saving process

  // Controllers for editable fields
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _userIdController = TextEditingController(); // Student/Staff ID
  final _phoneNumberController = TextEditingController();

  // State for image handling
  XFile? _selectedImage; // Holds newly selected image file
  String? _currentProfilePicUrl; // Holds the existing URL from Firestore

  User? _currentUser; // To store the logged-in user

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    // Dispose controllers
    _firstNameController.dispose();
    _lastNameController.dispose();
    _userIdController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  // Fetch current user data from Firestore
  Future<void> _loadUserData() async {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser == null) {
      // Handle case where user is somehow null (shouldn't happen if screen is protected)
      setState(() => _isLoadingData = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in!'), backgroundColor: Colors.red),
      );
      // Optionally navigate back Navigator.pop(context);
      return;
    }

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (docSnapshot.exists && mounted) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        // Populate controllers and state variables
        _firstNameController.text = data['firstName'] ?? '';
        _lastNameController.text = data['lastName'] ?? '';
        _userIdController.text = data['studentOrStaffId'] ?? '';
        _phoneNumberController.text = data['phoneNumber'] ?? '';
        _currentProfilePicUrl = data['profilePictureUrl']; // Store current URL
        // Note: We don't load faculty/email/type as they are not editable here
      } else {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User profile data not found.')),
         );
      }
    } catch (e) {
       debugPrint("Error loading user data: $e");
       ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e'), backgroundColor: Colors.red),
       );
    } finally {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  // --- Image Picker Logic --- (Reused from RegisterScreen)
  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
          source: source, imageQuality: 80, maxWidth: 800);

      if (image != null) {
        setState(() {
          _selectedImage = image; // Store selected image for upload later
          _currentProfilePicUrl = null; // Clear current URL display if new image is selected
        });
      }
    } catch (e) {
      // ... (error handling) ...
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  void _showImageSourceActionSheet() {
     // ... (Implementation is the same as in RegisterScreen) ...
     showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo Library'),
              onTap: () {
                _pickImage(ImageSource.gallery);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () {
                _pickImage(ImageSource.camera);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- Upload image to Firebase Storage --- (Reused/Adapted from RegisterScreen)
  Future<String?> _uploadProfileImage(String userId) async {
    if (_selectedImage == null) return null; // Only upload if new image selected

    try {
      // Define path: profile_pictures/USER_ID.jpg
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('$userId.jpg');

      // Put the file (handle potential errors)
      await storageRef.putFile(File(_selectedImage!.path));

      // Get the download URL
      return await storageRef.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
       if (!mounted) return null;
       ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Failed to upload profile image'), backgroundColor: Colors.red),
       );
      return null; // Return null on error
    }
  }

  // --- Save Changes Logic ---
  Future<void> _saveChanges() async {
     if (_currentUser == null) return; // Should not happen
     if (!(_formKey.currentState?.validate() ?? false)) return; // Validate form

     setState(() => _isSaving = true);

     String? newProfilePictureUrl;
     bool success = false;

     try {
         // 1. Upload new image IF one was selected
         if (_selectedImage != null) {
             newProfilePictureUrl = await _uploadProfileImage(_currentUser!.uid);
             // Optional: Handle upload failure more gracefully if needed
              if (newProfilePictureUrl == null && _selectedImage != null) {
                 throw Exception("Image selected but upload failed.");
              }
         }

         // 2. Prepare data to update in Firestore
         Map<String, dynamic> updateData = {
             'firstName': _firstNameController.text.trim(),
             'lastName': _lastNameController.text.trim(),
             'studentOrStaffId': _userIdController.text.trim(),
             'phoneNumber': _phoneNumberController.text.trim(),
             'lastUpdatedAt': FieldValue.serverTimestamp(), // Add update timestamp
         };

         // Only include profile picture URL if a new one was successfully uploaded
         if (newProfilePictureUrl != null) {
             updateData['profilePictureUrl'] = newProfilePictureUrl;
         }

         // 3. Update Firestore document
         await FirebaseFirestore.instance
             .collection('users')
             .doc(_currentUser!.uid)
             .update(updateData); // Use update, not set

         success = true;

     } catch (e) {
         debugPrint("Error saving profile: $e");
         if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error saving profile: $e'), backgroundColor: Colors.red),
          );
     } finally {
          if (mounted) {
             setState(() => _isSaving = false);
          }
     }

     // Show success message and pop if successful
      if (success && mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
           );
           Navigator.of(context).pop(); // Go back to settings screen
      }
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    // Determine image provider for CircleAvatar
    ImageProvider? imageProvider;
    if (_selectedImage != null) {
        imageProvider = FileImage(File(_selectedImage!.path)); // Show newly selected image
    } else if (_currentProfilePicUrl != null && _currentProfilePicUrl!.isNotEmpty) {
        imageProvider = NetworkImage(_currentProfilePicUrl!); // Show existing network image
    } else {
        imageProvider = null; // Will show placeholder icon
    }
    const String placeholderAsset = 'assets/placeholder_avatar.png'; // Define placeholder

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          // Add Save button to AppBar
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _isSaving
                ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,)))
                : TextButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    child: const Text('Save'),
                  ),
          )
        ],
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    // --- Profile Picture ---
                     Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: imageProvider,
                              child: (imageProvider == null) // Show icon only if no image provider
                                  ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8),
                                child: IconButton(
                                  icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                  onPressed: _showImageSourceActionSheet, // Trigger image picker
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                     const SizedBox(height: 30),

                    // --- Form Fields ---
                     TextFormField(
                       controller: _firstNameController,
                       decoration: const InputDecoration(labelText: 'First Name', prefixIcon: Icon(Icons.person_outline)),
                       validator: (value) => (value == null || value.trim().isEmpty) ? 'Cannot be empty' : null,
                     ),
                     const SizedBox(height: 16),
                      TextFormField(
                       controller: _lastNameController,
                       decoration: const InputDecoration(labelText: 'Last Name', prefixIcon: Icon(Icons.person_outline)),
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'Cannot be empty' : null,
                     ),
                      const SizedBox(height: 16),
                     TextFormField(
                       controller: _userIdController,
                       decoration: const InputDecoration(labelText: 'Student/Staff ID', prefixIcon: Icon(Icons.badge_outlined)),
                       keyboardType: TextInputType.number,
                       inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                       validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter ID';
                          if (value.length != 7) return 'ID must be 7 digits';
                          return null;
                       },
                     ),
                      const SizedBox(height: 16),
                      TextFormField(
                       controller: _phoneNumberController,
                       decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
                       keyboardType: TextInputType.phone,
                       inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter phone';
                          if (value.length < 9) return 'Invalid phone number';
                          return null;
                        },
                     ),

                     // Add spacing before save button if needed
                     const SizedBox(height: 40),
                     // Save Button (Moved to AppBar Action for better UX)
                     /*
                     ElevatedButton(
                       onPressed: _isSaving ? null : _saveChanges,
                       child: _isSaving
                           ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                           : const Text('Save Changes'),
                     ),
                     */

                  ],
                ),
              ),
            ),
    );
  }
}