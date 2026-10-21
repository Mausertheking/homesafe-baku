import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/analytics.dart';
import '../../core/callables.dart';
import '../../core/settings.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_service.dart';
import '../home_profile/home_profile.dart';

const letterProblems = ['gas_heater', 'co_alarm_missing', 'damp_mold', 'leak', 'other'];
const letterRecipients = ['landlord', 'building_manager', 'azerigaz', 'other'];

String problemLabel(AppLocalizations l, String id) => switch (id) {
      'gas_heater' => l.problemGasHeater,
      'co_alarm_missing' => l.problemCoAlarm,
      'damp_mold' => l.problemDamp,
      'leak' => l.problemLeak,
      _ => l.problemOther,
    };

String recipientLabel(AppLocalizations l, String id) => switch (id) {
      'landlord' => l.recipientLandlord,
      'building_manager' => l.recipientBuildingManager,
      'azerigaz' => l.recipientAzerigaz,
      _ => l.recipientOther,
    };

/// List of letters already written for this home.
class LettersScreen extends ConsumerWidget {
  const LettersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    final homeId = ref.watch(homeProfileProvider.select((p) => p.id));
    final lang = ref.watch(settingsProvider.select((s) => s.language));

    return Scaffold(
      appBar: AppBar(title: Text(l.lettersTitle), actions: const [EmergencyAction()]),
      floatingActionButton: user == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/letters/new'),
              icon: const Icon(Icons.edit),
              label: Text(l.letterNew),
            ),
      body: user == null
          ? UnavailableView(message: l.signInRequired, actionLabel: l.signIn, action: () => context.push('/sign-in'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users/${user.uid}/homes/$homeId/letters')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) return UnavailableView(message: l.errorGeneric);
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snap.data!.docs;
                if (docs.isEmpty) return UnavailableView(message: l.lettersEmpty);
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: docs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final d = docs[i].data();
                    final created = (d['createdAt'] as Timestamp?)?.toDate();
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(14),
                        leading: const Icon(Icons.mail_outline),
                        title: Text('${problemLabel(l, d['templateId'] as String? ?? '')} → '
                            '${recipientLabel(l, d['recipient'] as String? ?? '')}'),
                        subtitle: created == null ? null : Text(DateFormat.yMMMd(lang).format(created)),
                        onTap: () => context.push('/letters/preview', extra: LetterPreviewData(body: d['body'] as String? ?? '')),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class NewLetterScreen extends ConsumerStatefulWidget {
  const NewLetterScreen({super.key, this.initialProblem});

  /// Pre-selected problem when coming from a check result.
  final String? initialProblem;

  @override
  ConsumerState<NewLetterScreen> createState() => _NewLetterScreenState();
}

class _NewLetterScreenState extends ConsumerState<NewLetterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _recipientName = TextEditingController();
  final _description = TextEditingController();
  final _since = TextEditingController();
  late String _problem =
      letterProblems.contains(widget.initialProblem) ? widget.initialProblem! : letterProblems.first;
  String _recipient = letterRecipients.first;
  late String _language = ref.read(settingsProvider).language;
  bool _polish = false;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _address, _recipientName, _description, _since]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _generate() async {
    final l = AppLocalizations.of(context);
    if (!_form.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final res = await ref.read(callablesProvider).call('generateLetter', {
        'homeId': ref.read(homeProfileProvider).id,
        'templateId': _problem,
        'recipient': _recipient,
        'language': _language,
        'polish': _polish,
        'details': {
          'name': _name.text.trim(),
          'address': _address.text.trim(),
          'recipientName': _recipientName.text.trim(),
          'description': _description.text.trim(),
          'since': _since.text.trim(),
        },
      }, timeout: const Duration(seconds: 90));
      ref.read(analyticsProvider).log('letter_generated', {'problem': _problem, 'recipient': _recipient, 'language': _language});
      messenger.showSnackBar(SnackBar(content: Text(l.letterSavedToLog)));
      if (mounted) {
        context.pushReplacement('/letters/preview',
            extra: LetterPreviewData(body: res['body'] as String, pdfUrl: res['pdfUrl'] as String?));
      }
    } on BackendUnavailable {
      messenger.showSnackBar(SnackBar(content: Text(l.backendUnavailable)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.errorGeneric)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    String? required(String? v) => (v == null || v.trim().isEmpty) ? l.letterFieldRequired : null;

    Widget chips(String title, List<String> ids, String selected, String Function(String) label, void Function(String) on) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final id in ids)
                ChoiceChip(
                  label: Padding(padding: const EdgeInsets.all(6), child: Text(label(id), style: const TextStyle(fontSize: 16))),
                  selected: selected == id,
                  onSelected: (_) => setState(() => on(id)),
                ),
            ]),
          ]),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l.letterNew), actions: const [EmergencyAction()]),
      body: SafeArea(
        child: Form(
          key: _form,
          child: PageBody(children: [
            chips(l.letterProblem, letterProblems, _problem, (id) => problemLabel(l, id), (v) => _problem = v),
            chips(l.letterRecipient, letterRecipients, _recipient, (id) => recipientLabel(l, id), (v) => _recipient = v),
            chips(l.letterLanguage, SettingsController.supportedLanguages, _language,
                (id) => {'az': l.languageAz, 'ru': l.languageRu, 'en': l.languageEn}[id]!, (v) => _language = v),
            TextFormField(controller: _name, validator: required, decoration: InputDecoration(labelText: l.letterYourName)),
            const SizedBox(height: 12),
            TextFormField(controller: _address, validator: required, decoration: InputDecoration(labelText: l.letterAddress)),
            const SizedBox(height: 12),
            TextFormField(controller: _recipientName, decoration: InputDecoration(labelText: l.letterRecipientName)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              validator: required,
              minLines: 3,
              maxLines: 6,
              maxLength: 1000,
              decoration: InputDecoration(labelText: l.letterDescription),
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _since, decoration: InputDecoration(labelText: l.letterSince)),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _polish,
              onChanged: (v) => setState(() => _polish = v),
              title: Text(l.letterPolish),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _generate,
              icon: _busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.preview),
              label: Text(_busy ? l.letterGenerating : l.letterPreview),
            ),
          ]),
        ),
      ),
    );
  }
}

class LetterPreviewData {
  const LetterPreviewData({required this.body, this.pdfUrl});
  final String body;
  final String? pdfUrl;
}

class LetterPreviewScreen extends StatelessWidget {
  const LetterPreviewScreen({super.key, required this.data});
  final LetterPreviewData data;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.letterPreview), actions: const [EmergencyAction()]),
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: SelectableText(data.body, style: const TextStyle(fontSize: 17, height: 1.5)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: data.body));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.letterCopied)));
                  }
                },
                icon: const Icon(Icons.copy),
                label: Text(l.letterCopy),
              ),
              OutlinedButton.icon(
                onPressed: () => SharePlus.instance.share(ShareParams(text: data.body)),
                icon: const Icon(Icons.share),
                label: Text(l.letterShare),
              ),
              if (data.pdfUrl != null)
                FilledButton.icon(
                  onPressed: () => launchUrl(Uri.parse(data.pdfUrl!), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: Text(l.letterSavePdf),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}
