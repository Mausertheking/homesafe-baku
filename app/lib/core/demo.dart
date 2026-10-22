import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import 'widgets.dart';

/// Public web demo (GitHub Pages): built with `--dart-define=DEMO=true`.
/// There is no server behind it, so the app runs as a guest: everything that
/// works on the device is available; account features say they are off.
const demoMode = bool.fromEnvironment('DEMO');

/// Shown where a feature needs an account. In the demo it explains that the
/// feature is switched off instead of offering a sign-in that cannot work.
class AccountRequiredView extends StatelessWidget {
  const AccountRequiredView({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (demoMode) return UnavailableView(message: l.demoFeatureOff, icon: Icons.cloud_off_rounded);
    return UnavailableView(message: l.signInRequired, actionLabel: l.signIn, action: () => context.push('/sign-in'));
  }
}
