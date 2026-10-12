import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ring_journal.dart';
import '../services/zap_executor.dart';
import '../services/zap_ledger.dart';
import 'nwc_provider.dart';
import 'storage_provider.dart';

/// Persistent record of the zaps alarms may owe.
final zapLedgerProvider = Provider<ZapLedger>((ref) {
  return ZapLedger(ref.watch(sharedPreferencesProvider));
});

/// The one implementation that sends a payment.
final zapExecutorProvider = Provider<ZapExecutor>((ref) {
  return ZapExecutor(
    storage: ref.watch(storageServiceProvider),
    payer: ref.watch(nwcServiceProvider),
  );
});

/// Native start/stop journal used to settle rings the engine did not see.
final ringJournalProvider = Provider<RingJournal>((ref) {
  return PlatformRingJournal();
});
