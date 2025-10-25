import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alarm/alarm.dart';
import 'app_theme.dart';
import 'providers/storage_provider.dart';
import 'screens/alarm_list_screen.dart';
import 'screens/alarm_edit_screen.dart';
import 'screens/alarm_ring_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/alarm_service.dart';
import 'services/nwc_service.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // AlarmServiceの初期化
  await AlarmService.initialize();
  
  // Rust Bridgeの初期化
  await NwcService.initialize();
  
  // SharedPreferencesの初期化
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    ProviderScope(
      overrides: [
        // SharedPreferencesをProviderにオーバーライド
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    
    // GoRouterの初期化
    _router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            // 初回起動チェック
            final storage = ref.read(storageServiceProvider);
            if (!storage.hasCompletedOnboarding()) {
              // 初回起動時はオンボーディング画面へリダイレクト
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  context.go('/onboarding');
                }
              });
            }
            return const AlarmListScreen();
          },
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/edit',
          builder: (context, state) {
            final alarmId = state.uri.queryParameters['alarmId'];
            return AlarmEditScreen(
              alarmId: alarmId != null ? int.parse(alarmId) : null,
            );
          },
        ),
        GoRoute(
          path: '/ring',
          builder: (context, state) {
            final alarmId = state.uri.queryParameters['alarmId'];
            return AlarmRingScreen(
              alarmId: alarmId != null ? int.parse(alarmId) : 0,
            );
          },
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    );
    
    // アラームのリングイベントをリスニング
    Alarm.ringing.listen((alarmSet) {
      if (alarmSet.alarms.isNotEmpty) {
        final alarmSettings = alarmSet.alarms.first;
        debugPrint('🚨 アラームが鳴動開始: ID=${alarmSettings.id}');
        _navigateToRingScreen(alarmSettings.id);
      }
    });
    
    // アプリ起動時に鳴動中のアラームをチェック
    _checkRingingAlarms();
  }

  /// 鳴動中のアラームをチェックし、該当があれば画面遷移
  Future<void> _checkRingingAlarms() async {
    final ringingAlarms = await Alarm.getAlarms();
    if (ringingAlarms.isNotEmpty) {
      debugPrint('🔔 起動時に鳴動中のアラームを検出: ${ringingAlarms.length}件');
      _navigateToRingScreen(ringingAlarms.first.id);
    }
  }

  /// アラーム鳴動画面に遷移
  void _navigateToRingScreen(int alarmId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _router.go('/ring?alarmId=$alarmId');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ZapClock',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      // ローカライゼーション設定
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('ja'), // Japanese
      ],
    );
  }
}
