// lib/utils/perf.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Heuristic to lighten visual effects on lower-powered devices (phones).
/// Currently treats Android/iOS as low-perf relative to desktop defaults.
bool isMobileLowPerf(BuildContext context) {
  final platform = defaultTargetPlatform;
  return platform == TargetPlatform.android || platform == TargetPlatform.iOS;
}

/// Global Performance Mode toggle with persistence.
class Perf {
  static final ValueNotifier<bool> perfMode = ValueNotifier<bool>(false);

  static const _prefKey = 'perf_mode_enabled_v1';

  /// Load saved setting at startup. If no saved value, default to false.
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool(_prefKey);
      if (saved != null) perfMode.value = saved;
    } catch (_) {
      // Ignore persistence errors; default stays.
    }
  }

  /// Enable/disable performance mode and persist.
  static Future<void> setPerfMode(bool enabled) async {
    perfMode.value = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, enabled);
    } catch (_) {
      // Ignore persistence errors.
    }
  }
}
