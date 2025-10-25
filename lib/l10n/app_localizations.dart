import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'⚡ ZapClock'**
  String get appTitle;

  /// Settings button tooltip
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// Reload button text
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reload;

  /// Empty state title when there are no alarms
  ///
  /// In en, this message translates to:
  /// **'No alarms'**
  String get noAlarms;

  /// Empty state description
  ///
  /// In en, this message translates to:
  /// **'Tap the + button below\nto add a new alarm'**
  String get noAlarmsDescription;

  /// Timeout message in seconds
  ///
  /// In en, this message translates to:
  /// **'Auto-send in {seconds}s if not stopped'**
  String timeoutSeconds(int seconds);

  /// Timeout message in minutes
  ///
  /// In en, this message translates to:
  /// **'Auto-send in {minutes}min if not stopped'**
  String timeoutMinutes(int minutes);

  /// Title for creating a new alarm
  ///
  /// In en, this message translates to:
  /// **'New Alarm'**
  String get newAlarm;

  /// Title for editing an alarm
  ///
  /// In en, this message translates to:
  /// **'Edit Alarm'**
  String get editAlarm;

  /// Alarm label field
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get label;

  /// Alarm label hint text
  ///
  /// In en, this message translates to:
  /// **'Morning alarm'**
  String get labelHint;

  /// Alarm sound section title
  ///
  /// In en, this message translates to:
  /// **'Alarm Sound'**
  String get alarmSound;

  /// Button to select alarm sound
  ///
  /// In en, this message translates to:
  /// **'Select Sound'**
  String get selectSound;

  /// Default alarm sound option
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultSound;

  /// Message when no sound is selected
  ///
  /// In en, this message translates to:
  /// **'Not set (System sound)'**
  String get soundNotSet;

  /// System sound option
  ///
  /// In en, this message translates to:
  /// **'System Sound'**
  String get systemSound;

  /// Instruction to select sound from device
  ///
  /// In en, this message translates to:
  /// **'Select from device'**
  String get selectFromDevice;

  /// Success message when sound is selected
  ///
  /// In en, this message translates to:
  /// **'Sound selected: {name}'**
  String soundSelected(String name);

  /// Error message when sound selection fails
  ///
  /// In en, this message translates to:
  /// **'Failed to select sound'**
  String get soundSelectionFailed;

  /// Instruction to tap time picker
  ///
  /// In en, this message translates to:
  /// **'Tap to change time'**
  String get tapToChangeTime;

  /// Repeat days section title
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// Monday abbreviation
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get monday;

  /// Tuesday abbreviation
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tuesday;

  /// Wednesday abbreviation
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wednesday;

  /// Thursday abbreviation
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thursday;

  /// Friday abbreviation
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get friday;

  /// Saturday abbreviation
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get saturday;

  /// Sunday abbreviation
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sunday;

  /// Lightning settings section title
  ///
  /// In en, this message translates to:
  /// **'Lightning Payment Settings (Optional)'**
  String get lightningSettings;

  /// Payment amount field
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// Amount hint text
  ///
  /// In en, this message translates to:
  /// **'1000'**
  String get amountHint;

  /// Auto-payment timeout section title
  ///
  /// In en, this message translates to:
  /// **'Auto-payment timeout'**
  String get autoPaymentTime;

  /// 15 seconds timeout option
  ///
  /// In en, this message translates to:
  /// **'15s'**
  String get timeout15s;

  /// 30 seconds timeout option
  ///
  /// In en, this message translates to:
  /// **'30s'**
  String get timeout30s;

  /// 1 minute timeout option
  ///
  /// In en, this message translates to:
  /// **'1min'**
  String get timeout1m;

  /// 5 minutes timeout option
  ///
  /// In en, this message translates to:
  /// **'5min'**
  String get timeout5m;

  /// 10 minutes timeout option
  ///
  /// In en, this message translates to:
  /// **'10min'**
  String get timeout10m;

  /// 15 minutes timeout option
  ///
  /// In en, this message translates to:
  /// **'15min'**
  String get timeout15m;

  /// Timeout description
  ///
  /// In en, this message translates to:
  /// **'Payment will be sent automatically after this time'**
  String get timeoutDescription;

  /// Lightning settings detailed description
  ///
  /// In en, this message translates to:
  /// **'If you set an amount, payment will be sent automatically if you don\'t stop the alarm within the specified time'**
  String get lightningSettingsDescription;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Delete alarm dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Alarm'**
  String get deleteAlarm;

  /// Delete confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this alarm?'**
  String get deleteAlarmConfirm;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No Lightning settings message on ring screen
  ///
  /// In en, this message translates to:
  /// **'No Lightning settings'**
  String get noLightningSettings;

  /// Instruction to press stop button
  ///
  /// In en, this message translates to:
  /// **'Press button to stop'**
  String get pressToStop;

  /// Auto-payment alarm title on ring screen
  ///
  /// In en, this message translates to:
  /// **'Auto-payment alarm'**
  String get autoPaymentAlarm;

  /// Timeout message on ring screen (seconds)
  ///
  /// In en, this message translates to:
  /// **'Auto-send in {seconds}s if not stopped'**
  String timeoutMessageSeconds(int seconds);

  /// Timeout message on ring screen (minutes)
  ///
  /// In en, this message translates to:
  /// **'Auto-send in {minutes}min if not stopped'**
  String timeoutMessageMinutes(int minutes);

  /// Stop alarm button text when payment is configured
  ///
  /// In en, this message translates to:
  /// **'Stop now (no payment)'**
  String get stopNow;

  /// Stop alarm button text when no payment
  ///
  /// In en, this message translates to:
  /// **'Stop Alarm'**
  String get stopAlarm;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'⚙️ Settings'**
  String get settingsTitle;

  /// Save settings tooltip
  ///
  /// In en, this message translates to:
  /// **'Save settings'**
  String get saveSettings;

  /// NWC section title
  ///
  /// In en, this message translates to:
  /// **'Nostr Wallet Connect'**
  String get nwcTitle;

  /// NWC connection field label
  ///
  /// In en, this message translates to:
  /// **'NWC connection string'**
  String get nwcConnection;

  /// NWC connection hint
  ///
  /// In en, this message translates to:
  /// **'nostr+walletconnect://...'**
  String get nwcConnectionHint;

  /// NWC connection helper text
  ///
  /// In en, this message translates to:
  /// **'Enter connection string from Alby, Mutiny, etc.'**
  String get nwcConnectionHelper;

  /// Test connection button text
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get testConnection;

  /// Connection success message
  ///
  /// In en, this message translates to:
  /// **'Connection successful! Balance: {balance} sats'**
  String connectionSuccess(int balance);

  /// Error when connection string is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter connection string'**
  String get enterConnectionString;

  /// About NWC section title
  ///
  /// In en, this message translates to:
  /// **'About NWC'**
  String get aboutNwc;

  /// NWC description
  ///
  /// In en, this message translates to:
  /// **'Nostr Wallet Connect (NWC) is a way to securely connect your Lightning wallet to apps.'**
  String get nwcDescription;

  /// Supported wallets list
  ///
  /// In en, this message translates to:
  /// **'Supported wallets:\n• Alby (recommended)\n• Mutiny\n• Other NWC-compatible wallets'**
  String get supportedWallets;

  /// Donation recipient section title
  ///
  /// In en, this message translates to:
  /// **'Donation Recipient'**
  String get donationRecipient;

  /// Donation recipient section description
  ///
  /// In en, this message translates to:
  /// **'Choose where to send donations when alarm times out'**
  String get donationRecipientDescription;

  /// Button to select donation recipient
  ///
  /// In en, this message translates to:
  /// **'Select Recipient'**
  String get selectRecipient;

  /// Success message when recipient is saved
  ///
  /// In en, this message translates to:
  /// **'Donation recipient saved'**
  String get recipientSaved;

  /// Success message when NWC settings are saved
  ///
  /// In en, this message translates to:
  /// **'NWC settings saved'**
  String get nwcSaved;

  /// Warning when trying to save without connection string
  ///
  /// In en, this message translates to:
  /// **'Please enter NWC connection string'**
  String get enterNwcConnection;

  /// Skip button text on onboarding
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// Next button text on onboarding
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Start button text on last onboarding page
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// Onboarding page 1 title
  ///
  /// In en, this message translates to:
  /// **'Welcome to ZapClock'**
  String get onboardingTitle1;

  /// Onboarding page 1 description
  ///
  /// In en, this message translates to:
  /// **'An innovative alarm app\nusing Nostr Wallet Connect (NWC)'**
  String get onboardingDescription1;

  /// Onboarding page 2 title
  ///
  /// In en, this message translates to:
  /// **'Auto-payment Alarm'**
  String get onboardingTitle2;

  /// Onboarding page 2 description
  ///
  /// In en, this message translates to:
  /// **'If you don\'t stop the alarm,\nit will automatically zap your chosen recipient\n\nPerfect for those who can\'t wake up!'**
  String get onboardingDescription2;

  /// Onboarding page 3 title
  ///
  /// In en, this message translates to:
  /// **'Easy Setup'**
  String get onboardingTitle3;

  /// Onboarding page 3 description
  ///
  /// In en, this message translates to:
  /// **'1. Set up NWC connection\n2. Set alarm time\n3. Set amount and timeout\n\nThat\'s it!'**
  String get onboardingDescription3;

  /// Onboarding page 4 title
  ///
  /// In en, this message translates to:
  /// **'Ready to Go'**
  String get onboardingTitle4;

  /// Onboarding page 4 description
  ///
  /// In en, this message translates to:
  /// **'Let\'s start living a\nmore regular life with ZapClock!'**
  String get onboardingDescription4;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
