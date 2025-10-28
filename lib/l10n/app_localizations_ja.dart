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
  String get alarmSound => 'アラーム音';

  @override
  String get selectSound => '音源を選択';

  @override
  String get defaultSound => 'デフォルト';

  @override
  String get soundNotSet => '設定なし（システム音）';

  @override
  String get systemSound => 'システム音源';

  @override
  String get selectFromDevice => '端末の音源から選択';

  @override
  String soundSelected(String name) {
    return '音源を選択しました: $name';
  }

  @override
  String get soundSelectionFailed => '音源の選択に失敗しました';

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
  String get donationRecipient => '送金先';

  @override
  String get donationRecipientDescription => 'アラームがタイムアウトした際の送金先を選択してください';

  @override
  String get selectRecipient => '送金先を選択';

  @override
  String get recipientSaved => '送金先を保存しました';

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
      'アラームを止めないと\n選択した送金先に自動的に zap されます\n\n起きられないあなたへ最適！';

  @override
  String get onboardingTitle3 => '簡単設定';

  @override
  String get onboardingDescription3 =>
      '1. NWC 接続を設定\n2. アラーム時刻を設定\n3. 送金額とタイムアウトを設定\n\nこれだけでOK！';

  @override
  String get onboardingTitle4 => '準備完了';

  @override
  String get onboardingDescription4 => 'さあ、ZapClock で\n規則正しい生活を始めましょう！';

  @override
  String get onceOnly => '1回のみ';

  @override
  String get everyday => '毎日';

  @override
  String get weekdays => '平日';

  @override
  String get weekend => '週末';

  @override
  String get donationRecipientTitle => '寄付先';

  @override
  String get selectDonationRecipient => '寄付先を選択';

  @override
  String get defaultRecipient => 'デフォルト';

  @override
  String get useGlobalSetting => 'グローバル設定の寄付先を使用';

  @override
  String get defaultTapToSelect => 'デフォルト (タップして選択)';

  @override
  String get permissionsSettings => '権限設定';

  @override
  String get permissionsDescription => 'アプリが正常に動作するために必要な権限の状態を確認できます。';

  @override
  String get notification => '通知';

  @override
  String get notificationDescription => 'アラーム通知の表示に必要です';

  @override
  String get exactAlarm => '正確なアラーム';

  @override
  String get exactAlarmDescription => '指定した時刻に正確にアラームを鳴らすために必要です';

  @override
  String get mediaAccess => '音楽ファイル';

  @override
  String get mediaAccessDescription => 'カスタム着信音の選択に必要です';

  @override
  String get checkAllPermissions => 'すべての権限を確認';

  @override
  String get permitted => '許可済み';

  @override
  String get notPermitted => '未許可';

  @override
  String get permissionGranted => '権限が許可されました';

  @override
  String get permissionDenied => '権限が拒否されています';

  @override
  String get permissionDeniedMessage => 'この権限は設定から有効にする必要があります。\n設定画面を開きますか？';

  @override
  String get openSettings => '設定を開く';

  @override
  String get checkPermissions => '権限の確認';

  @override
  String get checkPermissionsMessage =>
      'アプリに必要な全ての権限を確認します。\n許可されていない権限がある場合、許可をリクエストします。';

  @override
  String get confirm => '確認する';

  @override
  String get allPermissionsGranted => '全ての権限が許可されています';

  @override
  String get somePermissionsDenied => '一部の権限が許可されませんでした';

  @override
  String get defaultDonationRecipientDescription => 'アラーム作成時のデフォルト寄付先として使用されます';

  @override
  String get addCustomRecipient => 'カスタム寄付先を追加';

  @override
  String get deleteConfirmation => '削除確認';

  @override
  String get selectEmoji => '絵文字を選択';

  @override
  String get nameRequired => '名前 *';

  @override
  String get nameHintExample => '例: Bitcoin Magazine';

  @override
  String get addressHintExample => '例: tips@bitcoin.com';

  @override
  String get description => '説明';

  @override
  String get descriptionHintExample => '例: Bitcoin news and education';

  @override
  String get nameAndAddressRequired => '名前とLightning Addressは必須です';

  @override
  String get add => '追加';

  @override
  String get addressAlreadyExists => 'この Lightning Address は既に登録されています';

  @override
  String get requestPermissions => '必要な権限の許可';

  @override
  String get grantNextPermissions => '次の画面で全ての権限を「許可」してください。';

  @override
  String get permissionsInsufficient => '権限が不足しています';

  @override
  String get permissionsInsufficientMessage =>
      '一部の権限が許可されませんでした。\n\nアプリが正常に動作しない可能性があります。\n設定から権限を有効にすることをお勧めします。';

  @override
  String get penaltyPresetTitle => 'ペナルティ設定';

  @override
  String get penaltyPresetDescription => 'タイムアウトと送金額のセットを選択してください';

  @override
  String get penaltyPreset15s => '⚡ 15秒 / 21 sats';

  @override
  String get penaltyPreset30s => '🔥 30秒 / 42 sats';

  @override
  String get penaltyPreset1m => '💪 1分 / 100 sats';

  @override
  String get penaltyPreset5m => '😴 5分 / 500 sats';

  @override
  String get penaltyPreset10m => '😱 10分 / 1,000 sats';

  @override
  String get penaltyPreset15m => '💀 15分 / 2,100 sats';

  @override
  String get penaltyPresetCustom => '⚙️ カスタム';

  @override
  String get customPenaltySettings => 'カスタム設定';

  @override
  String get customPenaltyDescription => 'タイムアウトと送金額を個別に設定できます';

  @override
  String get noPenalty => '送金設定なし';

  @override
  String get noPenaltyDescription => 'アラームを止めても送金されません';
}
