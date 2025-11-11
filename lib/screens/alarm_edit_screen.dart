import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_localizations.dart';
import '../models/alarm.dart';
import '../models/donation_recipient.dart';
import '../models/penalty_preset.dart';
import '../providers/alarm_provider.dart';
import '../providers/storage_provider.dart';
import '../services/ringtone_service.dart';
import '../app_theme.dart';

/// Alarm settings screen
class AlarmEditScreen extends StatefulWidget {
  /// Target alarm ID for editing (null for new creation)
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
  String? _donationRecipient;
  String? _soundPath;
  String? _soundName;
  Alarm? _originalAlarm;
  final _ringtoneService = RingtoneService();
  
  // 選択中のプリセット（nullの場合は「送金設定なし」）
  PenaltyPreset? _selectedPreset;
  // カスタム設定が選択されているか
  bool _isCustom = false;
  
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
    // デフォルトは「送金設定なし」
    _selectedPreset = null;
    _isCustom = false;
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
                  _donationRecipient = _originalAlarm!.donationRecipient;
                  _soundPath = _originalAlarm!.soundPath;
                  _soundName = _originalAlarm!.soundName;
                  
                  // プリセットを検出（マイグレーション）
                  if (_amountSats != null && _timeoutSeconds != null) {
                    final matchedPreset = PenaltyPreset.findClosestPreset(_timeoutSeconds, _amountSats);
                    if (matchedPreset != null) {
                      _selectedPreset = matchedPreset;
                      _isCustom = false;
                    } else {
                      // カスタム設定として扱う
                      _selectedPreset = null;
                      _isCustom = true;
                    }
                  } else {
                    // 送金設定なし
                    _selectedPreset = null;
                    _isCustom = false;
                  }
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
            error: (error, stack) {
              final l10n = AppLocalizations.of(context)!;
              return Center(
                child: Text('${l10n.errorOccurred}: $error'),
              );
            },
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
  
  /// Time selection picker
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
  
  /// Label input and sound selection section
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
  
  /// Select sound
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
  
  /// Repeat day selection
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
  
  /// Show time selection dialog
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
  
  /// Save alarm
  Future<void> _saveAlarm(BuildContext context, WidgetRef ref) async {
    try {
      // 送金設定がある場合は、amountSatsとtimeoutSecondsが必須
      final finalAmountSats = (_selectedPreset != null || _isCustom) ? _amountSats : null;
      final finalTimeoutSeconds = (_selectedPreset != null || _isCustom) ? _timeoutSeconds : null;
      
      // スヌーズモードの設定を取得
      final enableSnooze = _selectedPreset?.enableSnooze ?? false;
      final snoozeTimeoutRange = _selectedPreset?.snoozeTimeoutRange ?? (3, 30);
      
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
          amountSats: finalAmountSats,
          timeoutSeconds: finalTimeoutSeconds,
          donationRecipient: _donationRecipient,
          soundPath: _soundPath,
          soundName: _soundName,
          enableSnooze: enableSnooze,
          snoozeCount: 0, // 初期値
          snoozeTimeoutRange: snoozeTimeoutRange,
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
          amountSats: finalAmountSats,
          timeoutSeconds: finalTimeoutSeconds,
          donationRecipient: _donationRecipient,
          soundPath: _soundPath,
          soundName: _soundName,
          enableSnooze: enableSnooze,
          snoozeCount: 0, // リセット
          snoozeTimeoutRange: snoozeTimeoutRange,
        );
        await ref.read(alarmListProvider.notifier).updateAlarm(updatedAlarm);
      }
      
      if (context.mounted) {
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorOccurred}: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
  
  /// Delete confirmation dialog
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
  
  /// Lightning section header
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
  
  /// Lightning settings field (new UI: preset selection)
  Widget _buildLightningSettings() {
    final l10n = AppLocalizations.of(context)!;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // セクションタイトル
          Text(
            l10n.penaltyPresetTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.penaltyPresetDescription,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          
          // プリセット選択チップ
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // 「送金設定なし」オプション
              _buildPresetChip(
                label: l10n.noPenalty,
                emoji: '🚫',
                isSelected: _selectedPreset == null && !_isCustom,
                onTap: () {
                  setState(() {
                    _selectedPreset = null;
                    _isCustom = false;
                    _amountSats = null;
                    _timeoutSeconds = null;
                  });
                },
              ),
              
              // 各プリセット
              ...PenaltyPreset.presets.map((preset) {
                return _buildPresetChip(
                  label: _getPresetLabel(l10n, preset),
                  emoji: preset.emoji,
                  isSelected: _selectedPreset == preset && !_isCustom,
                  onTap: () {
                    setState(() {
                      _selectedPreset = preset;
                      _isCustom = false;
                      _amountSats = preset.amountSats;
                      _timeoutSeconds = preset.timeoutSeconds;
                      // スヌーズモードの設定を反映
                      // Note: enableSnoozeとsnoozeTimeoutRangeはsaveAlarm時に設定
                    });
                  },
                );
              }),
              
              // カスタムオプション
              _buildPresetChip(
                label: l10n.penaltyPresetCustom,
                emoji: '⚙️',
                isSelected: _isCustom,
                onTap: () => _showCustomSettingsDialog(),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 寄付先選択（送金設定がある場合のみ表示）
          if (_selectedPreset != null || _isCustom) ...[
            Consumer(
              builder: (context, ref, child) {
                return _buildDonationRecipientPicker(ref);
              },
            ),
            const SizedBox(height: 16),
          ],
          
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
                    _getSelectedDescription(l10n),
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
  
  /// Build preset chip
  Widget _buildPresetChip({
    required String label,
    required String emoji,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Get preset label
  String _getPresetLabel(AppLocalizations l10n, PenaltyPreset preset) {
    switch (preset.nameKey) {
      case 'penaltyPresetSnooze5s1':
        return '5秒 / 1 sat (テスト)';
      case 'penaltyPresetSnooze5m21':
        return '5分 / 21 sats';
      case 'penaltyPresetSnooze10m100':
        return '10分 / 100 sats';
      case 'penaltyPresetSnooze15m500':
        return '15分 / 500 sats';
      case 'penaltyPresetSnooze30m1000':
        return '30分 / 1000 sats';
      // 旧プリセットとの後方互換性
      case 'penaltyPreset15s':
        return l10n.penaltyPreset15s;
      case 'penaltyPreset30s':
        return l10n.penaltyPreset30s;
      case 'penaltyPreset1m':
        return l10n.penaltyPreset1m;
      case 'penaltyPreset5m':
        return l10n.penaltyPreset5m;
      case 'penaltyPreset10m':
        return l10n.penaltyPreset10m;
      case 'penaltyPreset15m':
        return l10n.penaltyPreset15m;
      default:
        return preset.nameKey;
    }
  }
  
  /// Get selected setting description
  String _getSelectedDescription(AppLocalizations l10n) {
    if (_selectedPreset == null && !_isCustom) {
      return l10n.noPenaltyDescription;
    } else if (_isCustom) {
      final timeoutStr = _getTimeoutLabel(l10n, _timeoutSeconds ?? 300);
      return '${l10n.customPenaltySettings}: $timeoutStr / ${_amountSats ?? 0} sats';
    } else if (_selectedPreset != null && _selectedPreset!.enableSnooze) {
      // スヌーズモードの説明
      final timeout = _selectedPreset!.timeoutSeconds;
      final timeStr = timeout >= 60 ? '${(timeout / 60).round()}分' : '${timeout}秒';
      final range = _selectedPreset!.snoozeTimeoutRange;
      return 'スヌーズ → ${timeStr}後に2回目のアラーム → ${range?.$1 ?? 3}~${range?.$2 ?? 30}秒以内に停止すれば${_selectedPreset!.amountSats} satsを失わない';
    } else if (_selectedPreset != null) {
      return l10n.lightningSettingsDescription;
    }
    return '';
  }
  
  /// Show custom settings dialog
  Future<void> _showCustomSettingsDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final timeoutController = TextEditingController(
      text: _timeoutSeconds?.toString() ?? '300',
    );
    final amountController = TextEditingController(
      text: _amountSats?.toString() ?? '100',
    );
    
    final result = await showDialog<Map<String, int>?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.customPenaltySettings),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.customPenaltyDescription,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                
                // タイムアウト入力
                TextField(
                  controller: timeoutController,
                  decoration: InputDecoration(
                    labelText: l10n.autoPaymentTime,
                    hintText: '300',
                    prefixIcon: const Icon(Icons.timer),
                    suffixText: '秒',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                
                // 送金額入力
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: l10n.amount,
                    hintText: '100',
                    prefixIcon: const Icon(Icons.monetization_on),
                    suffixText: 'sats',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                final timeout = int.tryParse(timeoutController.text);
                final amount = int.tryParse(amountController.text);
                
                if (timeout == null || amount == null || timeout <= 0 || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('正しい数値を入力してください'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                  return;
                }
                
                Navigator.of(context).pop({
                  'timeout': timeout,
                  'amount': amount,
                });
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
    
    if (result != null) {
      setState(() {
        _isCustom = true;
        _selectedPreset = null;
        _timeoutSeconds = result['timeout'];
        _amountSats = result['amount'];
      });
    }
    
    timeoutController.dispose();
    amountController.dispose();
  }
  
  /// Donation recipient selection UI
  Widget _buildDonationRecipientPicker(WidgetRef ref) {
    final storage = ref.read(storageServiceProvider);
    final presets = DonationRecipients.presetsSync;
    final customRecipients = storage.getCustomRecipients();
    final allRecipients = [...presets, ...customRecipients];
    
    // 選択中の寄付先を取得
    DonationRecipient? selectedRecipient;
    if (_donationRecipient != null) {
      try {
        selectedRecipient = allRecipients.firstWhere(
          (r) => r.lightningAddress == _donationRecipient,
        );
      } catch (e) {
        // 見つからない場合はnull
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.volunteer_activism, size: 20),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.donationRecipientTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => _selectDonationRecipient(ref),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.primaryLight),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  selectedRecipient?.emoji ?? '💝',
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedRecipient?.name ?? AppLocalizations.of(context)!.defaultTapToSelect,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (selectedRecipient != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          selectedRecipient.description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedRecipient.lightningAddress,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.primaryColor,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  /// Donation recipient selection dialog
  Future<void> _selectDonationRecipient(WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final storage = ref.read(storageServiceProvider);
    final presets = DonationRecipients.presetsSync;
    final customRecipients = storage.getCustomRecipients();
    final allRecipients = [...presets, ...customRecipients];
    
    final selected = await showDialog<DonationRecipient?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.selectDonationRecipient),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: allRecipients.length + 1, // +1 for "なし"オプション
              itemBuilder: (context, index) {
                // 最初の項目：「なし」オプション
                if (index == 0) {
                  final isSelected = _donationRecipient == null;
                  return ListTile(
                    leading: const Text('🚫', style: TextStyle(fontSize: 32)),
                    title: Text(l10n.defaultRecipient),
                    subtitle: Text(l10n.useGlobalSetting),
                    selected: isSelected,
                    selectedTileColor: AppTheme.primaryLight.withValues(alpha: 0.1),
                    onTap: () => Navigator.of(context).pop(null),
                  );
                }
                
                final recipient = allRecipients[index - 1];
                final isSelected = _donationRecipient == recipient.lightningAddress;
                final isCustom = index - 1 >= presets.length;
                
                return ListTile(
                  leading: Text(
                    recipient.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  title: Row(
                    children: [
                      Expanded(child: Text(recipient.name)),
                      if (isCustom)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber,
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(recipient.description),
                      const SizedBox(height: 4),
                      Text(
                        recipient.lightningAddress,
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  selected: isSelected,
                  selectedTileColor: AppTheme.primaryLight.withValues(alpha: 0.1),
                  onTap: () => Navigator.of(context).pop(recipient),
                );
              },
            ),
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
    
    if (selected != null) {
      setState(() {
        _donationRecipient = selected.lightningAddress;
      });
    } else if (selected == null && context.mounted) {
      // 「なし」が選択された場合
      setState(() {
        _donationRecipient = null;
      });
    }
  }
  
  /// Get timeout label
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

/// Day selection button
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

/// Sound selection result
class _SoundSelection {
  final String? path;
  final String name;
  
  _SoundSelection({required this.path, required this.name});
}
