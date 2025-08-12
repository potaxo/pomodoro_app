// lib/utils/ping_service_io.dart
// IO implementation. Only actually starts on Windows; otherwise no-op.

import 'dart:async' show unawaited;
import 'dart:io';

import 'ping_service_api.dart';

class _IoPingService implements PingService {
  HttpServer? _server;

  @override
  bool get isRunning => _server != null;

  @override
  Future<void> start({int port = 49666}) async {
    if (!Platform.isWindows) {
      // No-op on non-Windows
      return;
    }
    if (_server != null) return;

    // Bind localhost only to avoid firewall prompts.
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    _server = server;
    // Handle simple ping endpoint.
    unawaited(_serve(server));
  }

  Future<void> _serve(HttpServer server) async {
    await for (final req in server) {
      try {
        if (req.method == 'GET' && (req.uri.path == '/ping' || req.uri.path == '/health')) {
          req.response.statusCode = 200;
          req.response.headers.set(HttpHeaders.contentTypeHeader, 'text/plain; charset=utf-8');
          req.response.write('pong');
        } else {
          req.response.statusCode = 404;
        }
        await req.response.close();
      } catch (_) {
        // swallow errors to keep lightweight
      }
    }
  }

  @override
  Future<void> stop() async {
    final server = _server;
    if (server != null) {
      _server = null;
      await server.close(force: true);
    }
  }
}

PingService createPingService() => _IoPingService();
