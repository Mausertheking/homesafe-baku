import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/analytics.dart';
import '../../core/content_strings.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../../rules_engine/rules_engine.dart';
import '../home_profile/home_profile.dart';
import 'check_definitions.dart';
import 'check_history.dart';
import 'check_outcome.dart';
import 'rules_repository.dart';

/// One question per screen, big buttons. After every answer the rules are
/// evaluated; if an emergency rule matches, the emergency screen opens
/// immediately, before the check is finished.
class CheckFlowScreen extends ConsumerStatefulWidget {
  const CheckFlowScreen({super.key, required this.checkId});
  final String checkId;

  @override
  ConsumerState<CheckFlowScreen> createState() => _CheckFlowScreenState();
}

class _CheckFlowScreenState extends ConsumerState<CheckFlowScreen> {
  late final CheckDefinition _check = checkById(widget.checkId);
  final Answers _answers = {};
  final List<XFile> _photos = [];
  int _index = 0;
  bool _emergencyShown = false;
  Timer? _advance; // Auto-advance after a tap; cancelled on double taps.
  static const _engine = RulesEngine();

  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).log('check_started', {'check': widget.checkId});
    // Profile-derived facts count as answers from the start (rules use them).
    final profile = ref.read(homeProfileProvider);
    if (_check.id == gasCheck.id) {
      _answers.addAll(profile.toRuleAnswers());
    } else {
      final age = profile.buildingAgeBand;
      if (age != null) _answers['building_age_band'] = age;
    }
  }

  List<Question> get _visible => _check.visibleQuestions(_answers);

  Question get _current => _visible[_index.clamp(0, _visible.length - 1)];

  bool _isAnswered(Question q) => switch (q.kind) {
        QuestionKind.photos => _photos.isNotEmpty,
        QuestionKind.multiBool => q.fields.every(_answers.containsKey),
        _ => _answers.containsKey(q.id),
      };

  void _setAnswer(Map<String, Object?> values, {bool advance = true}) {
    setState(() {
      _answers.addAll(values);
      // Drop answers to questions that are now hidden, so stale answers
      // (e.g. "water near electrics" after un-ticking "leak") never count.
      final visibleFields = {for (final q in _visible) ...q.fields};
      final askedFields = {for (final q in _check.questions) ...q.fields};
      _answers.removeWhere((k, _) => askedFields.contains(k) && !visibleFields.contains(k));
    });
    _checkEmergency();
    _advance?.cancel();
    if (advance) _advance = Timer(const Duration(milliseconds: 220), () => mounted ? _next() : null);
  }

  Future<void> _checkEmergency() async {
    if (_emergencyShown) return;
    final rules = await ref.read(ruleSetProvider(_check.id).future);
    if (!mounted) return;
    if (_engine.evaluate(rules, _answers).emergency) {
      _emergencyShown = true;
      ref.read(analyticsProvider).log('emergency_opened', {'source': 'check'});
      context.push('/emergency');
    }
  }

  @override
  void dispose() {
    _advance?.cancel();
    super.dispose();
  }

  Future<void> _next() async {
    _advance?.cancel();
    final visible = _visible;
    final pos = visible.indexOf(_current);
    if (pos < visible.length - 1) {
      setState(() => _index = pos + 1);
      _prefill();
      return;
    }
    await _finish();
  }

  void _back() {
    _advance?.cancel();
    if (_index == 0) {
      context.pop();
    } else {
      setState(() => _index -= 1);
    }
  }

  void _prefill() {
    final q = _current;
    if (q.prefill == null || _answers.containsKey(q.id)) return;
    final value = q.prefill!(ref.read(homeProfileProvider));
    if (value != null) setState(() => _answers[q.id] = value);
  }

  Future<void> _finish() async {
    final rules = await ref.read(ruleSetProvider(_check.id).future);
    final evaluation = _engine.evaluate(rules, _answers);
    ref.read(analyticsProvider).log('check_completed', {'check': _check.id, 'level': evaluation.level.name});
    final outcome = CheckOutcome(
      checkId: _check.id,
      answers: Map.of(_answers),
      evaluation: evaluation,
      photos: List.of(_photos),
      allRulesReviewed: rules.allReviewed,
    );
    await ref.read(checkHistoryProvider.notifier).add(outcome);
    if (!mounted) return;
    context.pushReplacement('/result', extra: outcome);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = ref.watch(contentStringsProvider);
    final visible = _visible;
    final q = _current;
    final pos = visible.indexOf(q);

    final theme = Theme.of(context);
    final isLast = pos == visible.length - 1;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close_rounded), tooltip: l.close, onPressed: () => context.pop()),
        title: Text(_check.id == gasCheck.id ? l.checkGasTitle : l.checkDampTitle, overflow: TextOverflow.ellipsis),
        actions: const [EmergencyAction()],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Row(children: [
                Expanded(
                  child: Semantics(
                    label: l.questionProgress(pos + 1, visible.length),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: (pos + 1) / visible.length),
                      duration: const Duration(milliseconds: 250),
                      builder: (_, v, _) => LinearProgressIndicator(value: v),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ExcludeSemantics(
                  child: Text('${pos + 1}/${visible.length}',
                      style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
                ),
              ]),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: PageBody(
                  key: ValueKey(q.id),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        q.kind == QuestionKind.photos ? l.photosTitle : t(q.titleKey),
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 25),
                      ),
                    ),
                    if (t.has(q.helpKey)) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Icon(Icons.lightbulb_outline_rounded, color: theme.colorScheme.primary, size: 22),
                          const SizedBox(width: 10),
                          Expanded(child: Text(t(q.helpKey), style: theme.textTheme.bodyLarge)),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ..._answerWidgets(q, l, t),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Row(children: [
                    OutlinedButton(
                      onPressed: _back,
                      style: OutlinedButton.styleFrom(minimumSize: const Size(56, 56), padding: EdgeInsets.zero),
                      child: Icon(Icons.arrow_back_rounded, semanticLabel: l.back),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isAnswered(q) ? _next : null,
                        child: Text(isLast ? l.checkSeeResult : l.next),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _answerWidgets(Question q, AppLocalizations l, ContentStrings t) {
    final answer = _answers[q.id];
    switch (q.kind) {
      case QuestionKind.yesNo:
      case QuestionKind.yesNoUnsure:
        return [
          ChoiceButton(label: l.yes, selected: answer == true, onTap: () => _setAnswer({q.id: true})),
          ChoiceButton(label: l.no, selected: answer == false, onTap: () => _setAnswer({q.id: false})),
          if (q.kind == QuestionKind.yesNoUnsure)
            ChoiceButton(
                label: l.notSure, selected: answer == 'not_sure', onTap: () => _setAnswer({q.id: 'not_sure'})),
        ];
      case QuestionKind.single:
        return [
          for (final o in q.options)
            ChoiceButton(label: t(q.optionKey(o)), selected: answer == o.value, onTap: () => _setAnswer({q.id: o.value})),
        ];
      case QuestionKind.multiBool:
        final anyAnswered = q.fields.every(_answers.containsKey);
        final noneTicked = anyAnswered && q.fields.every((f) => _answers[f] == false);
        return [
          for (final o in q.options)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CheckboxListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                tileColor: _answers[o.key] == true
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: _answers[o.key] == true
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                    width: _answers[o.key] == true ? 2.5 : 1.5,
                  ),
                ),
                title: Text(t(q.optionKey(o)), style: const TextStyle(fontSize: 17.5, fontWeight: FontWeight.w600)),
                value: _answers[o.key] == true,
                onChanged: (v) => _setAnswer({
                  // Ticking one option answers the rest as "no".
                  for (final f in q.fields) f: _answers[f] ?? false,
                  o.key: v ?? false,
                }, advance: false),
              ),
            ),
          ChoiceButton(
            label: l.multiSelectNone,
            selected: noneTicked,
            onTap: () => _setAnswer({for (final f in q.fields) f: false}),
          ),
        ];
      case QuestionKind.photos:
        return [_PhotoPicker(photos: _photos, onChanged: () => setState(() {}))];
    }
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.photos, required this.onChanged});
  final List<XFile> photos;
  final VoidCallback onChanged;
  static const max = 5;

  Future<void> _pick(ImageSource source) async {
    // Resize on device: smaller uploads on weak connections, and enough
    // detail to see the damp.
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, maxWidth: 1600, imageQuality: 80);
    if (file != null && photos.length < max) {
      photos.add(file);
      onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(l.photosBody, style: Theme.of(context).textTheme.bodyLarge),
      const SizedBox(height: 16),
      Wrap(spacing: 12, runSpacing: 12, children: [
        for (final (i, p) in photos.indexed)
          Stack(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FutureBuilder(
                future: p.readAsBytes(),
                builder: (_, s) => s.hasData
                    ? Image.memory(s.data!, width: 100, height: 100, fit: BoxFit.cover, semanticLabel: l.photoLabel(i + 1))
                    : const SizedBox(width: 100, height: 100),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: IconButton.filledTonal(
                tooltip: l.removePhoto,
                icon: const Icon(Icons.close),
                onPressed: () {
                  photos.removeAt(i);
                  onChanged();
                },
              ),
            ),
          ]),
      ]),
      const SizedBox(height: 16),
      if (photos.length < max) ...[
        OutlinedButton.icon(
            onPressed: () => _pick(ImageSource.camera), icon: const Icon(Icons.photo_camera), label: Text(l.takePhoto)),
        const SizedBox(height: 12),
        OutlinedButton.icon(
            onPressed: () => _pick(ImageSource.gallery), icon: const Icon(Icons.photo_library), label: Text(l.choosePhoto)),
      ],
    ]);
  }
}
