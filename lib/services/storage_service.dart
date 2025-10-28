import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm.dart';
import '../models/donation_recipient.dart';

/// Local storage service
/// Persist alarm data using SharedPreferences
class StorageService {
  static const String _alarmsKey = 'alarms';
  static const String _nextIdKey = 'next_alarm_id';
  static const String _globalNwcConnectionKey = 'global_nwc_connection';
  static const String _hasCompletedOnboardingKey = 'has_completed_onboarding';
  static const String _donationRecipientKey = 'donation_recipient_address';
  static const String _customRecipientsKey = 'custom_donation_recipients';
  
  final SharedPreferences _prefs;
  
  StorageService(this._prefs);
  
  /// Get all alarms
  List<Alarm> getAlarms() {
    final alarmsJson = _prefs.getString(_alarmsKey);
    if (alarmsJson == null) {
      return [];
    }
    
    try {
      final List<dynamic> decoded = json.decode(alarmsJson);
      return decoded.map((json) => Alarm.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
  
  /// Save all alarms
  Future<bool> saveAlarms(List<Alarm> alarms) async {
    final alarmsJson = json.encode(
      alarms.map((alarm) => alarm.toJson()).toList(),
    );
    return await _prefs.setString(_alarmsKey, alarmsJson);
  }
  
  /// Add an alarm
  Future<bool> addAlarm(Alarm alarm) async {
    final alarms = getAlarms();
    alarms.add(alarm);
    return await saveAlarms(alarms);
  }
  
  /// Update an alarm
  Future<bool> updateAlarm(Alarm alarm) async {
    final alarms = getAlarms();
    final index = alarms.indexWhere((a) => a.id == alarm.id);
    
    if (index == -1) {
      return false;
    }
    
    alarms[index] = alarm;
    return await saveAlarms(alarms);
  }
  
  /// Delete an alarm
  Future<bool> deleteAlarm(int alarmId) async {
    final alarms = getAlarms();
    alarms.removeWhere((alarm) => alarm.id == alarmId);
    return await saveAlarms(alarms);
  }
  
  /// Get next alarm ID
  int getNextAlarmId() {
    final nextId = _prefs.getInt(_nextIdKey) ?? 1;
    return nextId;
  }
  
  /// Increment next alarm ID
  Future<int> incrementNextAlarmId() async {
    final nextId = getNextAlarmId();
    await _prefs.setInt(_nextIdKey, nextId + 1);
    return nextId;
  }
  
  /// Clear all data (for debugging)
  Future<bool> clearAll() async {
    await _prefs.remove(_alarmsKey);
    await _prefs.remove(_nextIdKey);
    return true;
  }
  
  // === Global NWC settings ===
  
  /// Get global NWC connection string
  String? getGlobalNwcConnection() {
    return _prefs.getString(_globalNwcConnectionKey);
  }
  
  /// Save global NWC connection string
  Future<bool> setGlobalNwcConnection(String connection) async {
    return await _prefs.setString(_globalNwcConnectionKey, connection);
  }
  
  // === Onboarding ===
  
  /// Get onboarding completion flag
  bool hasCompletedOnboarding() {
    return _prefs.getBool(_hasCompletedOnboardingKey) ?? false;
  }
  
  /// Set onboarding completion flag
  Future<bool> setOnboardingCompleted() async {
    return await _prefs.setBool(_hasCompletedOnboardingKey, true);
  }
  
  // === Donation recipient settings ===
  
  /// Get donation recipient Lightning Address
  /// Returns null if not set (uses default: Human Rights Foundation)
  String? getDonationRecipient() {
    return _prefs.getString(_donationRecipientKey);
  }
  
  /// Save donation recipient Lightning Address
  Future<bool> setDonationRecipient(String lightningAddress) async {
    return await _prefs.setString(_donationRecipientKey, lightningAddress);
  }
  
  // === User-defined donation recipients ===
  
  /// Get user-defined donation recipient list
  List<DonationRecipient> getCustomRecipients() {
    final recipientsJson = _prefs.getString(_customRecipientsKey);
    if (recipientsJson == null) {
      return [];
    }
    
    try {
      final List<dynamic> decoded = json.decode(recipientsJson);
      return decoded.map((json) => DonationRecipient.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
  
  /// Save user-defined donation recipient list
  Future<bool> saveCustomRecipients(List<DonationRecipient> recipients) async {
    final recipientsJson = json.encode(
      recipients.map((r) => r.toJson()).toList(),
    );
    return await _prefs.setString(_customRecipientsKey, recipientsJson);
  }
  
  /// Add user-defined donation recipient
  Future<bool> addCustomRecipient(DonationRecipient recipient) async {
    final recipients = getCustomRecipients();
    
    // Duplicate check (by Lightning Address)
    final isDuplicate = recipients.any(
      (r) => r.lightningAddress == recipient.lightningAddress,
    );
    
    if (isDuplicate) {
      return false; // Don't add if duplicate
    }
    
    recipients.add(recipient);
    return await saveCustomRecipients(recipients);
  }
  
  /// Delete user-defined donation recipient
  Future<bool> deleteCustomRecipient(String lightningAddress) async {
    final recipients = getCustomRecipients();
    recipients.removeWhere((r) => r.lightningAddress == lightningAddress);
    return await saveCustomRecipients(recipients);
  }
}
