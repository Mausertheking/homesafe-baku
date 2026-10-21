/// Condition tree for hazard rules.
///
/// A condition is either a group (`all`, `any`, `not`) or a single field
/// comparison (`{ "field": ..., "op": ..., "value": ... }`).
///
/// Missing-answer policy (important for safety, keep it simple):
/// * Every comparison on a field that is missing or null evaluates to FALSE,
///   including `neq`. "We don't know" is never treated as "not equal".
/// * `exists` is the only way to test for presence: `value: true` means the
///   field is answered, `value: false` means it is not.
/// * `not` simply inverts its child, so `not(eq x true)` is TRUE when x is
///   missing. Rule authors use this on purpose to be cautious (for example
///   "flue is not confirmed connected").
library;

/// Thrown when a rule file contains something the evaluator does not support.
/// A rule set that fails to parse is rejected as a whole, and the app keeps
/// using the last good (bundled) copy.
class RuleFormatException implements Exception {
  RuleFormatException(this.message);
  final String message;
  @override
  String toString() => 'RuleFormatException: $message';
}

typedef Answers = Map<String, Object?>;

sealed class Condition {
  const Condition();

  bool evaluate(Answers answers);

  /// Field names this condition reads. Used by tests and by the UI to know
  /// which answers a rule depends on.
  Set<String> get fields;

  static Condition fromJson(Object? json, {String path = 'conditions'}) {
    if (json is! Map) {
      throw RuleFormatException('$path must be an object');
    }
    final map = json.cast<String, Object?>();
    final groupKeys = map.keys.where((k) => k == 'all' || k == 'any' || k == 'not').toList();

    if (groupKeys.length > 1 || (groupKeys.isNotEmpty && map.containsKey('field'))) {
      throw RuleFormatException('$path mixes several condition kinds: ${map.keys.toList()}');
    }
    if (map.containsKey('all') || map.containsKey('any')) {
      final key = map.containsKey('all') ? 'all' : 'any';
      final list = map[key];
      if (list is! List) throw RuleFormatException('$path.$key must be a list');
      final children = [
        for (var i = 0; i < list.length; i++) Condition.fromJson(list[i], path: '$path.$key[$i]'),
      ];
      return key == 'all' ? AllCondition(children) : AnyCondition(children);
    }
    if (map.containsKey('not')) {
      return NotCondition(Condition.fromJson(map['not'], path: '$path.not'));
    }
    if (map.containsKey('field')) {
      return FieldCondition.fromJson(map, path: path);
    }
    throw RuleFormatException('$path is not a valid condition: ${map.keys.toList()}');
  }
}

/// True when every child is true. An empty `all` is true (standard logic),
/// but rule validation forbids empty top-level conditions.
class AllCondition extends Condition {
  const AllCondition(this.children);
  final List<Condition> children;

  @override
  bool evaluate(Answers answers) => children.every((c) => c.evaluate(answers));

  @override
  Set<String> get fields => {for (final c in children) ...c.fields};
}

/// True when at least one child is true. An empty `any` is false.
class AnyCondition extends Condition {
  const AnyCondition(this.children);
  final List<Condition> children;

  @override
  bool evaluate(Answers answers) => children.any((c) => c.evaluate(answers));

  @override
  Set<String> get fields => {for (final c in children) ...c.fields};
}

class NotCondition extends Condition {
  const NotCondition(this.child);
  final Condition child;

  @override
  bool evaluate(Answers answers) => !child.evaluate(answers);

  @override
  Set<String> get fields => child.fields;
}

enum Operator { eq, neq, isIn, gt, lt, exists }

const _opNames = {
  'eq': Operator.eq,
  'neq': Operator.neq,
  'in': Operator.isIn,
  'gt': Operator.gt,
  'lt': Operator.lt,
  'exists': Operator.exists,
};

class FieldCondition extends Condition {
  const FieldCondition(this.field, this.op, this.value);

  final String field;
  final Operator op;
  final Object? value;

  factory FieldCondition.fromJson(Map<String, Object?> map, {required String path}) {
    final field = map['field'];
    if (field is! String || field.isEmpty) {
      throw RuleFormatException('$path.field must be a non-empty string');
    }
    final opName = map['op'];
    final op = _opNames[opName];
    if (op == null) {
      throw RuleFormatException('$path.op "$opName" is not supported (use ${_opNames.keys.join(', ')})');
    }
    final value = map['value'];
    switch (op) {
      case Operator.isIn:
        if (value is! List) throw RuleFormatException('$path: "in" needs a list value');
      case Operator.gt || Operator.lt:
        if (value is! num) throw RuleFormatException('$path: "$opName" needs a number value');
      case Operator.exists:
        if (value != null && value is! bool) {
          throw RuleFormatException('$path: "exists" value must be true or false');
        }
      case Operator.eq || Operator.neq:
        if (!map.containsKey('value')) throw RuleFormatException('$path: "$opName" needs a value');
    }
    return FieldCondition(field, op, value);
  }

  @override
  Set<String> get fields => {field};

  @override
  bool evaluate(Answers answers) {
    final answer = answers[field];
    final present = answer != null;

    if (op == Operator.exists) {
      // `exists` with no value means "exists: true".
      final wanted = value as bool? ?? true;
      return present == wanted;
    }
    if (!present) return false; // Missing answers never match (see library doc).

    switch (op) {
      case Operator.eq:
        return _equals(answer, value);
      case Operator.neq:
        return !_equals(answer, value);
      case Operator.isIn:
        return (value as List).any((v) => _equals(answer, v));
      case Operator.gt:
        return answer is num && answer > (value as num);
      case Operator.lt:
        return answer is num && answer < (value as num);
      case Operator.exists:
        throw StateError('unreachable');
    }
  }

  /// Equality that treats 2 and 2.0 as equal (JSON numbers may arrive either
  /// way from Firestore) but never coerces between types: `true != "true"`.
  static bool _equals(Object? a, Object? b) {
    if (a is num && b is num) return a == b;
    return a == b;
  }
}
