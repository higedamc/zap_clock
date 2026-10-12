package com.zapclock.zap_clock

import android.app.Application
import android.content.Context
import android.util.Log
import com.gdelataillade.alarm.services.AlarmRingingLiveData
import org.json.JSONArray
import org.json.JSONObject

/**
 * Records when an alarm starts and stops ringing, with the wall-clock time,
 * in a small journal that survives the Flutter engine.
 *
 * The alarm plugin's foreground service runs in this process even when no
 * activity and no Dart isolate exist (alarm fired while the app was killed,
 * user pressed Stop on the notification). AlarmRingingLiveData is the one
 * signal the service publishes in that state, so this class observes it for
 * the lifetime of the process and appends start/stop entries. The Dart side
 * reads them through MainActivity ("readRingJournal") to settle zap
 * obligations whose deadline passed while it was not running:
 * stopped after the deadline means pay, stopped before means do not pay,
 * no record means do not pay.
 *
 * Entries carry no alarm id on purpose. AlarmRingingLiveData is a bare
 * Boolean, and the plugin populates ringingAlarmIds *after* publishing
 * `true` (AlarmService.kt:126 vs :175), so an id read here would be stale.
 * With allowAlarmOverlap=false at most one alarm rings at a time, and the
 * Dart side matches entries to obligations by time window.
 */
class ZapClockApplication : Application() {
    companion object {
        private const val TAG = "ZapClock"
        private const val PREFS = "zapclock_ring_journal"
        private const val KEY_ENTRIES = "entries"
        private const val MAX_ENTRIES = 100

        /** Oldest first. Each map has "event" ("start" | "stop") and "at" (epoch millis). */
        fun readJournal(context: Context): List<Map<String, Any>> {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val raw = prefs.getString(KEY_ENTRIES, null) ?: return emptyList()
            return try {
                val array = JSONArray(raw)
                (0 until array.length()).map { i ->
                    val obj = array.getJSONObject(i)
                    mapOf("event" to obj.getString("event"), "at" to obj.getLong("at"))
                }
            } catch (e: Exception) {
                Log.w(TAG, "ring journal unreadable, treating as empty", e)
                emptyList()
            }
        }
    }

    private var lastRinging: Boolean? = null

    override fun onCreate() {
        super.onCreate()
        // LiveData dispatches every postValue, and the plugin publishes `false`
        // twice per stop (stopAlarm and onDestroy), so only transitions are
        // journaled.
        AlarmRingingLiveData.instance.observeForever { ringing ->
            if (ringing == lastRinging) return@observeForever
            lastRinging = ringing
            append(if (ringing) "start" else "stop", System.currentTimeMillis())
        }
    }

    @Synchronized
    private fun append(event: String, at: Long) {
        val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val array = try {
            JSONArray(prefs.getString(KEY_ENTRIES, null) ?: "[]")
        } catch (e: Exception) {
            JSONArray()
        }
        array.put(JSONObject().put("event", event).put("at", at))
        val trimmed = if (array.length() > MAX_ENTRIES) {
            JSONArray().also { out ->
                for (i in array.length() - MAX_ENTRIES until array.length()) out.put(array.get(i))
            }
        } else {
            array
        }
        // commit(), not apply(): the process may be killed right after a stop.
        prefs.edit().putString(KEY_ENTRIES, trimmed.toString()).commit()
        Log.d(TAG, "ringJournal: $event at=$at entries=${trimmed.length()}")
    }
}
