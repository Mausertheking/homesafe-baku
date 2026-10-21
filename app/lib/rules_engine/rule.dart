import 'condition.dart';

/// Result levels, ordered by severity. `index` doubles as the rank.
enum HazardLevel {
  green,
  amber,
  red;

  static HazardLevel parse(Object? value, String path) {
    for (final level in values) {
      if (level.name == value) return level;
    }
    throw RuleFormatException('$path must be one of red, amber, green (got "$value")');
  }

  bool operator >(HazardLevel other) => index > other.index;
}

/// What a rule says when it matches. Only translation keys, never text.
class RuleResult {
  const RuleResult({
    required this.level,
    required this.emergency,
    required this.reasonKey,
    required this.stepKeys,
    this.category,
  });

  final HazardLevel level;

  /// When true the app opens the emergency screen immediately.
  final bool emergency;
  final String reasonKey;
  final List<String> stepKeys;

  /// Optional grouping used by the damp check: condensation, leak, structural.
  final String? category;

  factory RuleResult.fromJson(Object? json, String path) {
    if (json is! Map) throw RuleFormatException('$path must be an object');
    final reason = json['reason_key'];
    if (reason is! String || reason.isEmpty) {
      throw RuleFormatException('$path.reason_key must be a non-empty string');
    }
    final steps = json['steps_keys'] ?? const [];
    if (steps is! List || steps.any((s) => s is! String)) {
      throw RuleFormatException('$path.steps_keys must be a list of strings');
    }
    final emergency = json['emergency'] ?? false;
    if (emergency is! bool) throw RuleFormatException('$path.emergency must be true or false');
    final category = json['category'];
    if (category != null && category is! String) {
      throw RuleFormatException('$path.category must be a string');
    }
    return RuleResult(
      level: HazardLevel.parse(json['level'], '$path.level'),
      emergency: emergency,
      reasonKey: reason,
      stepKeys: steps.cast<String>(),
      category: category as String?,
    );
  }
}

class Rule {
  const Rule({
    required this.id,
    required this.hazard,
    required this.version,
    required this.priority,
    required this.conditions,
    required this.result,
    this.reviewed = false,
    this.reviewedBy,
    this.reviewedOn,
  });

  final String id;
  final String hazard;
  final int version;

  /// Higher priority rules are listed first when several match.
  final int priority;
  final Condition conditions;
  final RuleResult result;

  /// Expert review metadata. Shown in the app and used by the release checklist.
  final bool reviewed;
  final String? reviewedBy;
  final String? reviewedOn;

  bool matches(Answers answers) => conditions.evaluate(answers);

  factory Rule.fromJson(Object? json) {
    if (json is! Map) throw RuleFormatException('rule must be an object');
    final id = json['id'];
    if (id is! String || id.isEmpty) throw RuleFormatException('rule.id must be a non-empty string');
    final path = 'rule "$id"';
    final hazard = json['hazard'];
    if (hazard is! String) throw RuleFormatException('$path.hazard must be a string');
    final version = json['version'];
    if (version is! int) throw RuleFormatException('$path.version must be an integer');
    final priority = json['priority'] ?? 0;
    if (priority is! int) throw RuleFormatException('$path.priority must be an integer');
    final conditions = Condition.fromJson(json['conditions'], path: '$path.conditions');
    if (conditions is AllCondition && conditions.children.isEmpty ||
        conditions is AnyCondition && conditions.children.isEmpty) {
      // An empty top-level group would match (or never match) everyone,
      // which is almost certainly an authoring mistake.
      throw RuleFormatException('$path.conditions must not be empty');
    }
    return Rule(
      id: id,
      hazard: hazard,
      version: version,
      priority: priority,
      conditions: conditions,
      result: RuleResult.fromJson(json['result'], '$path.result'),
      reviewed: json['reviewed'] == true,
      reviewedBy: json['reviewedBy'] as String?,
      reviewedOn: json['reviewedOn'] as String?,
    );
  }
}

/// All rules for one check (for example `gas_co` or `damp_mold`).
class RuleSet {
  RuleSet({required this.check, required this.rulesVersion, required List<Rule> rules})
      : rules = List.unmodifiable(rules) {
    final seen = <String>{};
    for (final r in rules) {
      if (!seen.add(r.id)) throw RuleFormatException('duplicate rule id "${r.id}"');
    }
  }

  final String check;
  final int rulesVersion;
  final List<Rule> rules;

  bool get allReviewed => rules.every((r) => r.reviewed);

  /// Parses a whole rule file. Any invalid rule rejects the whole set, so a
  /// broken remote update can never partially replace good rules.
  factory RuleSet.fromJson(Object? json) {
    if (json is! Map) throw RuleFormatException('rule file must be an object');
    final check = json['check'];
    if (check is! String) throw RuleFormatException('rule file "check" must be a string');
    final version = json['rulesVersion'];
    if (version is! int) throw RuleFormatException('rule file "rulesVersion" must be an integer');
    final list = json['rules'];
    if (list is! List) throw RuleFormatException('rule file "rules" must be a list');
    return RuleSet(check: check, rulesVersion: version, rules: [for (final r in list) Rule.fromJson(r)]);
  }
}
