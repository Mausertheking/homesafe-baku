// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'HomeSafe';

  @override
  String get continueLabel => 'Продолжить';

  @override
  String get back => 'Назад';

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get close => 'Закрыть';

  @override
  String get done => 'Готово';

  @override
  String get next => 'Далее';

  @override
  String get yes => 'Да';

  @override
  String get no => 'Нет';

  @override
  String get notSure => 'Не уверен(а)';

  @override
  String get retry => 'Попробовать снова';

  @override
  String get loading => 'Загрузка…';

  @override
  String get errorGeneric => 'Что-то пошло не так. Попробуйте ещё раз.';

  @override
  String get offlineNotice =>
      'Нет интернета. Некоторым функциям нужен интернет.';

  @override
  String get signInRequired => 'Войдите, чтобы пользоваться этим.';

  @override
  String get signIn => 'Войти';

  @override
  String get backendUnavailable =>
      'Эта функция сейчас недоступна. Попробуйте позже.';

  @override
  String get emergencyButton => 'Экстренно';

  @override
  String get emergencyButtonHint =>
      'Открывает экстренные шаги и номера телефонов';

  @override
  String get emergencyTitle => 'Экстренная ситуация';

  @override
  String get emergencyIntro =>
      'Если пахнет газом, сработал датчик CO или кому-то плохо, кружится голова или он теряет сознание:';

  @override
  String get emergencyStep1 =>
      'Немедленно выведите всех наружу. Оставьте дверь открытой.';

  @override
  String get emergencyStep2 =>
      'Не трогайте выключатели, розетки и ничего с огнём. Не звоните изнутри.';

  @override
  String get emergencyStep3 => 'Звоните за помощью, выйдя из здания.';

  @override
  String get emergencyStep4 =>
      'Не возвращайтесь, пока газовая служба не скажет, что это безопасно.';

  @override
  String get emergencyStep5 =>
      'Обратитесь к врачу, даже если стало лучше. Скажите, что могли надышаться газом или угарным газом.';

  @override
  String get emergencyCallSection => 'Вызовите помощь';

  @override
  String emergencyCall(String name, String number) {
    return 'Позвонить: $name, $number';
  }

  @override
  String emergencyCallFailed(String number) {
    return 'Не удалось начать звонок. Наберите $number сами.';
  }

  @override
  String get emergencyNumbersUnverified =>
      'ДЛЯ РАЗРАБОТЧИКОВ: эти номера ещё не проверены.';

  @override
  String get emergencyImSafe => 'Я уже в безопасности';

  @override
  String get onboardingWhatTitle => 'Безопасный дом';

  @override
  String get onboardingWhatBody =>
      'HomeSafe помогает проверить газовые обогреватели, угарный газ, сырость и плесень. Помогает фиксировать проблемы и просить о ремонте.';

  @override
  String get onboardingSafetyTitle => 'Важно';

  @override
  String get onboardingSafetyBody =>
      'Это приложение даёт советы, а не гарантии. В экстренной ситуации вызывайте помощь.';

  @override
  String get onboardingSafetyAccept => 'Понятно';

  @override
  String get onboardingLanguageTitle => 'Выберите язык';

  @override
  String get onboardingStart => 'Начать';

  @override
  String get languageAz => 'Azərbaycanca';

  @override
  String get languageRu => 'Русский';

  @override
  String get languageEn => 'English';

  @override
  String get changeLanguage => 'Сменить язык';

  @override
  String get signInTitle => 'Вход';

  @override
  String get signInWhy =>
      'Аккаунт сохраняет журнал доказательств и позволяет делать отчёты и письма. Используйте свою почту.';

  @override
  String get emailLabel => 'Эл. почта';

  @override
  String get passwordLabel => 'Пароль';

  @override
  String get signInEmail => 'Войти';

  @override
  String get createAccount => 'Создать аккаунт';

  @override
  String get tryWithoutAccount => 'Попробовать без аккаунта';

  @override
  String get guestNotice =>
      'Без аккаунта можно проходить проверки, но нельзя сохранять доказательства.';

  @override
  String get authErrorEmail => 'Проверьте почту и пароль.';

  @override
  String get authErrorWeakPassword => 'Используйте не менее 8 символов.';

  @override
  String get profileTitle => 'Ваш дом';

  @override
  String get profileIntro => 'Несколько фактов о доме делают проверки точнее.';

  @override
  String get profileRole => 'Вы снимаете жильё или владеете им?';

  @override
  String get roleRenter => 'Снимаю';

  @override
  String get roleOwner => 'Владею';

  @override
  String get profileDistrict => 'Район';

  @override
  String get profileBuildingAge => 'Когда построен дом?';

  @override
  String get ageBefore1960 => 'До 1960';

  @override
  String get age1960to1990 => '1960–1990';

  @override
  String get age1991to2010 => '1991–2010';

  @override
  String get ageAfter2010 => 'После 2010';

  @override
  String get profileHeating => 'Как отапливается дом?';

  @override
  String get heatingIndividualGas => 'Газовый обогреватель в комнате';

  @override
  String get heatingGasBoiler => 'Газовый котёл (комби)';

  @override
  String get heatingCentral => 'Центральное отопление';

  @override
  String get heatingElectric => 'Электрическое';

  @override
  String get heatingOther => 'Другое';

  @override
  String get profileWaterHeater => 'Где ваша газовая колонка?';

  @override
  String get waterHeaterBathroom => 'Ванная';

  @override
  String get waterHeaterKitchen => 'Кухня';

  @override
  String get waterHeaterOther => 'Другая комната';

  @override
  String get waterHeaterNone => 'Нет колонки';

  @override
  String get profileCoAlarm => 'Есть ли у вас датчик угарного газа (CO)?';

  @override
  String get profileContract => 'Есть ли письменный договор аренды?';

  @override
  String get profileSaved => 'Сохранено';

  @override
  String get cardGasTitle => 'Проверка газа и CO';

  @override
  String get cardGasBody => 'Короткие вопросы об обогревателях и воздухе.';

  @override
  String get cardDampTitle => 'Проверка сырости и плесени';

  @override
  String get cardDampBody => 'Фото и вопросы, чтобы найти причину.';

  @override
  String get cardEvidenceTitle => 'Журнал доказательств';

  @override
  String get cardEvidenceBody => 'Фото и заметки с подтверждённой датой.';

  @override
  String get cardLettersTitle => 'Письма';

  @override
  String get cardLettersBody => 'Попросите о ремонте или проверке.';

  @override
  String get cardRightsTitle => 'Ваши права';

  @override
  String get cardRightsBody => 'Правовая информация простым языком.';

  @override
  String get cardAskTitle => 'Спросить HomeSafe';

  @override
  String get cardAskBody => 'Вопросы о вашем доме.';

  @override
  String get seasonalTitle => 'Отопительный сезон';

  @override
  String get seasonalBody =>
      'Проверьте датчик CO и не закрывайте вентиляцию и решётки.';

  @override
  String get settingsTooltip => 'Настройки';

  @override
  String get profileMissing =>
      'Расскажите о доме для более точных результатов.';

  @override
  String get profileSetUp => 'Заполнить';

  @override
  String get checkGasTitle => 'Проверка газа и CO';

  @override
  String get checkDampTitle => 'Проверка сырости и плесени';

  @override
  String questionProgress(int current, int total) {
    return 'Вопрос $current из $total';
  }

  @override
  String get checkSeeResult => 'Посмотреть результат';

  @override
  String get photosTitle => 'Добавьте фото сырости или плесени';

  @override
  String get photosBody => 'Добавьте от 1 до 5 фото. Они остаются личными.';

  @override
  String get takePhoto => 'Сделать фото';

  @override
  String get choosePhoto => 'Выбрать из галереи';

  @override
  String get removePhoto => 'Удалить фото';

  @override
  String photoLabel(int number) {
    return 'Фото $number';
  }

  @override
  String get multiSelectNone => 'Ничего из этого';

  @override
  String get resultTitle => 'Результат';

  @override
  String get levelRed => 'Срочно';

  @override
  String get levelAmber => 'Серьёзно';

  @override
  String get levelGreen => 'Наблюдайте';

  @override
  String get levelRedHint => 'Действуйте сейчас.';

  @override
  String get levelAmberHint => 'Исправьте в ближайшее время.';

  @override
  String get levelGreenHint => 'Следите за этим.';

  @override
  String get resultWhy => 'Почему';

  @override
  String get resultNextSteps => 'Что делать дальше';

  @override
  String get resultSaveToEvidence => 'Сохранить в журнал';

  @override
  String get resultSaved => 'Сохранено в журнал доказательств.';

  @override
  String get resultAskAssistant => 'Спросить HomeSafe об этом';

  @override
  String get resultCausesTitle => 'Вероятные причины';

  @override
  String get causeCondensation => 'Вероятно, конденсат';

  @override
  String get causeLeak => 'Вероятно, протечка';

  @override
  String get causeStructural => 'Вероятно, сырость в конструкции';

  @override
  String get causeUnclear => 'По ответам причина неясна';

  @override
  String get resultDisclaimer =>
      'Это совет, а не гарантия. Если вы беспокоитесь, обратитесь к специалисту.';

  @override
  String get resultRulesUnreviewed =>
      'Эти проверки ещё ждут проверки экспертом.';

  @override
  String get resultOpenEmergency => 'Открыть экстренные шаги';

  @override
  String get evidenceTitle => 'Журнал доказательств';

  @override
  String get evidenceEmpty => 'Пока пусто. Добавьте фото или заметку.';

  @override
  String get evidenceAdd => 'Добавить';

  @override
  String get evidenceAddPhoto => 'Фото';

  @override
  String get evidenceAddNote => 'Заметка';

  @override
  String get evidenceAddSymptom => 'Симптом';

  @override
  String get evidenceNoteHint => 'Что произошло?';

  @override
  String get evidenceSymptomHint => 'Кто что почувствовал и когда?';

  @override
  String get evidencePhotoCaption => 'Подпись (необязательно)';

  @override
  String get evidenceVerified => 'Подтверждено';

  @override
  String get evidencePending => 'Подтверждается…';

  @override
  String get evidenceVerifiedHint =>
      'Сервер записал время и отпечаток (хеш) этой записи. Любое изменение не совпадёт.';

  @override
  String evidenceServerTime(String time) {
    return 'Записано: $time';
  }

  @override
  String get evidenceHash => 'Отпечаток (SHA-256)';

  @override
  String get evidenceDelete => 'Убрать из журнала';

  @override
  String get evidenceDeleteConfirm =>
      'Убрать эту запись? Она будет скрыта из журнала и отчётов, но останется в истории.';

  @override
  String get evidenceTypePhoto => 'Фото';

  @override
  String get evidenceTypeNote => 'Заметка';

  @override
  String get evidenceTypeSymptom => 'Симптом';

  @override
  String get evidenceTypeCheck => 'Результат проверки';

  @override
  String get evidenceTypeLetter => 'Письмо';

  @override
  String get evidenceMakeReport => 'Сделать отчёт';

  @override
  String get evidenceUploading => 'Загрузка…';

  @override
  String get reportTitle => 'Сделать отчёт';

  @override
  String get reportIntro =>
      'В PDF будут данные о доме, результаты проверок и доказательства с временем и отпечатками.';

  @override
  String get reportFrom => 'С';

  @override
  String get reportTo => 'По';

  @override
  String get reportGenerate => 'Создать PDF';

  @override
  String get reportGenerating => 'Отчёт создаётся…';

  @override
  String get reportReady => 'Ваш отчёт готов.';

  @override
  String get reportOpen => 'Открыть отчёт';

  @override
  String get reportLinkExpires => 'Ссылка действует 15 минут.';

  @override
  String get lettersTitle => 'Письма';

  @override
  String get letterNew => 'Новое письмо';

  @override
  String get lettersEmpty => 'Писем пока нет.';

  @override
  String get letterProblem => 'В чём проблема?';

  @override
  String get problemGasHeater => 'Газовый обогреватель';

  @override
  String get problemCoAlarm => 'Нет датчика CO';

  @override
  String get problemDamp => 'Сырость или плесень';

  @override
  String get problemLeak => 'Протечка';

  @override
  String get problemOther => 'Другое';

  @override
  String get letterRecipient => 'Кому письмо?';

  @override
  String get recipientLandlord => 'Арендодатель';

  @override
  String get recipientBuildingManager => 'Управление домом';

  @override
  String get recipientAzerigaz => 'Азеригаз';

  @override
  String get recipientOther => 'Другое';

  @override
  String get letterLanguage => 'Язык письма';

  @override
  String get letterYourName => 'Ваше имя';

  @override
  String get letterAddress => 'Адрес жилья';

  @override
  String get letterRecipientName => 'Имя получателя (необязательно)';

  @override
  String get letterDescription => 'Опишите проблему в нескольких словах';

  @override
  String get letterSince => 'С какого времени?';

  @override
  String get letterPolish => 'Улучшить текст с ИИ (факты не меняются)';

  @override
  String get letterPreview => 'Предпросмотр';

  @override
  String get letterCopy => 'Копировать';

  @override
  String get letterCopied => 'Скопировано';

  @override
  String get letterShare => 'Поделиться';

  @override
  String get letterSavePdf => 'Сохранить как PDF';

  @override
  String get letterSavedToLog => 'Письмо добавлено в журнал доказательств.';

  @override
  String get letterGenerating => 'Письмо готовится…';

  @override
  String get letterFieldRequired => 'Пожалуйста, заполните.';

  @override
  String get rightsTitle => 'Ваши права';

  @override
  String get rightsNotice => 'Общая информация, а не юридическая консультация.';

  @override
  String get rightsLawReference => 'Закон';

  @override
  String rightsReviewedBy(String name, String date) {
    return 'Проверено: $name, $date';
  }

  @override
  String get rightsNotReviewed => 'Ожидает проверки юристом.';

  @override
  String get rightsPending => 'Эта тема готовится и проверяется юристом.';

  @override
  String get chatTitle => 'Спросить HomeSafe';

  @override
  String get chatNotice =>
      'Ответы — совет, а не гарантия. В экстренной ситуации нажмите красную кнопку.';

  @override
  String get chatWelcome =>
      'Спросите про газовые обогреватели, CO, сырость, плесень или ваши права.';

  @override
  String get chatHint => 'Напишите вопрос';

  @override
  String get chatSend => 'Отправить';

  @override
  String get chatAttachPhoto => 'Добавить фото';

  @override
  String get chatRemovePhoto => 'Убрать фото';

  @override
  String get chatEmergencyDetected =>
      'Похоже на экстренную ситуацию. Следуйте экстренным шагам. Сообщение не отправлено.';

  @override
  String get chatRateLimited =>
      'Вы достигли лимита 30 сообщений на сегодня. Попробуйте завтра.';

  @override
  String get chatError =>
      'Не удалось получить ответ. Проверьте интернет и попробуйте снова.';

  @override
  String get chatEmergencyMentioned => 'В этом ответе есть экстренные шаги.';

  @override
  String get chatThinking => 'Думаю…';

  @override
  String get chatYou => 'Вы';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsHome => 'Ваш дом';

  @override
  String get settingsNotifications => 'Сезонные напоминания';

  @override
  String get settingsNotificationsBody =>
      'Напоминание раз в месяц с октября по апрель.';

  @override
  String get settingsExport => 'Выгрузить все мои данные';

  @override
  String get settingsExportWorking => 'Данные готовятся…';

  @override
  String get settingsExportReady => 'Данные готовы. Ссылка действует 15 минут.';

  @override
  String get settingsDownload => 'Скачать';

  @override
  String get settingsDelete => 'Удалить аккаунт и данные';

  @override
  String get settingsDeleteConfirmTitle => 'Удалить всё?';

  @override
  String get settingsDeleteConfirmBody =>
      'Будут удалены аккаунт, дома, проверки, доказательства, фото и письма. Это нельзя отменить.';

  @override
  String get settingsDeleteConfirm => 'Удалить';

  @override
  String get settingsDeleted => 'Аккаунт и данные удалены.';

  @override
  String get settingsPrivacy => 'Политика конфиденциальности';

  @override
  String get settingsTerms => 'Условия использования';

  @override
  String get settingsAbout => 'О приложении';

  @override
  String get settingsSignOut => 'Выйти';

  @override
  String settingsSignedInAs(String id) {
    return 'Вы вошли как $id';
  }

  @override
  String get settingsGuest => 'Без аккаунта';

  @override
  String get aboutBody =>
      'HomeSafe помогает жителям Баку находить и устранять опасности дома. Это советы, а не гарантии.';

  @override
  String aboutVersion(String version) {
    return 'Версия $version';
  }

  @override
  String get signInModeSignIn => 'У меня есть аккаунт';

  @override
  String get signInModeCreate => 'Я здесь впервые';

  @override
  String get passwordHint => 'Не менее 8 символов';

  @override
  String get showPassword => 'Показать пароль';

  @override
  String get hidePassword => 'Скрыть пароль';

  @override
  String get forgotPassword => 'Забыли пароль?';

  @override
  String get resetEmailSent =>
      'Мы отправили ссылку для сброса пароля. Проверьте почту.';

  @override
  String get authErrorEmailInUse => 'На эту почту уже есть аккаунт. Войдите.';

  @override
  String get authErrorInvalidEmail => 'Проверьте адрес почты.';

  @override
  String get emergencyBannerSub => 'Запах газа, сигнал CO или кому-то плохо';

  @override
  String get dashboardStatusTitle => 'Безопасность вашего дома';

  @override
  String get dashboardToolsTitle => 'Инструменты';

  @override
  String get statusNotChecked => 'Ещё не проверено';

  @override
  String statusCheckedOn(String date) {
    return 'Проверено: $date';
  }

  @override
  String get statusStart => 'Начать';

  @override
  String get statusAgain => 'Проверить снова';

  @override
  String get checkMinutes => 'Около 2 минут';

  @override
  String get historyTitle => 'История проверок';

  @override
  String get historyEmpty =>
      'Проверок пока нет. Здесь появятся ваши результаты.';

  @override
  String get historyOnDevice =>
      'Хранится только на этом телефоне. Чтобы сохранить в аккаунте, добавьте результат в журнал доказательств.';

  @override
  String get viewAll => 'Смотреть все';

  @override
  String get resultWriteLetter => 'Написать письмо об этом';

  @override
  String get signInWelcome => 'С возвращением';

  @override
  String get signInCreateTitle => 'Создайте аккаунт';

  @override
  String get orDivider => 'или';

  @override
  String get tipTitle => 'Совет по безопасности';

  @override
  String get chatSuggestTitle => 'Например, спросите';

  @override
  String get chatSuggest1 => 'По утрам у меня мокрые окна. Что делать?';

  @override
  String get chatSuggest2 => 'Как часто нужно проверять газовый котёл?';

  @override
  String get chatSuggest3 => 'Куда лучше поставить датчик CO?';

  @override
  String get chatAssistantUnavailable =>
      'Помощник сейчас недоступен. Попробуйте позже.';

  @override
  String get rightsDraft =>
      'Черновик: ещё не проверен юристом. Используйте только как общий ориентир.';

  @override
  String get rightsDraftBadge => 'Черновик';

  @override
  String get rightsSources => 'Источники';

  @override
  String get legalDocDraft =>
      'Черновик: юрист доработает этот текст до запуска.';

  @override
  String get signInAgree =>
      'Создавая аккаунт, вы соглашаетесь с Условиями использования и Политикой конфиденциальности.';

  @override
  String get settingsAccount => 'Аккаунт';

  @override
  String get settingsApp => 'Приложение';

  @override
  String get settingsYourData => 'Ваши данные';

  @override
  String get settingsLegal => 'Правовая информация';

  @override
  String get demoBanner =>
      'Онлайн-демо: здесь работают экстренный экран, проверки безопасности, история и «Ваши права». Аккаунты, журнал доказательств, письма, отчёты и ИИ-помощник требуют сервера HomeSafe и отключены.';

  @override
  String get demoFeatureOff =>
      'Этой функции нужен сервер HomeSafe, поэтому в онлайн-демо она отключена.';

  @override
  String get demoAccount => 'Онлайн-демо: аккаунт не нужен';
}
