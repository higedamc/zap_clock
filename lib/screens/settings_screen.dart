import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ 設定'),
        actions: [
          // 保存ボタン
          Consumer(
            builder: (context, ref, child) {
              return IconButton(
                icon: const Icon(Icons.save),
                onPressed: () => _saveSettings(ref),
                tooltip: '設定を保存',
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
                _buildSectionHeader('Nostr Wallet Connect'),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _nwcConnectionController,
        decoration: const InputDecoration(
          labelText: 'NWC接続文字列',
          hintText: 'nostr+walletconnect://...',
          prefixIcon: Icon(Icons.link),
          helperText: 'Alby、Mutinyなどから取得した接続文字列を入力',
        ),
        maxLines: 3,
        keyboardType: TextInputType.multiline,
      ),
    );
  }
  
  Widget _buildTestConnectionButton() {
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
                label: const Text('接続をテスト'),
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
    final connectionString = _nwcConnectionController.text.trim();
    
    if (connectionString.isEmpty) {
      ref.read(nwcConnectionStatusProvider.notifier).state =
          AsyncValue.error('接続文字列を入力してください', StackTrace.current);
      return;
    }
    
    ref.read(nwcConnectionStatusProvider.notifier).state =
        const AsyncValue.loading();
    
    try {
      final nwcService = ref.read(nwcServiceProvider);
      final balanceSats = await nwcService.testConnection(connectionString);
      
      // 残高をメッセージに含める
      final message = '接続成功！残高: $balanceSats sats';
      ref.read(nwcConnectionStatusProvider.notifier).state =
          AsyncValue.data(message);
    } catch (e) {
      ref.read(nwcConnectionStatusProvider.notifier).state =
          AsyncValue.error(e.toString(), StackTrace.current);
    }
  }
  
  Widget _buildInfoSection() {
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
                  'NWCについて',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Nostr Wallet Connect (NWC)は、Lightningウォレットをアプリに安全に接続する方法です。',
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 8),
            const Text(
              '対応ウォレット：\n• Alby（推奨）\n• Mutiny\n• その他NWC対応ウォレット',
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 12),
            const Text(
              '送金先: godzhigella@minibits.cash（固定）',
              style: TextStyle(
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
    final storage = ref.read(storageServiceProvider);
    
    // NWC接続文字列を保存
    final nwcConnection = _nwcConnectionController.text.trim();
    if (nwcConnection.isNotEmpty) {
      await storage.setGlobalNwcConnection(nwcConnection);
      
      if (!mounted) return;
      
      // 保存完了メッセージを表示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('NWC設定を保存しました'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('NWC接続文字列を入力してください'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}

