import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:homesafe/rules_engine/rules_engine.dart';

RuleSet loadRuleSet(String name) =>
    RuleSet.fromJson(jsonDecode(File('assets/rules/$name.json').readAsStringSync()));

RuleSet inlineSet(List<Map<String, Object?>> rules) =>
    RuleSet.fromJson({'check': 'test', 'rulesVersion': 7, 'rules': rules});

Map<String, Object?> ruleJson(String id, Map<String, Object?> conditions,
        {String level = 'amber', bool emergency = false, List<String> steps = const ['step.a'], int priority = 0, String? category}) =>
    {
      'id': id,
      'hazard': 'co',
      'version': 1,
      'priority': priority,
      'conditions': conditions,
      'result': {
        'level': level,
        'emergency': emergency,
        'reason_key': 'rule.$id.reason',
        'steps_keys': steps,
        'category': ?category,
      },
    };

/// One answer set per sample rule that MUST trigger it. Every rule in the
/// bundled files needs an entry here (enforced below), so a rule can't ship
/// without a test.
const gasFixtures = <String, Map<String, Object?>>{
  'gas-smell-now': {'smell_gas_now': true},
  'co-alarm-sounding': {'co_alarm_sounding': true},
  'co-bathroom-heater-no-vent-symptoms': {
    'heater_location': 'bathroom',
    'has_working_vent': false,
    'symptom_headache_at_home': true,
  },
  'co-symptoms-better-outside': {
    'symptom_nausea_at_home': true,
    'symptoms_better_outside': true,
    'heating_type': 'gas_boiler',
  },
  'co-no-flue': {'flue_connected': false, 'heating_type': 'individual_gas_heater'},
  'co-bathroom-heater-no-vent': {'heater_location': 'bathroom', 'has_working_vent': false},
  'co-overnight-closed-room': {'heater_used_overnight_closed_room': true, 'flue_connected': 'not_sure'},
  'co-yellow-flame': {'flame_color': 'yellow_orange'},
  'co-soot-stains': {'soot_or_stains': true},
  'co-stove-for-heating': {'uses_stove_for_heating': true},
  'co-symptoms-gas-home': {'symptom_sleepy_at_home': true, 'heater_location': 'kitchen'},
  'co-no-alarm': {'has_co_alarm': 'no', 'heating_type': 'gas_boiler'},
  'gas-service-overdue': {'last_service_years': 2, 'heating_type': 'gas_boiler'},
  'gas-service-unknown': {'last_service_years': 99, 'heater_location': 'kitchen'},
  'co-vent-unknown': {'has_working_vent': 'not_sure', 'heater_location': 'kitchen'},
  'co-flue-unknown-old-building': {
    'flue_connected': 'not_sure',
    'building_age_band': '1960_1990',
    'heating_type': 'individual_gas_heater',
  },
  'co-flame-unknown': {'flame_color': 'not_sure', 'heating_type': 'gas_boiler'},
  'co-good-setup': {
    'heating_type': 'gas_boiler',
    'has_co_alarm': 'yes',
    'has_working_vent': true,
    'flue_connected': true,
    'flame_color': 'blue',
  },
  'gas-none-at-home': {'heating_type': 'electric', 'heater_location': 'none', 'uses_stove_for_heating': false},
};

const dampFixtures = <String, Map<String, Object?>>{
  'damp-leak-near-electrics': {'visible_leak': true, 'water_near_electrics': true},
  'damp-visible-leak': {'visible_leak': true},
  'damp-ceiling-flat-above': {'damp_location': 'ceiling', 'flat_above': true},
  'damp-ceiling-top-floor': {'damp_location': 'ceiling', 'flat_above': false},
  'damp-penetrating-outer-wall': {'on_outer_wall': true, 'worse_after_rain': true},
  'damp-rising-ground-floor': {'ground_floor': true, 'damp_pattern': 'tide_mark_low'},
  'damp-mold-vulnerable': {'vulnerable_occupant': true, 'musty_smell': true},
  'damp-large-area': {'mold_area': 'large'},
  'damp-condensation-winter': {'worse_in_winter': true, 'condensation_on_windows': true},
  'damp-wet-room-no-ventilation': {'damp_location': 'bathroom', 'ventilation_ok': false},
  'damp-cold-corner': {'on_outer_wall': true, 'worse_in_winter': true, 'damp_pattern': 'spots_corners'},
  'damp-drying-clothes': {'dries_clothes_indoors': true, 'condensation_on_windows': true},
  'damp-small-surface-mold': {'mold_area': 'small', 'visible_leak': false, 'vulnerable_occupant': false},
};

void main() {
  const engine = RulesEngine();
  final gas = loadRuleSet('gas_co');
  final damp = loadRuleSet('damp_mold');

  group('bundled rule files', () {
    test('have the required number of sample rules', () {
      expect(gas.rules.length, greaterThanOrEqualTo(15));
      expect(damp.rules.length, greaterThanOrEqualTo(10));
    });

    test('are all marked unreviewed until experts sign them off', () {
      for (final r in [...gas.rules, ...damp.rules]) {
        expect(r.reviewed, isFalse, reason: '${r.id} must stay reviewed:false until expert review');
      }
    });

    test('every rule has a test fixture, and every fixture has a rule', () {
      expect(gas.rules.map((r) => r.id).toSet(), gasFixtures.keys.toSet());
      expect(damp.rules.map((r) => r.id).toSet(), dampFixtures.keys.toSet());
    });

    test('the specification example rule is present and unchanged in meaning', () {
      final r = gas.rules.firstWhere((r) => r.id == 'co-bathroom-heater-no-vent-symptoms');
      expect(r.result.level, HazardLevel.red);
      expect(r.result.emergency, isTrue);
      expect(r.result.reasonKey, 'rule.co_bathroom_no_vent.reason');
      expect(r.result.stepKeys, ['step.leave_now', 'step.call_gas_emergency', 'step.see_doctor']);
      expect(r.conditions.fields, {
        'heater_location', 'has_working_vent', 'symptom_headache_at_home', 'symptom_dizziness_at_home'
      });
    });

    test('bundled copies match shared/ (run tool/sync_shared.sh if this fails)', () {
      for (final name in ['gas_co', 'damp_mold']) {
        expect(File('assets/rules/$name.json').readAsStringSync(),
            File('../shared/rules/$name.json').readAsStringSync());
      }
    });
  });

  for (final (set, fixtures) in [(gas, gasFixtures), (damp, dampFixtures)]) {
    group('${set.check} sample rules', () {
      for (final rule in set.rules) {
        test(rule.id, () {
          final answers = fixtures[rule.id]!;
          // 1. The fixture triggers this rule.
          expect(rule.matches(answers), isTrue, reason: 'fixture should match ${rule.id}');
          // 2. Nobody is matched by an empty questionnaire.
          expect(rule.matches(const {}), isFalse, reason: '${rule.id} must not match empty answers');
          // 3. In the full set the rule shows up, and the final level is at
          //    least as severe as this rule's level.
          final result = engine.evaluate(set, answers);
          expect(result.matchedRuleIds, contains(rule.id));
          expect(result.level.index, greaterThanOrEqualTo(rule.result.level.index));
          expect(result.reasonKeys, contains(rule.result.reasonKey));
          for (final s in rule.result.stepKeys) {
            expect(result.stepKeys, contains(s));
          }
          if (rule.result.emergency) expect(result.emergency, isTrue);
          // 4. The fixture only uses fields the rule actually reads, so it
          //    is a minimal, meaningful trigger (catches typos in field names).
          expect(rule.conditions.fields, containsAll(answers.keys),
              reason: '${rule.id}: fixture uses a field the rule does not read');
          // 5. Flipping each boolean answer the rule needs stops the match,
          //    which guards against inverted conditions.
          for (final MapEntry(:key, :value) in answers.entries) {
            if (value is! bool) continue;
            final flipped = {...answers, key: !value};
            if (rule.conditions is AllCondition &&
                (rule.conditions as AllCondition).children
                    .any((c) => c is FieldCondition && c.field == key && c.op == Operator.eq)) {
              expect(rule.matches(flipped), isFalse, reason: '${rule.id}: flipping $key should stop the match');
            }
          }
        });
      }
    });
  }

  group('gas and CO scenarios', () {
    test('a well set-up gas home is green with the "good setup" reason', () {
      final r = engine.evaluate(gas, {
        ...gasFixtures['co-good-setup']!,
        'heater_location': 'kitchen',
        'smell_gas_now': false,
        'co_alarm_sounding': false,
        'soot_or_stains': false,
        'uses_stove_for_heating': false,
        'heater_used_overnight_closed_room': false,
        'last_service_years': 0.5,
      });
      expect(r.level, HazardLevel.green);
      expect(r.emergency, isFalse);
      expect(r.matchedRuleIds, ['co-good-setup']);
    });

    test('classic bathroom geyser with no vent and headaches is red + emergency, all reasons shown', () {
      final r = engine.evaluate(gas, {
        'heater_location': 'bathroom',
        'heating_type': 'individual_gas_heater',
        'has_working_vent': false,
        'symptom_headache_at_home': true,
        'has_co_alarm': 'no',
      });
      expect(r.level, HazardLevel.red);
      expect(r.emergency, isTrue);
      expect(r.matchedRuleIds, containsAll([
        'co-bathroom-heater-no-vent-symptoms', 'co-bathroom-heater-no-vent', 'co-symptoms-gas-home', 'co-no-alarm',
      ]));
      // Emergency rule comes first, so its steps lead the list.
      expect(r.matched.first.result.emergency, isTrue);
      expect(r.stepKeys.first, 'step.leave_now');
      expect(r.reasonKeys.length, r.matched.length);
    });

    test('gas smell always wins, even with answers that otherwise look safe (conflicting answers)', () {
      final r = engine.evaluate(gas, {
        ...gasFixtures['co-good-setup']!,
        'smell_gas_now': true,
      });
      expect(r.level, HazardLevel.red);
      expect(r.emergency, isTrue);
      expect(r.matchedRuleIds.first, 'gas-smell-now');
      expect(r.matchedRuleIds, contains('co-good-setup')); // Green reason is still reported.
    });

    test('"no gas at home" profile but a sounding CO alarm is still an emergency', () {
      final r = engine.evaluate(gas, {
        ...gasFixtures['gas-none-at-home']!,
        'co_alarm_sounding': true,
      });
      expect(r.level, HazardLevel.red);
      expect(r.emergency, isTrue);
    });

    test('CO alarm reported "yes" and sounding at the same time: alarm wins', () {
      final r = engine.evaluate(gas, {'has_co_alarm': 'yes', 'co_alarm_sounding': true, 'heating_type': 'gas_boiler'});
      expect(r.level, HazardLevel.red);
      expect(r.matchedRuleIds, isNot(contains('co-no-alarm')));
    });

    test('missing answers: only a profile, no questions answered', () {
      final r = engine.evaluate(gas, {'heating_type': 'gas_boiler', 'heater_location': 'kitchen', 'has_co_alarm': 'not_sure'});
      expect(r.level, HazardLevel.amber);
      expect(r.matchedRuleIds, ['co-no-alarm']);
    });

    test('missing flue answer counts as "not confirmed" for the overnight rule (cautious by design)', () {
      final r = engine.evaluate(gas, {'heater_used_overnight_closed_room': true});
      expect(r.matchedRuleIds, contains('co-overnight-closed-room'));
      final safe = engine.evaluate(gas, {'heater_used_overnight_closed_room': true, 'flue_connected': true});
      expect(safe.matchedRuleIds, isNot(contains('co-overnight-closed-room')));
    });

    test('service interval boundaries: 1 year is fine, 99 means unknown, not overdue', () {
      Set<String> ids(num years) =>
          engine.evaluate(gas, {'last_service_years': years, 'heating_type': 'gas_boiler'}).matchedRuleIds.toSet();
      expect(ids(1), isNot(contains('gas-service-overdue')));
      expect(ids(2), contains('gas-service-overdue'));
      expect(ids(2.0), contains('gas-service-overdue'));
      expect(ids(99), {'gas-service-unknown'});
    });

    test('no answers at all gives the default green result', () {
      final r = engine.evaluate(gas, {});
      expect(r.level, HazardLevel.green);
      expect(r.noRuleMatched, isTrue);
      expect(r.reasonKeys, [defaultReasonKey]);
      expect(r.stepKeys, defaultStepKeys);
      expect(r.rulesVersion, gas.rulesVersion);
    });
  });

  group('damp and mold scenarios', () {
    test('typical winter condensation is classified as condensation only', () {
      final r = engine.evaluate(damp, {
        'damp_location': 'bedroom',
        'on_outer_wall': true,
        'worse_in_winter': true,
        'condensation_on_windows': true,
        'damp_pattern': 'spots_corners',
        'mold_area': 'small',
        'visible_leak': false,
        'vulnerable_occupant': false,
        'flat_above': true,
        'ground_floor': false,
        'worse_after_rain': false,
      });
      expect(r.categories, {'condensation'});
      expect(r.level, HazardLevel.amber);
    });

    test('ceiling stain under a neighbour is a likely leak', () {
      final r = engine.evaluate(damp, {'damp_location': 'ceiling', 'flat_above': true, 'visible_leak': true});
      expect(r.categories, {'leak'});
      expect(r.matchedRuleIds, containsAll(['damp-ceiling-flat-above', 'damp-visible-leak']));
    });

    test('ground floor tide mark plus rain penetration is structural', () {
      final r = engine.evaluate(damp, {
        'ground_floor': true,
        'damp_pattern': 'tide_mark_low',
        'on_outer_wall': true,
        'worse_after_rain': true,
      });
      expect(r.categories, {'structural'});
    });

    test('mixed causes are all reported', () {
      final r = engine.evaluate(damp, {
        'visible_leak': true,
        'worse_in_winter': true,
        'condensation_on_windows': true,
        'ground_floor': true,
        'damp_pattern': 'tide_mark_low',
      });
      expect(r.categories, {'leak', 'condensation', 'structural'});
    });

    test('a leak near electrics is red but does NOT open the gas emergency screen', () {
      final r = engine.evaluate(damp, dampFixtures['damp-leak-near-electrics']!);
      expect(r.level, HazardLevel.red);
      expect(r.emergency, isFalse);
    });

    test('conflicting answers: small mold area but a vulnerable person makes it amber', () {
      final r = engine.evaluate(damp, {'mold_area': 'small', 'visible_leak': false, 'vulnerable_occupant': true, 'musty_smell': true});
      expect(r.level, HazardLevel.amber);
      expect(r.matchedRuleIds, ['damp-mold-vulnerable']);
    });
  });

  group('evaluator operators', () {
    RuleSet single(Map<String, Object?> cond) => inlineSet([ruleJson('r', {'all': [cond]})]);
    bool hit(Map<String, Object?> cond, Map<String, Object?> answers) =>
        engine.evaluate(single(cond), answers).matchedRuleIds.isNotEmpty;

    test('eq does not coerce types', () {
      final c = {'field': 'x', 'op': 'eq', 'value': false};
      expect(hit(c, {'x': false}), isTrue);
      expect(hit(c, {'x': 'false'}), isFalse);
      expect(hit(c, {'x': 0}), isFalse);
      expect(hit({'field': 'n', 'op': 'eq', 'value': 2}, {'n': 2.0}), isTrue);
    });

    test('neq is false when the answer is missing', () {
      final c = {'field': 'x', 'op': 'neq', 'value': 'a'};
      expect(hit(c, {'x': 'b'}), isTrue);
      expect(hit(c, {'x': 'a'}), isFalse);
      expect(hit(c, {}), isFalse);
      expect(hit(c, {'x': null}), isFalse);
    });

    test('in matches any listed value', () {
      final c = {'field': 'x', 'op': 'in', 'value': ['a', 'b']};
      expect(hit(c, {'x': 'b'}), isTrue);
      expect(hit(c, {'x': 'c'}), isFalse);
      expect(hit(c, {}), isFalse);
    });

    test('gt and lt only compare numbers', () {
      expect(hit({'field': 'n', 'op': 'gt', 'value': 1}, {'n': 1.5}), isTrue);
      expect(hit({'field': 'n', 'op': 'gt', 'value': 1}, {'n': 1}), isFalse);
      expect(hit({'field': 'n', 'op': 'lt', 'value': 1}, {'n': 0}), isTrue);
      expect(hit({'field': 'n', 'op': 'gt', 'value': 1}, {'n': '5'}), isFalse);
      expect(hit({'field': 'n', 'op': 'lt', 'value': 1}, {}), isFalse);
    });

    test('exists true/false and default', () {
      expect(hit({'field': 'x', 'op': 'exists', 'value': true}, {'x': 0}), isTrue);
      expect(hit({'field': 'x', 'op': 'exists', 'value': true}, {'x': null}), isFalse);
      expect(hit({'field': 'x', 'op': 'exists', 'value': false}, {}), isTrue);
      expect(hit({'field': 'x', 'op': 'exists'}, {'x': false}), isTrue);
    });

    test('not, any and nesting', () {
      final c = {
        'any': [
          {'not': {'field': 'a', 'op': 'eq', 'value': true}},
          {'all': [
            {'field': 'b', 'op': 'eq', 'value': 1},
            {'field': 'c', 'op': 'exists', 'value': true},
          ]},
        ],
      };
      expect(hit(c, {'a': true}), isFalse);
      expect(hit(c, {}), isTrue); // not(missing == true) is true by design.
      expect(hit(c, {'a': true, 'b': 1, 'c': 'x'}), isTrue);
    });

    test('final level is the highest matched; reasons from every rule; steps de-duplicated', () {
      final set = inlineSet([
        ruleJson('g', {'all': [{'field': 'x', 'op': 'exists'}]}, level: 'green', steps: ['step.a', 'step.b'], priority: 999),
        ruleJson('r', {'all': [{'field': 'x', 'op': 'exists'}]}, level: 'red', steps: ['step.b', 'step.c'], priority: 1),
        ruleJson('a', {'all': [{'field': 'x', 'op': 'exists'}]}, level: 'amber', steps: ['step.a'], priority: 5),
        ruleJson('none', {'all': [{'field': 'y', 'op': 'exists'}]}, level: 'red', emergency: true),
      ]);
      final r = engine.evaluate(set, {'x': 1});
      expect(r.level, HazardLevel.red);
      expect(r.emergency, isFalse);
      expect(r.matchedRuleIds, ['r', 'a', 'g']); // Level beats priority.
      expect(r.reasonKeys, ['rule.r.reason', 'rule.a.reason', 'rule.g.reason']);
      expect(r.stepKeys, ['step.b', 'step.c', 'step.a']);
      expect(r.rulesVersion, 7);
    });

    test('same level is ordered by priority, then id', () {
      final set = inlineSet([
        ruleJson('b', {'all': [{'field': 'x', 'op': 'exists'}]}, priority: 1),
        ruleJson('a', {'all': [{'field': 'x', 'op': 'exists'}]}, priority: 1),
        ruleJson('c', {'all': [{'field': 'x', 'op': 'exists'}]}, priority: 9),
      ]);
      expect(engine.evaluate(set, {'x': 1}).matchedRuleIds, ['c', 'a', 'b']);
    });

    test('emergency flag from any matched rule', () {
      final set = inlineSet([
        ruleJson('e', {'all': [{'field': 'x', 'op': 'eq', 'value': true}]}, level: 'amber', emergency: true),
      ]);
      expect(engine.evaluate(set, {'x': true}).emergency, isTrue);
      expect(engine.evaluate(set, {'x': false}).emergency, isFalse);
    });

    test('categories are collected', () {
      final set = inlineSet([
        ruleJson('l', {'all': [{'field': 'x', 'op': 'exists'}]}, category: 'leak'),
        ruleJson('n', {'all': [{'field': 'x', 'op': 'exists'}]}),
      ]);
      expect(engine.evaluate(set, {'x': 1}).categories, {'leak'});
    });
  });

  group('invalid rule files are rejected', () {
    void bad(Map<String, Object?> cond) =>
        expect(() => inlineSet([ruleJson('r', cond)]), throwsA(isA<RuleFormatException>()));

    test('unknown operator', () => bad({'all': [{'field': 'x', 'op': 'contains', 'value': 1}]}));
    test('mixed group kinds', () => bad({'all': [], 'any': []}));
    test('field and group mixed', () => bad({'all': [], 'field': 'x'}));
    test('empty top-level conditions', () => bad({'all': []}));
    test('"in" without a list', () => bad({'all': [{'field': 'x', 'op': 'in', 'value': 'a'}]}));
    test('"gt" without a number', () => bad({'all': [{'field': 'x', 'op': 'gt', 'value': '1'}]}));
    test('"eq" without a value', () => bad({'all': [{'field': 'x', 'op': 'eq'}]}));
    test('missing field name', () => bad({'all': [{'op': 'eq', 'value': 1}]}));

    test('unknown level', () {
      final r = ruleJson('r', {'all': [{'field': 'x', 'op': 'exists'}]});
      (r['result'] as Map)['level'] = 'purple';
      expect(() => inlineSet([r]), throwsA(isA<RuleFormatException>()));
    });

    test('result text instead of a key is rejected', () {
      final r = ruleJson('r', {'all': [{'field': 'x', 'op': 'exists'}]});
      (r['result'] as Map).remove('reason_key');
      (r['result'] as Map)['reason'] = 'Some English text';
      expect(() => inlineSet([r]), throwsA(isA<RuleFormatException>()));
    });

    test('duplicate ids', () {
      final r = ruleJson('r', {'all': [{'field': 'x', 'op': 'exists'}]});
      expect(() => inlineSet([r, r]), throwsA(isA<RuleFormatException>()));
    });

    test('missing rulesVersion', () {
      expect(() => RuleSet.fromJson({'check': 'x', 'rules': []}), throwsA(isA<RuleFormatException>()));
    });
  });
}
