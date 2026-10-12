import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ring_countdown.dart';

/// Countdown from ring start to auto zap, kept in memory and mirrored to
/// SharedPreferences so the ring screen can show the remaining time after a
/// rebuild. The zap itself is executed by [AlarmRingController] through
/// [onTimeout]; this class never touches the wallet.
class AlarmCountdownService implements RingCountdown {
  static final AlarmCountdownService _instance = AlarmCountdownService._internal();
  factory AlarmCountdownService() => _instance;
  AlarmCountdownService._internal();

  final Map<int, Timer> _countdownTimers = {};
  final Map<int, DateTime> _startTimes = {};
  final Map<int, int> _timeoutSeconds = {};
  
  static const String _keyPrefix = 'alarm_countdown_';
  
  @override
  Future<void> start({
    required int alarmId,
    required int timeoutSeconds,
    required Future<void> Function() onTimeout,
  }) async {
    stop(alarmId);
    
    final startTime = DateTime.now();
    _startTimes[alarmId] = startTime;
    _timeoutSeconds[alarmId] = timeoutSeconds;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_keyPrefix${alarmId}_start', startTime.millisecondsSinceEpoch);
    await prefs.setInt('$_keyPrefix${alarmId}_timeout', timeoutSeconds);
    
    debugPrint('⏱️ alarm $alarmId: countdown started ($timeoutSeconds s)');
    
    _countdownTimers[alarmId] = Timer(Duration(seconds: timeoutSeconds), () async {
      debugPrint('⏰ alarm $alarmId: countdown expired');
      _countdownTimers.remove(alarmId);
      await onTimeout();
    });
  }
  
  @override
  void stop(int alarmId) async {
    _countdownTimers[alarmId]?.cancel();
    _countdownTimers.remove(alarmId);
    _startTimes.remove(alarmId);
    _timeoutSeconds.remove(alarmId);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyPrefix${alarmId}_start');
    await prefs.remove('$_keyPrefix${alarmId}_timeout');
    
    debugPrint('⏹️ alarm $alarmId: countdown stopped');
  }
  
  @override
  Future<int?> remainingSeconds(int alarmId) async {
    DateTime? startTime = _startTimes[alarmId];
    int? timeoutSeconds = _timeoutSeconds[alarmId];
    
    if (startTime == null || timeoutSeconds == null) {
      final prefs = await SharedPreferences.getInstance();
      final startMillis = prefs.getInt('$_keyPrefix${alarmId}_start');
      final storedTimeout = prefs.getInt('$_keyPrefix${alarmId}_timeout');
      
      if (startMillis == null || storedTimeout == null) {
        return null;
      }
      
      startTime = DateTime.fromMillisecondsSinceEpoch(startMillis);
      timeoutSeconds = storedTimeout;
      _startTimes[alarmId] = startTime;
      _timeoutSeconds[alarmId] = timeoutSeconds;
    }
    
    final elapsed = DateTime.now().difference(startTime).inSeconds;
    final remaining = timeoutSeconds - elapsed;
    return remaining > 0 ? remaining : 0;
  }
}
