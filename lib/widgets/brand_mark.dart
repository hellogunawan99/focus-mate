import 'package:flutter/material.dart';

import '../core/theme.dart';

/// The Focus Mate brand mark — a stylized eye/target concentric circle.
/// Used in the home header and challenge screen.
class BrandMark extends StatelessWidget {
  final double size;
  final Color? color;
  const BrandMark({super.key, this.size = 32, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BrandMarkPainter(color: color ?? BrandColors.amber),
      ),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  final Color color;
  _BrandMarkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.14;

    canvas.drawCircle(center, r * 0.92, p);
    canvas.drawCircle(center, r * 0.55, p);
    canvas.drawCircle(center, r * 0.22, p..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
