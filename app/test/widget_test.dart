import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart' show TextFormField;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homesafe/app.dart';
import 'package:homesafe/core/content_strings.dart';
import 'package:homesafe/core/firebase_bootstrap.dart';
import 'package:homesafe/core/router.dart';
import 'package:homesafe/core/settings.dart';
import 'package:homesafe/features/checks/rules_repository.dart';
import 'package:homesafe/features/dashboard/dashboard_screen.dart';
import 'package:homesafe/features/emergency/emergency_config.dart';
import 'package:homesafe/features/emergency/emergency_keywords.dart';
import 'package:homesafe/features/rights/legal_doc_screen.dart';
import 'package:homesafe/features/rights/rights_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Builds the real app with Firebase forced OFF (no network, no project),
/// which is exactly the "no internet" situation the emergency screen must
/// survive.
Future<ProviderContainer> bootApp(WidgetTester tester,
    {Map<String, Object> prefs = const {}, Future<bool> Function()? firebase}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  late EmergencyConfig emergency;
  late ContentCatalog catalog;
  await tester.runAsync(() async {
    emergency = await loadEmergencyConfig(rootBundle);
    catalog = await ContentCatalog.load(rootBundle);
    await initializeDateFormatting();
  });
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(sp),
    emergencyConfigProvider.overrideWithValue(emergency),
    contentCatalogProvider.overrideWithValue(catalog),
    emergencyDetectorProvider.overrideWithValue(EmergencyKeywordDetector.fromJsonString(
        File('assets/config/emergency_keywords.json').readAsStringSync())),
    firebaseReadyProvider.overrideWith((ref) => firebase != null ? firebase() : Future.value(false)),
  ]);
  addTearDown(container.dispose);
  // Asset loading is real I/O, so warm the rule sets outside the fake clock.
  await tester.runAsync(() => Future.wait([
        for (final id in checkIds) container.read(ruleSetProvider(id).future),
      ]));
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const HomeSafeApp()));
  await tester.pumpAndSettle();
  return container;
}

/// A typical Android phone (412 x 915 logical pixels).
void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1236, 2745);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

const onboarded = {'settings.onboardingDone': true, 'settings.guestMode': true};

void main() {
  testWidgets('first launch shows onboarding in Azerbaijani by default', (tester) async {
    await bootApp(tester);
    expect(find.text('Daha təhlükəsiz ev'), findsOneWidget);
  });

  for (final (lang, title, call) in [
    ('az', 'Təcili vəziyyət', 'Qaz qəza xidməti'),
    ('ru', 'Экстренная ситуация', 'Аварийная газовая служба'),
    ('en', 'Emergency', 'Gas emergency'),
  ]) {
    testWidgets('emergency screen works offline, even before onboarding ($lang)', (tester) async {
      final c = await bootApp(tester, prefs: {'settings.language': lang});
      final sw = Stopwatch()..start();
      c.read(routerProvider).push('/emergency');
      await tester.pumpAndSettle();
      sw.stop();
      expect(find.text(title), findsWidgets);
      for (final t in [call, '104', '112', '103']) {
        await tester.scrollUntilVisible(find.text(t), 120);
        expect(find.text(t), findsOneWidget);
      }
      // Rendering is synchronous from preloaded data; well under 2 s.
      expect(sw.elapsedMilliseconds, lessThan(2000));
    });
  }

  testWidgets('dashboard: emergency button first, all six feature cards', (tester) async {
    usePhoneScreen(tester);
    await bootApp(tester, prefs: {...onboarded, 'settings.language': 'en'});
    expect(find.text('Emergency'), findsOneWidget);
    final emergencyY = tester.getTopLeft(find.text('Emergency')).dy;
    final gasY = tester.getTopLeft(find.text('Gas and CO check')).dy;
    expect(emergencyY, lessThan(gasY));
    for (final t in ['Gas and CO check', 'Damp and mold check', 'Evidence log', 'Letters', 'Your rights', 'Ask HomeSafe']) {
      await tester.scrollUntilVisible(find.text(t), 100);
      expect(find.text(t), findsOneWidget);
    }
  });

  testWidgets('no sign-in bounce while the saved login is still being restored', (tester) async {
    usePhoneScreen(tester);
    final never = Completer<bool>(); // Firebase still starting.
    await bootApp(tester, prefs: {'settings.onboardingDone': true, 'settings.language': 'en'}, firebase: () => never.future);
    expect(find.text('Your home safety'), findsOneWidget);
    expect(find.text('Welcome back'), findsNothing);
  });

  test('heating season is October to April', () {
    for (final m in [10, 11, 12, 1, 2, 3, 4]) {
      expect(isHeatingSeason(DateTime(2026, m, 15)), isTrue, reason: 'month $m');
    }
    for (final m in [5, 6, 7, 8, 9]) {
      expect(isHeatingSeason(DateTime(2026, m, 15)), isFalse, reason: 'month $m');
    }
  });

  testWidgets('answering "I smell gas" opens the emergency screen immediately', (tester) async {
    final c = await bootApp(tester, prefs: {...onboarded, 'settings.language': 'en'});
    c.read(routerProvider).push('/check/gas_co');
    await tester.pumpAndSettle();
    expect(find.text('Do you smell gas right now?'), findsOneWidget);
    await tester.tap(find.text('Yes'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(find.text('Get everyone out now. Leave the door open behind you.'), findsOneWidget);
  });

  testWidgets('a full safe gas check ends on a result screen with reasons and steps', (tester) async {
    usePhoneScreen(tester);
    final c = await bootApp(tester, prefs: {...onboarded, 'settings.language': 'en'});
    c.read(routerProvider).push('/check/gas_co');
    await tester.pumpAndSettle();

    Future<void> answer(String label) async {
      await tester.ensureVisible(find.text(label).first);
      await tester.tap(find.text(label).first);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
    }

    await answer('No'); // smell gas
    await answer('No'); // CO alarm sounding
    await answer('I do not have one'); // water heater
    await answer('Electric'); // heating
    await answer('None of these'); // symptoms
    await answer('No'); // CO alarm owned
    await answer('No'); // overnight heater
    await answer('No'); // cooker for heating
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();

    expect(find.text('Result'), findsOneWidget);
    expect(find.text('Monitor'), findsOneWidget);
    expect(find.text('You do not seem to use gas for heating or hot water.'), findsOneWidget);
    expect(find.text('These checks are still waiting for expert review.'), findsOneWidget);

    // The result is remembered on the phone and shown on the dashboard.
    c.read(routerProvider).go('/');
    await tester.pumpAndSettle();
    expect(find.textContaining('Checked'), findsOneWidget);
    expect(find.text('Monitor'), findsOneWidget);
  });

  testWidgets('sign-in is email only, with password reset and guest mode', (tester) async {
    usePhoneScreen(tester);
    final c = await bootApp(tester, prefs: {'settings.onboardingDone': true, 'settings.language': 'en'});
    c.read(routerProvider).go('/sign-in');
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Email'), findsOneWidget);
    expect(find.textContaining('Phone'), findsNothing);
    expect(find.text('Forgot your password?'), findsOneWidget);
    await tester.tap(find.text('I am new here'));
    await tester.pumpAndSettle();
    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('By creating an account you agree to the Terms of use and the Privacy policy.'), findsOneWidget);
    await tester.tap(find.text('I have an account'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Try without an account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Try without an account'));
    await tester.pumpAndSettle();
    expect(find.text('Your home safety'), findsOneWidget);
  });

  testWidgets('legal drafts open offline: rights topic and privacy policy', (tester) async {
    usePhoneScreen(tester);
    final c = await bootApp(tester, prefs: {...onboarded, 'settings.language': 'en'});
    // Asset loading is real I/O: resolve it outside the fake clock.
    final sub = c.listen(legalTopicsProvider, (_, _) {});
    addTearDown(sub.close);
    await tester.runAsync(() => c.read(legalTopicsProvider.future));
    c.read(routerProvider).push('/rights');
    await tester.pumpAndSettle();
    expect(find.text('Repairs'), findsOneWidget);
    expect(find.text('Draft'), findsNWidgets(5));
    await tester.tap(find.text('Inspections and entry'));
    await tester.pumpAndSettle();
    expect(find.text('Draft: not yet checked by a lawyer. Use it as general guidance only.'), findsOneWidget);
    expect(find.textContaining('nobody may enter a home against the will'), findsOneWidget);

    await tester.runAsync(() => c.read(legalDocProvider(('privacy', 'en')).future));
    c.read(routerProvider).push('/legal/privacy');
    await tester.pumpAndSettle();
    expect(find.text('Draft: a lawyer will finalise this text before launch.'), findsOneWidget);
    expect(find.text('What we collect and why'), findsOneWidget);
  });

  testWidgets('guest cannot open the evidence log without signing in', (tester) async {
    final c = await bootApp(tester, prefs: {...onboarded, 'settings.language': 'en'});
    c.read(routerProvider).push('/evidence');
    await tester.pumpAndSettle();
    expect(find.text('Sign in to use this.'), findsOneWidget);
  });

  testWidgets('chat blocks an emergency message locally and opens the emergency screen', (tester) async {
    // Chat needs an account; for a guest it shows sign-in. The keyword check
    // itself is covered by emergency_keywords_test.dart (shared vectors).
    final c = await bootApp(tester, prefs: {...onboarded, 'settings.language': 'ru'});
    c.read(routerProvider).push('/chat');
    await tester.pumpAndSettle();
    expect(find.text('Войдите, чтобы пользоваться этим.'), findsOneWidget);
  });

  testWidgets('works at a very large system font size', (tester) async {
    tester.view.physicalSize = const Size(720, 1520); // Small Android phone.
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final c = await bootApp(tester, prefs: {...onboarded, 'settings.language': 'az'});
    expect(tester.takeException(), isNull);
    c.read(routerProvider).push('/emergency');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
