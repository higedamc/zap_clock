import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:alarm/alarm.dart';
import '../l10n/app_localizations.dart';
import '../models/alarm.dart' as app_models;
import '../providers/alarm_provider.dart';
import '../providers/nwc_provider.dart';
import '../providers/storage_provider.dart';
import '../services/alarm_countdown_service.dart';
import '../services/lock_screen_service.dart';
import '../app_theme.dart';

/// Alarm ringing screen
/// Lightning payment functionality planned for future
/// Currently can stop alarm with temporary button
class AlarmRingScreen extends StatefulWidget {
  final int alarmId;
  
  const AlarmRingScreen({super.key, required this.alarmId});

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  app_models.Alarm? _alarm;
  bool _isProcessingPayment = false;
  String? _paymentError;
  Timer? _updateTimer;
  int _remainingSeconds = 0; // 初期値は0、アラーム読み込み時に設定
  final _countdownService = AlarmCountdownService();
  int? _randomSnoozeTimeout; // 2回目のアラームのランダム秒数
  
  @override
  void initState() {
    super.initState();
    
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
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }
  
  /// バックグラウンドカウントダウンと同期
  void _syncWithBackgroundCountdown(WidgetRef ref) async {
    // 送金設定がない場合はカウントダウン不要
    if (_alarm?.amountSats == null) {
      debugPrint('⏱️ 送金設定なし、カウントダウン同期をスキップ');
      return;
    }
    
    // スヌーズモードの1回目のアラーム：カウントダウン不要
    final isSnoozeMode = _alarm?.enableSnooze ?? false;
    final isFirstAlarm = (_alarm?.snoozeCount ?? 0) == 0;
    
    if (isSnoozeMode && isFirstAlarm) {
      debugPrint('😴 スヌーズモード1回目: カウントダウンなし（スヌーズボタンを待つだけ）');
      return;
    }
    
    // スヌーズモードの2回目のアラームの場合、ランダムなタイムアウトを生成
    if (_alarm!.enableSnooze && _alarm!.snoozeCount == 1) {
      final range = _alarm!.snoozeTimeoutRange;
      final random = DateTime.now().millisecond % (range.$2 - range.$1 + 1);
      _randomSnoozeTimeout = range.$1 + random;
      debugPrint('🎲 スヌーズ2回目: ランダムタイムアウト = ${_randomSnoozeTimeout}秒');
      
      if (!mounted) return;
      setState(() {
        _remainingSeconds = _randomSnoozeTimeout!;
      });
      
      // 簡易的なカウントダウン（バックグラウンドサービス使わない）
      _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        
        setState(() {
          _remainingSeconds--;
        });
        
        if (_remainingSeconds <= 0) {
          timer.cancel();
          debugPrint('⏰ スヌーズタイムアウト！自動Zap実行');
          _executeAutoZap(ref);
        }
      });
      
      return;
    }
    
    debugPrint('⏱️ バックグラウンドカウントダウンとの同期を開始...');
    
    // バックグラウンドで既に開始されているカウントダウンから残り時間を取得
    final remainingSeconds = await _countdownService.getRemainingSeconds(widget.alarmId);
    
    if (remainingSeconds == null) {
      debugPrint('⚠️ バックグラウンドカウントダウンが見つかりません（まだ開始されていない可能性）');
      // フォールバック: 設定されたタイムアウト時間を使用
      if (!mounted) return;
      setState(() {
        _remainingSeconds = _alarm!.timeoutSeconds ?? 300;
      });
      debugPrint('⏱️ フォールバック: タイムアウト設定値を使用 (${_remainingSeconds}秒)');
    } else {
      if (!mounted) return;
      setState(() {
        _remainingSeconds = remainingSeconds;
      });
      debugPrint('✅ バックグラウンドカウントダウンと同期完了: 残り${_remainingSeconds}秒');
    }
    
    // 1秒ごとに残り時間を更新
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      // バックグラウンドの残り時間を取得
      final remaining = await _countdownService.getRemainingSeconds(widget.alarmId);
      
      if (remaining == null || remaining <= 0) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _remainingSeconds = 0;
          });
        }
        debugPrint('⏰ カウントダウン完了または停止');
        return;
      }
      
      if (mounted) {
        setState(() {
          _remainingSeconds = remaining;
        });
      }
    });
    
    debugPrint('⏱️ 定期更新タイマーを開始しました');
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
                
                // バックグラウンドカウントダウンと同期（初回のみ）
                if (_updateTimer == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _syncWithBackgroundCountdown(ref);
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
              : () => _handleSnooze(context, ref),
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
                // バックグラウンドカウントダウンをキャンセル
                _countdownService.stopCountdown(widget.alarmId);
                _updateTimer?.cancel();
                
                // アラームを停止（送金なし）
                _stopAlarmAndCloseScreen(context, ref);
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
  
  /// スヌーズボタンを押した時の処理
  Future<void> _handleSnooze(BuildContext context, WidgetRef ref) async {
    debugPrint('😴 スヌーズボタンが押されました');
    
    // バックグラウンドカウントダウンを停止（1回目は基本的に動いてないが念のため）
    _countdownService.stopCountdown(widget.alarmId);
    _updateTimer?.cancel();
    
    // アラームを停止
    await Alarm.stop(widget.alarmId);
    
    // スヌーズカウントをインクリメント
    final updatedAlarm = _alarm!.copyWith(snoozeCount: 1);
    await ref.read(alarmListProvider.notifier).updateAlarm(updatedAlarm);
    
    // 指定時間後に2回目のアラームをスケジュール
    final alarmService = ref.read(alarmServiceProvider);
    await alarmService.scheduleAlarm(updatedAlarm);
    
    final timeout = _alarm!.timeoutSeconds!;
    final timeStr = timeout >= 60 ? '${(timeout / 60).round()}分' : '${timeout}秒';
    debugPrint('✅ スヌーズ完了、${timeStr}後に2回目のアラームをスケジュールしました');
    
    // Leave the ring screen. If the device is still locked the task is hidden
    // so the user lands on the lock screen; the route is reset to '/' either
    // way so the next foreground does not show a stale ring screen.
    await LockScreenService.leaveRingScreen();
    if (context.mounted) {
      context.go('/');
    }
  }
  
  /// 自動Zap実行
  Future<void> _executeAutoZap(WidgetRef ref) async {
    if (_isProcessingPayment) return;
    
    setState(() {
      _isProcessingPayment = true;
      _paymentError = null;
    });
    
    try {
      final storage = ref.read(storageServiceProvider);
      final nwcConnection = storage.getGlobalNwcConnection();
      
      if (nwcConnection == null || nwcConnection.isEmpty) {
        debugPrint('⚠️ NWC接続が設定されていません');
        await _stopAlarmAndCloseScreen(context, ref);
        return;
      }
      
      final recipientAddress = _alarm!.donationRecipient 
          ?? storage.getDonationRecipient() 
          ?? 'hi@getalby.com'; // fallback
      
      debugPrint('💳 自動Zap実行: ${_alarm!.amountSats} sats → $recipientAddress');
      
      final nwcService = ref.read(nwcServiceProvider);
      await nwcService.payWithNwc(
        connectionString: nwcConnection,
        lightningAddress: recipientAddress,
        amountSats: _alarm!.amountSats!,
        comment: 'donation from ZapClock',
      );
      
      debugPrint('✅ 自動Zap成功');
      
      await _stopAlarmAndCloseScreen(context, ref);
      
    } catch (e) {
      debugPrint('❌ 自動Zap失敗: $e');
      
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
          _paymentError = 'Payment failed: $e';
        });
      }
      
      // エラーでもアラームは停止
      await _stopAlarmAndCloseScreen(context, ref);
    }
  }
  
  /// アラームを実際に停止して画面を閉じる
  Future<void> _stopAlarmAndCloseScreen(
    BuildContext context,
    WidgetRef ref,
  ) async {
    debugPrint('🛑 _stopAlarmAndCloseScreen開始');
    
    // バックグラウンドカウントダウンを停止
    _countdownService.stopCountdown(widget.alarmId);
    
    // アラームを停止
    debugPrint('🔕 Alarm.stopを呼び出します: ID=${widget.alarmId}');
    await Alarm.stop(widget.alarmId);
    debugPrint('✅ Alarm.stop完了');
    
    // 繰り返しアラームの場合、次回のスケジュールを設定
    if (_alarm != null && _alarm!.hasRepeat) {
      debugPrint('🔄 繰り返しアラーム：次回をスケジュール');
      final alarmService = ref.read(alarmServiceProvider);
      await alarmService.scheduleAlarm(_alarm!);
      debugPrint('✅ 次回のスケジュール完了');
    }
    
    // Leave the ring screen. If the device is still locked the task is hidden
    // so the user lands on the lock screen; the route is reset to '/' either
    // way so the next foreground does not show a stale ring screen.
    await LockScreenService.leaveRingScreen();
    if (!context.mounted) {
      debugPrint('⚠️ context.mountedがfalseのため画面を閉じられません');
      return;
    }
    
    debugPrint('🚪 画面を閉じます');
    context.go('/');
    debugPrint('✅ _stopAlarmAndCloseScreen完了');
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
