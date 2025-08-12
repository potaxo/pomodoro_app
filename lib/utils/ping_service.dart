// lib/utils/ping_service.dart
// Provides a tiny local HTTP ping endpoint to check liveness.
// Windows-only behavior is implemented in the platform-specific part.

import 'ping_service_api.dart';
import 'ping_service_stub.dart'
  if (dart.library.io) 'ping_service_io.dart' as impl;

// Single shared instance using conditional factory
final PingService pingService = impl.createPingService();
