import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/settings.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../checks/check_history.dart';
import '../home_profile/home_profile.dart';

/// October to April. Pure function so it is easy to test.
bool isHeatingSeason(DateTime now) => now.month >= 10 || now.month <= 4;

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key, this.now});

  /// Injectable clock for tests.
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final profile = ref.watch(homeProfileProvider);
    final history = ref.watch(checkHistoryProvider);

    final tools = [
      (Icons.fact_check_outlined, l.cardEvidenceTitle, l.cardEvidenceBody, '/evidence'),
      (Icons.mail_outline_rounded, l.cardLettersTitle, l.cardLettersBody, '/letters'),
      (Icons.gavel_rounded, l.cardRightsTitle, l.cardRightsBody, '/rights'),
      (Icons.forum_outlined, l.cardAskTitle, l.cardAskBody, '/chat'),
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(children: [
          const IconTile(icon: Icons.shield_rounded, size: 34),
          const SizedBox(width: 10),
          Flexible(
            child: Text(l.appTitle,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          ),
        ]),
        actions: [
          IconButton(
            tooltip: l.settingsTooltip,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: PageBody(children: [
          // Always first, always visible.
          const EmergencyBanner(),
          const SizedBox(height: 14),
          if (isHeatingSeason((now ?? DateTime.now)())) ...[
            _InfoCard(icon: Icons.thermostat_rounded, title: l.seasonalTitle, body: l.seasonalBody),
            const SizedBox(height: 12),
          ],
          if (!profile.isComplete) ...[
            _InfoCard(
              icon: Icons.home_work_outlined,
              title: l.profileTitle,
              body: l.profileMissing,
              action: l.profileSetUp,
              onTap: () => context.push('/profile'),
              accent: true,
            ),
            const SizedBox(height: 12),
          ],
          SectionHeader(
            l.dashboardStatusTitle,
            trailing: history.isEmpty
                ? null
                : TextButton(onPressed: () => context.push('/history'), child: Text(l.viewAll)),
          ),
          Card(
            child: Column(children: [
              _CheckRow(
                checkId: 'gas_co',
                icon: Icons.local_fire_department_outlined,
                title: l.cardGasTitle,
                body: l.cardGasBody,
              ),
              const Divider(indent: 16, endIndent: 16),
              _CheckRow(
                checkId: 'damp_mold',
                icon: Icons.water_damage_outlined,
                title: l.cardDampTitle,
                body: l.cardDampBody,
              ),
            ]),
          ),
          const SizedBox(height: 12),
          SectionHeader(l.dashboardToolsTitle),
          LayoutBuilder(builder: (context, c) {
            // Two columns normally, one column at very large font sizes.
            final scale = MediaQuery.textScalerOf(context).scale(1);
            final columns = scale > 1.5 || c.maxWidth < 300 ? 1 : 2;
            const gap = 12.0;
            return Wrap(spacing: gap, runSpacing: gap, children: [
              for (final (icon, title, body, route) in tools)
                SizedBox(
                  width: (c.maxWidth - gap * (columns - 1)) / columns,
                  child: _ToolCard(icon: icon, title: title, body: body, onTap: () => context.push(route)),
                ),
            ]);
          }),
        ]),
      ),
    );
  }
}

/// One check on the status card: latest result (or "not checked yet") and a
/// button to start / repeat. Tapping a past result reopens it.
class _CheckRow extends ConsumerWidget {
  const _CheckRow({required this.checkId, required this.icon, required this.title, required this.body});
  final String checkId;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    ref.watch(checkHistoryProvider);
    final latest = ref.read(checkHistoryProvider.notifier).latest(checkId);
    final lang = ref.watch(settingsProvider.select((s) => s.language));

    Future<void> reopen() async {
      final outcome = await ref.read(checkHistoryProvider.notifier).reopen(latest!);
      if (context.mounted) context.push('/result', extra: outcome);
    }

    return InkWell(
      borderRadius: BorderRadius.circular(radiusLarge),
      onTap: latest == null ? () => context.push('/check/$checkId') : reopen,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          IconTile(icon: icon, size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              if (latest == null)
                Text('${l.statusNotChecked} · ${l.checkMinutes}', style: theme.textTheme.bodyMedium)
              else
                Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  LevelBadge(level: latest.level),
                  Text(l.statusCheckedOn(DateFormat.MMMd(lang).format(latest.at)), style: theme.textTheme.bodyMedium),
                ]),
            ]),
          ),
          const SizedBox(width: 8),
          latest == null
              ? FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(48, 48), padding: const EdgeInsets.symmetric(horizontal: 16)),
                  onPressed: () => context.push('/check/$checkId'),
                  child: Text(l.statusStart),
                )
              : IconButton.filledTonal(
                  tooltip: l.statusAgain,
                  onPressed: () => context.push('/check/$checkId'),
                  icon: const Icon(Icons.refresh_rounded),
                ),
        ]),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.icon, required this.title, required this.body, required this.onTap});
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: true,
        label: '$title. $body',
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 148),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                IconTile(icon: icon, size: 44),
                const SizedBox(height: 12),
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(body, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title, required this.body, this.action, this.onTap, this.accent = false});
  final IconData icon;
  final String title;
  final String body;
  final String? action;
  final VoidCallback? onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = accent ? scheme.primaryContainer : scheme.tertiaryContainer;
    final fg = accent ? scheme.onPrimaryContainer : scheme.onTertiaryContainer;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(radiusLarge),
      child: InkWell(
        borderRadius: BorderRadius.circular(radiusLarge),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            ExcludeSemantics(child: Icon(icon, color: fg, size: 30)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16.5, color: fg)),
                const SizedBox(height: 2),
                Text(body, style: TextStyle(color: fg, fontSize: 15, height: 1.35)),
              ]),
            ),
            if (action != null) ...[
              const SizedBox(width: 8),
              Text(action!, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 15)),
              Icon(Icons.chevron_right_rounded, color: fg),
            ],
          ]),
        ),
      ),
    );
  }
}
