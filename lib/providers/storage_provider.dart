import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/storage_service.dart';
import '../models/donation_recipient.dart';

/// SharedPreferencesのProvider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden');
});

/// StorageServiceのProvider
final storageServiceProvider = Provider<StorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StorageService(prefs);
});

/// 現在の寄付先アドレスのProvider
final donationRecipientProvider = StateProvider<String>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return storage.getDonationRecipient() ?? DonationRecipients.defaultRecipientSync.lightningAddress;
});

