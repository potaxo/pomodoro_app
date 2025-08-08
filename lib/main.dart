// lib/main.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pomodoro_app/models/pomodoro_record.dart';
import 'package:pomodoro_app/screens/home_screen.dart';
import 'package:pomodoro_app/widgets/ambient_background.dart';

Future<void> main() async {
  // Ensure that Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register our custom adapter
  Hive.registerAdapter(PomodoroRecordAdapter());
  
  // Open the box so we can use it later
  await Hive.openBox<PomodoroRecord>('pomodoro_box');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'Pomodoro Focus App',
      themeMode: ThemeMode.system,
      theme: base.copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: base.appBarTheme.copyWith(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: base.colorScheme.onSurface,
        ),
        cardTheme: base.cardTheme.copyWith(
          color: Colors.white.withValues(alpha: 0.05),
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
        ),
      ),
      home: AmbientBackground(child: const HomeScreen()),
    );
  }
}