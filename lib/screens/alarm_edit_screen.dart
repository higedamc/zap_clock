import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/alarm.dart';
import '../providers/alarm_provider.dart';
import '../app_theme.dart';

/// アラーム設定画面
class AlarmEditScreen extends StatefulWidget {
  /// 編集対象のアラームID（nullの場合は新規作成）
  final int? alarmId;
  
  const AlarmEditScreen({super.key, this.alarmId});

  @override
  State<AlarmEditScreen> createState() => _AlarmEditScreenState();
}

class _AlarmEditScreenState extends State<AlarmEditScreen> {
  late int _hour;
  late int _minute;
  late bool _isEnabled;
  late String _label;
  late List<bool> _repeatDays;
  int? _amountSats;
  int? _timeoutSeconds;
  Alarm? _originalAlarm;
  
  // タイムアウトのプリセット（秒単位）
  static const List<int> _timeoutPresets = [15, 30, 60, 300, 600, 900];
  
  // プリセットのラベル
  static const Map<int, String> _timeoutLabels = {
    15: '15秒',
    30: '30秒',
    60: '1分',
    300: '5分',
    600: '10分',
    900: '15分',
  };
  
  @override
  void initState() {
    super.initState();
    // デフォルト値を設定
    final now = DateTime.now();
    _hour = now.hour;
    _minute = now.minute;
    _isEnabled = true;
    _label = '';
    _repeatDays = List.filled(7, false);
    _timeoutSeconds = 300; // デフォルト5分=300秒
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.alarmId == null ? '新しいアラーム' : 'アラームを編集'),
        actions: [
          if (widget.alarmId != null)
            Consumer(
              builder: (context, ref, child) {
                return IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmDelete(context, ref),
                );
              },
            ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final alarmsAsync = ref.watch(alarmListProvider);
          
          return alarmsAsync.when(
            data: (alarms) {
              // 編集モードの場合、既存のアラームを読み込む
              if (widget.alarmId != null && _originalAlarm == null) {
                try {
                  _originalAlarm = alarms.firstWhere((a) => a.id == widget.alarmId);
                  _hour = _originalAlarm!.hour;
                  _minute = _originalAlarm!.minute;
                  _isEnabled = _originalAlarm!.isEnabled;
                  _label = _originalAlarm!.label;
                  _repeatDays = List.from(_originalAlarm!.repeatDays);
                  _amountSats = _originalAlarm!.amountSats;
                  _timeoutSeconds = _originalAlarm!.timeoutSeconds ?? 300;
                } catch (e) {
                  // アラームが見つからない場合
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      context.pop();
                    }
                  });
                }
              }
              
              return _buildForm(context, ref);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('エラーが発生しました: $error'),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildForm(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 時刻選択
          _buildTimePicker(context),
          
          const Divider(height: 1),
          
          // ラベル入力
          _buildLabelInput(),
          
          const Divider(height: 1),
          
          // 繰り返し設定
          _buildRepeatDays(),
          
          const Divider(height: 1),
          
          // Lightning設定
          _buildLightningSectionHeader(),
          _buildLightningSettings(),
          
          const Divider(height: 1),
          
          const SizedBox(height: 32),
          
          // 保存ボタン
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: Consumer(
                builder: (context, ref, child) {
                  return ElevatedButton(
                    onPressed: () => _saveAlarm(context, ref),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      '保存',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  /// 時刻選択ピッカー
  Widget _buildTimePicker(BuildContext context) {
    return InkWell(
      onTap: () => _selectTime(context),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'タップして時刻を変更',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// ラベル入力フィールド
  Widget _buildLabelInput() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: TextEditingController(text: _label)
          ..selection = TextSelection.collapsed(offset: _label.length),
        decoration: const InputDecoration(
          labelText: 'ラベル',
          hintText: '朝のアラーム',
          prefixIcon: Icon(Icons.label_outline),
        ),
        onChanged: (value) {
          setState(() {
            _label = value;
          });
        },
      ),
    );
  }
  
  /// 繰り返し曜日選択
  Widget _buildRepeatDays() {
    const dayNames = ['月', '火', '水', '木', '金', '土', '日'];
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '繰り返し',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              return _DayButton(
                label: dayNames[index],
                isSelected: _repeatDays[index],
                onTap: () {
                  setState(() {
                    _repeatDays[index] = !_repeatDays[index];
                  });
                },
              );
            }),
          ),
        ],
      ),
    );
  }
  
  /// 時刻選択ダイアログを表示
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteTextColor: AppTheme.primaryColor,
              dayPeriodTextColor: AppTheme.primaryColor,
              dialHandColor: AppTheme.primaryColor,
              dialBackgroundColor: AppTheme.primaryLight.withValues(alpha: 0.2),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _hour = picked.hour;
        _minute = picked.minute;
      });
    }
  }
  
  /// アラームを保存
  Future<void> _saveAlarm(BuildContext context, WidgetRef ref) async {
    try {
      if (widget.alarmId == null) {
        // 新規作成
        final newId = await ref.read(alarmListProvider.notifier).getNextAlarmId();
        final newAlarm = Alarm(
          id: newId,
          hour: _hour,
          minute: _minute,
          isEnabled: _isEnabled,
          label: _label,
          repeatDays: _repeatDays,
          amountSats: _amountSats,
          timeoutSeconds: _timeoutSeconds ?? 300,
        );
        await ref.read(alarmListProvider.notifier).addAlarm(newAlarm);
      } else {
        // 更新
        final updatedAlarm = _originalAlarm!.copyWith(
          hour: _hour,
          minute: _minute,
          isEnabled: _isEnabled,
          label: _label,
          repeatDays: _repeatDays,
          amountSats: _amountSats,
          timeoutSeconds: _timeoutSeconds ?? 300,
        );
        await ref.read(alarmListProvider.notifier).updateAlarm(updatedAlarm);
      }
      
      if (context.mounted) {
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
  
  /// 削除確認ダイアログ
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('アラームを削除'),
          content: const Text('このアラームを削除してもよろしいですか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
              ),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );
    
    if (confirmed == true && context.mounted) {
      await ref.read(alarmListProvider.notifier).deleteAlarm(widget.alarmId!);
      if (context.mounted) {
        context.pop();
      }
    }
  }
  
  /// Lightningセクションヘッダー
  Widget _buildLightningSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          const Icon(
            Icons.flash_on,
            color: AppTheme.accentColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Lightning送金設定（オプション）',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Lightning設定フィールド
  Widget _buildLightningSettings() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 送金額
          TextField(
            controller: TextEditingController(
              text: _amountSats?.toString() ?? '',
            )..selection = TextSelection.collapsed(
                offset: _amountSats?.toString().length ?? 0,
              ),
            decoration: const InputDecoration(
              labelText: '送金額',
              hintText: '1000',
              prefixIcon: Icon(Icons.monetization_on),
              suffixText: 'sats',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _amountSats = value.isEmpty ? null : int.tryParse(value);
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // タイムアウト時間選択
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.timer, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '自動送金までの時間',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _timeoutPresets.map((seconds) {
                  final isSelected = _timeoutSeconds == seconds;
                  return ChoiceChip(
                    label: Text(_timeoutLabels[seconds]!),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _timeoutSeconds = seconds;
                        });
                      }
                    },
                    selectedColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                'この時間が経過すると自動的に送金されます',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 説明テキスト
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 18,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '送金額を設定すると、指定時間内にアラームを止めないと自動的にLightning送金されます',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 曜日選択ボタン
class _DayButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _DayButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

