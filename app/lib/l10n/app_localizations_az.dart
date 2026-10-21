// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Azerbaijani (`az`).
class AppLocalizationsAz extends AppLocalizations {
  AppLocalizationsAz([String locale = 'az']) : super(locale);

  @override
  String get appTitle => 'HomeSafe';

  @override
  String get continueLabel => 'Davam et';

  @override
  String get back => 'Geri';

  @override
  String get cancel => 'Ləğv et';

  @override
  String get save => 'Yadda saxla';

  @override
  String get close => 'Bağla';

  @override
  String get done => 'Hazırdır';

  @override
  String get next => 'Növbəti';

  @override
  String get yes => 'Bəli';

  @override
  String get no => 'Xeyr';

  @override
  String get notSure => 'Əmin deyiləm';

  @override
  String get retry => 'Yenidən cəhd et';

  @override
  String get loading => 'Yüklənir…';

  @override
  String get errorGeneric => 'Xəta baş verdi. Yenidən cəhd edin.';

  @override
  String get offlineNotice =>
      'İnternet yoxdur. Bəzi funksiyalar üçün internet lazımdır.';

  @override
  String get signInRequired => 'Bundan istifadə etmək üçün daxil olun.';

  @override
  String get signIn => 'Daxil ol';

  @override
  String get backendUnavailable =>
      'Bu funksiya hazırda əlçatan deyil. Sonra yenidən cəhd edin.';

  @override
  String get emergencyButton => 'Təcili';

  @override
  String get emergencyButtonHint =>
      'Təcili addımları və telefon nömrələrini açır';

  @override
  String get emergencyTitle => 'Təcili vəziyyət';

  @override
  String get emergencyIntro =>
      'Qaz iyi gəlirsə, CO siqnalı çalırsa və ya kiminsə başı hərlənirsə, ürəyi bulanırsa, huşunu itirirsə:';

  @override
  String get emergencyStep1 => 'Hamını dərhal çölə çıxarın. Qapını açıq qoyun.';

  @override
  String get emergencyStep2 =>
      'İşıq açarlarına, rozetkalara və alovlu əşyalara toxunmayın. İçəridən zəng etməyin.';

  @override
  String get emergencyStep3 => 'Binadan çıxdıqdan sonra kömək üçün zəng edin.';

  @override
  String get emergencyStep4 =>
      'Qaz xidməti təhlükəsiz olduğunu deyənə qədər geri qayıtmayın.';

  @override
  String get emergencyStep5 =>
      'Özünüzü yaxşı hiss etsəniz belə, həkimə müraciət edin. Qaz və ya dəm qazı ilə nəfəs aldığınızı deyin.';

  @override
  String get emergencyCallSection => 'Kömək çağırın';

  @override
  String emergencyCall(String name, String number) {
    return '$name – $number nömrəsinə zəng et';
  }

  @override
  String emergencyCallFailed(String number) {
    return 'Zəng başlamadı. $number nömrəsini özünüz yığın.';
  }

  @override
  String get emergencyNumbersUnverified =>
      'TƏRTİBATÇI QEYDİ: bu təcili nömrələr hələ yoxlanılmayıb.';

  @override
  String get emergencyImSafe => 'Mən artıq təhlükəsizəm';

  @override
  String get onboardingWhatTitle => 'Daha təhlükəsiz ev';

  @override
  String get onboardingWhatBody =>
      'HomeSafe qaz qızdırıcılarını, dəm qazını, rütubəti və kifi yoxlamağa kömək edir. Problemləri qeyd etməyə və təmir tələb etməyə kömək edir.';

  @override
  String get onboardingSafetyTitle => 'Vacibdir';

  @override
  String get onboardingSafetyBody =>
      'Bu tətbiq zəmanət deyil, məsləhət verir. Təcili vəziyyətdə kömək çağırın.';

  @override
  String get onboardingSafetyAccept => 'Başa düşdüm';

  @override
  String get onboardingLanguageTitle => 'Dili seçin';

  @override
  String get onboardingStart => 'Başla';

  @override
  String get languageAz => 'Azərbaycanca';

  @override
  String get languageRu => 'Русский';

  @override
  String get languageEn => 'English';

  @override
  String get changeLanguage => 'Dili dəyiş';

  @override
  String get signInTitle => 'Daxil olun';

  @override
  String get signInWhy =>
      'Hesab sübut jurnalınızı qoruyur, hesabat və məktub yaratmağa imkan verir. E-poçtunuzdan istifadə edin.';

  @override
  String get emailLabel => 'E-poçt';

  @override
  String get passwordLabel => 'Şifrə';

  @override
  String get signInEmail => 'Daxil ol';

  @override
  String get createAccount => 'Hesab yarat';

  @override
  String get tryWithoutAccount => 'Hesabsız sına';

  @override
  String get guestNotice =>
      'Hesabsız yoxlamaları edə bilərsiniz, amma sübutları saxlaya bilməzsiniz.';

  @override
  String get authErrorEmail => 'E-poçtu və şifrəni yoxlayın.';

  @override
  String get authErrorWeakPassword => 'Ən azı 8 simvol istifadə edin.';

  @override
  String get profileTitle => 'Eviniz';

  @override
  String get profileIntro =>
      'Eviniz haqqında bir neçə məlumat yoxlamaları daha dəqiq edir.';

  @override
  String get profileRole => 'Evi kirayə götürmüsünüz, yoxsa sizindir?';

  @override
  String get roleRenter => 'Kirayədə qalıram';

  @override
  String get roleOwner => 'Ev mənimdir';

  @override
  String get profileDistrict => 'Rayon';

  @override
  String get profileBuildingAge => 'Bina nə vaxt tikilib?';

  @override
  String get ageBefore1960 => '1960-dan əvvəl';

  @override
  String get age1960to1990 => '1960–1990';

  @override
  String get age1991to2010 => '1991–2010';

  @override
  String get ageAfter2010 => '2010-dan sonra';

  @override
  String get profileHeating => 'Eviniz necə qızdırılır?';

  @override
  String get heatingIndividualGas => 'Otaqda qaz qızdırıcısı';

  @override
  String get heatingGasBoiler => 'Qaz qazanı (kombi)';

  @override
  String get heatingCentral => 'Mərkəzi istilik';

  @override
  String get heatingElectric => 'Elektrik';

  @override
  String get heatingOther => 'Digər';

  @override
  String get profileWaterHeater => 'Qaz su qızdırıcınız (kolonka) haradadır?';

  @override
  String get waterHeaterBathroom => 'Vanna otağı';

  @override
  String get waterHeaterKitchen => 'Mətbəx';

  @override
  String get waterHeaterOther => 'Başqa otaq';

  @override
  String get waterHeaterNone => 'Yoxdur';

  @override
  String get profileCoAlarm => 'Dəm qazı (CO) siqnalizatorunuz var?';

  @override
  String get profileContract => 'Yazılı kirayə müqaviləniz var?';

  @override
  String get profileSaved => 'Yadda saxlanıldı';

  @override
  String get cardGasTitle => 'Qaz və CO yoxlaması';

  @override
  String get cardGasBody => 'Qızdırıcılar və hava haqqında qısa suallar.';

  @override
  String get cardDampTitle => 'Rütubət və kif yoxlaması';

  @override
  String get cardDampBody => 'Səbəbi tapmaq üçün şəkillər və suallar.';

  @override
  String get cardEvidenceTitle => 'Sübut jurnalı';

  @override
  String get cardEvidenceBody => 'Tarixi təsdiqlənmiş şəkillər və qeydlər.';

  @override
  String get cardLettersTitle => 'Məktublar';

  @override
  String get cardLettersBody => 'Təmir və ya yoxlama tələb edin.';

  @override
  String get cardRightsTitle => 'Hüquqlarınız';

  @override
  String get cardRightsBody => 'Sadə dildə hüquqi məlumat.';

  @override
  String get cardAskTitle => 'HomeSafe-dən soruş';

  @override
  String get cardAskBody => 'Eviniz haqqında suallar.';

  @override
  String get seasonalTitle => 'İstilik mövsümü';

  @override
  String get seasonalBody =>
      'CO siqnalizatorunu yoxlayın, ventilyasiya dəliklərini açıq saxlayın.';

  @override
  String get settingsTooltip => 'Ayarlar';

  @override
  String get profileMissing =>
      'Daha dəqiq nəticə üçün eviniz haqqında məlumat verin.';

  @override
  String get profileSetUp => 'Doldur';

  @override
  String get checkGasTitle => 'Qaz və CO yoxlaması';

  @override
  String get checkDampTitle => 'Rütubət və kif yoxlaması';

  @override
  String questionProgress(int current, int total) {
    return 'Sual $current / $total';
  }

  @override
  String get checkSeeResult => 'Nəticəyə bax';

  @override
  String get photosTitle => 'Rütubətin və ya kifin şəklini əlavə edin';

  @override
  String get photosBody =>
      '1-dən 5-ə qədər şəkil əlavə edin. Onlar gizli qalır.';

  @override
  String get takePhoto => 'Şəkil çək';

  @override
  String get choosePhoto => 'Qalereyadan seç';

  @override
  String get removePhoto => 'Şəkli sil';

  @override
  String photoLabel(int number) {
    return 'Şəkil $number';
  }

  @override
  String get multiSelectNone => 'Heç biri';

  @override
  String get resultTitle => 'Nəticə';

  @override
  String get levelRed => 'Təcili';

  @override
  String get levelAmber => 'Ciddi';

  @override
  String get levelGreen => 'Nəzarətdə saxlayın';

  @override
  String get levelRedHint => 'İndi tədbir görün.';

  @override
  String get levelAmberHint => 'Tezliklə düzəldin.';

  @override
  String get levelGreenHint => 'Diqqətdə saxlayın.';

  @override
  String get resultWhy => 'Niyə';

  @override
  String get resultNextSteps => 'Nə etməli';

  @override
  String get resultSaveToEvidence => 'Sübut jurnalına saxla';

  @override
  String get resultSaved => 'Sübut jurnalına saxlanıldı.';

  @override
  String get resultAskAssistant => 'Bu barədə HomeSafe-dən soruş';

  @override
  String get resultCausesTitle => 'Ehtimal olunan səbəblər';

  @override
  String get causeCondensation => 'Ehtimal ki, kondensasiya';

  @override
  String get causeLeak => 'Ehtimal ki, sızma';

  @override
  String get causeStructural => 'Ehtimal ki, tikinti rütubəti';

  @override
  String get causeUnclear => 'Cavablara görə aydın səbəb yoxdur';

  @override
  String get resultDisclaimer =>
      'Bu zəmanət deyil, məsləhətdir. Narahatsınızsa, mütəxəssisə müraciət edin.';

  @override
  String get resultRulesUnreviewed =>
      'Bu yoxlamalar hələ ekspert tərəfindən yoxlanılmayıb.';

  @override
  String get resultOpenEmergency => 'Təcili addımları aç';

  @override
  String get evidenceTitle => 'Sübut jurnalı';

  @override
  String get evidenceEmpty =>
      'Hələ heç nə yoxdur. Şəkil və ya qeyd əlavə edin.';

  @override
  String get evidenceAdd => 'Əlavə et';

  @override
  String get evidenceAddPhoto => 'Şəkil';

  @override
  String get evidenceAddNote => 'Qeyd';

  @override
  String get evidenceAddSymptom => 'Simptom';

  @override
  String get evidenceNoteHint => 'Nə baş verdi?';

  @override
  String get evidenceSymptomHint => 'Kim nə hiss etdi və nə vaxt?';

  @override
  String get evidencePhotoCaption => 'Açıqlama (istəyə görə)';

  @override
  String get evidenceVerified => 'Təsdiqlənib';

  @override
  String get evidencePending => 'Təsdiqlənir…';

  @override
  String get evidenceVerifiedHint =>
      'Server bu qeydin vaxtını və barmaq izini (hash) yazıb. Sonradan dəyişiklik uyğun gəlməz.';

  @override
  String evidenceServerTime(String time) {
    return 'Qeyd olunub: $time';
  }

  @override
  String get evidenceHash => 'Barmaq izi (SHA-256)';

  @override
  String get evidenceDelete => 'Jurnaldan çıxar';

  @override
  String get evidenceDeleteConfirm =>
      'Bu qeyd çıxarılsın? O, jurnal və hesabatlardan gizlədiləcək. Tarixçədə qalacaq.';

  @override
  String get evidenceTypePhoto => 'Şəkil';

  @override
  String get evidenceTypeNote => 'Qeyd';

  @override
  String get evidenceTypeSymptom => 'Simptom';

  @override
  String get evidenceTypeCheck => 'Yoxlama nəticəsi';

  @override
  String get evidenceTypeLetter => 'Məktub';

  @override
  String get evidenceMakeReport => 'Hesabat hazırla';

  @override
  String get evidenceUploading => 'Yüklənir…';

  @override
  String get reportTitle => 'Hesabat hazırla';

  @override
  String get reportIntro =>
      'PDF-də ev məlumatları, yoxlama nəticələri və vaxt və barmaq izləri ilə sübutlar olacaq.';

  @override
  String get reportFrom => 'Başlanğıc';

  @override
  String get reportTo => 'Son';

  @override
  String get reportGenerate => 'PDF yarat';

  @override
  String get reportGenerating => 'Hesabat hazırlanır…';

  @override
  String get reportReady => 'Hesabatınız hazırdır.';

  @override
  String get reportOpen => 'Hesabatı aç';

  @override
  String get reportLinkExpires => 'Keçid 15 dəqiqə işləyir.';

  @override
  String get lettersTitle => 'Məktublar';

  @override
  String get letterNew => 'Yeni məktub';

  @override
  String get lettersEmpty => 'Hələ məktub yoxdur.';

  @override
  String get letterProblem => 'Problem nədir?';

  @override
  String get problemGasHeater => 'Qaz qızdırıcısı';

  @override
  String get problemCoAlarm => 'CO siqnalizatoru yoxdur';

  @override
  String get problemDamp => 'Rütubət və ya kif';

  @override
  String get problemLeak => 'Sızma';

  @override
  String get problemOther => 'Digər';

  @override
  String get letterRecipient => 'Kimə ünvanlanır?';

  @override
  String get recipientLandlord => 'Ev sahibi';

  @override
  String get recipientBuildingManager => 'Bina idarəsi';

  @override
  String get recipientAzerigaz => 'Azəriqaz';

  @override
  String get recipientOther => 'Digər';

  @override
  String get letterLanguage => 'Məktubun dili';

  @override
  String get letterYourName => 'Adınız';

  @override
  String get letterAddress => 'Evin ünvanı';

  @override
  String get letterRecipientName => 'Alıcının adı (istəyə görə)';

  @override
  String get letterDescription => 'Problemi bir neçə sözlə təsvir edin';

  @override
  String get letterSince => 'Nə vaxtdan?';

  @override
  String get letterPolish => 'Mətni Sİ ilə yaxşılaşdır (faktlar dəyişmir)';

  @override
  String get letterPreview => 'Önizləmə';

  @override
  String get letterCopy => 'Kopyala';

  @override
  String get letterCopied => 'Kopyalandı';

  @override
  String get letterShare => 'Paylaş';

  @override
  String get letterSavePdf => 'PDF kimi saxla';

  @override
  String get letterSavedToLog => 'Məktub sübut jurnalına əlavə edildi.';

  @override
  String get letterGenerating => 'Məktub hazırlanır…';

  @override
  String get letterFieldRequired => 'Zəhmət olmasa doldurun.';

  @override
  String get rightsTitle => 'Hüquqlarınız';

  @override
  String get rightsNotice => 'Ümumi məlumatdır, hüquqi məsləhət deyil.';

  @override
  String get rightsLawReference => 'Qanun';

  @override
  String rightsReviewedBy(String name, String date) {
    return '$name tərəfindən $date tarixində yoxlanılıb';
  }

  @override
  String get rightsNotReviewed => 'Hüquqşünasın yoxlamasını gözləyir.';

  @override
  String get rightsPending =>
      'Bu mövzu hazırlanır və hüquqşünas tərəfindən yoxlanılır.';

  @override
  String get chatTitle => 'HomeSafe-dən soruş';

  @override
  String get chatNotice =>
      'Cavablar zəmanət deyil, məsləhətdir. Təcili vəziyyətdə qırmızı düyməni basın.';

  @override
  String get chatWelcome =>
      'Qaz qızdırıcıları, CO, rütubət, kif və ya hüquqlarınız haqqında soruşun.';

  @override
  String get chatHint => 'Sualınızı yazın';

  @override
  String get chatSend => 'Göndər';

  @override
  String get chatAttachPhoto => 'Şəkil əlavə et';

  @override
  String get chatRemovePhoto => 'Şəkli sil';

  @override
  String get chatEmergencyDetected =>
      'Bu təcili vəziyyətə bənzəyir. Dərhal təcili addımlara əməl edin. Mesajınız göndərilmədi.';

  @override
  String get chatRateLimited =>
      'Bugünkü 30 mesaj limitinə çatdınız. Sabah yenidən cəhd edin.';

  @override
  String get chatError =>
      'Cavab alınmadı. İnterneti yoxlayıb yenidən cəhd edin.';

  @override
  String get chatEmergencyMentioned => 'Bu cavabda təcili addımlar var.';

  @override
  String get chatThinking => 'Düşünür…';

  @override
  String get chatYou => 'Siz';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsLanguage => 'Dil';

  @override
  String get settingsHome => 'Eviniz';

  @override
  String get settingsNotifications => 'Mövsümi xatırlatmalar';

  @override
  String get settingsNotificationsBody =>
      'Oktyabrdan apreldək ayda bir xatırlatma.';

  @override
  String get settingsExport => 'Bütün məlumatlarımı ixrac et';

  @override
  String get settingsExportWorking => 'Məlumatlarınız hazırlanır…';

  @override
  String get settingsExportReady =>
      'Məlumatlarınız hazırdır. Keçid 15 dəqiqə işləyir.';

  @override
  String get settingsDownload => 'Yüklə';

  @override
  String get settingsDelete => 'Hesabımı və məlumatlarımı sil';

  @override
  String get settingsDeleteConfirmTitle => 'Hər şey silinsin?';

  @override
  String get settingsDeleteConfirmBody =>
      'Bu, hesabınızı, evlərinizi, yoxlamaları, sübutları, şəkilləri və məktubları silir. Geri qaytarmaq olmaz.';

  @override
  String get settingsDeleteConfirm => 'Sil';

  @override
  String get settingsDeleted => 'Hesabınız və məlumatlarınız silindi.';

  @override
  String get settingsPrivacy => 'Məxfilik siyasəti';

  @override
  String get settingsTerms => 'İstifadə şərtləri';

  @override
  String get settingsAbout => 'Haqqında';

  @override
  String get settingsSignOut => 'Çıxış';

  @override
  String settingsSignedInAs(String id) {
    return '$id kimi daxil olmusunuz';
  }

  @override
  String get settingsGuest => 'Hesabsız istifadə';

  @override
  String get aboutBody =>
      'HomeSafe Bakıda insanlara evdəki təhlükələri tapmağa və aradan qaldırmağa kömək edir. Zəmanət deyil, məsləhət verir.';

  @override
  String aboutVersion(String version) {
    return 'Versiya $version';
  }

  @override
  String get signInModeSignIn => 'Hesabım var';

  @override
  String get signInModeCreate => 'Mən yeniyəm';

  @override
  String get passwordHint => 'Ən azı 8 simvol';

  @override
  String get showPassword => 'Şifrəni göstər';

  @override
  String get hidePassword => 'Şifrəni gizlət';

  @override
  String get forgotPassword => 'Şifrəni unutmusunuz?';

  @override
  String get resetEmailSent =>
      'Şifrəni yeniləmək üçün e-poçtunuza keçid göndərdik.';

  @override
  String get authErrorEmailInUse => 'Bu e-poçtla artıq hesab var. Daxil olun.';

  @override
  String get authErrorInvalidEmail => 'E-poçt ünvanını yoxlayın.';

  @override
  String get emergencyBannerSub =>
      'Qaz iyi, CO siqnalı və ya kimsə özünü pis hiss edir';

  @override
  String get dashboardStatusTitle => 'Evinizin təhlükəsizliyi';

  @override
  String get dashboardToolsTitle => 'Alətlər';

  @override
  String get statusNotChecked => 'Hələ yoxlanılmayıb';

  @override
  String statusCheckedOn(String date) {
    return 'Yoxlanılıb: $date';
  }

  @override
  String get statusStart => 'Başla';

  @override
  String get statusAgain => 'Yenidən yoxla';

  @override
  String get checkMinutes => 'Təxminən 2 dəqiqə';

  @override
  String get historyTitle => 'Yoxlama tarixçəsi';

  @override
  String get historyEmpty =>
      'Hələ yoxlama yoxdur. Nəticələriniz burada görünəcək.';

  @override
  String get historyOnDevice =>
      'Yalnız bu telefonda saxlanılır. Hesabınızda saxlamaq üçün nəticəni sübut jurnalına əlavə edin.';

  @override
  String get viewAll => 'Hamısına bax';

  @override
  String get resultWriteLetter => 'Bu barədə məktub yaz';

  @override
  String get signInWelcome => 'Xoş gəlmisiniz';

  @override
  String get signInCreateTitle => 'Hesabınızı yaradın';

  @override
  String get orDivider => 'və ya';

  @override
  String get tipTitle => 'Təhlükəsizlik məsləhəti';

  @override
  String get chatSuggestTitle => 'Belə soruşa bilərsiniz';

  @override
  String get chatSuggest1 => 'Səhərlər pəncərələrim yaş olur. Nə etməliyəm?';

  @override
  String get chatSuggest2 => 'Qaz qazanı nə qədər tez-tez yoxlanılmalıdır?';

  @override
  String get chatSuggest3 => 'CO siqnalizatorunu harada quraşdırmalıyam?';

  @override
  String get chatAssistantUnavailable =>
      'Köməkçi hazırda əlçatan deyil. Bir az sonra yenidən cəhd edin.';

  @override
  String get rightsDraft =>
      'Qaralama: hələ hüquqşünas tərəfindən yoxlanılmayıb. Yalnız ümumi istiqamət kimi istifadə edin.';

  @override
  String get rightsDraftBadge => 'Qaralama';

  @override
  String get rightsSources => 'Mənbələr';

  @override
  String get legalDocDraft =>
      'Qaralama: bu mətn istifadəyə verilməzdən əvvəl hüquqşünas tərəfindən yekunlaşdırılacaq.';

  @override
  String get signInAgree =>
      'Hesab yaratmaqla İstifadə şərtləri və Məxfilik siyasəti ilə razılaşırsınız.';

  @override
  String get settingsAccount => 'Hesab';

  @override
  String get settingsApp => 'Tətbiq';

  @override
  String get settingsYourData => 'Məlumatlarınız';

  @override
  String get settingsLegal => 'Hüquqi';
}
