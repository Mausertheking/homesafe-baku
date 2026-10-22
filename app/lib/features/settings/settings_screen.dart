import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/callables.dart';
import '../../core/demo.dart';
import '../../core/settings.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_service.dart';
import '../checks/check_history.dart';
import '../home_profile/home_profile.dart';
import '../onboarding/onboarding_screen.dart';

/// App version shown in About. TODO(team): read from package info at release.
const appVersion = '0.1.0';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;

  Future<void> _export() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    messenger.showSnackBar(SnackBar(content: Text(l.settingsExportWorking)));
    try {
      final res = await ref.read(callablesProvider).call('exportMyData', {}, timeout: const Duration(minutes: 5));
      final url = res['url'] as String;
      messenger.showSnackBar(SnackBar(
        duration: const Duration(minutes: 1),
        content: Text(l.settingsExportReady),
        action: SnackBarAction(
            label: l.settingsDownload, onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)),
      ));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.errorGeneric)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(l.settingsDeleteConfirmTitle),
        content: Text(l.settingsDeleteConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: Text(l.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(d, true),
            child: Text(l.settingsDeleteConfirm),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(callablesProvider).call('deleteMyAccount', {}, timeout: const Duration(minutes: 5));
      await ref.read(authServiceProvider).signOut();
      await ref.read(homeProfileProvider.notifier).clearLocal();
      await ref.read(checkHistoryProvider.notifier).clear();
      messenger.showSnackBar(SnackBar(content: Text(l.settingsDeleted)));
      if (mounted) context.go('/sign-in');
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.errorGeneric)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final user = ref.watch(currentUserProvider);

    final scheme = Theme.of(context).colorScheme;
    Widget group(String title, List<Widget> tiles) => Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Semantics(
                header: true,
                child: Text(title.toUpperCase(),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.primary, letterSpacing: 0.8, fontWeight: FontWeight.w800)),
              ),
            ),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
                for (final (i, tile) in tiles.indexed) ...[
                  if (i > 0) const Divider(indent: 56),
                  tile,
                ],
              ]),
            ),
          ]),
        );
    const chevron = Icon(Icons.chevron_right_rounded);

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle), actions: const [EmergencyAction()]),
      body: SafeArea(
        child: PageBody(children: [
          group(l.settingsAccount, [
            ListTile(
              leading: const Icon(Icons.person_outline_rounded),
              title: Text(demoMode
                  ? l.demoAccount
                  : user == null
                      ? l.settingsGuest
                      : l.settingsSignedInAs(user.email ?? '')),
              trailing: demoMode
                  ? null
                  : user == null
                  ? TextButton(onPressed: () => context.push('/sign-in'), child: Text(l.signIn))
                  : TextButton(
                      onPressed: () async {
                        await ref.read(authServiceProvider).signOut();
                        if (context.mounted) context.go('/sign-in');
                      },
                      child: Text(l.settingsSignOut)),
            ),
          ]),
          group(l.settingsLanguage, [
            const Padding(padding: EdgeInsets.fromLTRB(12, 12, 12, 4), child: LanguagePicker()),
          ]),
          group(l.settingsApp, [
            ListTile(
              leading: const Icon(Icons.home_work_outlined),
              title: Text(l.settingsHome),
              trailing: chevron,
              onTap: () => context.push('/profile'),
            ),
            ListTile(
              leading: const Icon(Icons.history_rounded),
              title: Text(l.historyTitle),
              trailing: chevron,
              onTap: () => context.push('/history'),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.notifications_outlined),
              title: Text(l.settingsNotifications),
              subtitle: Text(l.settingsNotificationsBody),
              value: settings.notificationsEnabled,
              onChanged: (v) => ref.read(settingsProvider.notifier).setNotifications(v),
            ),
          ]),
          if (user != null)
            group(l.settingsYourData, [
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: Text(l.settingsExport),
                enabled: !_busy,
                trailing: chevron,
                onTap: _export,
              ),
              ListTile(
                leading: Icon(Icons.delete_forever_outlined, color: scheme.error),
                title: Text(l.settingsDelete, style: TextStyle(color: scheme.error)),
                enabled: !_busy,
                onTap: _delete,
              ),
            ]),
          group(l.settingsLegal, [
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(l.settingsPrivacy),
              trailing: chevron,
              onTap: () => context.push('/legal/privacy'),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(l.settingsTerms),
              trailing: chevron,
              onTap: () => context.push('/legal/terms'),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: Text(l.settingsAbout),
              trailing: chevron,
              onTap: () => _textPage(context, l.settingsAbout, '${l.aboutBody}\n\n${l.aboutVersion(appVersion)}'),
            ),
          ]),
        ]),
      ),
    );
  }

  void _textPage(BuildContext context, String title, String body) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: PageBody(children: [Text(body, style: const TextStyle(fontSize: 18))]),
      ),
    ));
  }
}
