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
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark
        ? [
            const Color(0xFF241E92),
            const Color(0xFF5432D3),
            const Color(0xFF7F39FB),
            const Color(0xFFE53E3E),
          ]
        : [
            const Color(0xFFFFDEE9),
            const Color(0xFFB5FFFC),
            const Color(0xFFFFC1CC),
            const Color(0xFFFFF6E7),
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
                palette[0].withOpacity(isDark ? 0.55 : 0.85),
                palette[1].withOpacity(isDark ? 0.40 : 0.70),
                palette[2].withOpacity(isDark ? 0.30 : 0.55),
                palette[3].withOpacity(isDark ? 0.25 : 0.45),
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
                  Colors.white.withOpacity(isDark ? 0.02 : 0.06),
                  Colors.white.withOpacity(0.00),
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
