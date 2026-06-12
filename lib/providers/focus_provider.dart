import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/math_problem.dart';
import '../services/notification_service.dart';
import '../services/settings_repository.dart';

enum FocusState { idle, running, challengeActive, paused }

/// Single source of truth for the focus-mode state machine.
class FocusProvider extends ChangeNotifier {
  final SettingsRepository _repo;
  final FocusNotificationService _notif;
  final MathProblemGenerator _gen = MathProblemGenerator();

  AppSettings _settings = AppSettings.defaults;
  FocusState _state = FocusState.idle;
  MathProblem? _currentProblem;
  int _challengeAttempts = 0;

  /// When is the next OS-scheduled alert due? Used for the live countdown UI.
  DateTime? _nextAlertAt;
  Timer? _ticker;

  /// Cached "time until next alert" — recomputed every second by [_ticker].
  Duration _nextAlertIn = Duration.zero;

  /// Total focus minutes for the current session (for stats / progress bar).
  int _problemsSolved = 0;
  int _totalFocusSeconds = 0;
  DateTime? _sessionStartedAt;

  FocusProvider({
    required SettingsRepository repo,
    required FocusNotificationService notif,
  })  : _repo = repo,
        _notif = notif;

  // --- Read-only views ---------------------------------------------------
  AppSettings get settings => _settings;
  FocusState get state => _state;
  MathProblem? get currentProblem => _currentProblem;
  int get challengeAttempts => _challengeAttempts;
  Duration get nextAlertIn => _nextAlertIn;
  DateTime? get nextAlertAt => _nextAlertAt;
  bool get isRunning => _state == FocusState.running;
  int get problemsSolved => _problemsSolved;
  int get totalFocusSeconds => _totalFocusSeconds;

  /// Progress 0..1 for the countdown ring/bar (0 = just started, 1 = next
  /// alert is due now).
  double get countdownProgress {
    if (_state != FocusState.running) return 0;
    final total = _settings.intervalMinutes * 60;
    if (total <= 0) return 0;
    final remaining = _nextAlertIn.inSeconds.clamp(0, total);
    return 1 - (remaining / total);
  }

  Future<void> bootstrap() async {
    _settings = await _repo.load();
    notifyListeners();
  }

  // --- Settings ----------------------------------------------------------
  Future<void> setInterval(int minutes) async {
    if (minutes < 1 || minutes > 240) return;
    _settings = _settings.copyWith(intervalMinutes: minutes);
    await _repo.save(_settings);
    if (_state == FocusState.running) {
      await _restartTimer();
    }
    notifyListeners();
  }

  Future<void> setDifficulty(int tier) async {
    if (tier < 1 || tier > 5) return;
    _settings = _settings.copyWith(difficultyTier: tier);
    await _repo.save(_settings);
    notifyListeners();
  }

  Future<void> setSound(bool v) async {
    _settings = _settings.copyWith(soundEnabled: v);
    await _repo.save(_settings);
    notifyListeners();
  }

  Future<void> setVibration(bool v) async {
    _settings = _settings.copyWith(vibrationEnabled: v);
    await _repo.save(_settings);
    notifyListeners();
  }

  // --- Focus mode lifecycle --------------------------------------------
  Future<bool> enableFocusMode() async {
    await _notif.init();
    _state = FocusState.running;
    _settings = _settings.copyWith(focusModeEnabled: true);
    await _repo.save(_settings);
    _sessionStartedAt = DateTime.now();
    _problemsSolved = 0;
    _totalFocusSeconds = 0;
    await _restartTimer();
    _startTicker();
    notifyListeners();
    return true;
  }

  Future<void> disableFocusMode() async {
    _state = FocusState.idle;
    _settings = _settings.copyWith(focusModeEnabled: false);
    await _repo.save(_settings);
    await _notif.cancelAll();
    _stopTicker();
    _nextAlertAt = null;
    _nextAlertIn = Duration.zero;
    notifyListeners();
  }

  /// Called by the OS / user tapping a notification. Switches into
  /// challenge mode; the UI is forced to show the full-screen challenge.
  Future<void> triggerChallenge() async {
    _currentProblem = _gen.generate(tier: _settings.difficultyTier);
    _challengeAttempts = 0;
    _state = FocusState.challengeActive;
    _stopTicker(); // pause countdown while user is solving
    await _notif.showFocusAlert(
      sound: _settings.soundEnabled,
      vibrate: _settings.vibrationEnabled,
    );
    notifyListeners();
  }

  /// Validate the user-submitted answer. Returns true if correct.
  /// Incorrect answer → regenerate a new problem and force another try.
  bool submitAnswer(int value) {
    if (_state != FocusState.challengeActive || _currentProblem == null) {
      return false;
    }
    _challengeAttempts++;
    if (value == _currentProblem!.answer) {
      _dismissChallenge();
      return true;
    }
    // Wrong answer: hand them a fresh problem (still in challengeActive).
    _currentProblem = _gen.generate(tier: _settings.difficultyTier);
    notifyListeners();
    return false;
  }

  void _dismissChallenge() {
    _state = FocusState.running;
    _currentProblem = null;
    _problemsSolved++;
    _notif.cancelFocusAlert();
    // Reschedule the next interval from the moment they solved it.
    _notif.scheduleNext(
      intervalMinutes: _settings.intervalMinutes,
      sound: _settings.soundEnabled,
      vibrate: _settings.vibrationEnabled,
    );
    _nextAlertAt = DateTime.now()
        .add(Duration(minutes: _settings.intervalMinutes));
    _nextAlertIn = Duration(minutes: _settings.intervalMinutes);
    _startTicker();
    notifyListeners();
  }

  Future<void> _restartTimer() async {
    await _notif.cancelAll();
    await _notif.scheduleNext(
      intervalMinutes: _settings.intervalMinutes,
      sound: _settings.soundEnabled,
      vibrate: _settings.vibrationEnabled,
    );
    _nextAlertAt = DateTime.now()
        .add(Duration(minutes: _settings.intervalMinutes));
    _nextAlertIn = Duration(minutes: _settings.intervalMinutes);
  }

  // --- Live countdown ticker --------------------------------------------
  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_state != FocusState.running || _nextAlertAt == null) return;
      final remaining = _nextAlertAt!.difference(DateTime.now());
      _nextAlertIn = remaining.isNegative ? Duration.zero : remaining;
      _totalFocusSeconds++;
      // If we've hit zero without the OS having fired the alert (e.g. exact
      // alarm permission was denied and we fell back to inexact scheduling),
      // proactively trigger the challenge so the user isn't left waiting.
      if (_nextAlertIn == Duration.zero) {
        _ticker?.cancel();
        triggerChallenge();
        return;
      }
      notifyListeners();
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
