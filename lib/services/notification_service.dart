import 'dart:io' show Platform;
import 'dart:ui' show Color;

import 'package:flutter/services.dart' show MissingPluginException, MethodChannel;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Channel / IDs used across the app.
class NotificationChannels {
  static const String focusAlert = 'focus_alert_channel';
  static const String focusService = 'focus_service_channel';
  static const int focusAlertId = 1001;
  static const int focusServiceId = 1002;
}

/// Notification + exact-alarm permission requests.
class NotificationPermissionService {
  Future<bool> ensurePermissions() async {
    // Android 13+ requires runtime POST_NOTIFICATIONS.
    final notif = await Permission.notification.request();

    if (Platform.isAndroid) {
      // Android 12+ requires SCHEDULE_EXACT_ALARM (granted via system
      // settings, not runtime). We open the settings page if denied.
      final exact = await Permission.scheduleExactAlarm.request();
      if (!exact.isGranted) {
        // Don't fail; degraded mode still uses inexact alarms.
      }
      // Battery optimization opt-out helps background reliability.
      await Permission.ignoreBatteryOptimizations.request();
    }
    return notif.isGranted;
  }
}

/// Wraps flutter_local_notifications to show focus-alert and schedule the
/// next interval.
class FocusNotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  void Function()? _onTap;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    // Set the local timezone to the device's actual timezone. Without this,
    // tz.local defaults to UTC and zonedSchedule computes the wrong fire time.
    try {
      // flutter_native_timezone gives the IANA name (e.g. "Asia/Makassar").
      // We try a few strategies in order of preference.
      String? tzName;
      try {
        tzName = await _readNativeTimezone();
      } catch (_) {}
      tzName ??= _mapTzName(DateTime.now().timeZoneName);
      try {
        if (tzName != null) tz.setLocalLocation(tz.getLocation(tzName));
      } catch (_) {
        // Fallback: try common Asia timezones.
        for (final fallback in <String>[
          'Asia/Jakarta',
          'Asia/Makassar',
          'Asia/Singapore',
          'Asia/Shanghai',
          'UTC',
        ]) {
          try {
            tz.setLocalLocation(tz.getLocation(fallback));
            break;
          } catch (_) {
            continue;
          }
        }
      }
    } catch (_) {
      // Last-ditch: do nothing, tz.local will be UTC.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) {
        if (_onTap != null) _onTap!();
      },
    );

    // Capture launch payload (when app was killed and reopened by tap).
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _pendingLaunchPayload = launch?.notificationResponse?.payload;
    }

    // Create the high-importance alert channel for Android 8+.
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          NotificationChannels.focusAlert,
          'Focus Alerts',
          description: 'Anti-drowsiness alerts requiring a math challenge',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );
      // Request POST_NOTIFICATIONS runtime permission (Android 13+).
      await androidImpl.requestNotificationsPermission();
      // Request exact alarm permission (Android 12+). This opens a system
      // dialog the first time. If denied, we fall back to inexact scheduling.
      await androidImpl.requestExactAlarmsPermission();
    }
    _initialized = true;
  }

  /// Map a short timezone name (e.g. "WITA", "PST", "GMT+8") to a tz database
  /// name. Falls back to UTC if unknown.
  String? _mapTzName(String name) {
    const map = {
      'WIB': 'Asia/Jakarta',
      'WITA': 'Asia/Makassar',
      'WIT': 'Asia/Jayapura',
      'PST': 'America/Los_Angeles',
      'PDT': 'America/Los_Angeles',
      'EST': 'America/New_York',
      'EDT': 'America/New_York',
      'CST': 'America/Chicago',
      'CDT': 'America/Chicago',
      'MST': 'America/Denver',
      'MDT': 'America/Denver',
      'BST': 'Europe/London',
      'GMT': 'Europe/London',
      'CET': 'Europe/Paris',
      'CEST': 'Europe/Paris',
      'JST': 'Asia/Tokyo',
      'KST': 'Asia/Seoul',
      'IST': 'Asia/Kolkata',
      'SGT': 'Asia/Singapore',
      'HKT': 'Asia/Hong_Kong',
    };
    return map[name];
  }

  /// Try to read the device's IANA timezone name. We avoid pulling in
  /// flutter_native_timezone as a hard dependency by catching any error.
  Future<String?> _readNativeTimezone() async {
    // On most Android devices DateTime.now().timeZoneName is the abbreviation
    // (WITA, PST). The IANA name can be read via a platform channel which we
    // don't have here. We rely on the abbreviation → IANA map.
    return null;
  }

  /// Show the high-priority focus alert immediately. This is the notification
  /// the user must solve to dismiss.
  Future<void> showFocusAlert({
    required bool sound,
    required bool vibrate,
  }) async {
    if (!_initialized) await init();
    final androidDetails = AndroidNotificationDetails(
      NotificationChannels.focusAlert,
      'Focus Alerts',
      channelDescription:
          'Anti-drowsiness alerts requiring a math challenge',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      playSound: sound,
      enableVibration: vibrate,
      ticker: 'Focus Mate: solve the math problem',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );
    await _plugin.show(
      NotificationChannels.focusAlertId,
      'Wake up 👀',
      'Solve the math problem to keep going.',
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: 'open_challenge',
    );
  }

  /// Cancel the currently-visible focus alert.
  Future<void> cancelFocusAlert() => _plugin.cancel(NotificationChannels.focusAlertId);

  /// Schedule a one-shot "next alert" for [intervalMinutes] from now.
  /// Uses the OS scheduler (AlarmManager on Android, UNCalendar on iOS) so
  /// the alert fires even if the app is killed.
  Future<void> scheduleNext({
    required int intervalMinutes,
    required bool sound,
    required bool vibrate,
  }) async {
    if (!_initialized) await init();
    final when = tz.TZDateTime.now(tz.local)
        .add(Duration(minutes: intervalMinutes));

    final androidDetails = AndroidNotificationDetails(
      NotificationChannels.focusAlert,
      'Focus Alerts',
      channelDescription: 'Scheduled anti-drowsiness alerts',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      playSound: sound,
      enableVibration: vibrate,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    try {
      await _plugin.zonedSchedule(
        NotificationChannels.focusAlertId,
        'Wake up 👀',
        'Solve the math problem to keep going.',
        when,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'open_challenge',
      );
    } catch (_) {
      // Fallback to inexact if exact-alarm permission missing.
      await _plugin.zonedSchedule(
        NotificationChannels.focusAlertId,
        'Wake up 👀',
        'Solve the math problem to keep going.',
        when,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'open_challenge',
      );
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  /// Register a callback for taps that happen while the app is alive.
  void setOnTapCallback(void Function() cb) {
    _onTap = cb;
  }

  /// Returns the payload of the notification that launched the app, if any.
  /// Should be called once at startup and the result consumed.
  String? _pendingLaunchPayload;
  Future<String?> getLaunchNotificationPayload() async => _pendingLaunchPayload;

  // --- Escalation (continuous alarm when user ignores challenge) -------
  //
  // flutter_local_notifications doesn't natively support a looping alarm
  // sound, so we use the platform channel to drive a native MediaPlayer
  // on Android. The native side is in MainActivity.kt.
  static final _alarmChannel = MethodChannel('id.focusmate.alarm');

  /// Start a continuous looping alarm. Updates the notification to a
  /// high-urgency alarm with fullScreenIntent so it pops up over the
  /// lock screen even from a backgrounded app.
  Future<void> escalateChallenge({
    required bool sound,
    required bool vibrate,
  }) async {
    if (!_initialized) await init();
    // 1. Re-show the notification with maximum urgency.
    final androidDetails = AndroidNotificationDetails(
      NotificationChannels.focusAlert,
      'Focus Alerts',
      channelDescription: 'Critical anti-drowsiness alarm',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      playSound: sound,
      enableVibration: vibrate,
      ticker: 'WAKE UP — solve the math problem',
      color: const Color(0xFFFF6F6F),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );
    await _plugin.show(
      NotificationChannels.focusAlertId,
      '🚨 WAKE UP — solve the math problem',
      'Touch the screen to silence the alarm.',
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: 'open_challenge',
    );
    // 2. Start the native looping alarm (Android only; iOS handles via
    // the critical notification's built-in sound loop).
    if (sound) {
      try {
        await _alarmChannel.invokeMethod('startLoopingAlarm', {
          'rawResourceName': 'focus_alarm',
          'vibrate': vibrate,
        });
      } on MissingPluginException {
        // Running on a platform without the channel (e.g. tests, iOS).
      } catch (_) {
        // Fallback: the notification sound will still play, just not loop.
      }
    }
  }

  /// Stop the looping alarm and revert the notification to standard state.
  Future<void> stopEscalation() async {
    try {
      await _alarmChannel.invokeMethod('stopLoopingAlarm');
    } on MissingPluginException {
      // ignore
    } catch (_) {
      // ignore
    }
  }
}
