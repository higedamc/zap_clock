import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_localizations.dart';
import '../models/alarm.dart';
import '../providers/alarm_provider.dart';
import '../services/ringtone_service.dart';
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
  String? _soundPath;
  String? _soundName;
  Alarm? _originalAlarm;
  final _ringtoneService = RingtoneService();
  
  // タイムアウトのプリセット（秒単位）
  static const List<int> _timeoutPresets = [15, 30, 60, 300, 600, 900];
  
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
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.alarmId == null ? l10n.newAlarm : l10n.editAlarm),
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
                  _soundPath = _originalAlarm!.soundPath;
                  _soundName = _originalAlarm!.soundName;
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
          
          // ラベル入力と音源選択
          _buildLabelAndSoundSection(),
          
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
                    child: Text(
                      AppLocalizations.of(context)!.save,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              AppLocalizations.of(context)!.tapToChangeTime,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// ラベル入力と音源選択セクション
  Widget _buildLabelAndSoundSection() {
    final l10n = AppLocalizations.of(context)!;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ラベル入力
          TextField(
            controller: TextEditingController(text: _label)
              ..selection = TextSelection.collapsed(offset: _label.length),
            decoration: InputDecoration(
              labelText: l10n.label,
              hintText: l10n.labelHint,
              prefixIcon: const Icon(Icons.label_outline),
            ),
            onChanged: (value) {
              setState(() {
                _label = value;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // 音源選択（ラベルの下）
          Row(
            children: [
              const Icon(
                Icons.volume_up,
                color: AppTheme.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.alarmSound,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _soundName ?? l10n.defaultSound,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _selectSound,
                icon: const Icon(Icons.music_note),
                tooltip: l10n.selectSound,
                color: AppTheme.primaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// 音源を選択
  Future<void> _selectSound() async {
    final l10n = AppLocalizations.of(context)!;
    
    // 選択肢をダイアログで表示
    final result = await showDialog<_SoundSelection?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.selectSound),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // デフォルト音源
              ListTile(
                leading: const Icon(Icons.music_note),
                title: Text(l10n.defaultSound),
                subtitle: const Text('alarm_sound.mp3'),
                selected: _soundPath == null,
                onTap: () => Navigator.of(context).pop(
                  _SoundSelection(path: null, name: l10n.defaultSound),
                ),
              ),
              const Divider(),
              // システム音源
              ListTile(
                leading: const Icon(Icons.folder_special),
                title: Text(l10n.systemSound),
                subtitle: Text(l10n.selectFromDevice),
                onTap: () async {
                  Navigator.of(context).pop(
                    _SoundSelection(path: 'SYSTEM_PICKER', name: ''),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
          ],
        );
      },
    );
    
    if (result != null) {
      if (result.path == 'SYSTEM_PICKER') {
        // システム音源ピッカーを開く
        try {
          final ringtoneResult = await _ringtoneService.pickRingtone();
          if (ringtoneResult != null) {
            setState(() {
              _soundPath = ringtoneResult['path'];
              _soundName = ringtoneResult['name'];
            });
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.soundSelected(ringtoneResult['name']!)),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${l10n.soundSelectionFailed}: $e'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        }
      } else {
        // デフォルト音源
        setState(() {
          _soundPath = result.path;
          _soundName = result.name;
        });
      }
    }
  }
  
  /// 繰り返し曜日選択
  Widget _buildRepeatDays() {
    final l10n = AppLocalizations.of(context)!;
    final dayNames = [
      l10n.monday,
      l10n.tuesday,
      l10n.wednesday,
      l10n.thursday,
      l10n.friday,
      l10n.saturday,
      l10n.sunday,
    ];
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.repeat,
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
          soundPath: _soundPath,
          soundName: _soundName,
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
          soundPath: _soundPath,
          soundName: _soundName,
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
    final l10n = AppLocalizations.of(context)!;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.deleteAlarm),
          content: Text(l10n.deleteAlarmConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
              ),
              child: Text(l10n.delete),
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
    final l10n = AppLocalizations.of(context)!;
    
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
            l10n.lightningSettings,
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
    final l10n = AppLocalizations.of(context)!;
    
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
            decoration: InputDecoration(
              labelText: l10n.amount,
              hintText: l10n.amountHint,
              prefixIcon: const Icon(Icons.monetization_on),
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
                    l10n.autoPaymentTime,
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
                    label: Text(_getTimeoutLabel(l10n, seconds)),
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
                l10n.timeoutDescription,
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
                    l10n.lightningSettingsDescription,
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
  
  /// タイムアウトラベルを取得
  String _getTimeoutLabel(AppLocalizations l10n, int seconds) {
    switch (seconds) {
      case 15:
        return l10n.timeout15s;
      case 30:
        return l10n.timeout30s;
      case 60:
        return l10n.timeout1m;
      case 300:
        return l10n.timeout5m;
      case 600:
        return l10n.timeout10m;
      case 900:
        return l10n.timeout15m;
      default:
        return '$seconds';
    }
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

/// 音源選択の結果
class _SoundSelection {
  final String? path;
  final String name;
  
  _SoundSelection({required this.path, required this.name});
}
