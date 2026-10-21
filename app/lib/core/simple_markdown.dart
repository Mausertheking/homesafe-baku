import 'package:flutter/material.dart';

/// Renders the small Markdown subset used by the legal texts: `#`/`##`
/// headings, `-` bullets, `1.` numbered steps, `**bold**` and paragraphs.
/// Kept tiny on purpose (no package, works offline, nothing executable).
class SimpleMarkdown extends StatelessWidget {
  const SimpleMarkdown(this.source, {super.key, this.skipTitle = false});
  final String source;

  /// Leave out the leading `# Title` line (when the app bar already shows it).
  final bool skipTitle;

  static final _numbered = RegExp(r'^(\d+)\.\s+(.*)$');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final children = <Widget>[];
    var lines = source.split('\n');
    if (skipTitle && lines.isNotEmpty && lines.first.startsWith('# ')) lines = lines.skip(1).toList();
    for (final raw in lines) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) {
        children.add(const SizedBox(height: 10));
      } else if (line.startsWith('# ')) {
        children.add(Semantics(
          header: true,
          child: Text(line.substring(2), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        ));
      } else if (line.startsWith('## ')) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 2),
          child: Semantics(header: true, child: Text(line.substring(3), style: theme.textTheme.titleMedium)),
        ));
      } else if (line.startsWith('- ')) {
        children.add(_Item(marker: '•', text: line.substring(2)));
      } else if (_numbered.hasMatch(line)) {
        final m = _numbered.firstMatch(line)!;
        children.add(_Item(marker: '${m[1]}.', text: m[2]!));
      } else {
        children.add(_Rich(line));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.marker, required this.text});
  final String marker;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 26,
            child: Text(marker, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
          ),
          Expanded(child: _Rich(text)),
        ]),
      );
}

/// A line with `**bold**` spans.
class _Rich extends StatelessWidget {
  const _Rich(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge;
    final parts = text.split('**');
    return Text.rich(TextSpan(style: style, children: [
      for (final (i, p) in parts.indexed)
        TextSpan(text: p, style: i.isOdd ? const TextStyle(fontWeight: FontWeight.w700) : null),
    ]));
  }
}
