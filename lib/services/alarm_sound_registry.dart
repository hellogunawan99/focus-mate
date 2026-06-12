/// Registry of available alarm sound presets.
///
/// Each entry has an ID (used in settings) and a metadata map used by
/// the UI to render the option. The `rawResourceName` is the Android
/// res/raw/ file (no extension). The `iosBundleName` is the filename
/// (with extension) in the iOS bundle's Sounds directory.
class AlarmSoundPreset {
  final String id;
  final String label;
  final String description;
  final String rawResourceName; // Android
  final String? iosBundleName; // iOS (null = use system fallback)

  const AlarmSoundPreset({
    required this.id,
    required this.label,
    required this.description,
    required this.rawResourceName,
    this.iosBundleName,
  });
}

class AlarmSoundRegistry {
  static const List<AlarmSoundPreset> all = [
    AlarmSoundPreset(
      id: 'classic',
      label: 'Classic',
      description: 'Crisp two-tone ascending beep',
      rawResourceName: 'focus_alarm',
      iosBundleName: 'focus_alarm.m4a',
    ),
    // Future presets can be added here. Each requires a sound file in
    // res/raw/ (Android) and ios/Runner/Sounds/ (iOS).
  ];

  static AlarmSoundPreset byId(String id) =>
      all.firstWhere((p) => p.id == id, orElse: () => all.first);
}
