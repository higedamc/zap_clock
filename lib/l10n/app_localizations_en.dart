// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => '⚡ ZapClock';

  @override
  String get settings => 'Settings';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get reload => 'Reload';

  @override
  String get noAlarms => 'No alarms';

  @override
  String get noAlarmsDescription =>
      'Tap the + button below\nto add a new alarm';

  @override
  String timeoutSeconds(int seconds) {
    return 'Auto-send in ${seconds}s if not stopped';
  }

  @override
  String timeoutMinutes(int minutes) {
    return 'Auto-send in ${minutes}min if not stopped';
  }

  @override
  String get newAlarm => 'New Alarm';

  @override
  String get editAlarm => 'Edit Alarm';

  @override
  String get label => 'Label';

  @override
  String get labelHint => 'Morning alarm';

  @override
  String get alarmSound => 'Alarm Sound';

  @override
  String get selectSound => 'Select Sound';

  @override
  String get defaultSound => 'Default';

  @override
  String get soundNotSet => 'Not set (System sound)';

  @override
  String get systemSound => 'System Sound';

  @override
  String get selectFromDevice => 'Select from device';

  @override
  String soundSelected(String name) {
    return 'Sound selected: $name';
  }

  @override
  String get soundSelectionFailed => 'Failed to select sound';

  @override
  String get tapToChangeTime => 'Tap to change time';

  @override
  String get repeat => 'Repeat';

  @override
  String get monday => 'Mon';

  @override
  String get tuesday => 'Tue';

  @override
  String get wednesday => 'Wed';

  @override
  String get thursday => 'Thu';

  @override
  String get friday => 'Fri';

  @override
  String get saturday => 'Sat';

  @override
  String get sunday => 'Sun';

  @override
  String get lightningSettings => 'Lightning Payment Settings (Optional)';

  @override
  String get amount => 'Amount';

  @override
  String get amountHint => '1000';

  @override
  String get autoPaymentTime => 'Auto-payment timeout';

  @override
  String get timeout15s => '15s';

  @override
  String get timeout30s => '30s';

  @override
  String get timeout1m => '1min';

  @override
  String get timeout5m => '5min';

  @override
  String get timeout10m => '10min';

  @override
  String get timeout15m => '15min';

  @override
  String get timeoutDescription =>
      'Payment will be sent automatically after this time';

  @override
  String get lightningSettingsDescription =>
      'If you set an amount, payment will be sent automatically if you don\'t stop the alarm within the specified time';

  @override
  String get save => 'Save';

  @override
  String get deleteAlarm => 'Delete Alarm';

  @override
  String get deleteAlarmConfirm =>
      'Are you sure you want to delete this alarm?';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get noLightningSettings => 'No Lightning settings';

  @override
  String get pressToStop => 'Press button to stop';

  @override
  String get autoPaymentAlarm => 'Auto-payment alarm';

  @override
  String timeoutMessageSeconds(int seconds) {
    return 'Auto-send in ${seconds}s if not stopped';
  }

  @override
  String timeoutMessageMinutes(int minutes) {
    return 'Auto-send in ${minutes}min if not stopped';
  }

  @override
  String get stopNow => 'Stop now (no payment)';

  @override
  String get stopAlarm => 'Stop Alarm';

  @override
  String get settingsTitle => '⚙️ Settings';

  @override
  String get saveSettings => 'Save settings';

  @override
  String get nwcTitle => 'Nostr Wallet Connect';

  @override
  String get nwcConnection => 'NWC connection string';

  @override
  String get nwcConnectionHint => 'nostr+walletconnect://...';

  @override
  String get nwcConnectionHelper =>
      'Enter connection string from Alby, Mutiny, etc.';

  @override
  String get testConnection => 'Test Connection';

  @override
  String connectionSuccess(int balance) {
    return 'Connection successful! Balance: $balance sats';
  }

  @override
  String get enterConnectionString => 'Please enter connection string';

  @override
  String get aboutNwc => 'About NWC';

  @override
  String get nwcDescription =>
      'Nostr Wallet Connect (NWC) is a way to securely connect your Lightning wallet to apps.';

  @override
  String get supportedWallets =>
      'Supported wallets:\n• Alby (recommended)\n• Mutiny\n• Other NWC-compatible wallets';

  @override
  String get donationRecipient => 'Donation Recipient';

  @override
  String get donationRecipientDescription =>
      'Choose where to send donations when alarm times out';

  @override
  String get selectRecipient => 'Select Recipient';

  @override
  String get recipientSaved => 'Donation recipient saved';

  @override
  String get nwcSaved => 'NWC settings saved';

  @override
  String get enterNwcConnection => 'Please enter NWC connection string';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get start => 'Start';

  @override
  String get onboardingTitle1 => 'Welcome to ZapClock';

  @override
  String get onboardingDescription1 =>
      'An innovative alarm app\nusing Nostr Wallet Connect (NWC)';

  @override
  String get onboardingTitle2 => 'Auto-payment Alarm';

  @override
  String get onboardingDescription2 =>
      'If you don\'t stop the alarm,\nit will automatically zap your chosen recipient\n\nPerfect for those who can\'t wake up!';

  @override
  String get onboardingTitle3 => 'Easy Setup';

  @override
  String get onboardingDescription3 =>
      '1. Set up NWC connection\n2. Set alarm time\n3. Set amount and timeout\n\nThat\'s it!';

  @override
  String get onboardingTitle4 => 'Ready to Go';

  @override
  String get onboardingDescription4 =>
      'Let\'s start living a\nmore regular life with ZapClock!';

  @override
  String get onceOnly => 'Once only';

  @override
  String get everyday => 'Every day';

  @override
  String get weekdays => 'Weekdays';

  @override
  String get weekend => 'Weekend';

  @override
  String get donationRecipientTitle => 'Donation Recipient';

  @override
  String get selectDonationRecipient => 'Select Recipient';

  @override
  String get defaultRecipient => 'Default';

  @override
  String get useGlobalSetting => 'Use global setting';

  @override
  String get defaultTapToSelect => 'Default (tap to select)';

  @override
  String get permissionsSettings => 'Permissions Settings';

  @override
  String get permissionsDescription =>
      'You can check the status of permissions required for the app to function properly.';

  @override
  String get notification => 'Notification';

  @override
  String get notificationDescription =>
      'Required to display alarm notifications';

  @override
  String get exactAlarm => 'Exact Alarm';

  @override
  String get exactAlarmDescription =>
      'Required to ring the alarm at the exact specified time';

  @override
  String get mediaAccess => 'Media Access';

  @override
  String get mediaAccessDescription => 'Required to select custom ringtones';

  @override
  String get checkAllPermissions => 'Check all permissions';

  @override
  String get permitted => 'Permitted';

  @override
  String get notPermitted => 'Not permitted';

  @override
  String get permissionGranted => 'Permission granted';

  @override
  String get permissionDenied => 'Permission denied';

  @override
  String get permissionDeniedMessage =>
      'This permission needs to be enabled from settings.\nWould you like to open settings?';

  @override
  String get openSettings => 'Open settings';

  @override
  String get checkPermissions => 'Check Permissions';

  @override
  String get checkPermissionsMessage =>
      'Check all permissions required for the app.\nIf any permissions are not granted, you will be prompted to grant them.';

  @override
  String get confirm => 'Confirm';

  @override
  String get allPermissionsGranted => 'All permissions granted';

  @override
  String get somePermissionsDenied => 'Some permissions were not granted';

  @override
  String get defaultDonationRecipientDescription =>
      'Used as the default donation recipient when creating alarms';

  @override
  String get addCustomRecipient => 'Add custom recipient';

  @override
  String get deleteConfirmation => 'Delete Confirmation';

  @override
  String get selectEmoji => 'Select emoji';

  @override
  String get nameRequired => 'Name *';

  @override
  String get nameHintExample => 'e.g., Bitcoin Magazine';

  @override
  String get addressHintExample => 'e.g., tips@bitcoin.com';

  @override
  String get description => 'Description';

  @override
  String get descriptionHintExample => 'e.g., Bitcoin news and education';

  @override
  String get nameAndAddressRequired =>
      'Name and Lightning Address are required';

  @override
  String get add => 'Add';

  @override
  String get addressAlreadyExists =>
      'This Lightning Address is already registered';

  @override
  String get requestPermissions => 'Request Permissions';

  @override
  String get grantNextPermissions =>
      'Please grant all permissions on the next screen.';

  @override
  String get permissionsInsufficient => 'Insufficient Permissions';

  @override
  String get permissionsInsufficientMessage =>
      'Some permissions were not granted.\n\nThe app may not function properly.\nWe recommend enabling permissions from settings.';

  @override
  String get penaltyPresetTitle => 'Penalty Settings';

  @override
  String get penaltyPresetDescription => 'Choose a timeout and amount preset';

  @override
  String get penaltyPreset15s => '⚡ 15s / 21 sats';

  @override
  String get penaltyPreset30s => '🔥 30s / 42 sats';

  @override
  String get penaltyPreset1m => '💪 1min / 100 sats';

  @override
  String get penaltyPreset5m => '😴 5min / 500 sats';

  @override
  String get penaltyPreset10m => '😱 10min / 1,000 sats';

  @override
  String get penaltyPreset15m => '💀 15min / 2,100 sats';

  @override
  String get penaltyPresetCustom => '⚙️ Custom';

  @override
  String get customPenaltySettings => 'Custom Settings';

  @override
  String get customPenaltyDescription => 'Set timeout and amount individually';

  @override
  String get noPenalty => 'No payment';

  @override
  String get noPenaltyDescription =>
      'No payment will be sent when alarm is stopped';
}
