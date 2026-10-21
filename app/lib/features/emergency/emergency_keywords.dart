import 'dart:convert';

/// Detects emergency messages (gas smell, CO alarm, fainting, ...) in az, ru
/// and en BEFORE anything is sent to the AI.
///
/// Must behave exactly like functions/src/emergency.ts. Both read
/// shared/emergency_keywords.json and both pass
/// shared/emergency_keyword_cases.json.
class EmergencyKeywordDetector {
  EmergencyKeywordDetector._(this._phrases, this._combos);

  /// Builds a detector from the JSON text of emergency_keywords.json.
  factory EmergencyKeywordDetector.fromJsonString(String source) {
    final json = jsonDecode(source) as Map<String, Object?>;
    final phrases = <String>{
      for (final list in (json['phrases'] as Map).values)
        for (final p in list as List) fold(p as String),
    }..remove('');
    final combos = [
      for (final combo in json['combos'] as List)
        [
          for (final group in (combo as Map)['groups'] as List)
            [for (final p in group as List) fold(p as String)],
        ],
    ];
    return EmergencyKeywordDetector._(phrases.toList(), combos);
  }

  final List<String> _phrases;
  final List<List<List<String>>> _combos;

  bool isEmergency(String message) {
    final text = ' ${fold(message)}';
    if (text.trim().isEmpty) return false;
    bool has(String phrase) => text.contains(' $phrase');
    if (_phrases.any(has)) return true;
    return _combos.any((groups) => groups.every((g) => g.any(has)));
  }

  static final _nonWord = RegExp(r'[^\p{L}\p{N}]+', unicode: true);
  static final _combining = RegExp(r'[̀-ͯ]');
  static const _letters = {
    'ə': 'e', 'ı': 'i', 'ğ': 'g', 'ö': 'o', 'ü': 'u', 'ç': 'c', 'ş': 's', 'ё': 'е',
  };

  /// Lowercase, Azerbaijani letters to ASCII, ё→е, strip combining marks
  /// (the dot left over from lowercasing "İ"), non-letters to single spaces.
  static String fold(String input) {
    final lower = input.toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final ch = String.fromCharCode(rune);
      buffer.write(_letters[ch] ?? ch);
    }
    return buffer
        .toString()
        .replaceAll(_combining, '')
        .replaceAll(_nonWord, ' ')
        .trim();
  }
}
