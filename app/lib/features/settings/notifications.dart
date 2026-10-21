import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firebase_bootstrap.dart';
import '../../core/settings.dart';

/// Seasonal reminders go to an FCM topic per language (seasonal_az, ...).
/// Topics mean the server never stores device tokens or personal data.
final notificationSyncProvider = FutureProvider<void>((ref) async {
  if (!ref.watch(firebaseAvailableProvider) || kIsWeb) return;
  final enabled = ref.watch(settingsProvider.select((s) => s.notificationsEnabled));
  final language = ref.watch(settingsProvider.select((s) => s.language));
  final fcm = FirebaseMessaging.instance;
  try {
    if (enabled) {
      final perm = await fcm.requestPermission();
      if (perm.authorizationStatus == AuthorizationStatus.denied) return;
    }
    for (final lang in SettingsController.supportedLanguages) {
      final topic = 'seasonal_$lang';
      if (enabled && lang == language) {
        await fcm.subscribeToTopic(topic);
      } else {
        await fcm.unsubscribeFromTopic(topic);
      }
    }
  } catch (e) {
    debugPrint('notification topic sync failed: $e');
  }
});
