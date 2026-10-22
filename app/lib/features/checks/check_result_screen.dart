import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics.dart';
import '../../core/content_strings.dart';
import '../../core/demo.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../../rules_engine/rules_engine.dart';
import '../auth/auth_service.dart';
import 'check_definitions.dart';
import 'check_outcome.dart';

class CheckResultScreen extends ConsumerStatefulWidget {
  const CheckResultScreen({super.key, required this.outcome});
  final CheckOutcome outcome;

  @override
  ConsumerState<CheckResultScreen> createState() => _CheckResultScreenState();
}

class _CheckResultScreenState extends ConsumerState<CheckResultScreen> {
  bool _saving = false;
  bool _saved = false;

  bool _requireAccount() {
    if (ref.read(currentUserProvider) != null) return true;
    final l = AppLocalizations.of(context);
    if (demoMode) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.demoFeatureOff)));
      return false;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l.signInRequired),
      action: SnackBarAction(label: l.signIn, onPressed: () => context.push('/sign-in')),
    ));
    return false;
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!_requireAccount()) return;
    setState(() => _saving = true);
    try {
      await ref.read(checkRepositoryProvider).save(widget.outcome);
      ref.read(analyticsProvider).log('evidence_added', {'type': 'check'});
      if (mounted) setState(() => _saved = true);
      messenger.showSnackBar(SnackBar(content: Text(l.resultSaved)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.errorGeneric)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = ref.watch(contentStringsProvider);
    final theme = Theme.of(context);
    final e = widget.outcome.evaluation;
    final isDamp = widget.outcome.checkId == dampCheck.id;
    final palette = levelPalette(e.level.name, theme.brightness);
    final (label, hint, icon) = switch (e.level) {
      HazardLevel.red => (l.levelRed, l.levelRedHint, Icons.error_rounded),
      HazardLevel.amber => (l.levelAmber, l.levelAmberHint, Icons.warning_amber_rounded),
      HazardLevel.green => (l.levelGreen, l.levelGreenHint, Icons.check_circle_rounded),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l.resultTitle),
        // Always offer a way home, even when the result is the only route.
        leading: context.canPop()
            ? null
            : IconButton(tooltip: l.close, icon: const Icon(Icons.home_outlined), onPressed: () => context.go('/')),
        actions: const [EmergencyAction()],
      ),
      body: SafeArea(
        child: PageBody(children: [
          // Summary
          Semantics(
            liveRegion: true,
            label: '$label. $hint',
            excludeSemantics: true,
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(color: palette.strong, borderRadius: BorderRadius.circular(radiusLarge)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: Icon(icon, color: Colors.white, size: 34),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(widget.outcome.checkId == gasCheck.id ? l.checkGasTitle : l.checkDampTitle,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14.5, fontWeight: FontWeight.w600)),
                      Text(label, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, height: 1.15)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 12),
                Text(hint, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          if (e.emergency) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: emergencyRed, foregroundColor: emergencyOnRed),
              onPressed: () => context.push('/emergency'),
              icon: const Icon(Icons.warning_rounded),
              label: Text(l.resultOpenEmergency),
            ),
          ],
          if (isDamp) ...[
            const SizedBox(height: 20),
            SectionHeader(l.resultCausesTitle),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (e.categories.isEmpty) Chip(avatar: const Icon(Icons.help_outline_rounded, size: 20), label: Text(l.causeUnclear)),
              for (final (cat, text, ico) in [
                ('condensation', l.causeCondensation, Icons.water_drop_outlined),
                ('leak', l.causeLeak, Icons.plumbing_rounded),
                ('structural', l.causeStructural, Icons.foundation_rounded),
              ])
                if (e.categories.contains(cat))
                  Chip(
                    avatar: Icon(ico, size: 20, color: theme.colorScheme.primary),
                    label: Text(text),
                    backgroundColor: theme.colorScheme.primaryContainer,
                  ),
            ]),
          ],
          const SizedBox(height: 20),
          SectionHeader(l.resultNextSteps),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: Column(children: [
                for (final (i, key) in e.stepKeys.indexed) _Step(number: i + 1, text: t(key), color: palette.strong),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          SectionHeader(l.resultWhy),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: Column(children: [
                for (final key in e.reasonKeys) _Reason(text: t(key)),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          NoticeBanner(text: l.resultDisclaimer),
          if (!widget.outcome.allRulesReviewed) ...[
            const SizedBox(height: 8),
            NoticeBanner(text: l.resultRulesUnreviewed, icon: Icons.science_outlined, warning: true),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving || _saved ? null : _save,
            icon: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(_saved ? Icons.check_rounded : Icons.bookmark_add_outlined),
            label: Text(_saved ? l.resultSaved : l.resultSaveToEvidence),
          ),
          if (e.level != HazardLevel.green) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                if (_requireAccount()) context.push('/letters/new', extra: widget.outcome.suggestedLetterProblem);
              },
              icon: const Icon(Icons.mail_outline_rounded),
              label: Text(l.resultWriteLetter),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/chat', extra: _chatPrompt(l, t, e)),
            icon: const Icon(Icons.forum_outlined),
            label: Text(l.resultAskAssistant),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: () => context.pushReplacement('/check/${widget.outcome.checkId}'),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l.statusAgain),
          ),
        ]),
      ),
    );
  }

  /// Pre-fills the chat with a short question about this result. The server
  /// also loads the latest saved check itself.
  String _chatPrompt(AppLocalizations l, ContentStrings t, Evaluation e) {
    final title = widget.outcome.checkId == gasCheck.id ? l.checkGasTitle : l.checkDampTitle;
    final level = switch (e.level) {
      HazardLevel.red => l.levelRed,
      HazardLevel.amber => l.levelAmber,
      HazardLevel.green => l.levelGreen,
    };
    return '$title: $level. ${t(e.reasonKeys.first)} ';
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text, required this.color});
  final int number;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ExcludeSemantics(
            child: CircleAvatar(
              radius: 15,
              backgroundColor: color,
              child: Text('$number', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
            ),
          ),
        ]),
      );
}

class _Reason extends StatelessWidget {
  const _Reason({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(Icons.info_outline_rounded, size: 20, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
        ]),
      );
}
