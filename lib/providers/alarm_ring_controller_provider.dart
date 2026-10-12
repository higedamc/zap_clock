import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/alarm_countdown_service.dart';
import '../services/alarm_platform.dart';
import '../services/alarm_ring_controller.dart';
import 'alarm_provider.dart';
import 'storage_provider.dart';
import 'zap_providers.dart';

/// The single stop path. Bound once in [MyApp]; the ring screen only talks to
/// this controller, never to the alarm plugin directly.
final alarmRingControllerProvider = Provider<AlarmRingController>((ref) {
  final controller = AlarmRingController(
    platform: PluginAlarmPlatform(),
    storage: ref.watch(storageServiceProvider),
    scheduler: ref.watch(alarmServiceProvider),
    zap: ref.watch(zapExecutorProvider),
    ledger: ref.watch(zapLedgerProvider),
    journal: ref.watch(ringJournalProvider),
    countdown: AlarmCountdownService(),
    onAlarmsChanged: () => ref.read(alarmListProvider.notifier).loadAlarms(),
  );
  ref.onDispose(controller.dispose);
  return controller;
});
