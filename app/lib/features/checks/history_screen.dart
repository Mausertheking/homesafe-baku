import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/settings.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import 'check_history.dart';

/// All checks done on this phone, newest first. Tap to reopen the result.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final history = ref.watch(checkHistoryProvider);
    final lang = ref.watch(settingsProvider.select((s) => s.language));
    final fmt = DateFormat.yMMMd(lang).add_Hm();

    return Scaffold(
      appBar: AppBar(title: Text(l.historyTitle), actions: const [EmergencyAction()]),
      body: SafeArea(
        child: history.isEmpty
            ? UnavailableView(message: l.historyEmpty, icon: Icons.history_rounded)
            : PageBody(children: [
                NoticeBanner(text: l.historyOnDevice, icon: Icons.phone_iphone_rounded),
                const SizedBox(height: 16),
                for (final c in history)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: IconTile(
                          icon: c.checkId == 'gas_co' ? Icons.local_fire_department_outlined : Icons.water_damage_outlined,
                        ),
                        title: Text(c.checkId == 'gas_co' ? l.checkGasTitle : l.checkDampTitle,
                            style: Theme.of(context).textTheme.titleMedium),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                            LevelBadge(level: c.level),
                            Text(fmt.format(c.at)),
                          ]),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () async {
                          final outcome = await ref.read(checkHistoryProvider.notifier).reopen(c);
                          if (context.mounted) context.push('/result', extra: outcome);
                        },
                      ),
                    ),
                  ),
              ]),
      ),
    );
  }
}
