import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/analytics.dart';
import '../../core/demo.dart';
import '../../core/callables.dart';
import '../../core/settings.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_service.dart';
import '../emergency/emergency_config.dart';
import '../home_profile/home_profile.dart';

enum _Role { user, assistant, system }

class _Message {
  _Message(this.role, this.text, {this.photo, this.mentionsEmergency = false});
  final _Role role;
  final String text;
  final Uint8List? photo;
  final bool mentionsEmergency;
}

/// Ask HomeSafe. The emergency keyword check runs HERE, before anything is
/// sent. The server runs the same check again (defence in depth).
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, this.initialText});
  final String? initialText;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  late final _input = TextEditingController(text: widget.initialText ?? '');
  final _scroll = ScrollController();
  final List<_Message> _messages = [];
  Uint8List? _photo;
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1280, imageQuality: 70);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() => _photo = bytes);
    }
  }

  Future<void> _send([String? preset]) async {
    final l = AppLocalizations.of(context);
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _sending) return;

    // 1. Emergency check BEFORE any network call.
    if (ref.read(emergencyDetectorProvider).isEmergency(text)) {
      ref.read(analyticsProvider).log('chat_emergency_blocked');
      setState(() {
        _messages.add(_Message(_Role.user, text));
        _messages.add(_Message(_Role.system, l.chatEmergencyDetected, mentionsEmergency: true));
        _input.clear();
        _photo = null;
      });
      context.push('/emergency');
      return;
    }

    final photo = _photo;
    setState(() {
      _messages.add(_Message(_Role.user, text, photo: photo));
      _input.clear();
      _photo = null;
      _sending = true;
    });
    _scrollToEnd();

    try {
      ref.read(analyticsProvider).log('chat_message_sent');
      final res = await ref.read(callablesProvider).call('askHomeSafe', {
        'homeId': ref.read(homeProfileProvider).id,
        'message': text,
        'language': ref.read(settingsProvider).language,
        if (photo != null) 'photo': {'mimeType': 'image/jpeg', 'data': base64Encode(photo)},
      });
      if (!mounted) return;
      if (res['emergency'] == true) {
        // Server caught something the client list missed.
        setState(() => _messages.add(_Message(_Role.system, l.chatEmergencyDetected, mentionsEmergency: true)));
        context.push('/emergency');
      } else {
        setState(() => _messages.add(_Message(_Role.assistant, res['answer'] as String? ?? '',
            mentionsEmergency: res['mentionsEmergency'] == true)));
      }
    } on FirebaseFunctionsException catch (e) {
      setState(() => _messages.add(
          _Message(_Role.system, switch (e.code) {
            'resource-exhausted' => l.chatRateLimited,
            'unavailable' => l.chatAssistantUnavailable,
            _ => l.chatError,
          })));
    } on BackendUnavailable {
      setState(() => _messages.add(_Message(_Role.system, l.backendUnavailable)));
    } catch (_) {
      setState(() => _messages.add(_Message(_Role.system, l.chatError)));
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l.chatTitle), actions: const [EmergencyAction()]),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: NoticeBanner(text: l.chatNotice),
          ),
          Expanded(
            child: user == null
                ? const AccountRequiredView()
                : ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_messages.isEmpty) ...[
                        const SizedBox(height: 16),
                        const Center(child: IconTile(icon: Icons.forum_outlined, size: 64)),
                        const SizedBox(height: 14),
                        Text(l.chatWelcome, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 20),
                        Text(l.chatSuggestTitle, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        // Tap an example to ask it straight away.
                        for (final q in [l.chatSuggest1, l.chatSuggest2, l.chatSuggest3])
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ActionChip(
                              avatar: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                              label: Text(q, softWrap: true),
                              onPressed: _sending ? null : () => _send(q),
                            ),
                          ),
                      ],
                      for (final m in _messages) _Bubble(message: m),
                      if (_sending)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(children: [
                            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                            const SizedBox(width: 8),
                            Text(l.chatThinking),
                          ]),
                        ),
                    ],
                  ),
          ),
          if (user != null) ...[
            if (_photo != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(_photo!, width: 64, height: 64, fit: BoxFit.cover, semanticLabel: l.evidenceTypePhoto),
                  ),
                  IconButton(tooltip: l.chatRemovePhoto, onPressed: () => setState(() => _photo = null), icon: const Icon(Icons.close)),
                ]),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              color: scheme.surfaceContainer,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                IconButton(tooltip: l.chatAttachPhoto, onPressed: _pickPhoto, icon: const Icon(Icons.add_photo_alternate_outlined)),
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 5,
                    maxLength: 2000,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(hintText: l.chatHint, counterText: ''),
                  ),
                ),
                IconButton.filled(
                  tooltip: l.chatSend,
                  onPressed: _sending ? null : _send,
                  icon: const Icon(Icons.send),
                ),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final _Message message;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isUser = message.role == _Role.user;
    final isSystem = message.role == _Role.system;
    final bg = isUser ? scheme.primaryContainer : isSystem ? scheme.errorContainer : scheme.surfaceContainerHighest;
    final fg = isUser ? scheme.onPrimaryContainer : isSystem ? scheme.onErrorContainer : scheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.85),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (message.photo != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(message.photo!, height: 140, fit: BoxFit.cover, semanticLabel: l.evidenceTypePhoto),
            ),
            const SizedBox(height: 8),
          ],
          SelectableText(message.text, style: TextStyle(color: fg, fontSize: 17, height: 1.4)),
          if (message.mentionsEmergency) ...[
            const SizedBox(height: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: emergencyRed, foregroundColor: emergencyOnRed),
              onPressed: () => context.push('/emergency'),
              icon: const Icon(Icons.warning_rounded),
              label: Text(l.resultOpenEmergency),
            ),
          ],
        ]),
      ),
    );
  }
}
