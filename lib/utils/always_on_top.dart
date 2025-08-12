// lib/utils/always_on_top.dart
// Facade for window always-on-top control. Actual behavior only on Windows.

import 'always_on_top_api.dart';
import 'always_on_top_stub.dart'
  if (dart.library.io) 'always_on_top_io.dart' as impl;

final AlwaysOnTopApi alwaysOnTop = impl.createAlwaysOnTop();

class AlwaysOnTop {
  static Future<void> init() => alwaysOnTop.init();
  static Future<bool> get() => alwaysOnTop.get();
  static Future<void> set(bool v) => alwaysOnTop.set(v);
  static Future<bool> toggle() => alwaysOnTop.toggle();
}
