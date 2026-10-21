import '../../rules_engine/rules_engine.dart';
import '../home_profile/home_profile.dart';

enum QuestionKind {
  /// Yes / No. Stores true / false.
  yesNo,

  /// Yes / No / Not sure. Stores true / false / "not_sure".
  yesNoUnsure,

  /// One option from a list. Stores the option's value.
  single,

  /// Several yes/no facts on one screen (e.g. symptoms). Each option is its
  /// own boolean field; unticked options are stored as false.
  multiBool,

  /// Damp check only: 1 to 5 photos. Not used by rules.
  photos,
}

class QuestionOption {
  const QuestionOption(this.key, this.value);

  /// Text key suffix: `q.<question>.opt.<key>`
  final String key;
  final Object value;
}

class Question {
  const Question(
    this.id, {
    required this.kind,
    this.options = const [],
    this.prefill,
    this.showIf,
  });

  final String id;
  final QuestionKind kind;
  final List<QuestionOption> options;

  /// Fills the answer from the home profile so the user only confirms it.
  final Object? Function(HomeProfile profile)? prefill;

  /// Question is skipped (and its answer removed) when this returns false.
  final bool Function(Answers answers)? showIf;

  String get titleKey => 'q.$id.title';
  String get helpKey => 'q.$id.help';
  String optionKey(QuestionOption o) => 'q.$id.opt.${o.key}';

  /// Fields this question writes.
  List<String> get fields => kind == QuestionKind.multiBool
      ? [for (final o in options) o.key]
      : kind == QuestionKind.photos
          ? const []
          : [id];
}

class CheckDefinition {
  const CheckDefinition({required this.id, required this.questions});
  final String id; // Matches the rule file: gas_co, damp_mold.
  final List<Question> questions;

  List<Question> visibleQuestions(Answers answers) =>
      [for (final q in questions) if (q.showIf == null || q.showIf!(answers)) q];
}

bool _gasPresent(Answers a) =>
    const ['individual_gas_heater', 'gas_boiler'].contains(a['heating_type']) ||
    const ['bathroom', 'kitchen', 'other'].contains(a['heater_location']);

bool _anySymptom(Answers a) => const [
      'symptom_headache_at_home',
      'symptom_dizziness_at_home',
      'symptom_nausea_at_home',
      'symptom_sleepy_at_home',
    ].any((f) => a[f] == true);

/// Gas and CO: urgent questions first so an emergency is caught on screen 1-2.
const gasCheck = CheckDefinition(id: 'gas_co', questions: [
  Question('smell_gas_now', kind: QuestionKind.yesNo),
  Question('co_alarm_sounding', kind: QuestionKind.yesNo),
  Question('heater_location',
      kind: QuestionKind.single, options: _heaterLocations, prefill: _prefillHeaterLocation),
  Question('heating_type', kind: QuestionKind.single, options: _heatingTypes, prefill: _prefillHeating),
  Question('has_working_vent', kind: QuestionKind.yesNoUnsure, showIf: _gasPresent),
  Question('flue_connected', kind: QuestionKind.yesNoUnsure, showIf: _gasPresent),
  Question('flame_color', kind: QuestionKind.single, options: _flameColors, showIf: _gasPresent),
  Question('soot_or_stains', kind: QuestionKind.yesNo, showIf: _gasPresent),
  Question('symptoms', kind: QuestionKind.multiBool, options: _symptoms),
  Question('symptoms_better_outside', kind: QuestionKind.yesNoUnsure, showIf: _anySymptom),
  Question('last_service_years', kind: QuestionKind.single, options: _serviceAges, showIf: _gasPresent),
  Question('has_co_alarm', kind: QuestionKind.single, options: _coAlarm, prefill: _prefillCoAlarm),
  Question('heater_used_overnight_closed_room', kind: QuestionKind.yesNo),
  Question('uses_stove_for_heating', kind: QuestionKind.yesNo),
]);

const dampCheck = CheckDefinition(id: 'damp_mold', questions: [
  Question('photos', kind: QuestionKind.photos),
  Question('damp_location', kind: QuestionKind.single, options: _dampLocations),
  Question('on_outer_wall', kind: QuestionKind.yesNoUnsure),
  Question('damp_pattern', kind: QuestionKind.single, options: _dampPatterns),
  Question('mold_area', kind: QuestionKind.single, options: _moldAreas),
  Question('worse_in_winter', kind: QuestionKind.yesNoUnsure),
  Question('worse_after_rain', kind: QuestionKind.yesNoUnsure),
  Question('condensation_on_windows', kind: QuestionKind.yesNo),
  Question('musty_smell', kind: QuestionKind.yesNo),
  Question('visible_leak', kind: QuestionKind.yesNo),
  Question('water_near_electrics', kind: QuestionKind.yesNo, showIf: _leakVisible),
  Question('flat_above', kind: QuestionKind.yesNo),
  Question('ground_floor', kind: QuestionKind.yesNo),
  Question('ventilation_ok', kind: QuestionKind.yesNo),
  Question('dries_clothes_indoors', kind: QuestionKind.yesNo),
  Question('vulnerable_occupant', kind: QuestionKind.yesNo),
]);

CheckDefinition checkById(String id) => id == gasCheck.id ? gasCheck : dampCheck;

bool _leakVisible(Answers a) => a['visible_leak'] == true;
Object? _prefillHeaterLocation(HomeProfile p) => p.heaterLocation;
Object? _prefillHeating(HomeProfile p) => p.heatingType;
Object? _prefillCoAlarm(HomeProfile p) => p.hasCoAlarm;

const _heaterLocations = [
  QuestionOption('bathroom', 'bathroom'),
  QuestionOption('kitchen', 'kitchen'),
  QuestionOption('other', 'other'),
  QuestionOption('none', 'none'),
];
const _heatingTypes = [
  QuestionOption('individual_gas_heater', 'individual_gas_heater'),
  QuestionOption('gas_boiler', 'gas_boiler'),
  QuestionOption('central_heating', 'central_heating'),
  QuestionOption('electric', 'electric'),
  QuestionOption('other', 'other'),
];
const _flameColors = [
  QuestionOption('blue', 'blue'),
  QuestionOption('yellow_orange', 'yellow_orange'),
  QuestionOption('not_sure', 'not_sure'),
];
const _symptoms = [
  QuestionOption('symptom_headache_at_home', true),
  QuestionOption('symptom_dizziness_at_home', true),
  QuestionOption('symptom_nausea_at_home', true),
  QuestionOption('symptom_sleepy_at_home', true),
];

/// Numbers in years, compared by the rules with gt/lt. 99 = never/unknown.
const _serviceAges = [
  QuestionOption('under_1', 0.5),
  QuestionOption('one_to_three', 2),
  QuestionOption('over_3', 4),
  QuestionOption('unknown', 99),
];
const _coAlarm = [
  QuestionOption('yes', 'yes'),
  QuestionOption('no', 'no'),
  QuestionOption('not_sure', 'not_sure'),
];
const _dampLocations = [
  QuestionOption('bathroom', 'bathroom'),
  QuestionOption('kitchen', 'kitchen'),
  QuestionOption('bedroom', 'bedroom'),
  QuestionOption('living_room', 'living_room'),
  QuestionOption('ceiling', 'ceiling'),
  QuestionOption('other', 'other'),
];
const _dampPatterns = [
  QuestionOption('spots_corners', 'spots_corners'),
  QuestionOption('patch_ceiling', 'patch_ceiling'),
  QuestionOption('tide_mark_low', 'tide_mark_low'),
  QuestionOption('spreading_patch', 'spreading_patch'),
  QuestionOption('not_sure', 'not_sure'),
];
const _moldAreas = [
  QuestionOption('small', 'small'),
  QuestionOption('medium', 'medium'),
  QuestionOption('large', 'large'),
];
