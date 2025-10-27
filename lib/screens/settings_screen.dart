import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../l10n/app_localizations.dart';
import '../models/donation_recipient.dart';
import '../providers/nwc_provider.dart';
import '../providers/storage_provider.dart';
import '../services/permission_service.dart';
import '../app_theme.dart';

/// NWC/Lightning設定画面
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nwcConnectionController = TextEditingController();
  bool _isLoaded = false;
  DonationRecipient? _selectedRecipient;
  
  @override
  void dispose() {
    _nwcConnectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        actions: [
          // 保存ボタン
          Consumer(
            builder: (context, ref, child) {
              return IconButton(
                icon: const Icon(Icons.save),
                onPressed: () => _saveSettings(ref),
                tooltip: l10n.saveSettings,
              );
            },
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          // 初回ロード時に設定を読み込む
          if (!_isLoaded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadSettings(ref);
            });
            _isLoaded = true;
          }
          
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 権限管理セクション
                _buildSectionHeader('権限設定'),
                _buildPermissionsSection(),
                
                const Divider(height: 32),
                
                // NWC設定セクション
                _buildSectionHeader(l10n.nwcTitle),
                _buildNwcConnectionField(),
                _buildTestConnectionButton(),
                
                const Divider(height: 32),
                
                // 送金先選択セクション
                _buildSectionHeader(l10n.donationRecipient),
                _buildDonationRecipientSection(),
                
                const Divider(height: 32),
                
                // 説明セクション
                _buildInfoSection(),
                
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
  
  Widget _buildNwcConnectionField() {
    final l10n = AppLocalizations.of(context)!;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _nwcConnectionController,
        decoration: InputDecoration(
          labelText: l10n.nwcConnection,
          hintText: l10n.nwcConnectionHint,
          prefixIcon: const Icon(Icons.link),
          helperText: l10n.nwcConnectionHelper,
        ),
        maxLines: 3,
        keyboardType: TextInputType.multiline,
      ),
    );
  }
  
  Widget _buildTestConnectionButton() {
    final l10n = AppLocalizations.of(context)!;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Consumer(
        builder: (context, ref, child) {
          final connectionStatus = ref.watch(nwcConnectionStatusProvider);
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: () => _testConnection(ref),
                icon: const Icon(Icons.wifi_tethering),
                label: Text(l10n.testConnection),
              ),
              
              const SizedBox(height: 8),
              
              connectionStatus.when(
                data: (message) {
                  if (message == null) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.successColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppTheme.successColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            message,
                            style: const TextStyle(
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.errorColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error,
                        color: AppTheme.errorColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          error.toString(),
                          style: const TextStyle(
                            color: AppTheme.errorColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Future<void> _testConnection(WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final connectionString = _nwcConnectionController.text.trim();
    
    if (connectionString.isEmpty) {
      ref.read(nwcConnectionStatusProvider.notifier).state =
          AsyncValue.error(l10n.enterConnectionString, StackTrace.current);
      return;
    }
    
    ref.read(nwcConnectionStatusProvider.notifier).state =
        const AsyncValue.loading();
    
    try {
      final nwcService = ref.read(nwcServiceProvider);
      final balanceSats = await nwcService.testConnection(connectionString);
      
      // 残高をメッセージに含める
      final message = l10n.connectionSuccess(balanceSats);
      ref.read(nwcConnectionStatusProvider.notifier).state =
          AsyncValue.data(message);
    } catch (e) {
      ref.read(nwcConnectionStatusProvider.notifier).state =
          AsyncValue.error(e.toString(), StackTrace.current);
    }
  }
  
  /// 権限管理セクション
  Widget _buildPermissionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'アプリが正常に動作するために必要な権限の状態を確認できます。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          
          // 通知権限
          FutureBuilder<PermissionStatus>(
            future: Permission.notification.status,
            builder: (context, snapshot) {
              final status = snapshot.data;
              return _buildPermissionTile(
                icon: Icons.notifications,
                title: '通知',
                description: 'アラーム通知の表示に必要です',
                status: status,
                onTap: () => _requestPermission(Permission.notification),
              );
            },
          ),
          
          const SizedBox(height: 8),
          
          // 正確なアラーム権限
          FutureBuilder<PermissionStatus>(
            future: Permission.scheduleExactAlarm.status,
            builder: (context, snapshot) {
              final status = snapshot.data;
              return _buildPermissionTile(
                icon: Icons.alarm,
                title: '正確なアラーム',
                description: '指定した時刻に正確にアラームを鳴らすために必要です',
                status: status,
                onTap: () => _requestPermission(Permission.scheduleExactAlarm),
              );
            },
          ),
          
          const SizedBox(height: 8),
          
          // 音楽ファイルアクセス権限
          FutureBuilder<PermissionStatus>(
            future: Permission.audio.status,
            builder: (context, snapshot) {
              final status = snapshot.data;
              return _buildPermissionTile(
                icon: Icons.music_note,
                title: '音楽ファイル',
                description: 'カスタム着信音の選択に必要です',
                status: status,
                onTap: () => _requestPermission(Permission.audio),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // すべての権限をリクエスト
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _requestAllPermissions,
              icon: const Icon(Icons.security),
              label: const Text('すべての権限を確認'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 権限タイル
  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required String description,
    required PermissionStatus? status,
    required VoidCallback onTap,
  }) {
    final isGranted = status?.isGranted ?? false;
    final color = isGranted ? AppTheme.successColor : AppTheme.errorColor;
    final statusText = isGranted ? '許可済み' : '未許可';
    final statusIcon = isGranted ? Icons.check_circle : Icons.cancel;
    
    return InkWell(
      onTap: isGranted ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isGranted 
                ? AppTheme.successColor.withValues(alpha: 0.3)
                : AppTheme.errorColor.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                Icon(statusIcon, color: color, size: 20),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// 個別の権限をリクエスト
  Future<void> _requestPermission(Permission permission) async {
    final status = await permission.request();
    
    if (!mounted) return;
    
    if (status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('権限が許可されました'),
          backgroundColor: AppTheme.successColor,
          duration: Duration(seconds: 2),
        ),
      );
    } else if (status.isPermanentlyDenied) {
      // 永続的に拒否された場合、設定画面へ誘導
      final shouldOpen = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('権限が拒否されています'),
          content: const Text(
            'この権限は設定から有効にする必要があります。\n設定画面を開きますか？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('設定を開く'),
            ),
          ],
        ),
      );
      
      if (shouldOpen == true) {
        await openAppSettings();
      }
    }
    
    // 画面を再描画
    setState(() {});
  }
  
  /// すべての権限をリクエスト
  Future<void> _requestAllPermissions() async {
    final permissionService = PermissionService();
    
    // 権限リクエストダイアログを表示
    final shouldRequest = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('権限の確認'),
        content: const Text(
          'アプリに必要な全ての権限を確認します。\n'
          '許可されていない権限がある場合、許可をリクエストします。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('確認する'),
          ),
        ],
      ),
    );
    
    if (shouldRequest != true) return;
    
    // 権限をリクエスト
    final results = await permissionService.requestAllPermissions();
    permissionService.logPermissionSummary(results);
    
    if (!mounted) return;
    
    // 結果を表示
    final hasAll = await permissionService.hasAllRequiredPermissions();
    if (hasAll) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('全ての権限が許可されています'),
          backgroundColor: AppTheme.successColor,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('一部の権限が許可されませんでした'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
    
    // 画面を再描画
    setState(() {});
  }
  
  Widget _buildInfoSection() {
    final l10n = AppLocalizations.of(context)!;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryLight.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryLight.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.aboutNwc,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.nwcDescription,
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.supportedWallets,
              style: const TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
  
  /// グローバル送金先選択セクション
  Widget _buildDonationRecipientSection() {
    final l10n = AppLocalizations.of(context)!;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'アラーム作成時のデフォルト寄付先として使用されます',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _selectDonationRecipient,
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
                    _selectedRecipient?.emoji ?? DonationRecipients.defaultRecipientSync.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedRecipient?.name ?? DonationRecipients.defaultRecipientSync.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedRecipient?.description ?? DonationRecipients.defaultRecipientSync.description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedRecipient?.lightningAddress ?? DonationRecipients.defaultRecipientSync.lightningAddress,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.primaryColor,
                            fontFamily: 'monospace',
                          ),
                        ),
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
          const SizedBox(height: 12),
          
          // カスタム寄付先を追加ボタン
          Consumer(
            builder: (context, ref, child) {
              return SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _addCustomRecipient(ref),
                  icon: const Icon(Icons.add),
                  label: const Text('カスタム寄付先を追加'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  /// グローバル送金先を選択
  Future<void> _selectDonationRecipient() async {
    final l10n = AppLocalizations.of(context)!;
    
    final selected = await showDialog<DonationRecipient?>(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            // プリセット + カスタムを結合
            final presets = DonationRecipients.presetsSync;
            final customRecipients = ref.read(storageServiceProvider).getCustomRecipients();
            final allRecipients = [...presets, ...customRecipients];
            
            return AlertDialog(
              title: Text(l10n.selectRecipient),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: allRecipients.length,
                  itemBuilder: (context, index) {
                    final recipient = allRecipients[index];
                    final isSelected = _selectedRecipient?.lightningAddress == recipient.lightningAddress;
                    final isCustom = index >= presets.length;
                    
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
                      trailing: isCustom
                          ? IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () async {
                                final shouldDelete = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('削除確認'),
                                    content: Text('「${recipient.name}」を削除しますか？'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('キャンセル'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppTheme.errorColor,
                                        ),
                                        child: const Text('削除'),
                                      ),
                                    ],
                                  ),
                                );
                                
                                if (shouldDelete == true) {
                                  await ref
                                      .read(storageServiceProvider)
                                      .deleteCustomRecipient(recipient.lightningAddress);
                                  
                                  // 画面を更新
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                    _selectDonationRecipient();
                                  }
                                }
                              },
                            )
                          : null,
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
      },
    );
    
    if (selected != null) {
      setState(() {
        _selectedRecipient = selected;
      });
    }
  }
  
  /// カスタム寄付先を追加
  Future<void> _addCustomRecipient(WidgetRef ref) async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedEmoji = '💝';
    
    final commonEmojis = ['💝', '⚡', '🧡', '💰', '🎁', '🌟', '❤️', '💙', '💚', '💛'];
    
    final result = await showDialog<DonationRecipient?>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('カスタム寄付先を追加'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 絵文字選択
                    const Text(
                      '絵文字を選択',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: commonEmojis.map((emoji) {
                        final isSelected = selectedEmoji == emoji;
                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              selectedEmoji = emoji;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(emoji, style: const TextStyle(fontSize: 24)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    
                    // 名前入力
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '名前 *',
                        hintText: '例: Bitcoin Magazine',
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Lightning Address 入力
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'Lightning Address *',
                        hintText: '例: tips@bitcoin.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    
                    // 説明入力
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: '説明',
                        hintText: '例: Bitcoin news and education',
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('キャンセル'),
                ),
                TextButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final address = addressController.text.trim();
                    final description = descriptionController.text.trim();
                    
                    if (name.isEmpty || address.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('名前とLightning Addressは必須です'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                      return;
                    }
                    
                    // Lightning Address の形式チェック
                    if (!address.contains('@')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lightning Addressの形式が正しくありません'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                      return;
                    }
                    
                    final recipient = DonationRecipient(
                      name: name,
                      lightningAddress: address,
                      description: description.isEmpty ? 'Custom recipient' : description,
                      emoji: selectedEmoji,
                    );
                    
                    Navigator.of(context).pop(recipient);
                  },
                  child: const Text('追加'),
                ),
              ],
            );
          },
        );
      },
    );
    
    if (result != null && mounted) {
      final storage = ref.read(storageServiceProvider);
      final success = await storage.addCustomRecipient(result);
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('「${result.name}」を追加しました'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('この Lightning Address は既に登録されています'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
    
    nameController.dispose();
    addressController.dispose();
    descriptionController.dispose();
  }
  
  /// 設定を読み込む
  Future<void> _loadSettings(WidgetRef ref) async {
    final storage = ref.read(storageServiceProvider);
    
    final nwcConnection = storage.getGlobalNwcConnection();
    if (nwcConnection != null) {
      _nwcConnectionController.text = nwcConnection;
    }
    
    // 送金先を読み込む
    final recipientAddress = storage.getDonationRecipient();
    if (recipientAddress != null) {
      _selectedRecipient = await DonationRecipients.findByAddress(recipientAddress);
    }
    _selectedRecipient ??= DonationRecipients.defaultRecipientSync;
  }
  
  /// 設定を保存
  Future<void> _saveSettings(WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final storage = ref.read(storageServiceProvider);
    
    bool hasError = false;
    
    // NWC接続文字列を保存
    final nwcConnection = _nwcConnectionController.text.trim();
    if (nwcConnection.isNotEmpty) {
      await storage.setGlobalNwcConnection(nwcConnection);
    } else {
      hasError = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.enterNwcConnection),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
    
    // グローバル送金先を保存
    if (_selectedRecipient != null) {
      await storage.setDonationRecipient(_selectedRecipient!.lightningAddress);
      // 寄付先Providerも更新（アラーム一覧画面のカード表記を更新するため）
      ref.read(donationRecipientProvider.notifier).state = _selectedRecipient!.lightningAddress;
    }
    
    if (!mounted) return;
    
    // 保存完了メッセージを表示（エラーがなかった場合のみ）
    if (!hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.nwcSaved}\n寄付先を保存しました'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

