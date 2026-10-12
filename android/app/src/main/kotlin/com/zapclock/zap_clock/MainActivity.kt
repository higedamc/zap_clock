package com.zapclock.zap_clock

import android.app.Activity
import android.app.KeyguardManager
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Vibrator
import android.os.VibratorManager
import android.provider.Settings
import com.gdelataillade.alarm.alarm.AlarmService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.zapclock.zap_clock/ringtone"
    private val PERMISSION_CHANNEL = "com.zapclock.zap_clock/permission"
    private val LOCK_SCREEN_CHANNEL = "com.zapclock.zap_clock/lockscreen"
    private val ALARM_NATIVE_CHANNEL = "com.zapclock.zap_clock/alarm_native"
    private val RINGTONE_PICKER_REQUEST = 100
    private var pendingResult: MethodChannel.Result? = null
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleAlarmClockIntent(intent)
        // Lock-screen bypass (showWhenLocked / turnScreenOn) is NOT set here on
        // purpose. The alarm plugin owns it: AlarmPlugin observes
        // AlarmRingingLiveData and sets the flags for the ringing window only.
        // LiveData re-delivers its last value to a new observer once the activity
        // is STARTED, so a cold start launched by the full-screen intent should
        // receive `true` before the first frame. Untested hypothesis: if a device
        // shows the first frame behind the keyguard on cold start, pre-setting
        // the flags here from AlarmRingingLiveData.instance.value would be the
        // fix. Add it only once that is observed on a device, not before.
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleAlarmClockIntent(intent)
    }
    
    /**
     * Handle AlarmClock intents (SET_ALARM, SHOW_ALARMS, etc.)
     * This makes the app recognizable as a clock app by the system
     */
    private fun handleAlarmClockIntent(intent: Intent?) {
        when (intent?.action) {
            "android.intent.action.SET_ALARM" -> {
                // Handle SET_ALARM intent
                // For now, just open the app's main screen
                // In the future, could pre-populate alarm settings from intent extras
                android.util.Log.d("ZapClock", "Received SET_ALARM intent")
            }
            "android.intent.action.SHOW_ALARMS" -> {
                // Handle SHOW_ALARMS intent
                // Just open the app's alarm list screen (default behavior)
                android.util.Log.d("ZapClock", "Received SHOW_ALARMS intent")
            }
            "android.intent.action.DISMISS_ALARM" -> {
                // Handle DISMISS_ALARM intent
                android.util.Log.d("ZapClock", "Received DISMISS_ALARM intent")
            }
            "android.intent.action.SNOOZE_ALARM" -> {
                // Handle SNOOZE_ALARM intent
                android.util.Log.d("ZapClock", "Received SNOOZE_ALARM intent")
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Ringtone picker channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickRingtone" -> {
                    pickRingtone(result)
                }
                "getRingtoneName" -> {
                    val uri = call.argument<String>("uri")
                    if (uri != null) {
                        result.success(getRingtoneName(uri))
                    } else {
                        result.error("INVALID_ARGUMENT", "URI is null", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Permission channel (Full Screen Intent permission for Android 10+)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "canUseFullScreenIntent" -> {
                    result.success(canUseFullScreenIntent())
                }
                "openFullScreenIntentSettings" -> {
                    openFullScreenIntentSettings()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Lock screen exit channel.
        // The lock-screen bypass itself (showWhenLocked / turnScreenOn) is owned by
        // the alarm plugin: AlarmPlugin observes AlarmRingingLiveData and sets the
        // flags for the ringing window only. This channel only decides where the
        // user lands after the alarm has been stopped.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCK_SCREEN_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "leaveRingScreen" -> {
                    result.success(leaveRingScreen())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Native stop backstop. Dart calls Alarm.stop(id) first; this runs after
        // it and does not depend on what the plugin believes is ringing.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ALARM_NATIVE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "stopRingingBackstop" -> {
                    result.success(stopRingingBackstop())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    /**
     * Stops the alarm plugin's foreground service and the vibrator directly.
     *
     * AlarmApiImpl.stopAlarm only stops AlarmService when the id is in
     * AlarmService.ringingAlarmIds, which is the list of ids with a *playing*
     * MediaPlayer (AlarmService.kt:175, AudioService.kt:36). If audio failed to
     * start, vibration still starts (AlarmService.kt:177) but no Dart stop call
     * can reach the service, so it keeps vibrating (issue #11). Stopping the
     * service runs AlarmService.onDestroy, which cancels the vibrator and
     * publishes AlarmRingingLiveData(false); cancelling the vibrator here as
     * well covers the case where the service is already gone but the effect is
     * still playing.
     *
     * Safe because allowAlarmOverlap is false: at most one alarm rings at a time,
     * so stopping the whole service never silences another alarm.
     *
     * Returns true when the service was alive and has been asked to stop.
     */
    private fun stopRingingBackstop(): Boolean {
        val serviceAlive = AlarmService.instance != null
        var stopped = false
        if (serviceAlive) {
            stopped = stopService(Intent(this, AlarmService::class.java))
        }
        cancelVibration()
        android.util.Log.d("ZapClock", "stopRingingBackstop: serviceAlive=$serviceAlive stopped=$stopped")
        return stopped
    }

    private fun cancelVibration() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val manager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                manager.cancel()
            } else {
                @Suppress("DEPRECATION")
                val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                vibrator.cancel()
            }
        } catch (e: Exception) {
            android.util.Log.w("ZapClock", "cancelVibration failed", e)
        }
    }

    /**
     * Called by the ring screen after the alarm has been stopped.
     * If the keyguard is still locked, move the task to the back so the user
     * lands on the lock screen instead of the alarm list (issue #12).
     * Returns true when the task was moved to the back.
     *
     * moveTaskToBack keeps the activity and the Flutter engine alive, unlike
     * finish() / SystemNavigator.pop(), so the next ring does not pay a cold start.
     */
    private fun leaveRingScreen(): Boolean {
        val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        val locked = keyguardManager.isKeyguardLocked
        android.util.Log.d("ZapClock", "leaveRingScreen: keyguardLocked=$locked")
        if (!locked) return false
        val moved = moveTaskToBack(true)
        android.util.Log.d("ZapClock", "leaveRingScreen: movedTaskToBack=$moved")
        return moved
    }

    private fun pickRingtone(result: MethodChannel.Result) {
        pendingResult = result
        
        val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
            putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, RingtoneManager.TYPE_ALARM)
            putExtra(RingtoneManager.EXTRA_RINGTONE_TITLE, "アラーム音を選択")
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
        }
        
        startActivityForResult(intent, RINGTONE_PICKER_REQUEST)
    }

    private fun getRingtoneName(uriString: String): String {
        return try {
            val uri = Uri.parse(uriString)
            val ringtone = RingtoneManager.getRingtone(this, uri)
            ringtone.getTitle(this)
        } catch (e: Exception) {
            "Unknown"
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == RINGTONE_PICKER_REQUEST) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val uri: Uri? = data.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
                
                if (uri != null) {
                    // URIをコピーしてローカルファイルとして保存
                    val localPath = copyRingtoneToLocal(uri)
                    if (localPath != null) {
                        pendingResult?.success(mapOf(
                            "uri" to uri.toString(),
                            "path" to localPath,
                            "name" to getRingtoneName(uri.toString())
                        ))
                    } else {
                        pendingResult?.error("COPY_FAILED", "Failed to copy ringtone", null)
                    }
                } else {
                    pendingResult?.success(null)
                }
            } else {
                pendingResult?.success(null)
            }
            pendingResult = null
        }
    }

    private fun copyRingtoneToLocal(uri: Uri): String? {
        return try {
            val inputStream = contentResolver.openInputStream(uri)
            if (inputStream != null) {
                val fileName = "alarm_sound_${System.currentTimeMillis()}.mp3"
                val outputFile = File(filesDir, fileName)
                
                FileOutputStream(outputFile).use { outputStream ->
                    inputStream.copyTo(outputStream)
                }
                inputStream.close()
                
                outputFile.absolutePath
            } else {
                null
            }
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
    
    /**
     * Check if app can use Full Screen Intent (for displaying alarm screen over lock screen)
     * Android 10+ requires explicit permission
     */
    private fun canUseFullScreenIntent(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.canUseFullScreenIntent()
        } else {
            // Android 9 and below don't require this permission
            true
        }
    }
    
    /**
     * Open system settings to grant Full Screen Intent permission
     * User needs to enable "Display over other apps" or similar permission
     */
    private fun openFullScreenIntentSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                // Try to open the exact setting for Full Screen Intent
                val intent = Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT).apply {
                    data = Uri.parse("package:$packageName")
                }
                startActivity(intent)
            } catch (e: Exception) {
                // Fallback: open general app settings
                try {
                    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.parse("package:$packageName")
                    }
                    startActivity(intent)
                } catch (e2: Exception) {
                    e2.printStackTrace()
                }
            }
        }
    }
}
