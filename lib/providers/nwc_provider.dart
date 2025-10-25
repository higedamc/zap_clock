import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/nwc_service.dart';

/// NwcServiceのProvider
final nwcServiceProvider = Provider<NwcService>((ref) {
  return NwcService();
});

/// NWC接続状態のProvider
final nwcConnectionStatusProvider = StateProvider<AsyncValue<String?>>((ref) {
  return const AsyncValue.data(null);
});

