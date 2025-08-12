// lib/utils/platform.dart
// Cross-platform helper to know if we're on Windows without importing dart:io in web builds.

import 'platform_stub.dart'
    if (dart.library.io) 'platform_io.dart' as impl;

class PlatformEx {
  static bool get isWindows => impl.platformIsWindows();
}
