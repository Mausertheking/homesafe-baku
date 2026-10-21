import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/analytics.dart';
import '../../core/content_strings.dart';
import '../../core/settings.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_service.dart';
import 'evidence_repository.dart';

class EvidenceScreen extends ConsumerWidget {
  const EvidenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.evidenceTitle),
        actions: [
          if (user != null)
            IconButton(
              tooltip: l.evidenceMakeReport,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () => context.push('/evidence/report'),
            ),
          const EmergencyAction(),
        ],
      ),
      floatingActionButton: user == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddSheet(context, ref),
              icon: const Icon(Icons.add),
              label: Text(l.evidenceAdd),
            ),
      body: user == null
          ? UnavailableView(message: l.signInRequired, actionLabel: l.signIn, action: () => context.push('/sign-in'))
          : ref.watch(evidenceStreamProvider).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => UnavailableView(message: l.errorGeneric),
                data: (items) => items.isEmpty
                    ? UnavailableView(message: l.evidenceEmpty)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _EvidenceTile(item: items[i]),
                      ),
              ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l.evidenceAddPhoto),
            onTap: () {
              Navigator.pop(sheet);
              _addPhoto(context, ref);
            },
          ),
          ListTile(
            leading: const Icon(Icons.notes),
            title: Text(l.evidenceAddNote),
            onTap: () {
              Navigator.pop(sheet);
              _addText(context, ref, EvidenceType.note, l.evidenceNoteHint);
            },
          ),
          ListTile(
            leading: const Icon(Icons.healing_outlined),
            title: Text(l.evidenceAddSymptom),
            onTap: () {
              Navigator.pop(sheet);
              _addText(context, ref, EvidenceType.symptom, l.evidenceSymptomHint);
            },
          ),
        ]),
      ),
    );
  }

  Future<void> _addText(BuildContext context, WidgetRef ref, EvidenceType type, String hint) async {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(type == EvidenceType.note ? l.evidenceAddNote : l.evidenceAddSymptom),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 3,
          maxLines: 8,
          maxLength: 2000,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(d, controller.text.trim()), child: Text(l.save)),
        ],
      ),
    );
    if (text == null || text.isEmpty || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(evidenceRepositoryProvider).addText(type, text);
      ref.read(analyticsProvider).log('evidence_added', {'type': type.name});
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.errorGeneric)));
    }
  }

  Future<void> _addPhoto(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (s) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(l.takePhoto),
              onTap: () => Navigator.pop(s, ImageSource.camera)),
          ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l.choosePhoto),
              onTap: () => Navigator.pop(s, ImageSource.gallery)),
        ]),
      ),
    );
    if (source == null) return;
    final file = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 80);
    if (file == null) return;
    messenger.showSnackBar(SnackBar(content: Text(l.evidenceUploading)));
    try {
      await ref.read(evidenceRepositoryProvider).addPhoto(file);
      ref.read(analyticsProvider).log('evidence_added', {'type': 'photo'});
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.errorGeneric)));
    }
  }
}

class _EvidenceTile extends ConsumerStatefulWidget {
  const _EvidenceTile({required this.item});
  final EvidenceItem item;

  @override
  ConsumerState<_EvidenceTile> createState() => _EvidenceTileState();
}

class _EvidenceTileState extends ConsumerState<_EvidenceTile> {
  bool _expanded = false;
  EvidenceItem get item => widget.item;

  String _typeLabel(AppLocalizations l) => switch (item.type) {
        EvidenceType.photo => l.evidenceTypePhoto,
        EvidenceType.note => l.evidenceTypeNote,
        EvidenceType.symptom => l.evidenceTypeSymptom,
        EvidenceType.check => l.evidenceTypeCheck,
        EvidenceType.letter => l.evidenceTypeLetter,
      };

  IconData get _icon => switch (item.type) {
        EvidenceType.photo => Icons.photo_outlined,
        EvidenceType.note => Icons.notes,
        EvidenceType.symptom => Icons.healing_outlined,
        EvidenceType.check => Icons.fact_check_outlined,
        EvidenceType.letter => Icons.mail_outline,
      };

  /// Check items store a machine summary; show it in the reader's language.
  String _body(AppLocalizations l, ContentStrings t) {
    if (item.type != EvidenceType.check) return item.text;
    try {
      final j = jsonDecode(item.text) as Map<String, dynamic>;
      final title = j['check'] == 'gas_co' ? l.checkGasTitle : l.checkDampTitle;
      final level = switch (j['level']) { 'red' => l.levelRed, 'amber' => l.levelAmber, _ => l.levelGreen };
      return '$title: $level';
    } catch (_) {
      return item.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = ref.watch(contentStringsProvider);
    final lang = ref.watch(settingsProvider.select((s) => s.language));
    final fmt = DateFormat.yMMMd(lang).add_Hm();
    final time = item.serverTime ?? item.createdAt;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(_icon),
            const SizedBox(width: 8),
            Expanded(child: Text(_typeLabel(l), style: Theme.of(context).textTheme.titleMedium)),
            _VerifiedBadge(verified: item.verified),
            PopupMenuButton<String>(
              tooltip: l.evidenceDelete,
              onSelected: (_) => _confirmDelete(context),
              itemBuilder: (_) => [PopupMenuItem(value: 'delete', child: Text(l.evidenceDelete))],
            ),
          ]),
          if (item.storagePath != null) ...[
            const SizedBox(height: 8),
            _PrivatePhoto(path: item.storagePath!),
          ],
          if (_body(l, t).isNotEmpty) ...[
            const SizedBox(height: 8),
            // Long items (letters) are folded to a few lines; tap to expand.
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                _body(l, t),
                maxLines: _expanded ? null : 5,
                overflow: _expanded ? null : TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
          const SizedBox(height: 8),
          if (time != null) Text(l.evidenceServerTime(fmt.format(time.toLocal())), style: Theme.of(context).textTheme.bodySmall),
          if (item.sha256 != null)
            Text('${l.evidenceHash}: ${item.sha256!.substring(0, 16)}…',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace')),
        ]),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        content: Text(l.evidenceDeleteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(l.evidenceDelete)),
        ],
      ),
    );
    if (ok == true) await ref.read(evidenceRepositoryProvider).markDeleted(item.id);
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge({required this.verified});
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: l.evidenceVerifiedHint,
      triggerMode: TooltipTriggerMode.tap,
      child: Chip(
        visualDensity: VisualDensity.compact,
        avatar: Icon(verified ? Icons.verified : Icons.hourglass_top, size: 18,
            color: verified ? scheme.primary : scheme.outline),
        label: Text(verified ? l.evidenceVerified : l.evidencePending),
      ),
    );
  }
}

/// Loads the photo bytes through Storage security rules, so photos never
/// need a public link.
class _PrivatePhoto extends ConsumerStatefulWidget {
  const _PrivatePhoto({required this.path});
  final String path;

  @override
  ConsumerState<_PrivatePhoto> createState() => _PrivatePhotoState();
}

class _PrivatePhotoState extends ConsumerState<_PrivatePhoto> {
  late final Future<Uint8List?> _bytes = ref.read(evidenceRepositoryProvider).photoBytes(widget.path);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: FutureBuilder<Uint8List?>(
        future: _bytes,
        builder: (_, s) => s.data == null
            ? Container(height: 160, color: Theme.of(context).colorScheme.surfaceContainerHighest)
            : Image.memory(s.data!, height: 200, width: double.infinity, fit: BoxFit.cover, semanticLabel: l.evidenceTypePhoto),
      ),
    );
  }
}
