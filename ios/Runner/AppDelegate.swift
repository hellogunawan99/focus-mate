import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var alarmPlayer: AVAudioPlayer?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerAlarmChannel(messenger: engineBridge.binaryMessenger)
  }

  /// Register a method channel that drives a looping AVAudioPlayer
  /// for the escalation alarm on iOS. Mirrors the Android MainActivity
  /// implementation.
  private func registerAlarmChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "id.focusmate.alarm",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "startLoopingAlarm":
        let args = call.arguments as? [String: Any]
        let rawName = (args?["rawResourceName"] as? String) ?? "focus_alarm"
        self.startLoopingAlarm(rawName: rawName)
        result(nil)
      case "stopLoopingAlarm":
        self.stopLoopingAlarm()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func startLoopingAlarm(rawName: String) {
    stopLoopingAlarm()
    // For iOS, we use the bundled focus_alarm.m4a (registered in Info.plist
    // or referenced by full path). Fall back to system alarm sound if the
    // file isn't found.
    if let path = Bundle.main.path(forResource: "focus_alarm", ofType: "m4a") {
      let url = URL(fileURLWithPath: path)
      do {
        try AVAudioSession.sharedInstance().setCategory(
          .playback, mode: .default, options: [.duckOthers]
        )
        try AVAudioSession.sharedInstance().setActive(true)
        alarmPlayer = try AVAudioPlayer(contentsOf: url)
        alarmPlayer?.numberOfLoops = -1  // loop forever
        alarmPlayer?.volume = 1.0
        alarmPlayer?.prepareToPlay()
        alarmPlayer?.play()
      } catch {
        NSLog("FocusMate alarm failed to start: \(error.localizedDescription)")
      }
    } else {
      // Fallback: try system alarm
      if let url = URL(string: "system://alarm") {
        // system:// isn't a real URL scheme; this is just a stub. iOS
        // doesn't allow easy playback of system sounds programmatically
        // without AVAudioPlayer + bundled asset.
        NSLog("FocusMate alarm: focus_alarm.m4a not found in bundle")
      }
    }
  }

  private func stopLoopingAlarm() {
    alarmPlayer?.stop()
    alarmPlayer = nil
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }
}
