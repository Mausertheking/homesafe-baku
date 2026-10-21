import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/content_strings.dart';
import '../../core/firebase_bootstrap.dart';
import '../../core/settings.dart';
import '../../core/simple_markdown.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';

/// Topic ids in display order (used when nothing else is available).
const knownTopics = ['repairs', 'written_contracts', 'deposits', 'inspections', 'owners_duties'];

class LegalTopic {
  const LegalTopic({
    required this.id,
    this.title,
    this.body,
    this.lawReference,
    this.reviewedBy,
    this.reviewedOn,
    this.order = 0,
    this.sources = const [],
  });

  final String id;
  final Map<String, dynamic>? title;
  final Map<String, dynamic>? body;
  final Map<String, dynamic>? lawReference;
  final String? reviewedBy;
  final String? reviewedOn;
  final int order;
  final List<String> sources;

  /// Lawyer-reviewed. Unreviewed text is shown only with a "Draft" label, and
  /// the AI assistant never uses it.
  bool get reviewed => reviewedBy != null && reviewedOn != null;

  bool get hasText => body?.values.any((v) => v is String && v.trim().isNotEmpty) ?? false;

  String titleIn(String lang, ContentStrings t) =>
      (title?[lang] as String?)?.trim().isNotEmpty == true ? title![lang] as String : t('topic.$id');

  String? bodyIn(String lang) => _nonEmpty(body?[lang]);
  String? lawIn(String lang) => _nonEmpty(lawReference?[lang]);

  static String? _nonEmpty(Object? v) => v is String && v.trim().isNotEmpty ? v : null;

  static LegalTopic fromJson(String id, Map<String, dynamic> j) => LegalTopic(
        id: id,
        title: j['title'] as Map<String, dynamic>?,
        body: j['body'] as Map<String, dynamic>?,
        lawReference: j['lawReference'] as Map<String, dynamic>?,
        reviewedBy: j['reviewedBy'] as String?,
        reviewedOn: j['reviewedOn'] as String?,
        order: (j['order'] as num?)?.toInt() ?? 0,
        sources: [for (final s in (j['sources'] as List?) ?? const []) s as String],
      );
}

/// Draft texts bundled with the app (assets/legal/rights.json), so the
/// topics are readable offline and without an account.
final bundledTopicsProvider = FutureProvider<List<LegalTopic>>((ref) async {
  final json = jsonDecode(await rootBundle.loadString('assets/legal/rights.json')) as Map<String, dynamic>;
  return [
    for (final t in json['topics'] as List) LegalTopic.fromJson((t as Map)['id'] as String, Map<String, dynamic>.from(t)),
  ]..sort((a, b) => a.order.compareTo(b.order));
});

/// Firestore topics replace the bundled drafts once they carry text (the
/// lawyer-reviewed versions are published there). Cached by Firestore offline.
final legalTopicsProvider = StreamProvider<List<LegalTopic>>((ref) async* {
  final bundled = await ref.watch(bundledTopicsProvider.future);
  yield bundled;
  if (!ref.watch(firebaseAvailableProvider)) return;
  await for (final snap in FirebaseFirestore.instance.collection('legalTopics').snapshots()) {
    final remote = {for (final d in snap.docs) d.id: LegalTopic.fromJson(d.id, d.data())};
    yield [
      for (final b in bundled)
        if (remote[b.id] case final r? when r.reviewed || r.hasText) r else b,
      for (final r in remote.values)
        if (!bundled.any((b) => b.id == r.id) && r.hasText) r,
    ]..sort((a, b) => a.order.compareTo(b.order));
  }
});

class RightsScreen extends ConsumerWidget {
  const RightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = ref.watch(contentStringsProvider);
    final lang = ref.watch(settingsProvider.select((s) => s.language));
    final topics = ref.watch(legalTopicsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.rightsTitle), actions: const [EmergencyAction()]),
      body: SafeArea(
        child: PageBody(children: [
          NoticeBanner(text: l.rightsNotice, icon: Icons.gavel_rounded),
          const SizedBox(height: 16),
          ...topics.when(
            loading: () => [const Center(child: CircularProgressIndicator())],
            error: (_, _) => [Text(l.errorGeneric)],
            data: (list) => [
              for (final topic in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => context.push('/rights/topic', extra: topic),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(children: [
                          IconTile(icon: _icon(topic.id)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(topic.titleIn(lang, t), style: theme.textTheme.titleMedium),
                              const SizedBox(height: 4),
                              topic.reviewed
                                  ? Text(l.rightsReviewedBy(topic.reviewedBy!, topic.reviewedOn!),
                                      style: theme.textTheme.bodyMedium)
                                  : _DraftChip(label: l.rightsDraftBadge),
                            ]),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ]),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ]),
      ),
    );
  }

  static IconData _icon(String id) => switch (id) {
        'repairs' => Icons.build_outlined,
        'written_contracts' => Icons.description_outlined,
        'deposits' => Icons.savings_outlined,
        'inspections' => Icons.door_front_door_outlined,
        'owners_duties' => Icons.apartment_outlined,
        _ => Icons.gavel_rounded,
      };
}

class _DraftChip extends StatelessWidget {
  const _DraftChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = levelPalette('amber', Theme.of(context).brightness);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: p.soft, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.edit_note_rounded, size: 16, color: p.onSoft),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: p.onSoft, fontWeight: FontWeight.w700, fontSize: 13)),
      ]),
    );
  }
}

class RightsTopicScreen extends ConsumerWidget {
  const RightsTopicScreen({super.key, required this.topic});
  final LegalTopic topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = ref.watch(contentStringsProvider);
    final lang = ref.watch(settingsProvider.select((s) => s.language));
    final theme = Theme.of(context);
    final body = topic.bodyIn(lang);
    final law = topic.lawIn(lang);

    return Scaffold(
      appBar: AppBar(actions: const [EmergencyAction()]),
      body: SafeArea(
        child: PageBody(children: [
          Semantics(
            header: true,
            child: Text(topic.titleIn(lang, t), style: theme.textTheme.headlineMedium),
          ),
          const SizedBox(height: 16),
          NoticeBanner(text: l.rightsNotice, icon: Icons.gavel_rounded),
          if (!topic.reviewed && body != null) ...[
            const SizedBox(height: 8),
            NoticeBanner(text: l.rightsDraft, icon: Icons.edit_note_rounded, warning: true),
          ],
          const SizedBox(height: 20),
          if (body == null)
            Text(l.rightsPending, style: theme.textTheme.bodyLarge)
          else
            SimpleMarkdown(body),
          if (law != null) ...[
            const SizedBox(height: 20),
            SectionHeader(l.rightsLawReference),
            Text(law, style: theme.textTheme.bodyMedium),
          ],
          if (topic.sources.isNotEmpty) ...[
            const SizedBox(height: 16),
            SectionHeader(l.rightsSources),
            for (final s in topic.sources)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: SelectableText(s, style: theme.textTheme.bodySmall),
              ),
          ],
          const SizedBox(height: 20),
          Text(topic.reviewed ? l.rightsReviewedBy(topic.reviewedBy!, topic.reviewedOn!) : l.rightsNotReviewed,
              style: theme.textTheme.bodySmall),
        ]),
      ),
    );
  }
}
