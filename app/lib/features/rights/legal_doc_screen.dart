import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings.dart';
import '../../core/simple_markdown.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';

/// Privacy policy and terms of use, bundled with the app (readable offline)
/// from assets/legal/{privacy|terms}_{lang}.md. Drafts until a lawyer signs off.
const legalDocsFinal = false; // TODO(lawyer): set true once both texts are approved.

final legalDocProvider = FutureProvider.family<String, (String, String)>((ref, key) {
  final (kind, lang) = key;
  return rootBundle.loadString('assets/legal/${kind}_$lang.md');
});

class LegalDocScreen extends ConsumerWidget {
  const LegalDocScreen({super.key, required this.kind});

  /// `privacy` or `terms`.
  final String kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lang = ref.watch(settingsProvider.select((s) => s.language));
    final doc = ref.watch(legalDocProvider((kind, lang)));
    return Scaffold(
      appBar: AppBar(
        title: Text(kind == 'privacy' ? l.settingsPrivacy : l.settingsTerms),
        actions: const [EmergencyAction()],
      ),
      body: SafeArea(
        child: doc.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => UnavailableView(message: l.errorGeneric),
          data: (text) => PageBody(children: [
            if (!legalDocsFinal) ...[
              NoticeBanner(text: l.legalDocDraft, icon: Icons.edit_note_rounded, warning: true),
              const SizedBox(height: 16),
            ],
            SimpleMarkdown(text, skipTitle: true),
          ]),
        ),
      ),
    );
  }
}
