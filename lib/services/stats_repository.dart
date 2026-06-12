import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Daily focus stats — one entry per calendar day.
class DailyStat {
  /// ISO date string, e.g. "2026-06-13". Used as the key in storage.
  final String dateKey;

  /// Total focus seconds (sum of session durations).
  final int focusSeconds;

  /// Number of math problems solved (across all sessions).
  final int problemsSolved;

  /// Number of times the challenge escalated into a continuous alarm.
  final int escalationsTriggered;

  const DailyStat({
    required this.dateKey,
    required this.focusSeconds,
    required this.problemsSolved,
    required this.escalationsTriggered,
  });

  static const DailyStat empty = DailyStat(
    dateKey: '',
    focusSeconds: 0,
    problemsSolved: 0,
    escalationsTriggered: 0,
  );

  DailyStat add({
    int focusSeconds = 0,
    int problemsSolved = 0,
    int escalationsTriggered = 0,
  }) {
    return DailyStat(
      dateKey: dateKey,
      focusSeconds: this.focusSeconds + focusSeconds,
      problemsSolved: this.problemsSolved + problemsSolved,
      escalationsTriggered:
          this.escalationsTriggered + escalationsTriggered,
    );
  }

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'focusSeconds': focusSeconds,
        'problemsSolved': problemsSolved,
        'escalationsTriggered': escalationsTriggered,
      };

  static DailyStat fromJson(Map<String, dynamic> j) => DailyStat(
        dateKey: j['dateKey'] as String? ?? '',
        focusSeconds: j['focusSeconds'] as int? ?? 0,
        problemsSolved: j['problemsSolved'] as int? ?? 0,
        escalationsTriggered: j['escalationsTriggered'] as int? ?? 0,
      );
}

/// Tracks per-day focus stats and the user's streak (consecutive days
/// of using the app). Persists to SharedPreferences.
class StatsRepository {
  static const _kStats = 'daily_stats_json';
  static const _kStreak = 'streak_data_json';

  /// Returns the past [days] daily stats, oldest first. Missing days are
  /// returned as empty `DailyStat`s.
  Future<List<DailyStat>> getLastDays(int days) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kStats) ?? '{}';
    Map<String, dynamic> all;
    try {
      all = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      all = {};
    }
    final now = DateTime.now();
    return List.generate(days, (i) {
      final d = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: days - 1 - i));
      final key = _dateKey(d);
      final entry = all[key];
      if (entry is Map<String, dynamic>) return DailyStat.fromJson(entry);
      return DailyStat(dateKey: key, focusSeconds: 0, problemsSolved: 0, escalationsTriggered: 0);
    });
  }

  Future<void> addToToday({
    int focusSeconds = 0,
    int problemsSolved = 0,
    int escalationsTriggered = 0,
  }) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kStats) ?? '{}';
    Map<String, dynamic> all;
    try {
      all = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      all = {};
    }
    final key = _todayKey();
    final existing = all[key];
    final current = existing is Map<String, dynamic>
        ? DailyStat.fromJson(existing)
        : DailyStat(dateKey: key, focusSeconds: 0, problemsSolved: 0, escalationsTriggered: 0);
    final updated = current.add(
      focusSeconds: focusSeconds,
      problemsSolved: problemsSolved,
      escalationsTriggered: escalationsTriggered,
    );
    all[key] = updated.toJson();
    await p.setString(_kStats, jsonEncode(all));
  }

  /// Update the streak. Call this once per day when the user starts a
  /// focus session. Returns the new streak length.
  Future<int> bumpStreak() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kStreak) ?? '{}';
    Map<String, dynamic> data;
    try {
      data = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      data = {};
    }
    final lastDay = data['lastDay'] as String? ?? '';
    final current = data['current'] as int? ?? 0;
    final longest = data['longest'] as int? ?? 0;
    final today = _todayKey();

    int newStreak;
    if (lastDay == today) {
      // Already bumped today.
      newStreak = current;
    } else if (lastDay == _yesterdayKey()) {
      newStreak = current + 1;
    } else {
      // Either first time, or streak broken.
      newStreak = 1;
    }
    final newLongest =
        newStreak > longest ? newStreak : longest;

    data['lastDay'] = today;
    data['current'] = newStreak;
    data['longest'] = newLongest;
    await p.setString(_kStreak, jsonEncode(data));
    return newStreak;
  }

  Future<({int current, int longest, String lastDay})> getStreak() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kStreak) ?? '{}';
    Map<String, dynamic> data;
    try {
      data = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      data = {};
    }
    return (
      current: data['current'] as int? ?? 0,
      longest: data['longest'] as int? ?? 0,
      lastDay: data['lastDay'] as String? ?? '',
    );
  }

  static String _todayKey() => _dateKey(DateTime.now());
  static String _yesterdayKey() =>
      _dateKey(DateTime.now().subtract(const Duration(days: 1)));
  static String _dateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
