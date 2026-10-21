import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:homesafe/features/emergency/emergency_keywords.dart';

void main() {
  final detector = EmergencyKeywordDetector.fromJsonString(
      File('assets/config/emergency_keywords.json').readAsStringSync());
  final cases = (jsonDecode(File('../shared/emergency_keyword_cases.json').readAsStringSync())
      as Map)['cases'] as List;

  test('bundled keyword file matches shared/ (run tool/sync_shared.sh if this fails)', () {
    expect(File('assets/config/emergency_keywords.json').readAsStringSync(),
        File('../shared/emergency_keywords.json').readAsStringSync());
  });

  group('shared test vectors (same cases as the Cloud Function)', () {
    for (final c in cases.cast<Map>()) {
      test('"${c['text']}" -> ${c['emergency']}', () {
        expect(detector.isEmergency(c['text'] as String), c['emergency']);
      });
    }
  });

  test('folding handles Azerbaijani capitals and Russian ё', () {
    expect(EmergencyKeywordDetector.fold('QAZ İYİ, Şəhər!'), 'qaz iyi seher');
    expect(EmergencyKeywordDetector.fold('Котёл'), 'котел');
    expect(EmergencyKeywordDetector.fold('  can\'t   wake '), 'can t wake');
  });
}
