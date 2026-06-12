import 'package:shared_preferences/shared_preferences.dart';

/// Persisted user settings. Plain immutable class — mutated copies on save.
class AppSettings {
  /// Interval length in minutes between focus alerts.
  final int intervalMinutes;

  /// Math difficulty tier 1..5.
  final int difficultyTier;

  /// Whether focus mode is currently active.
  final bool focusModeEnabled;

  /// Whether sound is on for notifications.
  final bool soundEnabled;

  /// Whether vibration is on for notifications.
  final bool vibrationEnabled;

  /// Grace period (seconds) before the challenge escalates into a
  /// continuous alarm. User-configurable: 15, 30, 60 (default), or 120.
  final int escalationGraceSeconds;

  /// Identifier for the alarm sound preset. See
  /// [AlarmSoundRegistry] for the available IDs.
  final String alarmSoundId;

  /// Pomodoro mode settings. null = off (single interval only).
  /// workMinutes + breakMinutes repeat for [cyclesPerRound] cycles, then a
  /// longer [longBreakMinutes] break.
  final PomodoroSettings? pomodoro;

  const AppSettings({
    required this.intervalMinutes,
    required this.difficultyTier,
    required this.focusModeEnabled,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.escalationGraceSeconds,
    required this.alarmSoundId,
    required this.pomodoro,
  });

  static const AppSettings defaults = AppSettings(
    intervalMinutes: 60,
    difficultyTier: 3,
    focusModeEnabled: false,
    soundEnabled: true,
    vibrationEnabled: true,
    escalationGraceSeconds: 60,
    alarmSoundId: 'classic',
    pomodoro: null,
  );

  AppSettings copyWith({
    int? intervalMinutes,
    int? difficultyTier,
    bool? focusModeEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    int? escalationGraceSeconds,
    String? alarmSoundId,
    PomodoroSettings? pomodoro,
    bool clearPomodoro = false,
  }) {
    return AppSettings(
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      difficultyTier: difficultyTier ?? this.difficultyTier,
      focusModeEnabled: focusModeEnabled ?? this.focusModeEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      escalationGraceSeconds:
          escalationGraceSeconds ?? this.escalationGraceSeconds,
      alarmSoundId: alarmSoundId ?? this.alarmSoundId,
      pomodoro: clearPomodoro ? null : (pomodoro ?? this.pomodoro),
    );
  }
}

/// Pomodoro (work/break cycles) configuration.
class PomodoroSettings {
  /// Work interval length in minutes (e.g. 25 for classic).
  final int workMinutes;

  /// Short break length in minutes (e.g. 5).
  final int breakMinutes;

  /// How many work+break cycles per round before a long break.
  final int cyclesPerRound;

  /// Long break length in minutes (e.g. 15).
  final int longBreakMinutes;

  const PomodoroSettings({
    required this.workMinutes,
    required this.breakMinutes,
    required this.cyclesPerRound,
    required this.longBreakMinutes,
  });

  static const PomodoroSettings classic = PomodoroSettings(
    workMinutes: 25,
    breakMinutes: 5,
    cyclesPerRound: 4,
    longBreakMinutes: 15,
  );

  Map<String, dynamic> toJson() => {
        'workMinutes': workMinutes,
        'breakMinutes': breakMinutes,
        'cyclesPerRound': cyclesPerRound,
        'longBreakMinutes': longBreakMinutes,
      };

  static PomodoroSettings fromJson(Map<String, dynamic> j) =>
      PomodoroSettings(
        workMinutes: j['workMinutes'] as int? ?? 25,
        breakMinutes: j['breakMinutes'] as int? ?? 5,
        cyclesPerRound: j['cyclesPerRound'] as int? ?? 4,
        longBreakMinutes: j['longBreakMinutes'] as int? ?? 15,
      );
}

/// Wraps SharedPreferences with typed accessors. Survives app restart and
/// device reboot because SharedPreferences writes to platform-native
/// NSUserDefaults / SharedPreferences.
class SettingsRepository {
  static const _kInterval = 'interval_minutes';
  static const _kDifficulty = 'difficulty_tier';
  static const _kFocusEnabled = 'focus_mode_enabled';
  static const _kSound = 'sound_enabled';
  static const _kVibration = 'vibration_enabled';
  static const _kEscalationGrace = 'escalation_grace_seconds';
  static const _kAlarmSound = 'alarm_sound_id';
  static const _kPomodoro = 'pomodoro_json';

  Future<AppSettings> load() async {
    final p = await SharedPreferences.getInstance();
    PomodoroSettings? pomo;
    final pomoStr = p.getString(_kPomodoro);
    if (pomoStr != null && pomoStr.isNotEmpty) {
      try {
        // Stored as a simple "work,break,round,long" tuple string for
        // compatibility (avoid JSON-decode dependency).
        final parts = pomoStr.split(',');
        if (parts.length == 4) {
          pomo = PomodoroSettings(
            workMinutes: int.tryParse(parts[0]) ?? 25,
            breakMinutes: int.tryParse(parts[1]) ?? 5,
            cyclesPerRound: int.tryParse(parts[2]) ?? 4,
            longBreakMinutes: int.tryParse(parts[3]) ?? 15,
          );
        }
      } catch (_) { /* ignore */ }
    }
    return AppSettings(
      intervalMinutes: p.getInt(_kInterval) ?? 60,
      difficultyTier: p.getInt(_kDifficulty) ?? 3,
      focusModeEnabled: p.getBool(_kFocusEnabled) ?? false,
      soundEnabled: p.getBool(_kSound) ?? true,
      vibrationEnabled: p.getBool(_kVibration) ?? true,
      escalationGraceSeconds: p.getInt(_kEscalationGrace) ?? 60,
      alarmSoundId: p.getString(_kAlarmSound) ?? 'classic',
      pomodoro: pomo,
    );
  }

  Future<void> save(AppSettings s) async {
    final p = await SharedPreferences.getInstance();
    final pomoStr = s.pomodoro == null
        ? ''
        : '${s.pomodoro!.workMinutes},${s.pomodoro!.breakMinutes},'
            '${s.pomodoro!.cyclesPerRound},${s.pomodoro!.longBreakMinutes}';
    await Future.wait([
      p.setInt(_kInterval, s.intervalMinutes),
      p.setInt(_kDifficulty, s.difficultyTier),
      p.setBool(_kFocusEnabled, s.focusModeEnabled),
      p.setBool(_kSound, s.soundEnabled),
      p.setBool(_kVibration, s.vibrationEnabled),
      p.setInt(_kEscalationGrace, s.escalationGraceSeconds),
      p.setString(_kAlarmSound, s.alarmSoundId),
      p.setString(_kPomodoro, pomoStr),
    ]);
  }
}
