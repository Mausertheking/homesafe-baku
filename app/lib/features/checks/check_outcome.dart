import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../rules_engine/rules_engine.dart';
import '../auth/auth_service.dart';
import '../evidence/evidence_repository.dart';
import '../home_profile/home_profile.dart';

/// Everything the result screen needs, passed via go_router `extra`.
class CheckOutcome {
  CheckOutcome({
    required this.checkId,
    required this.answers,
    required this.evaluation,
    this.photos = const [],
    this.allRulesReviewed = false,
    this.fromHistory = false,
  });

  final String checkId;
  final Answers answers;
  final Evaluation evaluation;
  final List<XFile> photos;
  final bool allRulesReviewed;

  /// Reopened from the on-device history (no photos, already recorded).
  final bool fromHistory;

  /// Best matching letter template for this result (used by "Write a letter").
  String get suggestedLetterProblem {
    final ids = evaluation.matchedRuleIds;
    if (checkId == 'damp_mold') return evaluation.categories.contains('leak') ? 'leak' : 'damp_mold';
    if (ids.isNotEmpty && ids.every((id) => id == 'co-no-alarm')) return 'co_alarm_missing';
    return 'gas_heater';
  }
}

class CheckRepository {
  CheckRepository(this._ref);
  final Ref _ref;

  /// Saves the check (users/{uid}/homes/{homeId}/checks/{id}), adds a
  /// "check" evidence item that points to it, then uploads any photos as
  /// photo evidence. Returns the check id.
  Future<String> save(CheckOutcome outcome) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) throw NotSignedInException();
    final homeId = _ref.read(homeProfileProvider).id;
    final evidence = _ref.read(evidenceRepositoryProvider);
    final e = outcome.evaluation;

    final checkDoc = FirebaseFirestore.instance.collection('users/${user.uid}/homes/$homeId/checks').doc();
    // Make sure the parent home exists first (evidence repo does the same).
    await FirebaseFirestore.instance
        .doc('users/${user.uid}/homes/$homeId')
        .set(_ref.read(homeProfileProvider).toFirestore(), SetOptions(merge: true));
    await checkDoc.set({
      'hazard': outcome.checkId,
      'answers': outcome.answers,
      'resultLevel': e.level.name,
      'matchedRuleIds': e.matchedRuleIds,
      'rulesVersion': e.rulesVersion,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // The evidence text is a stable machine summary (hashed by the server);
    // the app and the PDF render it in the reader's language.
    await evidence.addText(
      EvidenceType.check,
      jsonEncode({
        'check': outcome.checkId,
        'level': e.level.name,
        'matchedRuleIds': e.matchedRuleIds,
        'rulesVersion': e.rulesVersion,
      }),
      checkId: checkDoc.id,
    );
    for (final photo in outcome.photos) {
      await evidence.addPhoto(photo);
    }
    return checkDoc.id;
  }
}

final checkRepositoryProvider = Provider<CheckRepository>(CheckRepository.new);
