// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => '⚡ ZapClock';

  @override
  String get settings => '設定';

  @override
  String get errorOccurred => 'エラーが発生しました';

  @override
  String get reload => '再読み込み';

  @override
  String get noAlarms => 'アラームがありません';

  @override
  String get noAlarmsDescription => '右下の + ボタンから\n新しいアラームを追加しましょう';

  @override
  String timeoutSeconds(int seconds) {
    return '$seconds秒以内に停止しないと自動送金';
  }

  @override
  String timeoutMinutes(int minutes) {
    return '$minutes分以内に停止しないと自動送金';
  }

  @override
  String get newAlarm => '新しいアラーム';

  @override
  String get editAlarm => 'アラームを編集';

  @override
  String get label => 'ラベル';

  @override
  String get labelHint => '朝のアラーム';

  @override
  String get tapToChangeTime => 'タップして時刻を変更';

  @override
  String get repeat => '繰り返し';

  @override
  String get monday => '月';

  @override
  String get tuesday => '火';

  @override
  String get wednesday => '水';

  @override
  String get thursday => '木';

  @override
  String get friday => '金';

  @override
  String get saturday => '土';

  @override
  String get sunday => '日';

  @override
  String get lightningSettings => 'Lightning送金設定（オプション）';

  @override
  String get amount => '送金額';

  @override
  String get amountHint => '1000';

  @override
  String get autoPaymentTime => '自動送金までの時間';

  @override
  String get timeout15s => '15秒';

  @override
  String get timeout30s => '30秒';

  @override
  String get timeout1m => '1分';

  @override
  String get timeout5m => '5分';

  @override
  String get timeout10m => '10分';

  @override
  String get timeout15m => '15分';

  @override
  String get timeoutDescription => 'この時間が経過すると自動的に送金されます';

  @override
  String get lightningSettingsDescription =>
      '送金額を設定すると、指定時間内にアラームを止めないと自動的にLightning送金されます';

  @override
  String get save => '保存';

  @override
  String get deleteAlarm => 'アラームを削除';

  @override
  String get deleteAlarmConfirm => 'このアラームを削除してもよろしいですか？';

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除';

  @override
  String get noLightningSettings => 'Lightning設定なし';

  @override
  String get pressToStop => 'ボタンを押して停止してください';

  @override
  String get autoPaymentAlarm => '自動送金アラーム';

  @override
  String timeoutMessageSeconds(int seconds) {
    return '$seconds秒以内に停止しないと自動送金されます';
  }

  @override
  String timeoutMessageMinutes(int minutes) {
    return '$minutes分以内に停止しないと自動送金されます';
  }

  @override
  String get stopNow => '今すぐ停止（送金なし）';

  @override
  String get stopAlarm => 'アラームを停止';

  @override
  String get settingsTitle => '⚙️ 設定';

  @override
  String get saveSettings => '設定を保存';

  @override
  String get nwcTitle => 'Nostr Wallet Connect';

  @override
  String get nwcConnection => 'NWC接続文字列';

  @override
  String get nwcConnectionHint => 'nostr+walletconnect://...';

  @override
  String get nwcConnectionHelper => 'Alby、Mutinyなどから取得した接続文字列を入力';

  @override
  String get testConnection => '接続をテスト';

  @override
  String connectionSuccess(int balance) {
    return '接続成功！残高: $balance sats';
  }

  @override
  String get enterConnectionString => '接続文字列を入力してください';

  @override
  String get aboutNwc => 'NWCについて';

  @override
  String get nwcDescription =>
      'Nostr Wallet Connect (NWC)は、Lightningウォレットをアプリに安全に接続する方法です。';

  @override
  String get supportedWallets =>
      '対応ウォレット：\n• Alby（推奨）\n• Mutiny\n• その他NWC対応ウォレット';

  @override
  String get recipientAddress => '送金先: godzhigella@minibits.cash（固定）';

  @override
  String get nwcSaved => 'NWC設定を保存しました';

  @override
  String get enterNwcConnection => 'NWC接続文字列を入力してください';

  @override
  String get skip => 'スキップ';

  @override
  String get next => '次へ';

  @override
  String get start => '始める';

  @override
  String get onboardingTitle1 => 'ZapClock へようこそ';

  @override
  String get onboardingDescription1 =>
      'Nostr Wallet Connect (NWC) を使った\n革新的なアラームアプリです';

  @override
  String get onboardingTitle2 => '自動送金アラーム';

  @override
  String get onboardingDescription2 =>
      'アラームを止めないと\n自動的に開発者に zap されます\n\n起きられないあなたへ最適！';

  @override
  String get onboardingTitle3 => '簡単設定';

  @override
  String get onboardingDescription3 =>
      '1. NWC 接続を設定\n2. アラーム時刻を設定\n3. 送金額とタイムアウトを設定\n\nこれだけでOK！';

  @override
  String get onboardingTitle4 => '準備完了';

  @override
  String get onboardingDescription4 => 'さあ、ZapClock で\n規則正しい生活を始めましょう！';
}
