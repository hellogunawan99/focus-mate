import 'package:flutter/material.dart';

/// A pulsating ring used to indicate "focusing" state on the home screen.
/// Three concentric rings that scale 1→1.2→1 with staggered phases.
class PulseRings extends StatefulWidget {
  final double size;
  final Color color;
  const PulseRings({super.key, this.size = 220, required this.color});

  @override
  State<PulseRings> createState() => _PulseRingsState();
}

class _PulseRingsState extends State<PulseRings>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          return Stack(
            alignment: Alignment.center,
            children: List.generate(3, (i) {
              final phase = (_ctrl.value + i / 3) % 1.0;
              final scale = 0.6 + phase * 0.7;
              final opacity = (1 - phase) * 0.4;
              return Container(
                width: widget.size * scale,
                height: widget.size * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.color.withValues(alpha: opacity),
                    width: 1.4,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
