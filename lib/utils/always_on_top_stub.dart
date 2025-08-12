// lib/utils/always_on_top_stub.dart

import 'always_on_top_api.dart';

class _NoopAlwaysOnTop implements AlwaysOnTopApi {
  bool _value = false;
  @override
  Future<void> init() async {}
  @override
  Future<bool> get() async => _value;
  @override
  Future<void> set(bool value) async { _value = value; }
  @override
  Future<bool> toggle() async { _value = !_value; return _value; }
}

AlwaysOnTopApi createAlwaysOnTop() => _NoopAlwaysOnTop();
