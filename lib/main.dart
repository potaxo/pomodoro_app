import 'package:flutter/material.dart';
import 'package:pomodoro_app/screens/home_screen.dart'; // We will create this file next

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pomodoro Focus App',
      theme: ThemeData(
        // Using a color scheme based on a seed color for a modern look
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
        useMaterial3: true,
        // Setting a consistent text theme
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontSize: 24.0, fontStyle: FontStyle.italic),
          bodyMedium: TextStyle(fontSize: 14.0),
        ),
      ),
      // The app starts with the HomeScreen
      home: const HomeScreen(),
    );
  }
}