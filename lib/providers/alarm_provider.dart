import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm.dart';
import '../services/storage_service.dart';
import '../services/alarm_service.dart';

/// SharedPreferencesのProvider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferencesProvider must be overridden');
});

/// StorageServiceのProvider
final storageServiceProvider = Provider<StorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StorageService(prefs);
});

/// AlarmServiceのProvider
final alarmServiceProvider = Provider<AlarmService>((ref) {
  return AlarmService();
});

/// アラームリストのStateNotifierProvider
final alarmListProvider = StateNotifierProvider<AlarmListNotifier, AsyncValue<List<Alarm>>>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  final alarmService = ref.watch(alarmServiceProvider);
  return AlarmListNotifier(storageService, alarmService);
});

/// アラームリスト管理Notifier
class AlarmListNotifier extends StateNotifier<AsyncValue<List<Alarm>>> {
  final StorageService _storageService;
  final AlarmService _alarmService;
  
  AlarmListNotifier(this._storageService, this._alarmService)
      : super(const AsyncValue.loading()) {
    loadAlarms();
  }
  
  /// アラーム一覧を読み込み
  Future<void> loadAlarms() async {
    state = const AsyncValue.loading();
    try {
      final alarms = _storageService.getAlarms();
      // 時刻順にソート
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
  
  /// アラームを追加
  Future<void> addAlarm(Alarm alarm) async {
    try {
      await _storageService.addAlarm(alarm);
      await _alarmService.scheduleAlarm(alarm);
      await loadAlarms();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  /// アラームを更新
  Future<void> updateAlarm(Alarm alarm) async {
    try {
      await _storageService.updateAlarm(alarm);
      await _alarmService.scheduleAlarm(alarm);
      await loadAlarms();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  /// アラームを削除
  Future<void> deleteAlarm(int alarmId) async {
    try {
      await _storageService.deleteAlarm(alarmId);
      await _alarmService.cancelAlarm(alarmId);
      await loadAlarms();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  /// アラームの有効/無効を切り替え
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
  
  /// 次のアラームIDを取得
  Future<int> getNextAlarmId() async {
    return await _storageService.incrementNextAlarmId();
  }
}

