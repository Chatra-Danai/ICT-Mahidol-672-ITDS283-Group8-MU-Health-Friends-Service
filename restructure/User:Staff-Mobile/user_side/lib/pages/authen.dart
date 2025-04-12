import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register.dart';
import 'user_dashboard_screen.dart'; // Make sure this import points to your actual dashboard

enum LoginStatus { initial, loading, success, failure }

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  LoginStatus _status = LoginStatus.initial;
  String _errorMessage = '';
  bool _isLoading = false;
  bool _obscurePassword = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildPuenjaiLogo() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40.0),
      child: FlutterLogo(size: 120),
    );
  }

  Future<void> _performLogin() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _status = LoginStatus.loading;
      _errorMessage = '';
    });

    try {
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _status = LoginStatus.success;
      });

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const UserDashboardScreen()),
      );

    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        case 'user-not-found':
          errorMessage = 'No account found for this email';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password';
          break;
        default:
          errorMessage = 'Login failed. Please try again';
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _status = LoginStatus.failure;
        _errorMessage = errorMessage;
        _passwordController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _status = LoginStatus.failure;
        _errorMessage = 'An unexpected error occurred';
      });
      debugPrint('Login error: $e');
    }
  }

  void _resetLogin() {
    _formKey.currentState?.reset();
    setState(() {
      _status = LoginStatus.initial;
      _errorMessage = '';
      _isLoading = false;
    });
    FocusScope.of(context).unfocus();
  }

  // --- NEW: Function to handle Forgot Password ---
  Future<void> _showForgotPasswordDialog() async {
    final TextEditingController resetEmailController = TextEditingController();
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        bool isSendingReset = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reset Password'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    const Text('Enter your registered email address to receive a password reset link.'),
                    const SizedBox(height: 15),
                    TextField(
                      controller: resetEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                TextButton(
                  onPressed: isSendingReset ? null : () async {
                    final String email = resetEmailController.text.trim();
                    if (email.isEmpty || !email.contains('@')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid email.'), backgroundColor: Colors.orange),
                      );
                      return;
                    }

                    setDialogState(() => isSendingReset = true);

                    try {
                      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password reset link sent! Please check your email (including spam folder).'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } on FirebaseAuthException catch (e) {
                      Navigator.of(dialogContext).pop();
                      String errorMsg = "Failed to send reset link.";
                      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
                        errorMsg = "If an account exists for that email, a reset link has been sent.";
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(errorMsg), backgroundColor: Colors.orange),
                        );
                      } else {
                        debugPrint("Password Reset Error: ${e.code} - ${e.message}");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
                        );
                      }
                    } catch (e) {
                      Navigator.of(dialogContext).pop();
                      debugPrint("Password Reset Error: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("An unexpected error occurred."), backgroundColor: Colors.red),
                      );
                    } finally {
                      setDialogState(() => isSendingReset = false);
                    }
                  },
                  child: isSendingReset
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Send Reset Link'),
                ),
              ],
            );
          }
        );
      },
    );
  }
  // --- End of Forgot Password Function ---

  Widget _buildBody() {
    Widget errorDisplayWidget = const SizedBox.shrink();
    if (_errorMessage.isNotEmpty) {
      errorDisplayWidget = Padding(
        padding: const EdgeInsets.only(top: 15.0, bottom: 0, left: 40, right: 40),
        child: Text(
          _errorMessage,
          style: const TextStyle(color: Colors.red, fontSize: 14),
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
            const Text('Login Success'),
          ],
        );

      case LoginStatus.failure:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPuenjaiLogo(),
            const Icon(Icons.error, color: Colors.red, size: 60),
            const SizedBox(height: 20),
            const Text('Login Failed', style: TextStyle(color: Colors.red)),
            errorDisplayWidget,
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _resetLogin,
              child: const Text('Try Again'),
            ),
          ],
        );

      case LoginStatus.initial:
      default:
        return Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPuenjaiLogo(),
              // Email Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 8.0),
                child: TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12.0)),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                  onChanged: (_) {
                    if (_errorMessage.isNotEmpty) {
                      setState(() => _errorMessage = '');
                    }
                  },
                ),
              ),
              // Password Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 8.0),
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12.0)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  onChanged: (_) {
                    if (_errorMessage.isNotEmpty) {
                      setState(() => _errorMessage = '');
                    }
                  },
                  onFieldSubmitted: (_) => _performLogin(),
                ),
              ),
              // Forgot Password Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _showForgotPasswordDialog,
                      child: const Text('Forgot Password?'),
                    ),
                  ],
                ),
              ),
              errorDisplayWidget,
              SizedBox(height: _errorMessage.isNotEmpty ? 15 : 30),
              // Login Button
              ElevatedButton(
                onPressed: _isLoading ? null : _performLogin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
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
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
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