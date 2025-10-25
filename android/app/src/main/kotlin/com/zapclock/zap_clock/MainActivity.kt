package com.zapclock.zap_clock

import android.app.Activity
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.zapclock.zap_clock/ringtone"
    private val RINGTONE_PICKER_REQUEST = 100
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
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
}
