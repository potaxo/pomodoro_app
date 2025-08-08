// lib/widgets/ambient_background.dart

import 'dart:math';
import 'package:flutter/material.dart';

/// Animated multi-stop gradient background with subtle movement.
class AmbientBackground extends StatefulWidget {
  final Widget child;

  const AmbientBackground({super.key, required this.child});

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Always-warm palette (kept consistent across light/dark)
    const palette = [
      Color.fromARGB(255, 205, 62, 110), // warm peach
      Color.fromARGB(255, 182, 180, 114), // soft coral
      Color.fromARGB(255, 154, 156, 64), // warm orange
      Color.fromARGB(255, 174, 80, 64), // cream
    ];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final angle = t * 2 * pi;
        final align = Alignment(cos(angle) * 0.75, sin(angle) * 0.75);

        return Container(
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
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.06),
                  Colors.white.withValues(alpha: 0.00),
                ],
              ),
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}
