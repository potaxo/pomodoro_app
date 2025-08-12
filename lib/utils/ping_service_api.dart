// lib/utils/ping_service_api.dart

abstract class PingService {
  Future<void> start({int port = 49666});
  Future<void> stop();
  bool get isRunning;
}
