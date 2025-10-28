import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/nwc_service.dart';

/// NwcService Provider
final nwcServiceProvider = Provider<NwcService>((ref) {
  return NwcService();
});

/// NWC connection status Provider
final nwcConnectionStatusProvider = StateProvider<AsyncValue<String?>>((ref) {
  return const AsyncValue.data(null);
});

