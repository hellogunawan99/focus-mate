import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/focus_provider.dart';
import '../widgets/aurora_background.dart';
import '../widgets/brand_mark.dart';
import '../widgets/pulse_rings.dart';
import 'challenge_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final focus = context.watch<FocusProvider>();
    if (focus.state == FocusState.challengeActive ||
        focus.state == FocusState.escalated) {
      return const ChallengeScreen();
    }
    return AuroraBackground(
      active: focus.isRunning,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            children: [
              _Header(running: focus.isRunning),
              const SizedBox(height: 12),
              Expanded(child: _Body(running: focus.isRunning)),
              const SizedBox(height: 12),
              _PrimaryAction(running: focus.isRunning),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool running;
  const _Header({required this.running});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const BrandMark(size: 28),
        const SizedBox(width: 10),
        Text(
          'Focus Mate',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: BrandColors.text,
            letterSpacing: -0.2,
          ),
        ),
        const Spacer(),
        _StatusPill(running: running),
        const SizedBox(width: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: BrandColors.surface.withValues(alpha: 0.6),
                border:
                    Border.all(color: BrandColors.outline.withValues(alpha: 0.5)),
              ),
              child: const Icon(Icons.tune_rounded,
                  size: 18, color: BrandColors.text),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool running;
  const _StatusPill({required this.running});

  @override
  Widget build(BuildContext context) {
    final color = running ? BrandColors.mint : BrandColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: running
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.6),
                        blurRadius: 6,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            running ? 'FOCUSING' : 'IDLE',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final bool running;
  const _Body({required this.running});

  @override
  Widget build(BuildContext context) {
    final focus = context.watch<FocusProvider>();
    return Center(
      child: running
          ? _RunningView(intervalMinutes: focus.settings.intervalMinutes)
          : _IdleView(intervalMinutes: focus.settings.intervalMinutes),
    );
  }
}

class _IdleView extends StatelessWidget {
  final int intervalMinutes;
  const _IdleView({required this.intervalMinutes});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 32),
        Text(
          'INTERVAL',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
            color: BrandColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        _BigNumber(value: intervalMinutes),
        Text(
          'minutes between alerts',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: BrandColors.textMuted,
          ),
        ),
        const SizedBox(height: 36),
        _IntervalSlider(initial: intervalMinutes),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: AppDecorations.glassCard,
          child: Row(
            children: [
              const Icon(Icons.bolt_rounded, color: BrandColors.amber, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'A math challenge fires at the end of each interval. '
                  'Solve it to keep going.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: BrandColors.textMuted,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RunningView extends StatelessWidget {
  final int intervalMinutes;
  const _RunningView({required this.intervalMinutes});

  @override
  Widget build(BuildContext context) {
    final focus = context.watch<FocusProvider>();
    final remaining = focus.nextAlertIn;
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Text(
          'NEXT ALERT IN',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
            color: BrandColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        _CountdownRing(
          progress: focus.countdownProgress,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 64,
                  fontWeight: FontWeight.w600,
                  color: BrandColors.amber,
                  letterSpacing: -2,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'mm:ss',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  letterSpacing: 2,
                  color: BrandColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _SessionStatsRow(focus: focus),
        const SizedBox(height: 20),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: AppDecorations.glassCard,
          child: Row(
            children: [
              const Icon(Icons.shield_moon_rounded,
                  color: BrandColors.mint, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session running',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: BrandColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'A math challenge will wake you up. Don\'t skip it.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: BrandColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CountdownRing extends StatelessWidget {
  final double progress;
  final Widget child;
  const _CountdownRing({required this.progress, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Track
          SizedBox.expand(
            child: CustomPaint(painter: _RingPainter(
              progress: 1.0,
              color: BrandColors.outline,
              strokeWidth: 6,
            )),
          ),
          // Progress
          SizedBox.expand(
            child: CustomPaint(painter: _RingPainter(
              progress: progress,
              color: BrandColors.amber,
              strokeWidth: 6,
            )),
          ),
          PulseRings(size: 200, color: BrandColors.amber),
          child,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = (size.shortestSide - strokeWidth) / 2;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -math.pi / 2, // start at top
      2 * math.pi * progress,
      false,
      p,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

class _SessionStatsRow extends StatelessWidget {
  final FocusProvider focus;
  const _SessionStatsRow({required this.focus});

  String _formatTotalFocus(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _Stat(
          label: 'FOCUS TIME',
          value: _formatTotalFocus(focus.totalFocusSeconds),
        ),
        Container(width: 1, height: 30, color: BrandColors.outline),
        _Stat(
          label: 'SOLVED',
          value: '${focus.problemsSolved}',
        ),
        Container(width: 1, height: 30, color: BrandColors.outline),
        _Stat(
          label: 'INTERVAL',
          value: '${focus.settings.intervalMinutes}m',
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: BrandColors.text,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9,
            letterSpacing: 1.5,
            color: BrandColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _BigNumber extends StatelessWidget {
  final int value;
  const _BigNumber({required this.value});
  @override
  Widget build(BuildContext context) {
    return Text(
      '$value',
      style: GoogleFonts.jetBrainsMono(
        fontSize: 120,
        fontWeight: FontWeight.w500,
        height: 1,
        letterSpacing: -4,
        color: BrandColors.text,
      ),
    );
  }
}

class _IntervalSlider extends StatelessWidget {
  final int initial;
  const _IntervalSlider({required this.initial});

  @override
  Widget build(BuildContext context) {
    final focus = context.read<FocusProvider>();
    double value = initial.toDouble();
    return StatefulBuilder(
      builder: (context, setState) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              Slider(
                min: 5,
                max: 120,
                divisions: 23,
                value: value.clamp(5, 120),
                onChanged: (v) => setState(() => value = v),
                onChangeEnd: (v) => focus.setInterval(v.round()),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('5 min',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11, color: BrandColors.textMuted)),
                    Text('${value.round()} min',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: BrandColors.amber,
                        )),
                    Text('120 min',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11, color: BrandColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  final bool running;
  const _PrimaryAction({required this.running});

  @override
  Widget build(BuildContext context) {
    final focus = context.read<FocusProvider>();
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: running ? BrandColors.coral : BrandColors.amber,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: () async {
          if (running) {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('End focus session?'),
                content: const Text(
                    'You can re-enable it any time. Pending alerts will be cancelled.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Stay focused'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: BrandColors.coral,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('End session'),
                  ),
                ],
              ),
            );
            if (confirm == true) await focus.disableFocusMode();
          } else {
            await focus.enableFocusMode();
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(running ? Icons.stop_rounded : Icons.play_arrow_rounded,
                size: 22),
            const SizedBox(width: 8),
            Text(
              running ? 'End focus session' : 'Start focus session',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
