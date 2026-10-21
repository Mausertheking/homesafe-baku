// Generates gas_co.json and damp_mold.json. Kept as a script so the shared
// "gas present" sub-condition is written once. Run: node build_rules.mjs
// The generated JSON files are the source of truth that ships in the app.
import { writeFileSync } from 'node:fs';

const f = (field, op, value) => (value === undefined ? { field, op } : { field, op, value });
const eq = (field, value) => f(field, 'eq', value);
const anyOf = (...c) => ({ any: c });
const allOf = (...c) => ({ all: c });
const not = (c) => ({ not: c });

const GAS_PRESENT = anyOf(
  f('heating_type', 'in', ['individual_gas_heater', 'gas_boiler']),
  f('heater_location', 'in', ['bathroom', 'kitchen', 'other']),
);
const ANY_SYMPTOM = anyOf(
  eq('symptom_headache_at_home', true),
  eq('symptom_dizziness_at_home', true),
  eq('symptom_nausea_at_home', true),
  eq('symptom_sleepy_at_home', true),
);
const review = { reviewed: false, reviewedBy: null, reviewedOn: null }; // TODO(chemical engineer): review every rule.

function rule(id, hazard, priority, conditions, level, reason, steps, extra = {}) {
  return {
    id, hazard, version: 1, priority, ...review, conditions,
    result: { level, emergency: extra.emergency === true, ...(extra.category ? { category: extra.category } : {}),
      reason_key: `rule.${reason}.reason`, steps_keys: steps.map((s) => `step.${s}`) },
  };
}

const gas = [
  rule('gas-smell-now', 'gas', 1000, allOf(eq('smell_gas_now', true)), 'red', 'gas_smell_now',
    ['leave_now', 'no_switches', 'call_gas_emergency_outside', 'dont_go_back'], { emergency: true }),
  rule('co-alarm-sounding', 'co', 990, allOf(eq('co_alarm_sounding', true)), 'red', 'co_alarm_sounding',
    ['leave_now', 'call_gas_emergency_outside', 'dont_go_back', 'see_doctor'], { emergency: true }),
  // The example rule from the specification, kept with its original id.
  rule('co-bathroom-heater-no-vent-symptoms', 'co', 900, allOf(
    eq('heater_location', 'bathroom'), eq('has_working_vent', false),
    anyOf(eq('symptom_headache_at_home', true), eq('symptom_dizziness_at_home', true)),
  ), 'red', 'co_bathroom_no_vent', ['leave_now', 'call_gas_emergency', 'see_doctor'], { emergency: true }),
  rule('co-symptoms-better-outside', 'co', 880, allOf(ANY_SYMPTOM, eq('symptoms_better_outside', true), GAS_PRESENT),
    'red', 'co_symptoms_better_outside', ['leave_now', 'call_gas_emergency_outside', 'see_doctor'], { emergency: true }),
  rule('co-no-flue', 'co', 800, allOf(eq('flue_connected', false), GAS_PRESENT), 'red', 'co_no_flue',
    ['stop_using_appliance', 'call_gas_service', 'install_co_alarm']),
  rule('co-bathroom-heater-no-vent', 'co', 780, allOf(eq('heater_location', 'bathroom'), eq('has_working_vent', false)),
    'red', 'co_bathroom_heater_no_vent', ['stop_using_appliance', 'call_gas_service', 'install_co_alarm']),
  rule('co-overnight-closed-room', 'co', 760, allOf(eq('heater_used_overnight_closed_room', true), not(eq('flue_connected', true))),
    'red', 'co_overnight_closed_room', ['no_overnight_heater', 'ventilate', 'install_co_alarm']),
  rule('co-yellow-flame', 'co', 600, allOf(eq('flame_color', 'yellow_orange')), 'amber', 'co_yellow_flame',
    ['call_gas_service', 'install_co_alarm']),
  rule('co-soot-stains', 'co', 590, allOf(eq('soot_or_stains', true)), 'amber', 'co_soot_stains',
    ['call_gas_service', 'install_co_alarm']),
  rule('co-stove-for-heating', 'co', 580, allOf(eq('uses_stove_for_heating', true)), 'amber', 'co_stove_for_heating',
    ['dont_heat_with_stove', 'ventilate']),
  rule('co-symptoms-gas-home', 'co', 570, allOf(ANY_SYMPTOM, GAS_PRESENT), 'amber', 'co_symptoms_gas_home',
    ['see_doctor', 'call_gas_service', 'install_co_alarm']),
  rule('co-no-alarm', 'co', 500, allOf(f('has_co_alarm', 'in', ['no', 'not_sure']), GAS_PRESENT), 'amber', 'co_no_alarm',
    ['install_co_alarm']),
  rule('gas-service-overdue', 'gas', 450, allOf(f('last_service_years', 'gt', 1), f('last_service_years', 'lt', 50), GAS_PRESENT),
    'amber', 'gas_service_overdue', ['call_gas_service']),
  rule('gas-service-unknown', 'gas', 440, allOf(f('last_service_years', 'gt', 50), GAS_PRESENT), 'amber', 'gas_service_unknown',
    ['call_gas_service']),
  rule('co-vent-unknown', 'co', 420, allOf(eq('has_working_vent', 'not_sure'), f('heater_location', 'in', ['bathroom', 'kitchen', 'other'])),
    'amber', 'co_vent_unknown', ['check_vent', 'call_gas_service']),
  rule('co-flue-unknown-old-building', 'co', 410, allOf(eq('flue_connected', 'not_sure'),
    f('building_age_band', 'in', ['before_1960', '1960_1990']), GAS_PRESENT), 'amber', 'co_flue_unknown_old_building',
    ['check_chimney', 'call_gas_service']),
  rule('co-flame-unknown', 'co', 300, allOf(eq('flame_color', 'not_sure'), GAS_PRESENT), 'green', 'co_flame_unknown',
    ['look_at_flame']),
  rule('co-good-setup', 'co', 100, allOf(GAS_PRESENT, eq('has_co_alarm', 'yes'), eq('has_working_vent', true),
    eq('flue_connected', true), eq('flame_color', 'blue')), 'green', 'co_good_setup',
    ['test_co_alarm_monthly', 'yearly_service']),
  rule('gas-none-at-home', 'gas', 90, allOf(f('heating_type', 'in', ['central_heating', 'electric']),
    eq('heater_location', 'none'), eq('uses_stove_for_heating', false)), 'green', 'gas_none_at_home',
    ['ventilate_kitchen']),
];

const damp = [
  rule('damp-leak-near-electrics', 'damp', 900, allOf(eq('visible_leak', true), eq('water_near_electrics', true)),
    'red', 'damp_leak_near_electrics', ['electrics_off_if_safe', 'call_building_manager', 'document_evidence'], { category: 'leak' }),
  rule('damp-visible-leak', 'damp', 700, allOf(eq('visible_leak', true)), 'amber', 'damp_visible_leak',
    ['find_leak_source', 'contact_landlord', 'document_evidence'], { category: 'leak' }),
  rule('damp-ceiling-flat-above', 'damp', 690, allOf(eq('damp_location', 'ceiling'), eq('flat_above', true)),
    'amber', 'damp_ceiling_flat_above', ['ask_neighbour_above', 'call_building_manager', 'document_evidence'], { category: 'leak' }),
  rule('damp-ceiling-top-floor', 'damp', 680, allOf(eq('damp_location', 'ceiling'), eq('flat_above', false)),
    'amber', 'damp_ceiling_top_floor', ['report_roof', 'document_evidence'], { category: 'leak' }),
  rule('damp-penetrating-outer-wall', 'damp', 650, allOf(eq('on_outer_wall', true), eq('worse_after_rain', true)),
    'amber', 'damp_penetrating_outer_wall', ['check_facade', 'call_building_manager', 'document_evidence'], { category: 'structural' }),
  rule('damp-rising-ground-floor', 'damp', 640, allOf(eq('ground_floor', true), eq('damp_pattern', 'tide_mark_low')),
    'amber', 'damp_rising_ground_floor', ['get_damp_survey', 'document_evidence'], { category: 'structural' }),
  rule('damp-mold-vulnerable', 'damp', 620, allOf(eq('vulnerable_occupant', true), anyOf(eq('musty_smell', true),
    eq('damp_pattern', 'spots_corners'), f('mold_area', 'in', ['medium', 'large']))), 'amber', 'damp_mold_vulnerable',
    ['see_doctor_breathing', 'keep_vulnerable_away', 'contact_landlord']),
  rule('damp-large-area', 'damp', 600, allOf(eq('mold_area', 'large')), 'amber', 'damp_large_area',
    ['professional_mold_removal', 'document_evidence']),
  rule('damp-condensation-winter', 'damp', 500, allOf(eq('worse_in_winter', true), eq('condensation_on_windows', true)),
    'amber', 'damp_condensation_winter', ['ventilate_daily', 'wipe_condensation', 'heat_evenly'], { category: 'condensation' }),
  rule('damp-wet-room-no-ventilation', 'damp', 490, allOf(f('damp_location', 'in', ['bathroom', 'kitchen']), eq('ventilation_ok', false)),
    'amber', 'damp_wet_room_no_ventilation', ['ventilate_daily', 'extractor_fan'], { category: 'condensation' }),
  rule('damp-cold-corner', 'damp', 480, allOf(eq('on_outer_wall', true), eq('worse_in_winter', true), eq('damp_pattern', 'spots_corners')),
    'amber', 'damp_cold_corner', ['heat_evenly', 'move_furniture_from_walls'], { category: 'condensation' }),
  rule('damp-drying-clothes', 'damp', 300, allOf(eq('dries_clothes_indoors', true), eq('condensation_on_windows', true)),
    'green', 'damp_drying_clothes', ['dry_clothes_ventilated', 'ventilate_daily'], { category: 'condensation' }),
  rule('damp-small-surface-mold', 'damp', 200, allOf(eq('mold_area', 'small'), eq('visible_leak', false), eq('vulnerable_occupant', false)),
    'green', 'damp_small_surface_mold', ['clean_small_mold', 'ventilate_daily'], { category: 'condensation' }),
];

const write = (name, check, rules) => writeFileSync(new URL(name, import.meta.url),
  JSON.stringify({ check, rulesVersion: 1, _comment: 'GENERATED by build_rules.mjs. All rules are reviewed:false until the chemical engineer signs them off.', rules }, null, 2) + '\n');
write('gas_co.json', 'gas_co', gas);
write('damp_mold.json', 'damp_mold', damp);
console.log(`gas_co: ${gas.length} rules, damp_mold: ${damp.length} rules`);
