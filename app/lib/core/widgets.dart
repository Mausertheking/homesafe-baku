import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import 'theme.dart';

/// Large red emergency button, always first on the dashboard.
class EmergencyBanner extends StatelessWidget {
  const EmergencyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l.emergencyButton,
      hint: l.emergencyButtonHint,
      excludeSemantics: true,
      child: Material(
        color: emergencyRed,
        borderRadius: BorderRadius.circular(radiusLarge),
        child: InkWell(
          borderRadius: BorderRadius.circular(radiusLarge),
          onTap: () => context.push('/emergency'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
            child: Row(children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
                child: const Icon(Icons.warning_rounded, color: emergencyOnRed, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.emergencyButton,
                      style: const TextStyle(color: emergencyOnRed, fontSize: 24, fontWeight: FontWeight.w800, height: 1.1)),
                  const SizedBox(height: 2),
                  Text(l.emergencyBannerSub,
                      style: TextStyle(color: emergencyOnRed.withValues(alpha: 0.92), fontSize: 14.5, height: 1.3)),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded, color: emergencyOnRed, size: 30),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Compact emergency action for app bars.
class EmergencyAction extends StatelessWidget {
  const EmergencyAction({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Semantics(
        button: true,
        label: l.emergencyButton,
        hint: l.emergencyButtonHint,
        excludeSemantics: true,
        child: Tooltip(
          message: l.emergencyButton,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: emergencyRed,
              foregroundColor: emergencyOnRed,
              minimumSize: const Size(48, 44),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w800),
            ),
            onPressed: () => context.push('/emergency'),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.warning_rounded, size: 20),
              const SizedBox(width: 6),
              Text(l.emergencyButton),
            ]),
          ),
        ),
      ),
    );
  }
}

/// A full-width answer card used in one-question-per-screen flows.
class ChoiceButton extends StatelessWidget {
  const ChoiceButton({super.key, required this.label, required this.selected, required this.onTap, this.icon});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        selected: selected,
        button: true,
        inMutuallyExclusiveGroup: true,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: selected ? scheme.primaryContainer : scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(radiusMedium + 2),
            border: Border.all(color: selected ? scheme.primary : scheme.outlineVariant, width: selected ? 2.5 : 1.5),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(radiusMedium + 2),
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 64),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(children: [
                    if (icon != null) ...[
                      Icon(icon, color: selected ? scheme.onPrimaryContainer : scheme.primary),
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: Text(label,
                          style: TextStyle(
                            fontSize: 17.5,
                            fontWeight: FontWeight.w600,
                            color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
                          )),
                    ),
                    const SizedBox(width: 8),
                    ExcludeSemantics(
                      child: Icon(
                        selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: selected ? scheme.primary : scheme.outline,
                        size: 26,
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Calm information banner (notices, disclaimers).
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({super.key, required this.text, this.icon = Icons.info_outline_rounded, this.warning = false});
  final String text;
  final IconData icon;

  /// Amber "pay attention" style (drafts, unreviewed content).
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final amber = levelPalette('amber', Theme.of(context).brightness);
    final bg = warning ? amber.soft : scheme.surfaceContainerLow;
    final fg = warning ? amber.onSoft : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(radiusMedium)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ExcludeSemantics(child: Icon(icon, color: warning ? amber.onSoft : scheme.primary, size: 22)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style: TextStyle(color: fg, fontSize: 15, height: 1.4, fontWeight: warning ? FontWeight.w600 : null)),
        ),
      ]),
    );
  }
}

/// Section title used on dashboard and result screens.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 10),
        child: Row(children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(text, style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          ?trailing,
        ]),
      );
}

/// Rounded, tinted square with an icon.
class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.icon, this.color, this.background, this.size = 48});
  final IconData icon;
  final Color? color;
  final Color? background;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background ?? scheme.primaryContainer,
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: Icon(icon, color: color ?? scheme.onPrimaryContainer, size: size * 0.55),
      ),
    );
  }
}

/// Pill showing Urgent / Serious / Monitor.
class LevelBadge extends StatelessWidget {
  const LevelBadge({super.key, required this.level, this.large = false});
  final String level; // red | amber | green
  final bool large;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = levelPalette(level, Theme.of(context).brightness);
    final (label, icon) = switch (level) {
      'red' => (l.levelRed, Icons.error_rounded),
      'amber' => (l.levelAmber, Icons.warning_amber_rounded),
      _ => (l.levelGreen, Icons.check_circle_rounded),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 14 : 10, vertical: large ? 8 : 5),
      decoration: BoxDecoration(color: p.soft, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: large ? 20 : 16, color: p.strong),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: p.onSoft, fontWeight: FontWeight.w700, fontSize: large ? 16 : 13.5)),
      ]),
    );
  }
}

/// Shown when a feature needs sign-in / the backend and it is not there.
class UnavailableView extends StatelessWidget {
  const UnavailableView({super.key, required this.message, this.action, this.actionLabel, this.icon = Icons.lock_outline_rounded});
  final String message;
  final VoidCallback? action;
  final String? actionLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          IconTile(icon: icon, size: 72),
          const SizedBox(height: 20),
          Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
          if (action != null) ...[
            const SizedBox(height: 20),
            FilledButton(onPressed: action, child: Text(actionLabel!)),
          ],
        ]),
      ),
    );
  }
}

/// Standard page padding + max width so tablets and the web preview look right.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 32), this.controller});
  final List<Widget> children;
  final EdgeInsets padding;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(controller: controller, padding: padding, children: children),
      ),
    );
  }
}
