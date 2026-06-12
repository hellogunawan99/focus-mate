import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../core/theme.dart';
import '../providers/focus_provider.dart';
import '../widgets/aurora_background.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  late final AnimationController _shakeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  late final AnimationController _successCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  bool _wrong = false;
  int _attemptsShown = 0;
  bool _showSuccess = false;
  int? _previousAttempts;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _controller.dispose();
    _focus.dispose();
    _shakeCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final focus = context.read<FocusProvider>();
    final raw = _controller.text.trim();
    final value = int.tryParse(raw);
    if (value == null) {
      _flashError('Numbers only.');
      return;
    }
    final correct = focus.submitAnswer(value);
    if (correct) {
      _showSuccessAnim();
    } else {
      _flashError('Not quite — try the new one.');
      _controller.clear();
      _focus.requestFocus();
    }
  }

  void _showSuccessAnim() {
    setState(() => _showSuccess = true);
    _successCtrl.forward(from: 0);
  }

  void _flashError(String msg) {
    setState(() => _wrong = true);
    _shakeCtrl.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _wrong = false);
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        duration: const Duration(milliseconds: 900),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final focus = context.watch<FocusProvider>();
    final problem = focus.currentProblem;
    final isEscalated = focus.state == FocusState.escalated;

    if (_previousAttempts != focus.challengeAttempts) {
      _previousAttempts = focus.challengeAttempts;
      _attemptsShown = focus.challengeAttempts;
    }

    if (problem == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            AuroraBackground(
              active: true,
              child: const SizedBox.expand(),
            ),
            // Red pulsing overlay when escalated
            if (isEscalated) _EscalationBackground(),
            GestureDetector(
              // Catch any tap outside the input field to acknowledge
              // interaction (stops the looping alarm if escalated).
              behavior: HitTestBehavior.translucent,
              onTap: () {
                if (isEscalated) {
                  final f = context.read<FocusProvider>();
                  f.acknowledgeInteraction();
                  // Bring focus back to the input so user can type.
                  _focus.requestFocus();
                }
              },
              child: SafeArea(
                child: Stack(
                  children: [
                    _content(focus, problem),
                    if (_showSuccess) _SuccessOverlay(controller: _successCtrl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(FocusProvider focus, dynamic problem) {
    final isEscalated = focus.state == FocusState.escalated;
    final secondsLeft = focus.challengeSecondsUntilEscalation;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _topBar(focus),
          const Spacer(),
          AnimatedBuilder(
            animation: _shakeCtrl,
            builder: (_, child) {
              final offset = _shakeCtrl.value == 0
                  ? 0.0
                  : 8 *
                      (1 - _shakeCtrl.value) *
                      ((_shakeCtrl.value * 12).floor().isEven ? 1 : -1);
              return Transform.translate(offset: Offset(offset, 0), child: child);
            },
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: (isEscalated
                            ? BrandColors.coral
                            : BrandColors.amber)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: (isEscalated
                                ? BrandColors.coral
                                : BrandColors.amber)
                            .withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    isEscalated ? 'TOUCH SCREEN' : 'WAKE UP',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.5,
                      color: isEscalated
                          ? BrandColors.coral
                          : BrandColors.amber,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (!isEscalated)
                  Text(
                    'Auto-alarm in ${secondsLeft}s',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      letterSpacing: 1.2,
                      color: BrandColors.textMuted,
                    ),
                  ),
                if (!isEscalated) const SizedBox(height: 12),
                Text(
                  problem.prompt,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: isEscalated ? 56 : 72,
                    fontWeight: FontWeight.w600,
                    color: _wrong ? BrandColors.coral : BrandColors.text,
                    letterSpacing: -1.5,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '= ?',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    color: BrandColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _controller,
            focusNode: _focus,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(
                signed: false, decimal: false),
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: BrandColors.text,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: const InputDecoration(
              hintText: 'your answer',
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: isEscalated
                    ? BrandColors.coral
                    : BrandColors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                isEscalated ? 'STOP ALARM & SUBMIT' : 'SUBMIT ANSWER',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          const Spacer(),
          Center(
            child: Text(
              isEscalated
                  ? 'Tap anywhere to silence the alarm — then solve it.'
                  : 'You can\'t skip this. Solve it to keep your session going.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: BrandColors.textMuted,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(FocusProvider focus) {
    return Row(
      children: [
        const Icon(Icons.local_fire_department_rounded,
            color: BrandColors.amber, size: 20),
        const SizedBox(width: 8),
        Text(
          'Stay sharp',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: BrandColors.textMuted,
          ),
        ),
        const Spacer(),
        if (focus.challengeAttempts > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: BrandColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: BrandColors.outline),
            ),
            child: Text(
              'attempt ${focus.challengeAttempts}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: BrandColors.textMuted,
              ),
            ),
          ),
      ],
    );
  }
}

class _SuccessOverlay extends StatelessWidget {
  final AnimationController controller;
  const _SuccessOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        if (controller.value == 0) return const SizedBox.shrink();
        final v = controller.value;
        // Quick pop then fade
        final scale = v < 0.6
            ? Curves.easeOutBack.transform(v / 0.6)
            : 1.0;
        final opacity = v < 0.6 ? 1.0 : 1.0 - ((v - 0.6) / 0.4);
        return Positioned.fill(
          child: IgnorePointer(
            child: Container(
              color: BrandColors.bg.withValues(alpha: 0.85 * opacity),
              child: Center(
                child: Transform.scale(
                  scale: scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: BrandColors.mint.withValues(alpha: 0.2),
                          border: Border.all(
                              color: BrandColors.mint, width: 2.5),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: BrandColors.mint,
                          size: 56,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Nice.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: BrandColors.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Back to focus.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: BrandColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Pulsating red overlay shown when the challenge has escalated (user
/// ignored the initial 60s grace period). Pulses 0.4s on, 0.4s off.
class _EscalationBackground extends StatefulWidget {
  @override
  State<_EscalationBackground> createState() => _EscalationBackgroundState();
}

class _EscalationBackgroundState extends State<_EscalationBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          return Container(
            color: BrandColors.coral.withValues(alpha: 0.08 + 0.10 * _ctrl.value),
          );
        },
      ),
    );
  }
}
