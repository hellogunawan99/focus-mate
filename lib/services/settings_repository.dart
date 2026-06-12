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

  const AppSettings({
    required this.intervalMinutes,
    required this.difficultyTier,
    required this.focusModeEnabled,
    required this.soundEnabled,
    required this.vibrationEnabled,
  });

  static const AppSettings defaults = AppSettings(
    intervalMinutes: 60,
    difficultyTier: 3,
    focusModeEnabled: false,
    soundEnabled: true,
    vibrationEnabled: true,
  );

  AppSettings copyWith({
    int? intervalMinutes,
    int? difficultyTier,
    bool? focusModeEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return AppSettings(
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      difficultyTier: difficultyTier ?? this.difficultyTier,
      focusModeEnabled: focusModeEnabled ?? this.focusModeEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }
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

  Future<AppSettings> load() async {
    final p = await SharedPreferences.getInstance();
    return AppSettings(
      intervalMinutes: p.getInt(_kInterval) ?? 60,
      difficultyTier: p.getInt(_kDifficulty) ?? 3,
      focusModeEnabled: p.getBool(_kFocusEnabled) ?? false,
      soundEnabled: p.getBool(_kSound) ?? true,
      vibrationEnabled: p.getBool(_kVibration) ?? true,
    );
  }

  Future<void> save(AppSettings s) async {
    final p = await SharedPreferences.getInstance();
    await Future.wait([
      p.setInt(_kInterval, s.intervalMinutes),
      p.setInt(_kDifficulty, s.difficultyTier),
      p.setBool(_kFocusEnabled, s.focusModeEnabled),
      p.setBool(_kSound, s.soundEnabled),
      p.setBool(_kVibration, s.vibrationEnabled),
    ]);
  }
}
