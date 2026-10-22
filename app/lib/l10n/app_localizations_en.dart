// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'HomeSafe';

  @override
  String get continueLabel => 'Continue';

  @override
  String get back => 'Back';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get close => 'Close';

  @override
  String get done => 'Done';

  @override
  String get next => 'Next';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get notSure => 'Not sure';

  @override
  String get retry => 'Try again';

  @override
  String get loading => 'Loading…';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get offlineNotice =>
      'You are offline. Some features need the internet.';

  @override
  String get signInRequired => 'Sign in to use this.';

  @override
  String get signIn => 'Sign in';

  @override
  String get backendUnavailable =>
      'This feature is not available right now. Try again later.';

  @override
  String get emergencyButton => 'Emergency';

  @override
  String get emergencyButtonHint =>
      'Opens the emergency steps and phone numbers';

  @override
  String get emergencyTitle => 'Emergency';

  @override
  String get emergencyIntro =>
      'If you smell gas, a CO alarm sounds, or someone feels dizzy, sick or faint:';

  @override
  String get emergencyStep1 =>
      'Get everyone out now. Leave the door open behind you.';

  @override
  String get emergencyStep2 =>
      'Do not touch light switches, sockets or anything with a flame. Do not call from inside.';

  @override
  String get emergencyStep3 => 'Call for help from outside the building.';

  @override
  String get emergencyStep4 =>
      'Do not go back in until the gas service says it is safe.';

  @override
  String get emergencyStep5 =>
      'See a doctor, even if you feel better. Say you may have breathed gas or carbon monoxide.';

  @override
  String get emergencyCallSection => 'Call for help';

  @override
  String emergencyCall(String name, String number) {
    return 'Call $name, $number';
  }

  @override
  String emergencyCallFailed(String number) {
    return 'Could not start the call. Dial $number yourself.';
  }

  @override
  String get emergencyNumbersUnverified =>
      'DEVELOPER NOTE: these emergency numbers are not verified yet.';

  @override
  String get emergencyImSafe => 'I am safe now';

  @override
  String get onboardingWhatTitle => 'A safer home';

  @override
  String get onboardingWhatBody =>
      'HomeSafe helps you check gas heaters, carbon monoxide, damp and mold. It helps you keep a record of problems and ask for repairs.';

  @override
  String get onboardingSafetyTitle => 'Important';

  @override
  String get onboardingSafetyBody =>
      'This app gives guidance, not a guarantee. In an emergency, call for help.';

  @override
  String get onboardingSafetyAccept => 'I understand';

  @override
  String get onboardingLanguageTitle => 'Choose your language';

  @override
  String get onboardingStart => 'Start';

  @override
  String get languageAz => 'Azərbaycanca';

  @override
  String get languageRu => 'Русский';

  @override
  String get languageEn => 'English';

  @override
  String get changeLanguage => 'Change language';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signInWhy =>
      'An account keeps your evidence log safe and lets you make reports and letters. Use your email.';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get signInEmail => 'Sign in';

  @override
  String get createAccount => 'Create account';

  @override
  String get tryWithoutAccount => 'Try without an account';

  @override
  String get guestNotice =>
      'Without an account you can do the checks, but you cannot save evidence.';

  @override
  String get authErrorEmail => 'Check your email and password.';

  @override
  String get authErrorWeakPassword => 'Use at least 8 characters.';

  @override
  String get profileTitle => 'Your home';

  @override
  String get profileIntro =>
      'A few facts about your home make the checks more accurate.';

  @override
  String get profileRole => 'Do you rent or own your home?';

  @override
  String get roleRenter => 'I rent';

  @override
  String get roleOwner => 'I own it';

  @override
  String get profileDistrict => 'District';

  @override
  String get profileBuildingAge => 'When was the building built?';

  @override
  String get ageBefore1960 => 'Before 1960';

  @override
  String get age1960to1990 => '1960 to 1990';

  @override
  String get age1991to2010 => '1991 to 2010';

  @override
  String get ageAfter2010 => 'After 2010';

  @override
  String get profileHeating => 'How is your home heated?';

  @override
  String get heatingIndividualGas => 'Gas heater in the room';

  @override
  String get heatingGasBoiler => 'Gas boiler (kombi)';

  @override
  String get heatingCentral => 'Central heating';

  @override
  String get heatingElectric => 'Electric';

  @override
  String get heatingOther => 'Other';

  @override
  String get profileWaterHeater => 'Where is your gas water heater (kolonka)?';

  @override
  String get waterHeaterBathroom => 'Bathroom';

  @override
  String get waterHeaterKitchen => 'Kitchen';

  @override
  String get waterHeaterOther => 'Another room';

  @override
  String get waterHeaterNone => 'I do not have one';

  @override
  String get profileCoAlarm => 'Do you have a carbon monoxide (CO) alarm?';

  @override
  String get profileContract => 'Do you have a written rental agreement?';

  @override
  String get profileSaved => 'Saved';

  @override
  String get cardGasTitle => 'Gas and CO check';

  @override
  String get cardGasBody => 'Quick questions about heaters and air.';

  @override
  String get cardDampTitle => 'Damp and mold check';

  @override
  String get cardDampBody => 'Photos and questions to find the cause.';

  @override
  String get cardEvidenceTitle => 'Evidence log';

  @override
  String get cardEvidenceBody => 'Photos and notes with a proven date.';

  @override
  String get cardLettersTitle => 'Letters';

  @override
  String get cardLettersBody => 'Ask for a repair or an inspection.';

  @override
  String get cardRightsTitle => 'Your rights';

  @override
  String get cardRightsBody => 'Legal information in plain language.';

  @override
  String get cardAskTitle => 'Ask HomeSafe';

  @override
  String get cardAskBody => 'Questions about your home.';

  @override
  String get seasonalTitle => 'Heating season';

  @override
  String get seasonalBody =>
      'Test your CO alarm and keep vents and air grilles clear.';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get profileMissing => 'Tell us about your home for better results.';

  @override
  String get profileSetUp => 'Set up';

  @override
  String get checkGasTitle => 'Gas and CO check';

  @override
  String get checkDampTitle => 'Damp and mold check';

  @override
  String questionProgress(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String get checkSeeResult => 'See result';

  @override
  String get photosTitle => 'Add photos of the damp or mold';

  @override
  String get photosBody => 'Add 1 to 5 photos. They stay private.';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get choosePhoto => 'Choose from gallery';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String photoLabel(int number) {
    return 'Photo $number';
  }

  @override
  String get multiSelectNone => 'None of these';

  @override
  String get resultTitle => 'Result';

  @override
  String get levelRed => 'Urgent';

  @override
  String get levelAmber => 'Serious';

  @override
  String get levelGreen => 'Monitor';

  @override
  String get levelRedHint => 'Act now.';

  @override
  String get levelAmberHint => 'Get this fixed soon.';

  @override
  String get levelGreenHint => 'Keep an eye on it.';

  @override
  String get resultWhy => 'Why';

  @override
  String get resultNextSteps => 'What to do next';

  @override
  String get resultSaveToEvidence => 'Save to evidence log';

  @override
  String get resultSaved => 'Saved to your evidence log.';

  @override
  String get resultAskAssistant => 'Ask HomeSafe about this';

  @override
  String get resultCausesTitle => 'Likely causes';

  @override
  String get causeCondensation => 'Likely condensation';

  @override
  String get causeLeak => 'Likely a leak';

  @override
  String get causeStructural => 'Likely structural damp';

  @override
  String get causeUnclear => 'No clear cause from your answers';

  @override
  String get resultDisclaimer =>
      'This is guidance, not a guarantee. If you are worried, ask a professional.';

  @override
  String get resultRulesUnreviewed =>
      'These checks are still waiting for expert review.';

  @override
  String get resultOpenEmergency => 'Open emergency steps';

  @override
  String get evidenceTitle => 'Evidence log';

  @override
  String get evidenceEmpty => 'Nothing here yet. Add a photo or a note.';

  @override
  String get evidenceAdd => 'Add';

  @override
  String get evidenceAddPhoto => 'Photo';

  @override
  String get evidenceAddNote => 'Note';

  @override
  String get evidenceAddSymptom => 'Symptom';

  @override
  String get evidenceNoteHint => 'What happened?';

  @override
  String get evidenceSymptomHint => 'Who felt what, and when?';

  @override
  String get evidencePhotoCaption => 'Caption (optional)';

  @override
  String get evidenceVerified => 'Verified';

  @override
  String get evidencePending => 'Verifying…';

  @override
  String get evidenceVerifiedHint =>
      'The server recorded the time and a fingerprint (hash) of this item. Any later change would not match.';

  @override
  String evidenceServerTime(String time) {
    return 'Recorded $time';
  }

  @override
  String get evidenceHash => 'Fingerprint (SHA-256)';

  @override
  String get evidenceDelete => 'Remove from log';

  @override
  String get evidenceDeleteConfirm =>
      'Remove this item? It will be hidden from your log and reports. Its record stays in the history.';

  @override
  String get evidenceTypePhoto => 'Photo';

  @override
  String get evidenceTypeNote => 'Note';

  @override
  String get evidenceTypeSymptom => 'Symptom';

  @override
  String get evidenceTypeCheck => 'Check result';

  @override
  String get evidenceTypeLetter => 'Letter';

  @override
  String get evidenceMakeReport => 'Make a report';

  @override
  String get evidenceUploading => 'Uploading…';

  @override
  String get reportTitle => 'Make a report';

  @override
  String get reportIntro =>
      'The PDF includes your home details, check results, and evidence with times and fingerprints.';

  @override
  String get reportFrom => 'From';

  @override
  String get reportTo => 'To';

  @override
  String get reportGenerate => 'Create PDF';

  @override
  String get reportGenerating => 'Creating your report…';

  @override
  String get reportReady => 'Your report is ready.';

  @override
  String get reportOpen => 'Open report';

  @override
  String get reportLinkExpires => 'The link works for 15 minutes.';

  @override
  String get lettersTitle => 'Letters';

  @override
  String get letterNew => 'New letter';

  @override
  String get lettersEmpty => 'No letters yet.';

  @override
  String get letterProblem => 'What is the problem?';

  @override
  String get problemGasHeater => 'Gas heater';

  @override
  String get problemCoAlarm => 'No CO alarm';

  @override
  String get problemDamp => 'Damp or mold';

  @override
  String get problemLeak => 'Leak';

  @override
  String get problemOther => 'Other';

  @override
  String get letterRecipient => 'Who is it for?';

  @override
  String get recipientLandlord => 'Landlord';

  @override
  String get recipientBuildingManager => 'Building manager';

  @override
  String get recipientAzerigaz => 'Azerigaz';

  @override
  String get recipientOther => 'Other';

  @override
  String get letterLanguage => 'Language of the letter';

  @override
  String get letterYourName => 'Your name';

  @override
  String get letterAddress => 'Address of the home';

  @override
  String get letterRecipientName => 'Recipient name (optional)';

  @override
  String get letterDescription => 'Describe the problem in a few words';

  @override
  String get letterSince => 'Since when?';

  @override
  String get letterPolish =>
      'Improve the wording with AI (the facts stay the same)';

  @override
  String get letterPreview => 'Preview';

  @override
  String get letterCopy => 'Copy';

  @override
  String get letterCopied => 'Copied';

  @override
  String get letterShare => 'Share';

  @override
  String get letterSavePdf => 'Save as PDF';

  @override
  String get letterSavedToLog => 'The letter was added to your evidence log.';

  @override
  String get letterGenerating => 'Preparing your letter…';

  @override
  String get letterFieldRequired => 'Please fill this in.';

  @override
  String get rightsTitle => 'Your rights';

  @override
  String get rightsNotice => 'General information, not legal advice.';

  @override
  String get rightsLawReference => 'Law';

  @override
  String rightsReviewedBy(String name, String date) {
    return 'Reviewed by $name on $date';
  }

  @override
  String get rightsNotReviewed => 'Waiting for review by a lawyer.';

  @override
  String get rightsPending =>
      'This topic is being prepared and checked by a lawyer.';

  @override
  String get chatTitle => 'Ask HomeSafe';

  @override
  String get chatNotice =>
      'Answers are guidance, not a guarantee. In an emergency, use the red button.';

  @override
  String get chatWelcome =>
      'Ask about gas heaters, CO, damp, mold, or your rights at home.';

  @override
  String get chatHint => 'Type your question';

  @override
  String get chatSend => 'Send';

  @override
  String get chatAttachPhoto => 'Add a photo';

  @override
  String get chatRemovePhoto => 'Remove the photo';

  @override
  String get chatEmergencyDetected =>
      'This sounds like an emergency. Follow the emergency steps now. Your message was not sent.';

  @override
  String get chatRateLimited =>
      'You have reached today\'s limit of 30 messages. Try again tomorrow.';

  @override
  String get chatError =>
      'Could not get an answer. Check your internet and try again.';

  @override
  String get chatEmergencyMentioned => 'This answer includes emergency steps.';

  @override
  String get chatThinking => 'Thinking…';

  @override
  String get chatYou => 'You';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsHome => 'Your home';

  @override
  String get settingsNotifications => 'Seasonal reminders';

  @override
  String get settingsNotificationsBody =>
      'A monthly reminder from October to April.';

  @override
  String get settingsExport => 'Export all my data';

  @override
  String get settingsExportWorking => 'Preparing your data…';

  @override
  String get settingsExportReady =>
      'Your data is ready. The link works for 15 minutes.';

  @override
  String get settingsDownload => 'Download';

  @override
  String get settingsDelete => 'Delete my account and data';

  @override
  String get settingsDeleteConfirmTitle => 'Delete everything?';

  @override
  String get settingsDeleteConfirmBody =>
      'This removes your account, homes, checks, evidence, photos and letters. It cannot be undone.';

  @override
  String get settingsDeleteConfirm => 'Delete';

  @override
  String get settingsDeleted => 'Your account and data were deleted.';

  @override
  String get settingsPrivacy => 'Privacy policy';

  @override
  String get settingsTerms => 'Terms of use';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String settingsSignedInAs(String id) {
    return 'Signed in as $id';
  }

  @override
  String get settingsGuest => 'Using without an account';

  @override
  String get aboutBody =>
      'HomeSafe helps people in Baku find and deal with dangers at home. It gives guidance, not a guarantee.';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get signInModeSignIn => 'I have an account';

  @override
  String get signInModeCreate => 'I am new here';

  @override
  String get passwordHint => 'At least 8 characters';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get forgotPassword => 'Forgot your password?';

  @override
  String get resetEmailSent =>
      'We sent you a link to reset your password. Check your email.';

  @override
  String get authErrorEmailInUse =>
      'This email already has an account. Sign in instead.';

  @override
  String get authErrorInvalidEmail => 'Check the email address.';

  @override
  String get emergencyBannerSub =>
      'Gas smell, CO alarm, or someone feels unwell';

  @override
  String get dashboardStatusTitle => 'Your home safety';

  @override
  String get dashboardToolsTitle => 'Tools';

  @override
  String get statusNotChecked => 'Not checked yet';

  @override
  String statusCheckedOn(String date) {
    return 'Checked $date';
  }

  @override
  String get statusStart => 'Start';

  @override
  String get statusAgain => 'Check again';

  @override
  String get checkMinutes => 'About 2 minutes';

  @override
  String get historyTitle => 'Check history';

  @override
  String get historyEmpty => 'No checks yet. Your results will appear here.';

  @override
  String get historyOnDevice =>
      'Saved on this phone only. Save a result to your evidence log to keep it in your account.';

  @override
  String get viewAll => 'See all';

  @override
  String get resultWriteLetter => 'Write a letter about this';

  @override
  String get signInWelcome => 'Welcome back';

  @override
  String get signInCreateTitle => 'Create your account';

  @override
  String get orDivider => 'or';

  @override
  String get tipTitle => 'Safety tip';

  @override
  String get chatSuggestTitle => 'Try asking';

  @override
  String get chatSuggest1 =>
      'My windows are wet every morning. What should I do?';

  @override
  String get chatSuggest2 => 'How often should a gas boiler be checked?';

  @override
  String get chatSuggest3 => 'Where should I put a CO alarm?';

  @override
  String get chatAssistantUnavailable =>
      'The assistant is not available right now. Please try again later.';

  @override
  String get rightsDraft =>
      'Draft: not yet checked by a lawyer. Use it as general guidance only.';

  @override
  String get rightsDraftBadge => 'Draft';

  @override
  String get rightsSources => 'Sources';

  @override
  String get legalDocDraft =>
      'Draft: a lawyer will finalise this text before launch.';

  @override
  String get signInAgree =>
      'By creating an account you agree to the Terms of use and the Privacy policy.';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsApp => 'App';

  @override
  String get settingsYourData => 'Your data';

  @override
  String get settingsLegal => 'Legal';

  @override
  String get demoBanner =>
      'Online demo: the emergency screen, safety checks, history and Your rights work here. Accounts, the evidence log, letters, reports and the AI assistant need the HomeSafe server and are switched off.';

  @override
  String get demoFeatureOff =>
      'This feature needs the HomeSafe server, so it is switched off in the online demo.';

  @override
  String get demoAccount => 'Online demo: no account needed';
}
