// lib/utils/always_on_top_api.dart

abstract class AlwaysOnTopApi {
  Future<void> init();
  Future<bool> get();
  Future<void> set(bool value);
  Future<bool> toggle();
}
