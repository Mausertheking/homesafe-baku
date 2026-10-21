import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings.dart';
import '../../rules_engine/rules_engine.dart';
import '../home_profile/home_profile.dart';
import 'check_outcome.dart';
import 'rules_repository.dart';

/// A finished check, kept ON THE DEVICE only (works for guests and offline).
/// Saving to the evidence log is a separate, explicit step.
class SavedCheck {
  const SavedCheck({required this.id, required this.checkId, required this.answers, required this.level, required this.at});

  final String id;
  final String checkId; // gas_co | damp_mold
  final Answers answers;
  final String level; // red | amber | green, at the time of the check
  final DateTime at;

  Map<String, Object?> toJson() =>
      {'id': id, 'checkId': checkId, 'answers': answers, 'level': level, 'at': at.toIso8601String()};

  static SavedCheck fromJson(Map<String, Object?> j) => SavedCheck(
        id: j['id'] as String,
        checkId: j['checkId'] as String,
        answers: Map<String, Object?>.from(j['answers'] as Map),
        level: j['level'] as String,
        at: DateTime.parse(j['at'] as String),
      );
}

class CheckHistoryController extends Notifier<List<SavedCheck>> {
  static const _key = 'checks.history';
  static const maxItems = 30;

  @override
  List<SavedCheck> build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const [];
    try {
      return [for (final j in jsonDecode(raw) as List) SavedCheck.fromJson(Map<String, Object?>.from(j as Map))];
    } catch (_) {
      return const []; // Corrupt history is not worth crashing over.
    }
  }

  Future<void> add(CheckOutcome outcome) async {
    final item = SavedCheck(
      id: newId(),
      checkId: outcome.checkId,
      answers: outcome.answers,
      level: outcome.evaluation.level.name,
      at: DateTime.now(),
    );
    state = [item, ...state].take(maxItems).toList();
    await _persist();
  }

  Future<void> clear() async {
    state = const [];
    await ref.read(sharedPreferencesProvider).remove(_key);
  }

  Future<void> _persist() => ref
      .read(sharedPreferencesProvider)
      .setString(_key, jsonEncode([for (final c in state) c.toJson()]));

  SavedCheck? latest(String checkId) {
    for (final c in state) {
      if (c.checkId == checkId) return c;
    }
    return null;
  }

  /// Rebuilds the full result from the stored answers with the CURRENT rules,
  /// so reopening an old result always shows up-to-date advice.
  Future<CheckOutcome> reopen(SavedCheck saved) async {
    final rules = await ref.read(ruleSetProvider(saved.checkId).future);
    return CheckOutcome(
      checkId: saved.checkId,
      answers: saved.answers,
      evaluation: const RulesEngine().evaluate(rules, saved.answers),
      allRulesReviewed: rules.allReviewed,
      fromHistory: true,
    );
  }
}

final checkHistoryProvider = NotifierProvider<CheckHistoryController, List<SavedCheck>>(CheckHistoryController.new);
