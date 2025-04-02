import 'package:flutter/material.dart';
import 'pages/authen.dart'; // Import your login screen file

void main() {
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
         textButtonTheme: TextButtonThemeData( // Optional: Style for TextButtons
             style: TextButton.styleFrom(
                foregroundColor: Colors.teal[700], // Example color
             )
         )
      ),
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