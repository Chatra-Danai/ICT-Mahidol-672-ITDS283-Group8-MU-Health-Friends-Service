import 'package:flutter/material.dart';

// Import Firebase Core
import 'package:firebase_core/firebase_core.dart';
// Import the generated Firebase options
import 'firebase_options.dart';

// Assuming your login screen is in lib/pages/authen.dart
// If it's directly in lib/, change this path accordingly
import 'pages/authen.dart'; // Import your login screen file

// --- FIX 1: Make main() asynchronous ---
void main() async {
  // --- FIX 2: Ensure Flutter bindings are initialized ---
  // This is required before calling Firebase.initializeApp()
  WidgetsFlutterBinding.ensureInitialized();

  // --- FIX 3: Initialize Firebase ---
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform, // Use generated options
    );
  } catch (e) {
    // Optionally handle initialization errors more gracefully
    debugPrint("Firebase initialization failed: $e");
    // You might want to show an error screen or message here
  }
  // --- End of Fixes ---

  // Now run the app vc*fter* initialization
  // ˘bvcxflutter vcrunb
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Puenjai App', // Or your app's name
      theme: ThemeData(
          primarySwatch: Colors.teal, // Example theme color
          visualDensity: VisualDensity.adaptivePlatformDensity,
          // Optional: Define consistent input/button styles like before
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12.0)),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
              // Optional: Style for TextButtons
              style: TextButton.styleFrom(
            foregroundColor: Colors.teal[700], // Example color
          ))),
      // Set the Login Screen (authen.dart) as the home/initial screen
      home: const AuthenticationScreen(),

      // Optional: Define named routes for more complex navigation later
      // routes: {
      //   '/login': (context) => const AuthenticationScreen(),
      //   '/register': (context) => const RegisterScreen(),
      //   // '/home': (context) => const HomeScreen(), // Example home screen
      // },
      // initialRoute: '/login', // Use initialRoute if using named routes
    );
  }
}

