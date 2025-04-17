import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Firebase imports
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

enum UserType { student, staff }

class RegistrationSuccessScreen extends StatelessWidget {
  const RegistrationSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Complete'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 100),
              const SizedBox(height: 25),
              const Text(
                'Registration Successful!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              const Text(
                'Your account has been created. You can now use your credentials to log in.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _userIdController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _staffInviteCodeController = TextEditingController();

  final List<String> _mahidolFacultiesAndUnits = [
    "Faculty of Dentistry",
    "Faculty of Medicine Ramathibodi Hospital",
    "Faculty of Medicine Siriraj Hospital",
    "Faculty of Medical Technology",
    "Faculty of Nursing",
    "Faculty of Pharmacy",
    "Faculty of Public Health",
    "Faculty of Tropical Medicine",
    "Faculty of Veterinary Science",
    "Faculty of Engineering",
    "Faculty of Environment and Resource Studies",
    "Faculty of ICT (Information and Communication Technology)",
    "Faculty of Science",
    "Faculty of Physical Therapy",
    "Faculty of Liberal Arts",
    "Faculty of Social Sciences and Humanities",
    "College of Management",
    "College of Music",
    "College of Religious Studies",
    "College of Sports Science and Technology",
    "Mahidol University International College (MUIC)",
    "Ratchasuda College",
    "ASEAN Institute for Health Development",
    "Institute for Innovative Learning",
    "Institute for Population and Social Research",
    "Institute of Human Rights and Peace Studies",
    "Institute of Molecular Biosciences",
    "Institute of Nutrition",
    "National Institute for Child and Family Development",
    "Mahidol University Kanchanaburi Campus",
    "Mahidol University Nakhon Sawan Campus",
    "Mahidol University Amnat Charoen Campus",
  ];

  String? _selectedFaculty;
  UserType? _selectedUserType;
  XFile? _selectedImage;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _obscureInviteCode = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _userIdController.dispose();
    _phoneNumberController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _staffInviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
          source: source, imageQuality: 80, maxWidth: 800);

      if (image != null) {
        setState(() => _selectedImage = image);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  void _showImageSourceActionSheet() {
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

  Future<String?> _uploadProfileImage(String userId) async {
    if (_selectedImage == null) return null;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('$userId.jpg');
      
      await storageRef.putFile(File(_selectedImage!.path));
      return await storageRef.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload profile image')),
      );
      return null;
    }
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please correct form errors')),
      );
      return;
    }
    if (_selectedUserType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select user type')),
      );
      return;
    }

    String? validInviteCodeDocId;

    // Validate staff invite code if staff is selected
    if (_selectedUserType == UserType.staff) {
      final String enteredCode = _staffInviteCodeController.text.trim();
      if (enteredCode.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter staff invite code')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final now = Timestamp.now();
        final querySnapshot = await FirebaseFirestore.instance
            .collection('staff_invite_codes')
            .where('code', isEqualTo: enteredCode)
            .where('expiresAt', isGreaterThan: now)
            .where('isUsed', isEqualTo: false)
            .limit(1)
            .get();

        if (querySnapshot.docs.isEmpty) {
          throw Exception("Invalid or expired staff invite code");
        } else {
          validInviteCodeDocId = querySnapshot.docs.first.id;
          debugPrint("Valid invite code found: $validInviteCodeDocId");
        }
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
        return;
      }
    }

    try {
      // Create user with Firebase Auth
      final email = _usernameController.text.trim();
      final password = _passwordController.text;
      
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final user = userCredential.user;
      if (user == null) throw Exception("User creation failed");

      // Upload profile image
      final profilePictureUrl = await _uploadProfileImage(user.uid);

      // Save user data to Firestore
      final userData = {
        'uid': user.uid,
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'studentOrStaffId': _userIdController.text.trim(),
        'faculty': _selectedFaculty,
        'phoneNumber': _phoneNumberController.text.trim(),
        'email': user.email,
        'userType': _selectedUserType.toString().split('.').last,
        'profilePictureUrl': profilePictureUrl,
        'createdAt': FieldValue.serverTimestamp(),
        if (validInviteCodeDocId != null) 'usedInviteCodeId': validInviteCodeDocId,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(userData);

      // Mark invite code as used if applicable
      if (validInviteCodeDocId != null) {
        await FirebaseFirestore.instance
            .collection('staff_invite_codes')
            .doc(validInviteCodeDocId)
            .update({'isUsed': true});
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RegistrationSuccessScreen()),
      );

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      String errorMessage = 'Registration failed. Please try again.';
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'Password must be at least 8 characters with uppercase, number and special char';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists for this email';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address';
          break;
        default:
          errorMessage = e.message ?? errorMessage;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textInputAction: textInputAction,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _selectedImage != null
                          ? FileImage(File(_selectedImage!.path))
                          : null,
                      child: _selectedImage == null
                          ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                          onPressed: _showImageSourceActionSheet,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text('Register as:', style: Theme.of(context).textTheme.titleMedium),
              Row(
                children: [
                  Expanded(child: RadioListTile<UserType>(
                    title: const Text('Student'),
                    value: UserType.student,
                    groupValue: _selectedUserType,
                    onChanged: (value) => setState(() {
                      _selectedUserType = value;
                      _staffInviteCodeController.clear();
                    }),
                  )),
                  Expanded(child: RadioListTile<UserType>(
                    title: const Text('Staff'),
                    value: UserType.staff,
                    groupValue: _selectedUserType,
                    onChanged: (value) => setState(() => _selectedUserType = value),
                  )),
                ],
              ),
              const SizedBox(height: 10),

              if (_selectedUserType == UserType.staff)
                _buildTextFormField(
                  controller: _staffInviteCodeController,
                  label: 'Staff Invite Code',
                  icon: Icons.vpn_key_outlined,
                  obscureText: _obscureInviteCode,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter staff invite code';
                    }
                    return null;
                  },
                  suffixIcon: IconButton(
                    icon: Icon(_obscureInviteCode ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureInviteCode = !_obscureInviteCode),
                  ),
                ),

              _buildTextFormField(
                controller: _firstNameController,
                label: 'First Name',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Please enter first name';
                  if (value.trim().length < 2) return 'Name too short';
                  return null;
                },
              ),

              _buildTextFormField(
                controller: _lastNameController,
                label: 'Last Name',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Please enter last name';
                  return null;
                },
              ),

              _buildTextFormField(
                controller: _userIdController,
                label: _selectedUserType == UserType.staff ? 'Staff ID' : 'Student ID',
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter ID';
                  if (value.length != 7) return 'ID must be 7 digits';
                  return null;
                },
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: DropdownButtonFormField<String>(
                  value: _selectedFaculty,
                  isExpanded: true,
                  hint: const Text('Select Faculty / Unit'),
                  decoration: InputDecoration(
                    labelText: 'Faculty / Unit',
                    prefixIcon: const Icon(Icons.school_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  items: _mahidolFacultiesAndUnits
                      .map((value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedFaculty = value),
                  validator: (value) =>
                      value == null ? 'Please select your Faculty / Unit' : null,
                ),
              ),

              _buildTextFormField(
                controller: _phoneNumberController,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter phone number';
                  if (value.length < 9) return 'Phone number too short';
                  return null;
                },
              ),

              _buildTextFormField(
                controller: _usernameController,
                label: 'Email (used for login)',
                icon: Icons.account_circle_outlined,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),

              _buildTextFormField(
                controller: _passwordController,
                label: 'Password',
                icon: Icons.lock_outline,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a password';
                  if (value.length < 8) return 'Password must be at least 8 characters';
                  if (!value.contains(RegExp(r'[A-Z]'))) {
                    return 'Include at least one uppercase letter';
                  }
                  if (!value.contains(RegExp(r'[0-9]'))) {
                    return 'Include at least one number';
                  }
                  return null;
                },
              ),

              _buildTextFormField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                icon: Icons.lock_outline,
                obscureText: _obscureConfirmPassword,
                textInputAction: TextInputAction.done,
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please confirm password';
                  if (value != _passwordController.text) return 'Passwords do not match';
                  return null;
                },
              ),

              const SizedBox(height: 25),

              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Register', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}