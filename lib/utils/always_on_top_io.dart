// lib/utils/always_on_top_io.dart
// IO implementation; only acts on Windows via window_manager.

import 'dart:io';
import 'package:window_manager/window_manager.dart';

import 'always_on_top_api.dart';

class _WindowsAlwaysOnTop implements AlwaysOnTopApi {
  bool _cached = false;

  @override
  Future<void> init() async {
    if (!Platform.isWindows) return; // no-op otherwise
    await windowManager.ensureInitialized();
    // Optionally set initial flags
    _cached = await windowManager.isAlwaysOnTop();
  }

  @override
  Future<bool> get() async {
    if (!Platform.isWindows) return _cached;
    _cached = await windowManager.isAlwaysOnTop();
    return _cached;
  }

  @override
  Future<void> set(bool value) async {
    _cached = value;
    if (!Platform.isWindows) return;
    await windowManager.setAlwaysOnTop(value);
  }

  @override
  Future<bool> toggle() async {
    final v = !(await get());
    await set(v);
    return v;
  }
}

AlwaysOnTopApi createAlwaysOnTop() => _WindowsAlwaysOnTop();
