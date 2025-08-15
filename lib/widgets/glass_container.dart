// lib/widgets/glass_container.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pomo/utils/perf.dart';

/// A reusable frosted glass container with subtle gradient, border and blur.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final GestureTapCallback? onTap;
  final Color? tintColor; // optional color tint

  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
    this.onTap,
    this.tintColor,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: Perf.perfMode,
      builder: (context, perfOn, _) {
        final bg = Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black;
        final lowPerf = isMobileLowPerf(context) || perfOn;

        final decoration = BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              (tintColor ?? bg).withValues(alpha: 0.10),
              (tintColor ?? bg).withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: (tintColor ?? bg).withValues(alpha: 0.18),
            width: 1,
          ),
          boxShadow: [
            if (!lowPerf)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                spreadRadius: 0.5,
                offset: const Offset(0, 4),
              ),
          ],
        );

        final content = RepaintBoundary(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: lowPerf
                // Skip expensive blur on mobile; keep the frosted look with tint
                ? Container(
                    padding: padding,
                    decoration: decoration,
                    child: child,
                  )
                : BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: padding,
                      decoration: decoration,
                      child: child,
                    ),
                  ),
          ),
        );

        if (onTap != null) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(borderRadius),
              onTap: onTap,
              child: content,
            ),
          );
        }
        return content;
      },
    );
  }
}

class GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? tintColor;

  const GlassButton({
    super.key,
    required this.child,
    this.onPressed,
    this.borderRadius = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    this.tintColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: borderRadius,
      padding: EdgeInsets.zero,
      tintColor: tintColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onPressed,
        child: Padding(padding: padding, child: Center(child: child)),
      ),
    );
  }
}
