import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
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
            const SizedBox(height: 12),
            Text(
              l10n.recipientAddress,
              style: const TextStyle(
                height: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 設定を読み込む
  void _loadSettings(WidgetRef ref) {
    final storage = ref.read(storageServiceProvider);
    
    final nwcConnection = storage.getGlobalNwcConnection();
    if (nwcConnection != null) {
      _nwcConnectionController.text = nwcConnection;
    }
  }
  
  /// 設定を保存
  Future<void> _saveSettings(WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final storage = ref.read(storageServiceProvider);
    
    // NWC接続文字列を保存
    final nwcConnection = _nwcConnectionController.text.trim();
    if (nwcConnection.isNotEmpty) {
      await storage.setGlobalNwcConnection(nwcConnection);
      
      if (!mounted) return;
      
      // 保存完了メッセージを表示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.nwcSaved),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.enterNwcConnection),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}

