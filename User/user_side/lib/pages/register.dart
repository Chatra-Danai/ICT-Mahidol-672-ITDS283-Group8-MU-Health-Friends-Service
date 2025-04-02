import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatters
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // Required for File type

// Enum to define user type
enum UserType { student, staff }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>(); // Key for the Form

  // --- Text Editing Controllers ---
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _userIdController = TextEditingController(); // For u_id
  final _phoneNumberController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Inside _RegisterScreenState class:

  final List<String> _mahidolFacultiesAndUnits = [
    // Health Sciences
    "Faculty of Dentistry",
    "Faculty of Medicine Ramathibodi Hospital",
    "Faculty of Medicine Siriraj Hospital",
    "Faculty of Medical Technology",
    "Faculty of Nursing",
    "Faculty of Pharmacy",
    "Faculty of Public Health",
    "Faculty of Tropical Medicine",
    "Faculty of Veterinary Science",
    // Science & Technology
    "Faculty of Engineering",
    "Faculty of Environment and Resource Studies",
    "Faculty of ICT (Information and Communication Technology)",
    "Faculty of Science",
    "Faculty of Physical Therapy",
    // Social Sciences & Humanities
    "Faculty of Liberal Arts",
    "Faculty of Social Sciences and Humanities",
    // Colleges
    "College of Management",
    "College of Music",
    "College of Religious Studies",
    "College of Sports Science and Technology",
    "Mahidol University International College (MUIC)",
    "Ratchasuda College", // (focusing on persons with disabilities) - kept description out for brevity
    // Institutes
    "ASEAN Institute for Health Development",
    "Institute for Innovative Learning",
    "Institute for Population and Social Research",
    "Institute of Human Rights and Peace Studies",
    "Institute of Molecular Biosciences",
    "Institute of Nutrition",
    "National Institute for Child and Family Development",
    // Other Academic Units
    "Mahidol University Kanchanaburi Campus",
    "Mahidol University Nakhon Sawan Campus",
    "Mahidol University Amnat Charoen Campus",
    // Consider adding an "Other" option if needed
  ];

  // State variable to hold the selection
  String? _selectedFaculty;

  // --- Remove the Faculty Text Controller ---
  // Remove this line: final _facultyController = TextEditingController();
  

  // --- State Variables ---
  UserType? _selectedUserType; // To store selected user type (student/staff)
  XFile? _selectedImage; // To store the selected image file from image_picker
  bool _isLoading = false; // To show loading indicator during registration
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    // Dispose controllers when the widget is removed from the widget tree
    _firstNameController.dispose();
    _lastNameController.dispose();
    _userIdController.dispose();
    _phoneNumberController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- Image Picker Logic ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
          source: source,
          imageQuality: 80, // Optional: Adjust image quality
          maxWidth: 800); // Optional: Limit image width

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      // Handle potential errors (e.g., permissions denied)
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
          children: <Widget>[
            ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                }),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () {
                _pickImage(ImageSource.camera);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }


  // --- Registration Logic ---
  Future<void> _register() async {
    // Validate the form
    if (_formKey.currentState?.validate() ?? false) {
      // Optional: Check if user type is selected
       if (_selectedUserType == null) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Please select user type (Student/Staff)')),
         );
         return;
       }
      // Optional: Check if image is selected (if required)
      // if (_selectedImage == null) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('Please select a profile photo')),
      //   );
      //   return;
      // }


      // If form is valid, show loading and simulate registration
      setState(() {
        _isLoading = true;
      });

      // --- Simulate network request/database operation ---
      await Future.delayed(const Duration(seconds: 2));
      // In a real app:
      // 1. Upload the image (_selectedImage.path) to storage if selected.
      // 2. Get the image URL.
      // 3. Send all controller data (_firstNameController.text, etc.),
      //    _selectedUserType, and image URL to your backend API.

      bool registrationSuccessful = true; // Assume success for simulation
      String message = 'Registration successful!';

      // Example simulation of potential failure
      // if (_usernameController.text == 'existinguser') {
      //   registrationSuccessful = false;
      //   message = 'Username already exists.';
      // }

      // --- Hide loading indicator ---
      if (!mounted) return; // Check if widget is still mounted
       setState(() {
         _isLoading = false;
       });

      // --- Show feedback ---
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(message),
            backgroundColor: registrationSuccessful ? Colors.green : Colors.red),
      );

      if (registrationSuccessful && mounted) {
        // Optionally navigate back or to login screen
         Navigator.of(context).pop(); // Go back to the previous screen
      }
    } else {
       // Form is invalid, validation errors are shown automatically
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please correct the errors in the form')),
        );
    }
  }

  // --- Helper to build TextFormFields ---
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: validator ?? // Default validator: Check if empty
            (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter $label';
              }
              return null; // Return null if valid
            },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // --- Profile Photo Input ---
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _selectedImage != null
                            ? FileImage(File(_selectedImage!.path)) // Use FileImage
                            : null, // No image if null
                        child: _selectedImage == null
                            ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                            : null, // No icon if image selected
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20,),
                            onPressed: _showImageSourceActionSheet,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // --- User Type Selection ---
                 Text('Register as:', style: Theme.of(context).textTheme.titleMedium),
                 Row(
                   children: [
                     Expanded(
                       child: RadioListTile<UserType>(
                         title: const Text('Student'),
                         value: UserType.student,
                         groupValue: _selectedUserType,
                         onChanged: (UserType? value) {
                           setState(() { _selectedUserType = value; });
                         },
                       ),
                     ),
                      Expanded(
                       child: RadioListTile<UserType>(
                         title: const Text('Staff'),
                         value: UserType.staff,
                         groupValue: _selectedUserType,
                         onChanged: (UserType? value) {
                           setState(() { _selectedUserType = value; });
                         },
                       ),
                     ),
                   ],
                 ),
                 const SizedBox(height: 10),


                // --- Input Fields ---
                _buildTextFormField(
                  controller: _firstNameController,
                  label: 'First Name',
                  icon: Icons.person_outline,
                ),
                 _buildTextFormField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  icon: Icons.person_outline,
                ),
                _buildTextFormField(
                  controller: _userIdController,
                  label: 'Student ID (e.g., 6787000)',
                  icon: Icons.badge_outlined,
                  // Consider adding format validation if needed
                  keyboardType: TextInputType.number,
                   inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: DropdownButtonFormField<String>(
                    value: _selectedFaculty, // Bind to state variable
                    isExpanded: true, // Allow dropdown to stretch
                    hint: const Text('Select Faculty / Unit'), // Placeholder text
                    decoration: InputDecoration(
                      labelText: 'Faculty / Unit',
                      prefixIcon: const Icon(Icons.school_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items: _mahidolFacultiesAndUnits.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          overflow: TextOverflow.ellipsis, // Handle long text
                        ),
                      );
                    }).toList(), // Create list of dropdown items
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedFaculty = newValue; // Update state on selection
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select your Faculty / Unit'; // Validation
                      }
                      return null;
                    },
                  ),
                ),
                _buildTextFormField(
                  controller: _phoneNumberController,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                   inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                _buildTextFormField(
                  controller: _usernameController,
                  label: 'Username',
                  icon: Icons.account_circle_outlined,
                   validator: (value) {
                     if (value == null || value.trim().isEmpty) {
                       return 'Please enter a username';
                     }
                     if (value.length < 4) { // Example validation
                         return 'Username must be at least 4 characters';
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
                    if (value == null || value.isEmpty) {
                       return 'Please enter a password';
                    }
                    if (value.length < 6) { // Example validation
                        return 'Password must be at least 6 characters';
                    }
                     return null;
                  },
                ),
                 _buildTextFormField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  icon: Icons.lock_outline,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done, // Last field
                   suffixIcon: IconButton(
                     icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                     onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                       return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                        return 'Passwords do not match';
                    }
                     return null;
                  },
                ),

                const SizedBox(height: 25),

                // --- Register Button ---
                ElevatedButton(
                  onPressed: _isLoading ? null : _register, // Disable button when loading
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
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
      ),
    );
  }
}

// --- Example main function to run this screen standalone ---
/*
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Register Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue, // Or your app's theme color
        visualDensity: VisualDensity.adaptivePlatformDensity,
        inputDecorationTheme: InputDecorationTheme( // Consistent styling
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
          ),
          filled: true, // Example theme setting
          fillColor: Colors.grey[50], // Example theme setting
        ),
        elevatedButtonTheme: ElevatedButtonThemeData( // Consistent button style
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
      ),
      home: const RegisterScreen(), // Start with the register screen
    );
  }
}
*/
// Add this class (e.g., at the end of register.dart)

  class RegistrationSuccessScreen extends StatelessWidget {
    const RegistrationSuccessScreen({super.key});

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Registration Complete'),
          centerTitle: true,
          automaticallyImplyLeading: false, // Remove back button
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 100,
                ),
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
                  // Action depends on your app flow.
                  // Option 1: Go back to the screen that opened registration (e.g., Login)
                  onPressed: () {
                    Navigator.of(context).pop(); // Pops the success screen
                  },
                  // Option 2: Navigate explicitly to Login screen, removing history
                  // onPressed: () {
                  //   Navigator.of(context).pushNamedAndRemoveUntil(
                  //       '/login', (Route<dynamic> route) => false);
                  // },
                  child: const Text('Done', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }