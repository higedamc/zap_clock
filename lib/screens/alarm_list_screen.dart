import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/alarm_provider.dart';
import '../models/alarm.dart';
import '../app_theme.dart';

/// アラーム一覧画面
class AlarmListScreen extends StatelessWidget {
  const AlarmListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚡ ZapClock'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push('/settings');
            },
            tooltip: '設定',
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final alarmsAsync = ref.watch(alarmListProvider);
          
          return alarmsAsync.when(
            data: (alarms) {
              if (alarms.isEmpty) {
                return _buildEmptyState(context);
              }
              return _buildAlarmList(alarms, ref);
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'エラーが発生しました',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(alarmListProvider.notifier).loadAlarms();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('再読み込み'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: Consumer(
        builder: (context, ref, child) {
          return FloatingActionButton(
            onPressed: () {
              context.push('/edit');
            },
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
  
  /// 空の状態を表示
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.alarm_off,
            size: 80,
            color: AppTheme.textHint,
          ),
          const SizedBox(height: 24),
          Text(
            'アラームがありません',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '右下の + ボタンから\n新しいアラームを追加しましょう',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textHint,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  /// アラームリストを表示
  Widget _buildAlarmList(List<Alarm> alarms, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: alarms.length,
      itemBuilder: (context, index) {
        final alarm = alarms[index];
        return _AlarmListItem(alarm: alarm);
      },
    );
  }
}

/// アラームリストのアイテム
class _AlarmListItem extends StatelessWidget {
  final Alarm alarm;
  
  const _AlarmListItem({required this.alarm});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          context.push('/edit?alarmId=${alarm.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 時刻表示
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 時刻
                    Text(
                      alarm.timeString,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: alarm.isEnabled 
                            ? AppTheme.textPrimary 
                            : AppTheme.textHint,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // ラベル
                    if (alarm.label.isNotEmpty)
                      Text(
                        alarm.label,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: alarm.isEnabled 
                              ? AppTheme.textPrimary 
                              : AppTheme.textHint,
                        ),
                      ),
                    const SizedBox(height: 4),
                    // 繰り返し設定
                    Row(
                      children: [
                        Icon(
                          alarm.hasRepeat ? Icons.repeat : Icons.calendar_today,
                          size: 16,
                          color: alarm.isEnabled 
                              ? AppTheme.textSecondary 
                              : AppTheme.textHint,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          alarm.repeatDaysString,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: alarm.isEnabled 
                                ? AppTheme.textSecondary 
                                : AppTheme.textHint,
                          ),
                        ),
                      ],
                    ),
                    // Lightning設定
                    if (alarm.amountSats != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.flash_on,
                                  size: 16,
                                  color: AppTheme.accentColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${alarm.amountSats} sats → godzhigella@minibits.cash',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.accentColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.timer,
                                  size: 14,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatTimeout(alarm.timeoutSeconds ?? 300),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // スイッチ
              Consumer(
                builder: (context, ref, child) {
                  return Switch(
                    value: alarm.isEnabled,
                    onChanged: (value) {
                      ref.read(alarmListProvider.notifier).toggleAlarm(alarm.id);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// タイムアウト時間を人間が読みやすい形式に変換
  String _formatTimeout(int seconds) {
    if (seconds < 60) {
      return '$seconds秒以内に停止しないと自動送金';
    } else {
      final minutes = seconds ~/ 60;
      return '$minutes分以内に停止しないと自動送金';
    }
  }
}

