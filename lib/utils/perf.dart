// lib/utils/perf.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Heuristic to lighten visual effects on lower-powered devices (phones).
/// Currently treats Android/iOS as low-perf relative to desktop defaults.
bool isMobileLowPerf(BuildContext context) {
  final platform = defaultTargetPlatform;
  return platform == TargetPlatform.android || platform == TargetPlatform.iOS;
}
