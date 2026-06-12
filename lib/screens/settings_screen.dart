import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/focus_provider.dart';
import '../services/alarm_sound_registry.dart';
import '../services/settings_repository.dart';
import '../widgets/aurora_background.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final focus = context.watch<FocusProvider>();
    return Scaffold(
      backgroundColor: BrandColors.bg,
      body: AuroraBackground(
        active: false,
        child: SafeArea(
          child: Column(
            children: [
              _AppBar(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    _SectionTitle('Mode'),
                    _ModeCard(focus: focus),
                    const SizedBox(height: 24),
                    _SectionTitle('Interval'),
                    _IntervalCard(focus: focus),
                    const SizedBox(height: 24),
                    _SectionTitle('Difficulty'),
                    _DifficultyCard(focus: focus),
                    const SizedBox(height: 24),
                    _SectionTitle('Escalation'),
                    _GraceCard(focus: focus),
                    const SizedBox(height: 24),
                    _SectionTitle('Alerts'),
                    _AlertsCard(focus: focus),
                    const SizedBox(height: 24),
                    _SectionTitle('About'),
                    _AboutCard(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: const Icon(Icons.arrow_back_rounded,
                    color: BrandColors.text, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Settings',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: BrandColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 2.5,
          color: BrandColors.textMuted,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.card,
      padding: const EdgeInsets.all(4),
      child: child,
    );
  }
}

class _IntervalCard extends StatelessWidget {
  final FocusProvider focus;
  const _IntervalCard({required this.focus});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            final selected = await showModalBottomSheet<int>(
              context: context,
              isScrollControlled: true,
              backgroundColor: BrandColors.surface,
              shape: const RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(28)),
              ),
              builder: (_) {
                int v = focus.settings.intervalMinutes;
                return StatefulBuilder(builder: (context, setState) {
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                        24, 8, 24, MediaQuery.of(context).viewInsets.bottom + 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: BrandColors.outline,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text('Set interval',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: BrandColors.text)),
                        const SizedBox(height: 4),
                        Text('How often a math challenge fires',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: BrandColors.textMuted)),
                        const SizedBox(height: 28),
                        Text('$v',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 96,
                                fontWeight: FontWeight.w300,
                                letterSpacing: -3,
                                color: BrandColors.amber,
                                height: 1)),
                        Text('minutes',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: BrandColors.textMuted)),
                        Slider(
                          min: 5,
                          max: 120,
                          divisions: 23,
                          value: v.toDouble().clamp(5, 120),
                          onChanged: (val) => setState(() => v = val.round()),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            onPressed: () => Navigator.pop(context, v),
                            child: const Text('SAVE'),
                          ),
                        ),
                      ],
                    ),
                  );
                });
              },
            );
            if (selected != null) await focus.setInterval(selected);
          },
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: BrandColors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.timer_outlined,
                      color: BrandColors.amber, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Interval length',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: BrandColors.text)),
                      const SizedBox(height: 2),
                      Text('${focus.settings.intervalMinutes} minutes',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: BrandColors.textMuted)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: BrandColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  final FocusProvider focus;
  const _DifficultyCard({required this.focus});

  @override
  Widget build(BuildContext context) {
    final labels = const [
      'Easy',
      'Normal',
      'Moderate',
      'Hard',
      'Brutal',
    ];
    final descriptions = const [
      'Single-digit math',
      'Two-digit math',
      'Three-digit + ×',
      'Multi-step',
      'No mercy',
    ];
    return _Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          children: List.generate(5, (i) {
            final tier = i + 1;
            final selected = focus.settings.difficultyTier == tier;
            return _DifficultyRow(
              tier: tier,
              label: labels[i],
              description: descriptions[i],
              selected: selected,
              onTap: () => focus.setDifficulty(tier),
            );
          }),
        ),
      ),
    );
  }
}

class _DifficultyRow extends StatelessWidget {
  final int tier;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;
  const _DifficultyRow({
    required this.tier,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? BrandColors.amber.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? BrandColors.amber.withValues(alpha: 0.45)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? BrandColors.amber : BrandColors.outline,
                ),
                child: Text(
                  '$tier',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.black : BrandColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: BrandColors.text)),
                    Text(description,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11, color: BrandColors.textMuted)),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded,
                    color: BrandColors.amber, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertsCard extends StatelessWidget {
  final FocusProvider focus;
  const _AlertsCard({required this.focus});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          _ToggleRow(
            icon: Icons.volume_up_rounded,
            title: 'Sound',
            subtitle: 'Play alert tone',
            value: focus.settings.soundEnabled,
            onChanged: focus.setSound,
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 1,
            color: BrandColors.outline,
          ),
          _ToggleRow(
            icon: Icons.vibration_rounded,
            title: 'Vibration',
            subtitle: 'Buzz on alert',
            value: focus.settings.vibrationEnabled,
            onChanged: focus.setVibration,
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: BrandColors.surfaceHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: BrandColors.amber, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: BrandColors.text)),
                Text(subtitle,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: BrandColors.textMuted)),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: BrandColors.lilac.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.info_outline_rounded,
                  color: BrandColors.lilac, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Focus Mate',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: BrandColors.text)),
                  const SizedBox(height: 4),
                  Text(
                    'Anti-drowsiness focus timer. Math challenges prevent '
                    'dismissal so you stay engaged.',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: BrandColors.textMuted,
                        height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mode card — choose between single interval or Pomodoro cycles.
class _ModeCard extends StatelessWidget {
  final FocusProvider focus;
  const _ModeCard({required this.focus});

  @override
  Widget build(BuildContext context) {
    final isPomo = focus.settings.pomodoro != null;
    return _Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          children: [
            _ModeRow(
              label: 'Single interval',
              description: 'Same interval on repeat',
              icon: Icons.timer_outlined,
              selected: !isPomo,
              onTap: () => focus.setPomodoro(null),
            ),
            const Divider(color: BrandColors.outline, height: 1),
            _ModeRow(
              label: 'Pomodoro',
              description:
                  '${focus.settings.pomodoro?.workMinutes ?? 25}min work / '
                  '${focus.settings.pomodoro?.breakMinutes ?? 5}min break / '
                  '${focus.settings.pomodoro?.longBreakMinutes ?? 15}min long',
              icon: Icons.local_cafe_outlined,
              selected: isPomo,
              onTap: () => focus.setPomodoro(PomodoroSettings.classic),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeRow extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ModeRow({
    required this.label,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, color: selected ? BrandColors.amber : BrandColors.textMuted, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: BrandColors.text)),
                    Text(description,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11, color: BrandColors.textMuted)),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded,
                    color: BrandColors.amber, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grace period card — how long until escalation kicks in.
class _GraceCard extends StatelessWidget {
  final FocusProvider focus;
  const _GraceCard({required this.focus});

  @override
  Widget build(BuildContext context) {
    const options = [15, 30, 60, 120];
    return _Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: BrandColors.coral.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.alarm_rounded,
                      color: BrandColors.coral, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Escalation delay',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: BrandColors.text)),
                      Text('How long to wait before looping alarm starts',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 11, color: BrandColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: options.map((s) {
                final selected = focus.settings.escalationGraceSeconds == s;
                return ChoiceChip(
                  label: Text('${s}s'),
                  selected: selected,
                  onSelected: (_) => focus.setEscalationGrace(s),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: BrandColors.surfaceHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.music_note_rounded,
                      color: BrandColors.amber, size: 16),
                  const SizedBox(width: 8),
                  Text('Alarm sound:',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, color: BrandColors.textMuted)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AlarmSoundRegistry.byId(focus.settings.alarmSoundId).label,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: BrandColors.text),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
