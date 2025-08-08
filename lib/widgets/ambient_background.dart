// lib/widgets/ambient_background.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pomodoro_app/utils/perf.dart';

/// Animated multi-stop gradient background with subtle movement.
class AmbientBackground extends StatefulWidget {
  final Widget child;
  /// Target "animation" update rate for the subtle gradient movement.
  /// Lower = fewer repaints (better performance). 8–15 gives a smooth, subtle shift.
  final int targetFps;

  const AmbientBackground({super.key, required this.child, this.targetFps = 12});

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // We throttle repaint frequency so the heavy blur layers above don't have to
  // recompute every device frame. This keeps UI interactions at full FPS while
  // the background moves slowly.
  late Duration _minFrameInterval;
  Duration _lastPainted = Duration.zero;
  double _t = 0; // cached value used for build.

  @override
  void initState() {
    super.initState();
  // On mobile, lower the animation FPS a bit more to reduce background repaints
  final defaultFps = widget.targetFps;
  final mobile = isMobileLowPerf(context);
  final clampedFps = (mobile ? (defaultFps * 0.75) : defaultFps).round().clamp(1, 30);
    _minFrameInterval = Duration(milliseconds: (1000 / clampedFps).round());
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60), // full loop duration
    )..addListener(_onTick)
     ..repeat();
  }

  void _onTick() {
    final elapsed = _controller.lastElapsedDuration ?? Duration.zero;
    if (elapsed - _lastPainted >= _minFrameInterval) {
      _lastPainted = elapsed;
      _t = _controller.value; // snapshot
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Always-warm palette (kept consistent across light/dark). Using static const
    // list so objects aren't rebuilt each frame.
    const palette = [
      Color.fromARGB(255, 205, 62, 110),
      Color.fromARGB(255, 182, 180, 114),
      Color.fromARGB(255, 154, 156, 64),
      Color.fromARGB(255, 174, 80, 64),
    ];

    final angle = _t * 2 * pi;
    final align = Alignment(cos(angle) * 0.75, sin(angle) * 0.75);

    // Only this lightweight background repaints; the child is passed through
    // unchanged so its subtree doesn't rebuild every tick.
    return Stack(
      fit: StackFit.expand,
      children: [
        // Moving radial gradient
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: align,
              radius: 1.2,
              colors: [
                palette[0].withValues(alpha: 0.85),
                palette[1].withValues(alpha: 0.70),
                palette[2].withValues(alpha: 0.55),
                palette[3].withValues(alpha: 0.45),
              ],
              stops: const [0.10, 0.45, 0.78, 1.0],
            ),
          ),
        ),
        // Subtle linear sheen overlay
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromARGB(15, 255, 255, 255), // ~0.06 alpha
                Color.fromARGB(0, 255, 255, 255),
              ],
            ),
          ),
        ),
        // App content isolated in its own repaint boundary so its rendering
        // isn't invalidated by the gradient animation.
        RepaintBoundary(child: widget.child),
      ],
    );
  }
}
