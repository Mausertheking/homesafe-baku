import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:homesafe/features/checks/check_definitions.dart';
import 'package:homesafe/rules_engine/rules_engine.dart';

Map<String, String> arb(String path) {
  final raw = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  return {
    for (final e in raw.entries)
      if (!e.key.startsWith('@')) e.key: e.value as String,
  };
}

/// "All screens work in all three languages with no missing translations."
void main() {
  const langs = ['az', 'ru', 'en'];
  final app = {for (final l in langs) l: arb('lib/l10n/app_$l.arb')};
  final content = {for (final l in langs) l: arb('assets/l10n/content_$l.arb')};

  test('app ARB files have exactly the same keys in all languages, none empty', () {
    for (final l in langs) {
      expect(app[l]!.keys.toSet(), app['en']!.keys.toSet(), reason: 'app_$l.arb keys differ from English');
      for (final e in app[l]!.entries) {
        expect(e.value.trim(), isNotEmpty, reason: '$l: ${e.key} is empty');
      }
    }
  });

  test('placeholders match across languages', () {
    final placeholder = RegExp(r'\{(\w+)\}');
    for (final key in app['en']!.keys) {
      final expected = placeholder.allMatches(app['en']![key]!).map((m) => m[1]).toSet();
      for (final l in langs) {
        final got = placeholder.allMatches(app[l]![key]!).map((m) => m[1]).toSet();
        expect(got, expected, reason: '$l: placeholders of $key');
      }
    }
  });

  test('content ARB files have the same keys in all languages, none empty', () {
    for (final l in langs) {
      expect(content[l]!.keys.toSet(), content['en']!.keys.toSet(), reason: 'content_$l.arb keys differ');
      for (final e in content[l]!.entries) {
        expect(e.value.trim(), isNotEmpty, reason: '$l: ${e.key} is empty');
      }
    }
  });

  test('every rule reason and step key has text in every language', () {
    final keys = <String>{'rule.default.reason', ...defaultStepKeys};
    for (final name in ['gas_co', 'damp_mold']) {
      final set = RuleSet.fromJson(jsonDecode(File('assets/rules/$name.json').readAsStringSync()));
      for (final r in set.rules) {
        keys
          ..add(r.result.reasonKey)
          ..addAll(r.result.stepKeys);
      }
    }
    for (final l in langs) {
      final missing = keys.where((k) => !content[l]!.containsKey(k)).toList();
      expect(missing, isEmpty, reason: 'content_$l.arb is missing rule texts');
    }
  });

  test('every check question and option has text in every language', () {
    final keys = <String>{};
    for (final check in [gasCheck, dampCheck]) {
      for (final q in check.questions) {
        if (q.kind == QuestionKind.photos) continue;
        keys.add(q.titleKey);
        for (final o in q.options) {
          keys.add(q.optionKey(o));
        }
      }
    }
    for (final l in langs) {
      final missing = keys.where((k) => !content[l]!.containsKey(k)).toList();
      expect(missing, isEmpty, reason: 'content_$l.arb is missing question texts');
    }
  });

  test('every question field that rules read is asked or comes from the profile', () {
    const profileFields = {'heating_type', 'heater_location', 'has_co_alarm', 'building_age_band'};
    for (final (name, check) in [('gas_co', gasCheck), ('damp_mold', dampCheck)]) {
      final asked = {for (final q in check.questions) ...q.fields, ...profileFields};
      final set = RuleSet.fromJson(jsonDecode(File('assets/rules/$name.json').readAsStringSync()));
      for (final r in set.rules) {
        expect(asked, containsAll(r.conditions.fields), reason: '${r.id} reads a field no question asks');
      }
    }
  });

  test('emergency service labels exist for every bundled number', () {
    final config = jsonDecode(File('assets/config/emergency.json').readAsStringSync()) as Map;
    for (final n in config['numbers'] as List) {
      for (final l in langs) {
        expect(content[l]!.containsKey((n as Map)['labelKey']), isTrue);
      }
    }
  });

  test('Azerbaijani text uses the Azerbaijani letters (spot check)', () {
    final all = app['az']!.values.join(' ');
    for (final ch in ['ə', 'ğ', 'ı', 'ö', 'ü', 'ç', 'ş']) {
      expect(all.contains(ch), isTrue, reason: 'no "$ch" anywhere in app_az.arb');
    }
  });

  test('legal drafts exist in every language and stay labelled as drafts', () {
    for (final l in langs) {
      for (final kind in ['privacy', 'terms']) {
        final text = File('assets/legal/${kind}_$l.md').readAsStringSync();
        expect(text.startsWith('# '), isTrue, reason: '${kind}_$l.md needs a title');
        expect(text.length, greaterThan(1500), reason: '${kind}_$l.md looks incomplete');
      }
    }
    final rights = jsonDecode(File('assets/legal/rights.json').readAsStringSync()) as Map;
    expect(File('assets/legal/rights.json').readAsStringSync(), File('../shared/legal/rights.json').readAsStringSync());
    expect(rights['status'], 'draft', reason: 'flip only after a lawyer has reviewed every topic');
    final topics = rights['topics'] as List;
    expect(topics.map((t) => (t as Map)['id']).toSet(),
        {'repairs', 'written_contracts', 'deposits', 'inspections', 'owners_duties'});
    for (final t in topics.cast<Map>()) {
      for (final field in ['title', 'body', 'lawReference']) {
        for (final l in langs) {
          expect(((t[field] as Map)[l] as String).trim(), isNotEmpty, reason: '${t['id']}.$field.$l');
        }
      }
      expect(t.containsKey('reviewedBy'), isFalse, reason: 'never ship a fake reviewer');
    }
  });
}
