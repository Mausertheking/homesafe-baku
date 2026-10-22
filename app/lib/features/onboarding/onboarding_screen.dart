import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics.dart';
import '../../core/demo.dart';
import '../../core/settings.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';

/// Three short screens: what the app does, the safety notice, language.
/// A language button sits in the app bar of every page so people who do
/// not read Azerbaijani (the default) can switch right away.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;

  void _goTo(int page) {
    _pages.animateToPage(page, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  Future<void> _finish() async {
    final settings = ref.read(settingsProvider);
    ref.read(analyticsProvider).log('onboarding_complete', {'language': settings.language});
    await ref.read(settingsProvider.notifier).completeOnboarding();
    if (mounted) context.go(demoMode ? '/' : '/sign-in');
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(actions: [
        IconButton(
          tooltip: l.changeLanguage,
          icon: const Icon(Icons.translate),
          onPressed: () => _goTo(2),
        ),
        // Reachable even on the very first launch.
        const EmergencyAction(),
      ]),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: PageView(
              controller: _pages,
              onPageChanged: (p) => setState(() => _page = p),
              children: [
                _Page(icon: Icons.home_outlined, title: l.onboardingWhatTitle, body: l.onboardingWhatBody),
                _Page(icon: Icons.health_and_safety_outlined, title: l.onboardingSafetyTitle, body: l.onboardingSafetyBody),
                const _LanguagePage(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 0; i < 3; i++)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _page
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
              ]),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _page < 2 ? () => _goTo(_page + 1) : _finish,
                child: Text(switch (_page) {
                  0 => l.continueLabel,
                  1 => l.onboardingSafetyAccept,
                  _ => l.onboardingStart,
                }),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return PageBody(padding: const EdgeInsets.all(28), children: [
      const SizedBox(height: 24),
      Center(
        child: ExcludeSemantics(
          child: Container(
            width: 168,
            height: 168,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
                child: Icon(icon, size: 60, color: Theme.of(context).colorScheme.onPrimary),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 28),
      Semantics(
        header: true,
        child: Text(title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
      ),
      const SizedBox(height: 16),
      Text(body, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 20)),
    ]);
  }
}

class _LanguagePage extends ConsumerWidget {
  const _LanguagePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return PageBody(padding: const EdgeInsets.all(28), children: [
      const SizedBox(height: 24),
      Semantics(
        header: true,
        child: Text(l.onboardingLanguageTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
      ),
      const SizedBox(height: 24),
      const LanguagePicker(),
    ]);
  }
}

/// Shared by onboarding and settings.
class LanguagePicker extends ConsumerWidget {
  const LanguagePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final current = ref.watch(settingsProvider.select((s) => s.language));
    final names = {'az': l.languageAz, 'ru': l.languageRu, 'en': l.languageEn};
    return RadioGroup<String>(
      groupValue: current,
      onChanged: (v) {
        if (v == null) return;
        ref.read(settingsProvider.notifier).setLanguage(v);
        ref.read(analyticsProvider).log('language_changed', {'language': v});
      },
      child: Column(children: [
        for (final code in SettingsController.supportedLanguages)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RadioListTile<String>(
              value: code,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              tileColor: Theme.of(context).colorScheme.surfaceContainerLowest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: code == current ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant,
                  width: code == current ? 2.5 : 1.5,
                ),
              ),
              title: Text(names[code]!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            ),
          ),
      ]),
    );
  }
}
