package id.focusmate.focus_mate

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "id.focusmate.alarm"
    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var vibrationEffect: VibrationEffect? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startLoopingAlarm" -> {
                        val rawName = call.argument<String>("rawResourceName") ?: "focus_alarm"
                        val vibrate = call.argument<Boolean>("vibrate") ?: true
                        startLoopingAlarm(rawName, vibrate)
                        result.success(null)
                    }
                    "stopLoopingAlarm" -> {
                        stopLoopingAlarm()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startLoopingAlarm(rawResourceName: String, vibrate: Boolean) {
        // Stop any existing playback first.
        stopLoopingAlarm()

        val resId = resources.getIdentifier(rawResourceName, "raw", packageName)
        if (resId == 0) {
            // Fallback: try the default alarm sound.
            try {
                mediaPlayer = MediaPlayer().apply {
                    setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .build()
                    )
                    val alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                    setDataSource(applicationContext, alarmUri)
                    isLooping = true
                    setVolume(1.0f, 1.0f)
                    prepare()
                    start()
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
            return
        }

        try {
            mediaPlayer = MediaPlayer.create(applicationContext, resId)?.apply {
                if (this == null) return@apply
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                isLooping = true
                setVolume(1.0f, 1.0f)
                start()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        if (vibrate) startVibrationLoop()
    }

    private fun stopLoopingAlarm() {
        try {
            mediaPlayer?.stop()
        } catch (_: Exception) { /* ignore */ }
        try {
            mediaPlayer?.release()
        } catch (_: Exception) { /* ignore */ }
        mediaPlayer = null
        stopVibrationLoop()
    }

    private fun startVibrationLoop() {
        try {
            val pattern = longArrayOf(0, 400, 200, 400, 200, 600)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val mgr = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                vibrator = mgr?.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                vibrator = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            }
            vibrator?.vibrate(pattern, 0) // 0 = repeat from start
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun stopVibrationLoop() {
        try {
            vibrator?.cancel()
        } catch (_: Exception) { /* ignore */ }
        vibrator = null
    }

    override fun onDestroy() {
        stopLoopingAlarm()
        super.onDestroy()
    }
}
