import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/alarm_countdown_service.dart';
import '../services/alarm_platform.dart';
import '../services/alarm_ring_controller.dart';
import '../services/zap_executor.dart';
import 'alarm_provider.dart';
import 'nwc_provider.dart';
import 'storage_provider.dart';

/// The single stop path. Bound once in [MyApp]; the ring screen only talks to
/// this controller, never to the alarm plugin directly.
final alarmRingControllerProvider = Provider<AlarmRingController>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final controller = AlarmRingController(
    platform: PluginAlarmPlatform(),
    storage: storage,
    scheduler: ref.watch(alarmServiceProvider),
    zap: ZapExecutor(storage: storage, payer: ref.watch(nwcServiceProvider)),
    countdown: AlarmCountdownService(),
    onAlarmsChanged: () => ref.read(alarmListProvider.notifier).loadAlarms(),
  );
  ref.onDispose(controller.dispose);
  return controller;
});
