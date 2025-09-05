// lib/main.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pomo/models/pomodoro_record.dart';
import 'package:pomo/screens/home_screen.dart';
import 'package:pomo/utils/perf.dart';
import 'package:pomo/widgets/ambient_background.dart';
import 'package:pomo/utils/always_on_top.dart';
import 'package:pomo/utils/platform.dart';

Future<void> main() async {
  // Ensure that Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register our custom adapter
  Hive.registerAdapter(PomodoroRecordAdapter());
  
  // Open the box so we can use it later
  await Hive.openBox<PomodoroRecord>('pomodoro_box');

  // Load performance mode preference
  await Perf.load();

  // Init always-on-top on Windows only.
  try {
    if (PlatformEx.isWindows) {
      await alwaysOnTop.init();
    }
  } catch (_) {
    // keep startup resilient
  }

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

    const noTransitions = PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _NoAnimationsPageTransitionsBuilder(),
        TargetPlatform.iOS: _NoAnimationsPageTransitionsBuilder(),
        TargetPlatform.linux: _NoAnimationsPageTransitionsBuilder(),
        TargetPlatform.macOS: _NoAnimationsPageTransitionsBuilder(),
        TargetPlatform.windows: _NoAnimationsPageTransitionsBuilder(),
      },
    );

  return MaterialApp(
      title: 'Pomodoro Focus App',
      themeMode: ThemeMode.system,
      theme: base.copyWith(
        pageTransitionsTheme: noTransitions,
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
        pageTransitionsTheme: noTransitions,
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
        ),
      ),
      // Single global animated background for all routes to avoid duplication
      builder: (context, child) => ValueListenableBuilder<bool>(
        valueListenable: Perf.perfMode,
        builder: (_, perfOn, _) => AmbientBackground(
          animate: !perfOn,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class _NoAnimationsPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoAnimationsPageTransitionsBuilder();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child; // no in/out animation
  }
}