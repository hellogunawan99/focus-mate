import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'providers/focus_provider.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
  );
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: BrandColors.bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  final repo = SettingsRepository();
  final notif = FocusNotificationService();
  await notif.init();

  final permService = NotificationPermissionService();
  await permService.ensurePermissions();

  final focus = FocusProvider(repo: repo, notif: notif);
  await focus.bootstrap();

  // If the OS launched us from a notification tap while the app was
  // terminated, surface the challenge immediately on first frame.
  final launchPayload = await notif.getLaunchNotificationPayload();
  if (launchPayload == 'open_challenge') {
    await focus.triggerChallenge();
  }

  runApp(FocusMateApp(focus: focus, notif: notif));
}

class FocusMateApp extends StatefulWidget {
  final FocusProvider focus;
  final FocusNotificationService notif;
  const FocusMateApp({super.key, required this.focus, required this.notif});

  @override
  State<FocusMateApp> createState() => _FocusMateAppState();
}

class _FocusMateAppState extends State<FocusMateApp> {
  @override
  void initState() {
    super.initState();
    // When the user taps the alert while the app is alive (foreground or
    // background-resumed), we route into the challenge.
    widget.notif.setOnTapCallback(_onNotificationTap);
  }

  void _onNotificationTap() {
    widget.focus.triggerChallenge();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<FocusProvider>.value(
      value: widget.focus,
      child: MaterialApp(
        title: 'Focus Mate',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        // Force dark theme for now — this app is meant for late-night
        // focus sessions and the design is dark-first.
        themeMode: ThemeMode.dark,
        // Global fix for Android rendering "yellow double underline" on
        // every Text widget — happens when DefaultTextStyle is missing
        // or when text sits inside a Stack outside a Material boundary.
        // Explicitly set decoration: none on the default text style.
        builder: (context, child) {
          return DefaultTextStyle(
            style: const TextStyle(decoration: TextDecoration.none),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const HomeScreen(),
      ),
    );
  }
}
