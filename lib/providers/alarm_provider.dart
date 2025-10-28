import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alarm.dart';
import '../services/storage_service.dart';
import '../services/alarm_service.dart';
import 'storage_provider.dart';

/// AlarmService Provider
final alarmServiceProvider = Provider<AlarmService>((ref) {
  return AlarmService();
});

/// Alarm list StateNotifierProvider
final alarmListProvider = StateNotifierProvider<AlarmListNotifier, AsyncValue<List<Alarm>>>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  final alarmService = ref.watch(alarmServiceProvider);
  return AlarmListNotifier(storageService, alarmService);
});

/// Alarm list management Notifier
class AlarmListNotifier extends StateNotifier<AsyncValue<List<Alarm>>> {
  final StorageService _storageService;
  final AlarmService _alarmService;
  
  AlarmListNotifier(this._storageService, this._alarmService)
      : super(const AsyncValue.loading()) {
    loadAlarms();
  }
  
  /// Load alarm list
  Future<void> loadAlarms() async {
    state = const AsyncValue.loading();
    try {
      final alarms = _storageService.getAlarms();
      // Sort by time
      alarms.sort((a, b) {
        if (a.hour != b.hour) {
          return a.hour.compareTo(b.hour);
        }
        return a.minute.compareTo(b.minute);
      });
      state = AsyncValue.data(alarms);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  /// Add an alarm
  Future<void> addAlarm(Alarm alarm) async {
    try {
      await _storageService.addAlarm(alarm);
      await _alarmService.scheduleAlarm(alarm);
      await loadAlarms();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  /// Update an alarm
  Future<void> updateAlarm(Alarm alarm) async {
    try {
      await _storageService.updateAlarm(alarm);
      await _alarmService.scheduleAlarm(alarm);
      await loadAlarms();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  /// Delete an alarm
  Future<void> deleteAlarm(int alarmId) async {
    try {
      await _storageService.deleteAlarm(alarmId);
      await _alarmService.cancelAlarm(alarmId);
      await loadAlarms();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  /// Toggle alarm enabled/disabled
  Future<void> toggleAlarm(int alarmId) async {
    final currentState = state;
    if (currentState is! AsyncData<List<Alarm>>) {
      return;
    }
    
    try {
      final alarms = currentState.value;
      final alarm = alarms.firstWhere((a) => a.id == alarmId);
      final updatedAlarm = alarm.copyWith(isEnabled: !alarm.isEnabled);
      await updateAlarm(updatedAlarm);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  /// Get next alarm ID
  Future<int> getNextAlarmId() async {
    return await _storageService.incrementNextAlarmId();
  }
}

