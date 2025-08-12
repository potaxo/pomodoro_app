// lib/utils/ping_service_stub.dart
// Stub for non-Windows platforms (or when dart:io is unavailable).

import 'ping_service_api.dart';

class _NoopPingService implements PingService {
  bool _running = false;
  @override
  Future<void> start({int port = 49666}) async {
    _running = true;
  }

  @override
  Future<void> stop() async {
    _running = false;
  }

  @override
  bool get isRunning => _running;
}

PingService createPingService() => _NoopPingService();
