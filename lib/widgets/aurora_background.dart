import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Animated mesh-gradient background. Two soft "aurora" blobs that drift
/// slowly. Used on the home and challenge screens.
class AuroraBackground extends StatefulWidget {
  final bool active;
  final Widget child;
  const AuroraBackground({super.key, required this.active, required this.child});

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base color
        const ColoredBox(color: BrandColors.bg),
        // Drifting blobs — only repaints when active state changes (the
        // painter itself caches its frame by t). Using RepaintBoundary to
        // isolate the painter from text repaints.
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              return CustomPaint(
                painter: _AuroraPainter(
                  t: _ctrl.value,
                  active: widget.active,
                ),
                child: const SizedBox.expand(),
              );
            },
          ),
        ),
        // The child is also wrapped in a RepaintBoundary so the animated
        // background never invalidates the text.
        RepaintBoundary(child: widget.child),
      ],
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final double t;
  final bool active;
  _AuroraPainter({required this.t, required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final blobA = _blob(
      size: size,
      center: Offset(
        size.width * (0.25 + 0.15 * math.sin(t * 2 * math.pi)),
        size.height * (0.20 + 0.10 * math.cos(t * 2 * math.pi)),
      ),
      radius: size.width * 0.55,
      color: active
          ? BrandColors.amber.withValues(alpha: 0.18)
          : BrandColors.lilac.withValues(alpha: 0.10),
    );
    final blobB = _blob(
      size: size,
      center: Offset(
        size.width * (0.75 + 0.20 * math.cos(t * 2 * math.pi)),
        size.height * (0.70 + 0.15 * math.sin(t * 2 * math.pi)),
      ),
      radius: size.width * 0.50,
      color: active
          ? BrandColors.lilac.withValues(alpha: 0.14)
          : BrandColors.amber.withValues(alpha: 0.06),
    );
    canvas.drawRect(Offset.zero & size, blobA);
    canvas.drawRect(Offset.zero & size, blobB);
  }

  Paint _blob({
    required Size size,
    required Offset center,
    required double radius,
    required Color color,
  }) {
    return Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0)],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldRepaint(_AuroraPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.active != active;
}

class _GrainOverlay extends StatelessWidget {
  const _GrainOverlay();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
