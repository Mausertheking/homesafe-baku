import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/analytics.dart';
import '../../core/callables.dart';
import '../../core/settings.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../home_profile/home_profile.dart';

/// Pick a date range; the generateReport function builds the PDF and returns
/// a short-lived signed link.
class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  late DateTimeRange _range = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 90)),
    end: DateTime.now(),
  );
  bool _busy = false;
  String? _url;
  String? _error;

  Future<void> _pick(bool start) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: start ? _range.start : _range.end,
    );
    if (picked == null) return;
    setState(() {
      _url = null;
      final s = start ? picked : _range.start;
      final e = start ? _range.end : picked;
      _range = s.isAfter(e) ? DateTimeRange(start: e, end: s) : DateTimeRange(start: s, end: e);
    });
  }

  Future<void> _generate() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await ref.read(callablesProvider).call('generateReport', {
        'homeId': ref.read(homeProfileProvider).id,
        'from': DateTime(_range.start.year, _range.start.month, _range.start.day).toUtc().toIso8601String(),
        'to': DateTime(_range.end.year, _range.end.month, _range.end.day, 23, 59, 59).toUtc().toIso8601String(),
        'language': ref.read(settingsProvider).language,
      }, timeout: const Duration(seconds: 120));
      ref.read(analyticsProvider).log('report_generated');
      setState(() => _url = res['url'] as String?);
    } on BackendUnavailable {
      setState(() => _error = l.backendUnavailable);
    } catch (_) {
      setState(() => _error = l.errorGeneric);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final fmt = DateFormat.yMMMd(ref.watch(settingsProvider.select((s) => s.language)));
    return Scaffold(
      appBar: AppBar(title: Text(l.reportTitle), actions: const [EmergencyAction()]),
      body: SafeArea(
        child: PageBody(children: [
          Text(l.reportIntro, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 20),
          ListTile(
            title: Text(l.reportFrom),
            subtitle: Text(fmt.format(_range.start), style: const TextStyle(fontSize: 18)),
            trailing: const Icon(Icons.edit_calendar),
            onTap: () => _pick(true),
          ),
          ListTile(
            title: Text(l.reportTo),
            subtitle: Text(fmt.format(_range.end), style: const TextStyle(fontSize: 18)),
            trailing: const Icon(Icons.edit_calendar),
            onTap: () => _pick(false),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _busy ? null : _generate,
            icon: _busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf),
            label: Text(_busy ? l.reportGenerating : l.reportGenerate),
          ),
          if (_error != null) ...[const SizedBox(height: 16), NoticeBanner(text: _error!, icon: Icons.error_outline)],
          if (_url != null) ...[
            const SizedBox(height: 20),
            NoticeBanner(text: '${l.reportReady} ${l.reportLinkExpires}', icon: Icons.check_circle_outline),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => launchUrl(Uri.parse(_url!), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new),
              label: Text(l.reportOpen),
            ),
          ],
        ]),
      ),
    );
  }
}
