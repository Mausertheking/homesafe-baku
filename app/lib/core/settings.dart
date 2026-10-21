import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in main() with the loaded instance, so reads are synchronous.
final sharedPreferencesProvider =
    Provider<SharedPreferences>((ref) => throw UnimplementedError('loaded in main'));

class AppSettings {
  const AppSettings({
    required this.language,
    required this.onboardingDone,
    required this.guestMode,
    required this.notificationsEnabled,
  });

  /// One of az (default), ru, en.
  final String language;
  final bool onboardingDone;

  /// "Try without account": checks work, evidence log does not.
  final bool guestMode;
  final bool notificationsEnabled;

  AppSettings copyWith({String? language, bool? onboardingDone, bool? guestMode, bool? notificationsEnabled}) =>
      AppSettings(
        language: language ?? this.language,
        onboardingDone: onboardingDone ?? this.onboardingDone,
        guestMode: guestMode ?? this.guestMode,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      );
}

class SettingsController extends Notifier<AppSettings> {
  static const _kLanguage = 'settings.language';
  static const _kOnboarding = 'settings.onboardingDone';
  static const _kGuest = 'settings.guestMode';
  static const _kNotifications = 'settings.notifications';
  static const supportedLanguages = ['az', 'ru', 'en'];

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final lang = prefs.getString(_kLanguage);
    return AppSettings(
      language: supportedLanguages.contains(lang) ? lang! : 'az',
      onboardingDone: prefs.getBool(_kOnboarding) ?? false,
      guestMode: prefs.getBool(_kGuest) ?? false,
      notificationsEnabled: prefs.getBool(_kNotifications) ?? true,
    );
  }

  Future<void> setLanguage(String language) async {
    assert(supportedLanguages.contains(language));
    state = state.copyWith(language: language);
    await _prefs.setString(_kLanguage, language);
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(onboardingDone: true);
    await _prefs.setBool(_kOnboarding, true);
  }

  Future<void> setGuestMode(bool value) async {
    state = state.copyWith(guestMode: value);
    await _prefs.setBool(_kGuest, value);
  }

  Future<void> setNotifications(bool value) async {
    state = state.copyWith(notificationsEnabled: value);
    await _prefs.setBool(_kNotifications, value);
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
