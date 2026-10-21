import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_az.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('az'),
    Locale('en'),
    Locale('ru'),
  ];

  /// appTitle
  ///
  /// In en, this message translates to:
  /// **'HomeSafe'**
  String get appTitle;

  /// continueLabel
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// back
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// save
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// close
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// done
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// next
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// yes
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// no
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// notSure
  ///
  /// In en, this message translates to:
  /// **'Not sure'**
  String get notSure;

  /// retry
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// loading
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// errorGeneric
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// offlineNotice
  ///
  /// In en, this message translates to:
  /// **'You are offline. Some features need the internet.'**
  String get offlineNotice;

  /// signInRequired
  ///
  /// In en, this message translates to:
  /// **'Sign in to use this.'**
  String get signInRequired;

  /// signIn
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// backendUnavailable
  ///
  /// In en, this message translates to:
  /// **'This feature is not available right now. Try again later.'**
  String get backendUnavailable;

  /// emergencyButton
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get emergencyButton;

  /// emergencyButtonHint
  ///
  /// In en, this message translates to:
  /// **'Opens the emergency steps and phone numbers'**
  String get emergencyButtonHint;

  /// emergencyTitle
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get emergencyTitle;

  /// emergencyIntro
  ///
  /// In en, this message translates to:
  /// **'If you smell gas, a CO alarm sounds, or someone feels dizzy, sick or faint:'**
  String get emergencyIntro;

  /// emergencyStep1
  ///
  /// In en, this message translates to:
  /// **'Get everyone out now. Leave the door open behind you.'**
  String get emergencyStep1;

  /// emergencyStep2
  ///
  /// In en, this message translates to:
  /// **'Do not touch light switches, sockets or anything with a flame. Do not call from inside.'**
  String get emergencyStep2;

  /// emergencyStep3
  ///
  /// In en, this message translates to:
  /// **'Call for help from outside the building.'**
  String get emergencyStep3;

  /// emergencyStep4
  ///
  /// In en, this message translates to:
  /// **'Do not go back in until the gas service says it is safe.'**
  String get emergencyStep4;

  /// emergencyStep5
  ///
  /// In en, this message translates to:
  /// **'See a doctor, even if you feel better. Say you may have breathed gas or carbon monoxide.'**
  String get emergencyStep5;

  /// emergencyCallSection
  ///
  /// In en, this message translates to:
  /// **'Call for help'**
  String get emergencyCallSection;

  /// emergencyCall
  ///
  /// In en, this message translates to:
  /// **'Call {name}, {number}'**
  String emergencyCall(String name, String number);

  /// emergencyCallFailed
  ///
  /// In en, this message translates to:
  /// **'Could not start the call. Dial {number} yourself.'**
  String emergencyCallFailed(String number);

  /// emergencyNumbersUnverified
  ///
  /// In en, this message translates to:
  /// **'DEVELOPER NOTE: these emergency numbers are not verified yet.'**
  String get emergencyNumbersUnverified;

  /// emergencyImSafe
  ///
  /// In en, this message translates to:
  /// **'I am safe now'**
  String get emergencyImSafe;

  /// onboardingWhatTitle
  ///
  /// In en, this message translates to:
  /// **'A safer home'**
  String get onboardingWhatTitle;

  /// onboardingWhatBody
  ///
  /// In en, this message translates to:
  /// **'HomeSafe helps you check gas heaters, carbon monoxide, damp and mold. It helps you keep a record of problems and ask for repairs.'**
  String get onboardingWhatBody;

  /// onboardingSafetyTitle
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get onboardingSafetyTitle;

  /// onboardingSafetyBody
  ///
  /// In en, this message translates to:
  /// **'This app gives guidance, not a guarantee. In an emergency, call for help.'**
  String get onboardingSafetyBody;

  /// onboardingSafetyAccept
  ///
  /// In en, this message translates to:
  /// **'I understand'**
  String get onboardingSafetyAccept;

  /// onboardingLanguageTitle
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get onboardingLanguageTitle;

  /// onboardingStart
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get onboardingStart;

  /// languageAz
  ///
  /// In en, this message translates to:
  /// **'Azərbaycanca'**
  String get languageAz;

  /// languageRu
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get languageRu;

  /// languageEn
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEn;

  /// changeLanguage
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get changeLanguage;

  /// signInTitle
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// signInWhy
  ///
  /// In en, this message translates to:
  /// **'An account keeps your evidence log safe and lets you make reports and letters. Use your email.'**
  String get signInWhy;

  /// emailLabel
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// passwordLabel
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// signInEmail
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInEmail;

  /// createAccount
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// tryWithoutAccount
  ///
  /// In en, this message translates to:
  /// **'Try without an account'**
  String get tryWithoutAccount;

  /// guestNotice
  ///
  /// In en, this message translates to:
  /// **'Without an account you can do the checks, but you cannot save evidence.'**
  String get guestNotice;

  /// authErrorEmail
  ///
  /// In en, this message translates to:
  /// **'Check your email and password.'**
  String get authErrorEmail;

  /// authErrorWeakPassword
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get authErrorWeakPassword;

  /// profileTitle
  ///
  /// In en, this message translates to:
  /// **'Your home'**
  String get profileTitle;

  /// profileIntro
  ///
  /// In en, this message translates to:
  /// **'A few facts about your home make the checks more accurate.'**
  String get profileIntro;

  /// profileRole
  ///
  /// In en, this message translates to:
  /// **'Do you rent or own your home?'**
  String get profileRole;

  /// roleRenter
  ///
  /// In en, this message translates to:
  /// **'I rent'**
  String get roleRenter;

  /// roleOwner
  ///
  /// In en, this message translates to:
  /// **'I own it'**
  String get roleOwner;

  /// profileDistrict
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get profileDistrict;

  /// profileBuildingAge
  ///
  /// In en, this message translates to:
  /// **'When was the building built?'**
  String get profileBuildingAge;

  /// ageBefore1960
  ///
  /// In en, this message translates to:
  /// **'Before 1960'**
  String get ageBefore1960;

  /// age1960to1990
  ///
  /// In en, this message translates to:
  /// **'1960 to 1990'**
  String get age1960to1990;

  /// age1991to2010
  ///
  /// In en, this message translates to:
  /// **'1991 to 2010'**
  String get age1991to2010;

  /// ageAfter2010
  ///
  /// In en, this message translates to:
  /// **'After 2010'**
  String get ageAfter2010;

  /// profileHeating
  ///
  /// In en, this message translates to:
  /// **'How is your home heated?'**
  String get profileHeating;

  /// heatingIndividualGas
  ///
  /// In en, this message translates to:
  /// **'Gas heater in the room'**
  String get heatingIndividualGas;

  /// heatingGasBoiler
  ///
  /// In en, this message translates to:
  /// **'Gas boiler (kombi)'**
  String get heatingGasBoiler;

  /// heatingCentral
  ///
  /// In en, this message translates to:
  /// **'Central heating'**
  String get heatingCentral;

  /// heatingElectric
  ///
  /// In en, this message translates to:
  /// **'Electric'**
  String get heatingElectric;

  /// heatingOther
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get heatingOther;

  /// profileWaterHeater
  ///
  /// In en, this message translates to:
  /// **'Where is your gas water heater (kolonka)?'**
  String get profileWaterHeater;

  /// waterHeaterBathroom
  ///
  /// In en, this message translates to:
  /// **'Bathroom'**
  String get waterHeaterBathroom;

  /// waterHeaterKitchen
  ///
  /// In en, this message translates to:
  /// **'Kitchen'**
  String get waterHeaterKitchen;

  /// waterHeaterOther
  ///
  /// In en, this message translates to:
  /// **'Another room'**
  String get waterHeaterOther;

  /// waterHeaterNone
  ///
  /// In en, this message translates to:
  /// **'I do not have one'**
  String get waterHeaterNone;

  /// profileCoAlarm
  ///
  /// In en, this message translates to:
  /// **'Do you have a carbon monoxide (CO) alarm?'**
  String get profileCoAlarm;

  /// profileContract
  ///
  /// In en, this message translates to:
  /// **'Do you have a written rental agreement?'**
  String get profileContract;

  /// profileSaved
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get profileSaved;

  /// cardGasTitle
  ///
  /// In en, this message translates to:
  /// **'Gas and CO check'**
  String get cardGasTitle;

  /// cardGasBody
  ///
  /// In en, this message translates to:
  /// **'Quick questions about heaters and air.'**
  String get cardGasBody;

  /// cardDampTitle
  ///
  /// In en, this message translates to:
  /// **'Damp and mold check'**
  String get cardDampTitle;

  /// cardDampBody
  ///
  /// In en, this message translates to:
  /// **'Photos and questions to find the cause.'**
  String get cardDampBody;

  /// cardEvidenceTitle
  ///
  /// In en, this message translates to:
  /// **'Evidence log'**
  String get cardEvidenceTitle;

  /// cardEvidenceBody
  ///
  /// In en, this message translates to:
  /// **'Photos and notes with a proven date.'**
  String get cardEvidenceBody;

  /// cardLettersTitle
  ///
  /// In en, this message translates to:
  /// **'Letters'**
  String get cardLettersTitle;

  /// cardLettersBody
  ///
  /// In en, this message translates to:
  /// **'Ask for a repair or an inspection.'**
  String get cardLettersBody;

  /// cardRightsTitle
  ///
  /// In en, this message translates to:
  /// **'Your rights'**
  String get cardRightsTitle;

  /// cardRightsBody
  ///
  /// In en, this message translates to:
  /// **'Legal information in plain language.'**
  String get cardRightsBody;

  /// cardAskTitle
  ///
  /// In en, this message translates to:
  /// **'Ask HomeSafe'**
  String get cardAskTitle;

  /// cardAskBody
  ///
  /// In en, this message translates to:
  /// **'Questions about your home.'**
  String get cardAskBody;

  /// seasonalTitle
  ///
  /// In en, this message translates to:
  /// **'Heating season'**
  String get seasonalTitle;

  /// seasonalBody
  ///
  /// In en, this message translates to:
  /// **'Test your CO alarm and keep vents and air grilles clear.'**
  String get seasonalBody;

  /// settingsTooltip
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// profileMissing
  ///
  /// In en, this message translates to:
  /// **'Tell us about your home for better results.'**
  String get profileMissing;

  /// profileSetUp
  ///
  /// In en, this message translates to:
  /// **'Set up'**
  String get profileSetUp;

  /// checkGasTitle
  ///
  /// In en, this message translates to:
  /// **'Gas and CO check'**
  String get checkGasTitle;

  /// checkDampTitle
  ///
  /// In en, this message translates to:
  /// **'Damp and mold check'**
  String get checkDampTitle;

  /// questionProgress
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String questionProgress(int current, int total);

  /// checkSeeResult
  ///
  /// In en, this message translates to:
  /// **'See result'**
  String get checkSeeResult;

  /// photosTitle
  ///
  /// In en, this message translates to:
  /// **'Add photos of the damp or mold'**
  String get photosTitle;

  /// photosBody
  ///
  /// In en, this message translates to:
  /// **'Add 1 to 5 photos. They stay private.'**
  String get photosBody;

  /// takePhoto
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// choosePhoto
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get choosePhoto;

  /// removePhoto
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// photoLabel
  ///
  /// In en, this message translates to:
  /// **'Photo {number}'**
  String photoLabel(int number);

  /// multiSelectNone
  ///
  /// In en, this message translates to:
  /// **'None of these'**
  String get multiSelectNone;

  /// resultTitle
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get resultTitle;

  /// levelRed
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get levelRed;

  /// levelAmber
  ///
  /// In en, this message translates to:
  /// **'Serious'**
  String get levelAmber;

  /// levelGreen
  ///
  /// In en, this message translates to:
  /// **'Monitor'**
  String get levelGreen;

  /// levelRedHint
  ///
  /// In en, this message translates to:
  /// **'Act now.'**
  String get levelRedHint;

  /// levelAmberHint
  ///
  /// In en, this message translates to:
  /// **'Get this fixed soon.'**
  String get levelAmberHint;

  /// levelGreenHint
  ///
  /// In en, this message translates to:
  /// **'Keep an eye on it.'**
  String get levelGreenHint;

  /// resultWhy
  ///
  /// In en, this message translates to:
  /// **'Why'**
  String get resultWhy;

  /// resultNextSteps
  ///
  /// In en, this message translates to:
  /// **'What to do next'**
  String get resultNextSteps;

  /// resultSaveToEvidence
  ///
  /// In en, this message translates to:
  /// **'Save to evidence log'**
  String get resultSaveToEvidence;

  /// resultSaved
  ///
  /// In en, this message translates to:
  /// **'Saved to your evidence log.'**
  String get resultSaved;

  /// resultAskAssistant
  ///
  /// In en, this message translates to:
  /// **'Ask HomeSafe about this'**
  String get resultAskAssistant;

  /// resultCausesTitle
  ///
  /// In en, this message translates to:
  /// **'Likely causes'**
  String get resultCausesTitle;

  /// causeCondensation
  ///
  /// In en, this message translates to:
  /// **'Likely condensation'**
  String get causeCondensation;

  /// causeLeak
  ///
  /// In en, this message translates to:
  /// **'Likely a leak'**
  String get causeLeak;

  /// causeStructural
  ///
  /// In en, this message translates to:
  /// **'Likely structural damp'**
  String get causeStructural;

  /// causeUnclear
  ///
  /// In en, this message translates to:
  /// **'No clear cause from your answers'**
  String get causeUnclear;

  /// resultDisclaimer
  ///
  /// In en, this message translates to:
  /// **'This is guidance, not a guarantee. If you are worried, ask a professional.'**
  String get resultDisclaimer;

  /// resultRulesUnreviewed
  ///
  /// In en, this message translates to:
  /// **'These checks are still waiting for expert review.'**
  String get resultRulesUnreviewed;

  /// resultOpenEmergency
  ///
  /// In en, this message translates to:
  /// **'Open emergency steps'**
  String get resultOpenEmergency;

  /// evidenceTitle
  ///
  /// In en, this message translates to:
  /// **'Evidence log'**
  String get evidenceTitle;

  /// evidenceEmpty
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet. Add a photo or a note.'**
  String get evidenceEmpty;

  /// evidenceAdd
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get evidenceAdd;

  /// evidenceAddPhoto
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get evidenceAddPhoto;

  /// evidenceAddNote
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get evidenceAddNote;

  /// evidenceAddSymptom
  ///
  /// In en, this message translates to:
  /// **'Symptom'**
  String get evidenceAddSymptom;

  /// evidenceNoteHint
  ///
  /// In en, this message translates to:
  /// **'What happened?'**
  String get evidenceNoteHint;

  /// evidenceSymptomHint
  ///
  /// In en, this message translates to:
  /// **'Who felt what, and when?'**
  String get evidenceSymptomHint;

  /// evidencePhotoCaption
  ///
  /// In en, this message translates to:
  /// **'Caption (optional)'**
  String get evidencePhotoCaption;

  /// evidenceVerified
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get evidenceVerified;

  /// evidencePending
  ///
  /// In en, this message translates to:
  /// **'Verifying…'**
  String get evidencePending;

  /// evidenceVerifiedHint
  ///
  /// In en, this message translates to:
  /// **'The server recorded the time and a fingerprint (hash) of this item. Any later change would not match.'**
  String get evidenceVerifiedHint;

  /// evidenceServerTime
  ///
  /// In en, this message translates to:
  /// **'Recorded {time}'**
  String evidenceServerTime(String time);

  /// evidenceHash
  ///
  /// In en, this message translates to:
  /// **'Fingerprint (SHA-256)'**
  String get evidenceHash;

  /// evidenceDelete
  ///
  /// In en, this message translates to:
  /// **'Remove from log'**
  String get evidenceDelete;

  /// evidenceDeleteConfirm
  ///
  /// In en, this message translates to:
  /// **'Remove this item? It will be hidden from your log and reports. Its record stays in the history.'**
  String get evidenceDeleteConfirm;

  /// evidenceTypePhoto
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get evidenceTypePhoto;

  /// evidenceTypeNote
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get evidenceTypeNote;

  /// evidenceTypeSymptom
  ///
  /// In en, this message translates to:
  /// **'Symptom'**
  String get evidenceTypeSymptom;

  /// evidenceTypeCheck
  ///
  /// In en, this message translates to:
  /// **'Check result'**
  String get evidenceTypeCheck;

  /// evidenceTypeLetter
  ///
  /// In en, this message translates to:
  /// **'Letter'**
  String get evidenceTypeLetter;

  /// evidenceMakeReport
  ///
  /// In en, this message translates to:
  /// **'Make a report'**
  String get evidenceMakeReport;

  /// evidenceUploading
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get evidenceUploading;

  /// reportTitle
  ///
  /// In en, this message translates to:
  /// **'Make a report'**
  String get reportTitle;

  /// reportIntro
  ///
  /// In en, this message translates to:
  /// **'The PDF includes your home details, check results, and evidence with times and fingerprints.'**
  String get reportIntro;

  /// reportFrom
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get reportFrom;

  /// reportTo
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get reportTo;

  /// reportGenerate
  ///
  /// In en, this message translates to:
  /// **'Create PDF'**
  String get reportGenerate;

  /// reportGenerating
  ///
  /// In en, this message translates to:
  /// **'Creating your report…'**
  String get reportGenerating;

  /// reportReady
  ///
  /// In en, this message translates to:
  /// **'Your report is ready.'**
  String get reportReady;

  /// reportOpen
  ///
  /// In en, this message translates to:
  /// **'Open report'**
  String get reportOpen;

  /// reportLinkExpires
  ///
  /// In en, this message translates to:
  /// **'The link works for 15 minutes.'**
  String get reportLinkExpires;

  /// lettersTitle
  ///
  /// In en, this message translates to:
  /// **'Letters'**
  String get lettersTitle;

  /// letterNew
  ///
  /// In en, this message translates to:
  /// **'New letter'**
  String get letterNew;

  /// lettersEmpty
  ///
  /// In en, this message translates to:
  /// **'No letters yet.'**
  String get lettersEmpty;

  /// letterProblem
  ///
  /// In en, this message translates to:
  /// **'What is the problem?'**
  String get letterProblem;

  /// problemGasHeater
  ///
  /// In en, this message translates to:
  /// **'Gas heater'**
  String get problemGasHeater;

  /// problemCoAlarm
  ///
  /// In en, this message translates to:
  /// **'No CO alarm'**
  String get problemCoAlarm;

  /// problemDamp
  ///
  /// In en, this message translates to:
  /// **'Damp or mold'**
  String get problemDamp;

  /// problemLeak
  ///
  /// In en, this message translates to:
  /// **'Leak'**
  String get problemLeak;

  /// problemOther
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get problemOther;

  /// letterRecipient
  ///
  /// In en, this message translates to:
  /// **'Who is it for?'**
  String get letterRecipient;

  /// recipientLandlord
  ///
  /// In en, this message translates to:
  /// **'Landlord'**
  String get recipientLandlord;

  /// recipientBuildingManager
  ///
  /// In en, this message translates to:
  /// **'Building manager'**
  String get recipientBuildingManager;

  /// recipientAzerigaz
  ///
  /// In en, this message translates to:
  /// **'Azerigaz'**
  String get recipientAzerigaz;

  /// recipientOther
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get recipientOther;

  /// letterLanguage
  ///
  /// In en, this message translates to:
  /// **'Language of the letter'**
  String get letterLanguage;

  /// letterYourName
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get letterYourName;

  /// letterAddress
  ///
  /// In en, this message translates to:
  /// **'Address of the home'**
  String get letterAddress;

  /// letterRecipientName
  ///
  /// In en, this message translates to:
  /// **'Recipient name (optional)'**
  String get letterRecipientName;

  /// letterDescription
  ///
  /// In en, this message translates to:
  /// **'Describe the problem in a few words'**
  String get letterDescription;

  /// letterSince
  ///
  /// In en, this message translates to:
  /// **'Since when?'**
  String get letterSince;

  /// letterPolish
  ///
  /// In en, this message translates to:
  /// **'Improve the wording with AI (the facts stay the same)'**
  String get letterPolish;

  /// letterPreview
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get letterPreview;

  /// letterCopy
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get letterCopy;

  /// letterCopied
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get letterCopied;

  /// letterShare
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get letterShare;

  /// letterSavePdf
  ///
  /// In en, this message translates to:
  /// **'Save as PDF'**
  String get letterSavePdf;

  /// letterSavedToLog
  ///
  /// In en, this message translates to:
  /// **'The letter was added to your evidence log.'**
  String get letterSavedToLog;

  /// letterGenerating
  ///
  /// In en, this message translates to:
  /// **'Preparing your letter…'**
  String get letterGenerating;

  /// letterFieldRequired
  ///
  /// In en, this message translates to:
  /// **'Please fill this in.'**
  String get letterFieldRequired;

  /// rightsTitle
  ///
  /// In en, this message translates to:
  /// **'Your rights'**
  String get rightsTitle;

  /// rightsNotice
  ///
  /// In en, this message translates to:
  /// **'General information, not legal advice.'**
  String get rightsNotice;

  /// rightsLawReference
  ///
  /// In en, this message translates to:
  /// **'Law'**
  String get rightsLawReference;

  /// rightsReviewedBy
  ///
  /// In en, this message translates to:
  /// **'Reviewed by {name} on {date}'**
  String rightsReviewedBy(String name, String date);

  /// rightsNotReviewed
  ///
  /// In en, this message translates to:
  /// **'Waiting for review by a lawyer.'**
  String get rightsNotReviewed;

  /// rightsPending
  ///
  /// In en, this message translates to:
  /// **'This topic is being prepared and checked by a lawyer.'**
  String get rightsPending;

  /// chatTitle
  ///
  /// In en, this message translates to:
  /// **'Ask HomeSafe'**
  String get chatTitle;

  /// chatNotice
  ///
  /// In en, this message translates to:
  /// **'Answers are guidance, not a guarantee. In an emergency, use the red button.'**
  String get chatNotice;

  /// chatWelcome
  ///
  /// In en, this message translates to:
  /// **'Ask about gas heaters, CO, damp, mold, or your rights at home.'**
  String get chatWelcome;

  /// chatHint
  ///
  /// In en, this message translates to:
  /// **'Type your question'**
  String get chatHint;

  /// chatSend
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatSend;

  /// chatAttachPhoto
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get chatAttachPhoto;

  /// chatRemovePhoto
  ///
  /// In en, this message translates to:
  /// **'Remove the photo'**
  String get chatRemovePhoto;

  /// chatEmergencyDetected
  ///
  /// In en, this message translates to:
  /// **'This sounds like an emergency. Follow the emergency steps now. Your message was not sent.'**
  String get chatEmergencyDetected;

  /// chatRateLimited
  ///
  /// In en, this message translates to:
  /// **'You have reached today\'s limit of 30 messages. Try again tomorrow.'**
  String get chatRateLimited;

  /// chatError
  ///
  /// In en, this message translates to:
  /// **'Could not get an answer. Check your internet and try again.'**
  String get chatError;

  /// chatEmergencyMentioned
  ///
  /// In en, this message translates to:
  /// **'This answer includes emergency steps.'**
  String get chatEmergencyMentioned;

  /// chatThinking
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get chatThinking;

  /// chatYou
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get chatYou;

  /// settingsTitle
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// settingsLanguage
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// settingsHome
  ///
  /// In en, this message translates to:
  /// **'Your home'**
  String get settingsHome;

  /// settingsNotifications
  ///
  /// In en, this message translates to:
  /// **'Seasonal reminders'**
  String get settingsNotifications;

  /// settingsNotificationsBody
  ///
  /// In en, this message translates to:
  /// **'A monthly reminder from October to April.'**
  String get settingsNotificationsBody;

  /// settingsExport
  ///
  /// In en, this message translates to:
  /// **'Export all my data'**
  String get settingsExport;

  /// settingsExportWorking
  ///
  /// In en, this message translates to:
  /// **'Preparing your data…'**
  String get settingsExportWorking;

  /// settingsExportReady
  ///
  /// In en, this message translates to:
  /// **'Your data is ready. The link works for 15 minutes.'**
  String get settingsExportReady;

  /// settingsDownload
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get settingsDownload;

  /// settingsDelete
  ///
  /// In en, this message translates to:
  /// **'Delete my account and data'**
  String get settingsDelete;

  /// settingsDeleteConfirmTitle
  ///
  /// In en, this message translates to:
  /// **'Delete everything?'**
  String get settingsDeleteConfirmTitle;

  /// settingsDeleteConfirmBody
  ///
  /// In en, this message translates to:
  /// **'This removes your account, homes, checks, evidence, photos and letters. It cannot be undone.'**
  String get settingsDeleteConfirmBody;

  /// settingsDeleteConfirm
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get settingsDeleteConfirm;

  /// settingsDeleted
  ///
  /// In en, this message translates to:
  /// **'Your account and data were deleted.'**
  String get settingsDeleted;

  /// settingsPrivacy
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacy;

  /// settingsTerms
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get settingsTerms;

  /// settingsAbout
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// settingsSignOut
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsSignOut;

  /// settingsSignedInAs
  ///
  /// In en, this message translates to:
  /// **'Signed in as {id}'**
  String settingsSignedInAs(String id);

  /// settingsGuest
  ///
  /// In en, this message translates to:
  /// **'Using without an account'**
  String get settingsGuest;

  /// aboutBody
  ///
  /// In en, this message translates to:
  /// **'HomeSafe helps people in Baku find and deal with dangers at home. It gives guidance, not a guarantee.'**
  String get aboutBody;

  /// aboutVersion
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String aboutVersion(String version);

  /// signInModeSignIn
  ///
  /// In en, this message translates to:
  /// **'I have an account'**
  String get signInModeSignIn;

  /// signInModeCreate
  ///
  /// In en, this message translates to:
  /// **'I am new here'**
  String get signInModeCreate;

  /// passwordHint
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordHint;

  /// showPassword
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// hidePassword
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// forgotPassword
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotPassword;

  /// resetEmailSent
  ///
  /// In en, this message translates to:
  /// **'We sent you a link to reset your password. Check your email.'**
  String get resetEmailSent;

  /// authErrorEmailInUse
  ///
  /// In en, this message translates to:
  /// **'This email already has an account. Sign in instead.'**
  String get authErrorEmailInUse;

  /// authErrorInvalidEmail
  ///
  /// In en, this message translates to:
  /// **'Check the email address.'**
  String get authErrorInvalidEmail;

  /// emergencyBannerSub
  ///
  /// In en, this message translates to:
  /// **'Gas smell, CO alarm, or someone feels unwell'**
  String get emergencyBannerSub;

  /// dashboardStatusTitle
  ///
  /// In en, this message translates to:
  /// **'Your home safety'**
  String get dashboardStatusTitle;

  /// dashboardToolsTitle
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get dashboardToolsTitle;

  /// statusNotChecked
  ///
  /// In en, this message translates to:
  /// **'Not checked yet'**
  String get statusNotChecked;

  /// statusCheckedOn
  ///
  /// In en, this message translates to:
  /// **'Checked {date}'**
  String statusCheckedOn(String date);

  /// statusStart
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get statusStart;

  /// statusAgain
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get statusAgain;

  /// checkMinutes
  ///
  /// In en, this message translates to:
  /// **'About 2 minutes'**
  String get checkMinutes;

  /// historyTitle
  ///
  /// In en, this message translates to:
  /// **'Check history'**
  String get historyTitle;

  /// historyEmpty
  ///
  /// In en, this message translates to:
  /// **'No checks yet. Your results will appear here.'**
  String get historyEmpty;

  /// historyOnDevice
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone only. Save a result to your evidence log to keep it in your account.'**
  String get historyOnDevice;

  /// viewAll
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get viewAll;

  /// resultWriteLetter
  ///
  /// In en, this message translates to:
  /// **'Write a letter about this'**
  String get resultWriteLetter;

  /// signInWelcome
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get signInWelcome;

  /// signInCreateTitle
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get signInCreateTitle;

  /// orDivider
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// tipTitle
  ///
  /// In en, this message translates to:
  /// **'Safety tip'**
  String get tipTitle;

  /// chatSuggestTitle
  ///
  /// In en, this message translates to:
  /// **'Try asking'**
  String get chatSuggestTitle;

  /// chatSuggest1
  ///
  /// In en, this message translates to:
  /// **'My windows are wet every morning. What should I do?'**
  String get chatSuggest1;

  /// chatSuggest2
  ///
  /// In en, this message translates to:
  /// **'How often should a gas boiler be checked?'**
  String get chatSuggest2;

  /// chatSuggest3
  ///
  /// In en, this message translates to:
  /// **'Where should I put a CO alarm?'**
  String get chatSuggest3;

  /// chatAssistantUnavailable
  ///
  /// In en, this message translates to:
  /// **'The assistant is not available right now. Please try again later.'**
  String get chatAssistantUnavailable;

  /// rightsDraft
  ///
  /// In en, this message translates to:
  /// **'Draft: not yet checked by a lawyer. Use it as general guidance only.'**
  String get rightsDraft;

  /// rightsDraftBadge
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get rightsDraftBadge;

  /// rightsSources
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get rightsSources;

  /// legalDocDraft
  ///
  /// In en, this message translates to:
  /// **'Draft: a lawyer will finalise this text before launch.'**
  String get legalDocDraft;

  /// signInAgree
  ///
  /// In en, this message translates to:
  /// **'By creating an account you agree to the Terms of use and the Privacy policy.'**
  String get signInAgree;

  /// settingsAccount
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// settingsApp
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get settingsApp;

  /// settingsYourData
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get settingsYourData;

  /// settingsLegal
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get settingsLegal;
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
      <String>['az', 'en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'az':
      return AppLocalizationsAz();
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
