import 'package:flutter/material.dart';
import 'dart:async'; // For simulating network delay
import 'register.dart'; // Import your home screen

// Define the possible states for our login screen
enum LoginStatus { initial, loading, success, failure }

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  // State variables
  LoginStatus _status = LoginStatus.initial;
  String _errorMessage = ''; // Holds validation errors OR login failure messages
  bool _isLoading = false; // To manage loading state and disable button

  // Controllers for the TextFields
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- Placeholder for the Puenjai Logo ---
  Widget _buildPuenjaiLogo() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40.0),
      child: FlutterLogo(size: 120),
    );
  }

  // --- Login Logic ---
  Future<void> _performLogin() async {
    // Prevent multiple login attempts while one is in progress
    if (_isLoading) return;

    // Hide keyboard
    FocusScope.of(context).unfocus();

    // Get username and password from controllers
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    // --- !!! NEW: Input Validation Check BEFORE Loading State !!! ---
    String? validationError;
    if (username.isEmpty && password.isEmpty) {
      validationError = 'Please enter username and password.';
    } else if (username.isEmpty) {
      validationError = 'Username cannot be empty.';
    } else if (password.isEmpty) {
      // Specific check for empty password
      validationError = 'Password cannot be empty.';
    }

    // If there's a validation error, show it and stop.
    if (validationError != null) {
      setState(() {
        _errorMessage = validationError!; // Show validation error message
        _status = LoginStatus.initial; // Stay on the initial screen
        _isLoading = false; // Ensure loading is off
      });
      return; // Exit the function, do not proceed to login attempt
    }
    // --- End of Input Validation Check ---

    // If validation passed, clear previous errors and proceed to loading state
    setState(() {
      _isLoading = true;
      _status = LoginStatus.loading;
      _errorMessage = ''; // Clear any previous validation errors
    });

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // --- Actual authentication check ---
    bool loginSuccessful;
    String loginFailureReason = ''; // Specific reason for login failure
    if (username == 'admin' && password == '1234') {
      loginSuccessful = true;
    } else {
      loginSuccessful = false;
      // Keep the generic message for security reasons usually,
      // but could be more specific if needed internally.
      loginFailureReason = 'Invalid username or password.';
    }

    // Update UI based on login result
    setState(() {
      if (loginSuccessful) {
        _status = LoginStatus.success;
      } else {
        _status = LoginStatus.failure;
        _errorMessage = loginFailureReason; // Show login failure message
        _passwordController.clear(); // Clear password on failed attempt
      }
      _isLoading = false; // Stop loading
    });

    // ... Optional navigation on success ...
  }

  // --- Reset to Initial State ---
  void _resetLogin() {
    setState(() {
      _status = LoginStatus.initial;
      _errorMessage = ''; // Clear any previous error messages
      _isLoading = false;
      _usernameController.clear();
      _passwordController.clear();
    });
     // Ensure keyboard is hidden when resetting
     FocusScope.of(context).unfocus();
  }

  // --- Build Different UI Based on State ---
  Widget _buildBody() {
    // Shared error message display widget (used in initial and failure states)
    Widget errorDisplayWidget = const SizedBox.shrink(); // Default empty space
    if (_errorMessage.isNotEmpty) {
       // Only display error if message exists
        errorDisplayWidget = Padding(
          padding: const EdgeInsets.only(top: 15.0, bottom: 0, left: 40, right: 40),
          child: Text(
            _errorMessage,
            style: TextStyle(
                color: _status == LoginStatus.failure ? Colors.red : Colors.redAccent, // Slightly different color for validation vs failure?
                fontSize: 14),
            textAlign: TextAlign.center,
          ),
        );
    }


    switch (_status) {
      case LoginStatus.loading:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPuenjaiLogo(),
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text('Logging in...'),
          ],
        );

      case LoginStatus.success:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPuenjaiLogo(),
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 20),
            const Text(
              'Login Success',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        );

      case LoginStatus.failure:
        // Failure state now primarily shows the result of a FAILED LOGIN ATTEMPT
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPuenjaiLogo(),
            const Icon(Icons.error, color: Colors.red, size: 60),
            const SizedBox(height: 20),
            const Text(
              'Login Failed',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            errorDisplayWidget, // Display the "Invalid credentials" message
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _resetLogin,
              child: const Text('Try Again'),
            ),
          ],
        );

      case LoginStatus.initial:
      default: // Default to initial state
        // Initial state now ALSO displays VALIDATION errors before attempting login
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPuenjaiLogo(),
            // --- Username Field ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 8.0),
              child: TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'Enter your username',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                     borderRadius: BorderRadius.all(Radius.circular(12.0)),
                  ),
                ),
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                 // Clear error message when user starts typing again
                 onChanged: (_) { if (_errorMessage.isNotEmpty) setState(() => _errorMessage = ''); },
              ),
            ),
            // --- Password Field ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 8.0),
              child: TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                   prefixIcon: Icon(Icons.lock_outline),
                   border: OutlineInputBorder(
                     borderRadius: BorderRadius.all(Radius.circular(12.0)),
                   ),
                ),
                keyboardType: TextInputType.visiblePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _performLogin(),
                // Clear error message when user starts typing again
                onChanged: (_) { if (_errorMessage.isNotEmpty) setState(() => _errorMessage = ''); },
              ),
            ),

            // --- Display Validation Errors Area ---
            // Use the shared widget defined earlier
             errorDisplayWidget,

            // Adjust spacing based on whether an error is shown
            SizedBox(height: _errorMessage.isNotEmpty ? 15 : 30),


            // --- Login Button ---
            ElevatedButton(
              onPressed: _isLoading ? null : _performLogin,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Login'),
            ),

            const SizedBox(height: 20),

            TextButton(
              onPressed: () {
                // Navigate to the Register screen
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              child: const Text(
                "Don't have an account? Register",
                style: TextStyle(color: Colors.blueGrey),
              ),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Puenjai Login'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }
}

// --- Example main function remains the same ---
/*
void main() {
  runApp(const MyApp());
}

// ... MyApp class definition ...
*/