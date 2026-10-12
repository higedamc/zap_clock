import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_localizations.dart';
import '../models/alarm.dart' as app_models;
import '../providers/alarm_ring_controller_provider.dart';
import '../providers/storage_provider.dart';
import '../services/alarm_ring_controller.dart';
import '../services/lock_screen_service.dart';
import '../app_theme.dart';

/// Alarm ringing screen.
///
/// Pure view over [AlarmRingController]: it shows the countdown and forwards
/// Stop / Snooze. It never stops the alarm or moves money itself, and it
/// leaves when the controller reports that the ring ended, whatever ended it.
class AlarmRingScreen extends ConsumerStatefulWidget {
  final int alarmId;
  
  const AlarmRingScreen({super.key, required this.alarmId});

  @override
  ConsumerState<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends ConsumerState<AlarmRingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  app_models.Alarm? _alarm;
  bool _isProcessingPayment = false;
  String? _paymentError;
  Timer? _updateTimer;
  int _remainingSeconds = 0; // 初期値は0、アラーム読み込み時に設定
  StreamSubscription<RingEnded>? _endedSubscription;
  bool _leaving = false;
  
  AlarmRingController get _controller => ref.read(alarmRingControllerProvider);
  
  @override
  void initState() {
    super.initState();
    
    // Leave as soon as the controller reports the ring ended, whether it was
    // the Stop button, Snooze, the zap timeout or the notification's Stop.
    _endedSubscription = _controller.ringEnded.listen(_onRingEnded);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_controller.ringingIds.contains(widget.alarmId)) {
        debugPrint('🔕 alarm ${widget.alarmId}: already ended, leaving ring screen');
        _leave();
      }
    });
    
    // 全画面表示にする
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    
    // アニメーション設定
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _updateTimer?.cancel();
    _endedSubscription?.cancel();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }
  
  /// Mirrors the controller's countdown on screen once a second. The zap
  /// itself fires in the controller, independent of this widget.
  void _startCountdownDisplay() async {
    if (_alarm?.amountSats == null) {
      return;
    }
    
    // スヌーズモードの1回目のアラーム：カウントダウン不要
    final isSnoozeMode = _alarm?.enableSnooze ?? false;
    final isFirstAlarm = (_alarm?.snoozeCount ?? 0) == 0;
    if (isSnoozeMode && isFirstAlarm) {
      return;
    }
    
    final remaining = await _controller.remainingSeconds(widget.alarmId);
    if (!mounted) return;
    if (remaining != null) {
      setState(() {
        _remainingSeconds = remaining;
      });
    }
    
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final remaining = await _controller.remainingSeconds(widget.alarmId);
      if (!mounted) return;
      
      if (remaining == null || remaining <= 0) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          // The controller is paying now; disable the buttons until it reports.
          _isProcessingPayment = true;
        });
        return;
      }
      
      setState(() {
        _remainingSeconds = remaining;
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // スヌーズモードの1回目は黄色、それ以外は赤色
    final isSnoozeFirstAlarm = (_alarm?.enableSnooze ?? false) && (_alarm?.snoozeCount ?? 0) == 0;
    final backgroundColor = isSnoozeFirstAlarm ? Colors.amber.shade700 : AppTheme.alarmRingColor;
    
    return PopScope(
      canPop: false, // 戻るボタンを無効化
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Consumer(
          builder: (context, ref, child) {
            // アラーム情報を直接取得（高速化）
            if (_alarm == null) {
              final storage = ref.read(storageServiceProvider);
              final alarms = storage.getAlarms();
              try {
                _alarm = alarms.firstWhere((a) => a.id == widget.alarmId);
                
                // 初期表示用に設定されたタイムアウト時間をセット
                // （バックグラウンド同期前でも正しい時間を表示）
                if (_remainingSeconds == 0 && _alarm!.amountSats != null) {
                  _remainingSeconds = _alarm!.timeoutSeconds ?? 300;
                }
                
                // Start mirroring the countdown (once).
                if (_updateTimer == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _startCountdownDisplay();
                  });
                }
              } catch (e) {
                // アラームが見つからない場合は画面を閉じる
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    context.go('/');
                  }
                });
                return const Center(child: CircularProgressIndicator());
              }
            }
            
            return _buildRingingUI(context, ref);
          },
        ),
      ),
    );
  }
  
  Widget _buildRingingUI(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            
            // アラームアイコン（アニメーション付き）
            ScaleTransition(
              scale: _scaleAnimation,
              child: const Icon(
                Icons.alarm,
                size: 120,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 時刻表示
            Text(
              _alarm?.timeString ?? '00:00',
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // ラベル表示
            if (_alarm?.label.isNotEmpty ?? false)
              Text(
                _alarm!.label,
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            
            const SizedBox(height: 48),
            
            // Lightning送金情報
            _buildPaymentInfo(),
            
            const Spacer(),
            
            // カウントダウンタイマー表示（スヌーズ1回目は表示しない）
            if (_alarm?.amountSats != null && 
                !(_alarm!.enableSnooze && _alarm!.snoozeCount == 0))
              _buildCountdownTimer(),
            
            const SizedBox(height: 16),
            
            // 手動停止ボタン
            _buildStopButton(context, ref),
            
            const SizedBox(height: 16),
            
            // エラーメッセージ
            if (_paymentError != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _paymentError!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  /// 送金情報を表示
  Widget _buildPaymentInfo() {
    final hasPaymentConfig = _alarm?.amountSats != null;
    final l10n = AppLocalizations.of(context)!;
    final isSnoozeMode = _alarm?.enableSnooze ?? false;
    final isFirstAlarm = (_alarm?.snoozeCount ?? 0) == 0;
    
    if (!hasPaymentConfig) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.alarm_off,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noLightningSettings,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.pressToStop,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    // スヌーズモードのメッセージ
    if (isSnoozeMode) {
      if (isFirstAlarm) {
        // 1回目：スヌーズボタンを押す（時間制限なし）
        final timeout = _alarm!.timeoutSeconds!;
        final timeStr = timeout >= 60 ? '${(timeout / 60).round()}分' : '${timeout}秒';
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.snooze,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'スヌーズモード',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'スヌーズボタンを押してください',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '$timeStr後に2回目のアラーム',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      } else {
        // 2回目：ランダムタイムアウト内に停止
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.flash_on,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                '2回目のアラーム！',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '時間内に停止ボタンを押してください',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '失敗時: ${_alarm!.amountSats} sats',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
    }
    
    // 通常モード
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.flash_on,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.autoPaymentAlarm,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.monetization_on,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${_alarm!.amountSats} sats',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _formatTimeoutMessage(l10n, _alarm!.timeoutSeconds ?? 300),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  /// カウントダウンタイマーを表示
  Widget _buildCountdownTimer() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    
    // 残り時間に応じて色を変更
    Color timerColor = Colors.white;
    if (_remainingSeconds < 60) {
      timerColor = Colors.red.shade300;
    } else if (_remainingSeconds < 180) {
      timerColor = Colors.orange.shade300;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: timerColor,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            timeString,
            style: TextStyle(
              color: timerColor,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
  
  /// 手動停止ボタンまたはスヌーズボタン
  Widget _buildStopButton(BuildContext context, WidgetRef ref) {
    final hasPaymentConfig = _alarm?.amountSats != null;
    final l10n = AppLocalizations.of(context)!;
    final isSnoozeMode = _alarm?.enableSnooze ?? false;
    final isFirstAlarm = (_alarm?.snoozeCount ?? 0) == 0;
    
    // スヌーズモードの1回目：スヌーズボタンを表示
    if (isSnoozeMode && isFirstAlarm && hasPaymentConfig) {
      return SizedBox(
        width: double.infinity,
        height: 64,
        child: ElevatedButton(
          onPressed: _isProcessingPayment
              ? null
              : () => _controller.snooze(widget.alarmId),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            elevation: 4,
          ),
          child: _isProcessingPayment
              ? const CircularProgressIndicator()
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.snooze,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'スヌーズ',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      );
    }
    
    // 通常の停止ボタン
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: _isProcessingPayment
            ? null
            : () {
                _updateTimer?.cancel();
                // Stop without paying. Every stop path lives in the controller.
                _controller.stop(widget.alarmId);
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.alarmRingColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          elevation: 4,
        ),
        child: _isProcessingPayment
            ? const CircularProgressIndicator()
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.alarm_off,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasPaymentConfig ? l10n.stopNow : l10n.stopAlarm,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
  
  /// The controller finished tearing down a ring.
  void _onRingEnded(RingEnded event) {
    if (event.alarmId != widget.alarmId) return;
    final zap = event.zap;
    if (zap != null && zap.attempted && !zap.paid && mounted) {
      setState(() {
        _paymentError = 'Payment failed: ${zap.error}';
      });
    }
    _leave();
  }
  
  /// Single exit path. If the device is still locked the task is hidden so
  /// the user lands on the lock screen; the route is reset to '/' either way
  /// so the next foreground does not show a stale ring screen.
  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    _updateTimer?.cancel();
    
    await LockScreenService.leaveRingScreen();
    if (!mounted) {
      debugPrint('⚠️ ring screen unmounted before navigating away');
      return;
    }
    
    debugPrint('🚪 leaving ring screen');
    context.go('/');
  }
  
  /// タイムアウト時間を表示用メッセージに変換
  String _formatTimeoutMessage(AppLocalizations l10n, int seconds) {
    if (seconds < 60) {
      return l10n.timeoutMessageSeconds(seconds);
    } else {
      final minutes = seconds ~/ 60;
      return l10n.timeoutMessageMinutes(minutes);
    }
  }
}
