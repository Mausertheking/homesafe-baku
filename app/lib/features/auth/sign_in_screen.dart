import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/firebase_bootstrap.dart';
import '../../core/settings.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import 'auth_service.dart';

/// Email + password sign-in / sign-up. Phone sign-in was removed on request.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _creating = false;
  bool _obscure = true;
  bool _busy = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String _message(AppLocalizations l, Object e) => switch (e) {
        AuthException(error: AuthError.invalidEmail) => l.authErrorInvalidEmail,
        AuthException(error: AuthError.emailOrPassword) => l.authErrorEmail,
        AuthException(error: AuthError.emailInUse) => l.authErrorEmailInUse,
        AuthException(error: AuthError.weakPassword) => l.authErrorWeakPassword,
        AuthException(error: AuthError.unavailable) => l.backendUnavailable,
        _ => l.errorGeneric,
      };

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await action();
      if (!mounted) return;
      if (success != null) setState(() => _info = success);
      if (ref.read(currentUserProvider) != null) _leave();
    } catch (e) {
      if (mounted) setState(() => _error = _message(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    final auth = ref.read(authServiceProvider);
    _run(() => _creating
        ? auth.createEmailAccount(_email.text, _password.text)
        : auth.signInWithEmail(_email.text, _password.text));
  }

  void _leave() => context.canPop() ? context.pop() : context.go('/');

  Future<void> _continueAsGuest() async {
    await ref.read(settingsProvider.notifier).setGuestMode(true);
    if (mounted) _leave();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final firebaseState = ref.watch(firebaseReadyProvider);
    final available = firebaseState.value == true;

    ref.listen(currentUserProvider, (_, user) {
      if (user != null && mounted) _leave();
    });

    return Scaffold(
      appBar: AppBar(actions: const [EmergencyAction()]),
      body: SafeArea(
        child: Form(
          key: _form,
          child: PageBody(children: [
            const Center(child: IconTile(icon: Icons.shield_outlined, size: 76)),
            const SizedBox(height: 20),
            Text(_creating ? l.signInCreateTitle : l.signInWelcome,
                textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(l.signInWhy, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 24),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: false, label: Text(l.signInModeSignIn)),
                ButtonSegment(value: true, label: Text(l.signInModeCreate)),
              ],
              selected: {_creating},
              onSelectionChanged: (s) => setState(() {
                _creating = s.first;
                _error = null;
                _info = null;
              }),
            ),
            const SizedBox(height: 20),
            if (firebaseState.hasValue && !available) ...[
              NoticeBanner(text: l.backendUnavailable, icon: Icons.cloud_off_rounded),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: l.emailLabel, prefixIcon: const Icon(Icons.mail_outline_rounded)),
              validator: (v) => (v == null || !v.contains('@')) ? l.authErrorInvalidEmail : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              autofillHints: [_creating ? AutofillHints.newPassword : AutofillHints.password],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: l.passwordLabel,
                helperText: _creating ? l.passwordHint : null,
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscure ? l.showPassword : l.hidePassword,
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) => (_creating && (v ?? '').length < 8) || (v ?? '').isEmpty ? l.authErrorWeakPassword : null,
            ),
            if (_error != null || _info != null) ...[
              const SizedBox(height: 14),
              Semantics(
                liveRegion: true,
                child: Text(_error ?? _info!,
                    style: TextStyle(
                        color: _error != null ? theme.colorScheme.error : theme.colorScheme.primary,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600)),
              ),
            ],
            if (_creating) ...[
              const SizedBox(height: 14),
              Text(l.signInAgree, style: theme.textTheme.bodyMedium),
              Wrap(spacing: 4, children: [
                TextButton(onPressed: () => context.push('/legal/terms'), child: Text(l.settingsTerms)),
                TextButton(onPressed: () => context.push('/legal/privacy'), child: Text(l.settingsPrivacy)),
              ]),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy || !available ? null : _submit,
              child: _busy
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : Text(_creating ? l.createAccount : l.signInEmail),
            ),
            if (!_creating)
              TextButton(
                onPressed: _busy || !available
                    ? null
                    : () => _run(() => ref.read(authServiceProvider).sendPasswordReset(_email.text),
                        success: l.resetEmailSent),
                child: Text(l.forgotPassword),
              ),
            const SizedBox(height: 16),
            Row(children: [
              const Expanded(child: Divider()),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(l.orDivider)),
              const Expanded(child: Divider()),
            ]),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _continueAsGuest,
              icon: const Icon(Icons.explore_outlined),
              label: Text(l.tryWithoutAccount),
            ),
            const SizedBox(height: 8),
            Text(l.guestNotice, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          ]),
        ),
      ),
    );
  }
}
