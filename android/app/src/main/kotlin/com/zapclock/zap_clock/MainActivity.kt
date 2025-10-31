package com.zapclock.zap_clock

import android.app.Activity
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.zapclock.zap_clock/ringtone"
    private val PERMISSION_CHANNEL = "com.zapclock.zap_clock/permission"
    private val RINGTONE_PICKER_REQUEST = 100
    private var pendingResult: MethodChannel.Result? = null
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleAlarmClockIntent(intent)
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
