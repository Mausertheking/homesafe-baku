import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/content_strings.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import 'emergency_config.dart';

/// The emergency screen. Must work with no internet and open in under two
/// seconds, so it only uses data preloaded in main(): bundled numbers and
/// bundled strings. No Firebase, no network, no async work.
class EmergencyScreen extends ConsumerWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final config = ref.watch(emergencyConfigProvider);
    final content = ref.watch(contentStringsProvider);
    final steps = [l.emergencyStep1, l.emergencyStep2, l.emergencyStep3, l.emergencyStep4, l.emergencyStep5];

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(primary: emergencyRed, onPrimary: emergencyOnRed),
      ),
      child: Scaffold(
        backgroundColor: emergencyRed,
        appBar: AppBar(
          backgroundColor: emergencyRed,
          foregroundColor: emergencyOnRed,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          title: Text(l.emergencyTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
          leading: IconButton(
            tooltip: l.close,
            icon: const Icon(Icons.close),
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              if (kDebugMode && !config.verified)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(8),
                  color: Colors.yellow.shade200,
                  child: Text(l.emergencyNumbersUnverified, style: const TextStyle(color: Colors.black)),
                ),
              Text(l.emergencyIntro,
                  style: const TextStyle(color: emergencyOnRed, fontSize: 20, fontWeight: FontWeight.w600, height: 1.35)),
              const SizedBox(height: 16),
              for (final (i, step) in steps.indexed) _Step(number: i + 1, text: step),
              const SizedBox(height: 20),
              Text(l.emergencyCallSection,
                  style: const TextStyle(color: emergencyOnRed, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              for (final n in config.numbers) ...[
                _CallButton(label: content(n.labelKey), number: n.number),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: emergencyOnRed,
                  side: const BorderSide(color: emergencyOnRed, width: 2),
                ),
                onPressed: () => context.canPop() ? context.pop() : context.go('/'),
                child: Text(l.emergencyImSafe),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});
  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: CircleAvatar(
              radius: 18,
              backgroundColor: emergencyOnRed,
              child: Text('$number', style: const TextStyle(color: emergencyRed, fontWeight: FontWeight.w800, fontSize: 18)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: emergencyOnRed, fontSize: 19, height: 1.35, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({required this.label, required this.number});
  final String label;
  final String number;

  Future<void> _call(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    var ok = false;
    try {
      ok = await launchUrl(Uri(scheme: 'tel', path: number));
    } catch (_) {
      ok = false;
    }
    if (!ok) messenger.showSnackBar(SnackBar(content: Text(l.emergencyCallFailed(number))));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l.emergencyCall(label, number),
      excludeSemantics: true,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: emergencyOnRed,
          foregroundColor: emergencyRed,
          minimumSize: const Size.fromHeight(64),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        onPressed: () => _call(context),
        child: Row(
          children: [
            const Icon(Icons.call, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
            Text(number, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}
