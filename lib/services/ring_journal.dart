import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A ring start or stop observed by the native side, with the wall-clock
/// time it happened. Written by ZapClockApplication (Kotlin) from
/// AlarmRingingLiveData, so it exists even when the Flutter engine is dead.
///
/// Entries carry no alarm id on purpose: AlarmRingingLiveData is a bare
/// Boolean, and allowAlarmOverlap is false so at most one alarm rings at a
/// time. Settlement matches entries to obligations by time window.
class RingJournalEntry {
  const RingJournalEntry({required this.isStart, required this.at});

  final bool isStart;
  final DateTime at;

  @override
  String toString() => '${isStart ? 'start' : 'stop'}@$at';
}

abstract class RingJournal {
  Future<List<RingJournalEntry>> read();
}

/// Reads the journal through the `com.zapclock.zap_clock/alarm_native`
/// channel. Any failure yields an empty journal, which settlement treats as
/// "cannot prove the alarm rang", so a broken channel can never cause a
/// payment.
class PlatformRingJournal implements RingJournal {
  static const _channel = MethodChannel('com.zapclock.zap_clock/alarm_native');

  @override
  Future<List<RingJournalEntry>> read() async {
    try {
      final raw = await _channel.invokeListMethod<Map<Object?, Object?>>(
        'readRingJournal',
      );
      if (raw == null) return const [];
      final entries = <RingJournalEntry>[];
      for (final item in raw) {
        final event = item['event'];
        final at = item['at'];
        if (event is! String || at is! int) continue;
        entries.add(RingJournalEntry(
          isStart: event == 'start',
          at: DateTime.fromMillisecondsSinceEpoch(at),
        ));
      }
      return entries;
    } on MissingPluginException {
      return const [];
    } on PlatformException catch (e) {
      debugPrint('⚠️ readRingJournal failed: $e');
      return const [];
    }
  }
}
