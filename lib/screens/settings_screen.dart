import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../models/donation_recipient.dart';
import '../providers/nwc_provider.dart';
import '../providers/alarm_provider.dart';
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
            _loadSettings(ref);
            _isLoaded = true;
          }
          
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
  
  /// 送金先選択セクション
  Widget _buildDonationRecipientSection() {
    final l10n = AppLocalizations.of(context)!;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.donationRecipientDescription,
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
                    _selectedRecipient?.emoji ?? DonationRecipients.defaultRecipient.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedRecipient?.name ?? DonationRecipients.defaultRecipient.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedRecipient?.description ?? DonationRecipients.defaultRecipient.description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedRecipient?.lightningAddress ?? DonationRecipients.defaultRecipient.lightningAddress,
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
        ],
      ),
    );
  }
  
  /// 送金先を選択
  Future<void> _selectDonationRecipient() async {
    final l10n = AppLocalizations.of(context)!;
    
    final selected = await showDialog<DonationRecipient?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.selectRecipient),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: DonationRecipients.presets.length,
              itemBuilder: (context, index) {
                final recipient = DonationRecipients.presets[index];
                final isSelected = _selectedRecipient?.lightningAddress == recipient.lightningAddress;
                
                return ListTile(
                  leading: Text(
                    recipient.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  title: Text(recipient.name),
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
        _selectedRecipient = selected;
      });
    }
  }
  
  /// 設定を読み込む
  void _loadSettings(WidgetRef ref) {
    final storage = ref.read(storageServiceProvider);
    
    final nwcConnection = storage.getGlobalNwcConnection();
    if (nwcConnection != null) {
      _nwcConnectionController.text = nwcConnection;
    }
    
    // 送金先を読み込む
    final recipientAddress = storage.getDonationRecipient();
    if (recipientAddress != null) {
      _selectedRecipient = DonationRecipients.findByAddress(recipientAddress);
    }
    _selectedRecipient ??= DonationRecipients.defaultRecipient;
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
    
    // 送金先を保存
    if (_selectedRecipient != null) {
      await storage.setDonationRecipient(_selectedRecipient!.lightningAddress);
    }
    
    if (!mounted) return;
    
    // 保存完了メッセージを表示（エラーがなかった場合のみ）
    if (!hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.nwcSaved}\n${l10n.recipientSaved}'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

