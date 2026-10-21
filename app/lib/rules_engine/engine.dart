import 'condition.dart';
import 'rule.dart';

/// Translation keys used when no rule matched.
const defaultReasonKey = 'rule.default.reason';
const defaultStepKeys = ['step.monitor_and_recheck'];

/// Outcome of running a rule set against a user's answers.
class Evaluation {
  const Evaluation({
    required this.level,
    required this.emergency,
    required this.matched,
    required this.reasonKeys,
    required this.stepKeys,
    required this.categories,
    required this.rulesVersion,
  });

  /// Highest level among matched rules (red > amber > green); green if none.
  final HazardLevel level;

  /// True if any matched rule asks for the emergency screen.
  final bool emergency;

  /// Matched rules, highest level first, then highest priority, then id.
  final List<Rule> matched;

  /// Reasons from EVERY matched rule, in [matched] order.
  final List<String> reasonKeys;

  /// Next steps from all matched rules, de-duplicated, first occurrence wins,
  /// so the most urgent rule's steps come first.
  final List<String> stepKeys;

  /// Distinct categories of matched rules, for example {leak, condensation}.
  final Set<String> categories;
  final int rulesVersion;

  List<String> get matchedRuleIds => [for (final r in matched) r.id];
  bool get noRuleMatched => matched.isEmpty;
}

class RulesEngine {
  const RulesEngine();

  /// Evaluates every rule (no short-circuit) and combines the results.
  Evaluation evaluate(RuleSet ruleSet, Answers answers) {
    final matched = ruleSet.rules.where((r) => r.matches(answers)).toList()
      ..sort((a, b) {
        final byLevel = b.result.level.index.compareTo(a.result.level.index);
        if (byLevel != 0) return byLevel;
        final byPriority = b.priority.compareTo(a.priority);
        if (byPriority != 0) return byPriority;
        return a.id.compareTo(b.id); // Stable, deterministic order.
      });

    if (matched.isEmpty) {
      return Evaluation(
        level: HazardLevel.green,
        emergency: false,
        matched: const [],
        reasonKeys: const [defaultReasonKey],
        stepKeys: defaultStepKeys,
        categories: const {},
        rulesVersion: ruleSet.rulesVersion,
      );
    }

    final steps = <String>[];
    for (final r in matched) {
      for (final s in r.result.stepKeys) {
        if (!steps.contains(s)) steps.add(s);
      }
    }

    return Evaluation(
      level: matched.first.result.level,
      emergency: matched.any((r) => r.result.emergency),
      matched: List.unmodifiable(matched),
      reasonKeys: [for (final r in matched) r.result.reasonKey],
      stepKeys: List.unmodifiable(steps),
      categories: {for (final r in matched) if (r.result.category != null) r.result.category!},
      rulesVersion: ruleSet.rulesVersion,
    );
  }
}
