import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings.dart';

/// Runtime-looked-up text: rule reasons, next steps, check questions,
/// service labels, districts. Rule files only contain keys like
/// `rule.co_no_flue.reason`; the words live in `assets/l10n/content_<lang>.arb`.
///
/// (gen-l10n ARB keys must be Dart identifiers, so dotted, data-driven keys
/// live in these separate ARB files and are loaded here.)
class ContentCatalog {
  ContentCatalog(this._byLanguage);

  final Map<String, Map<String, String>> _byLanguage;

  static const languages = ['az', 'ru', 'en'];

  static Future<ContentCatalog> load(AssetBundle bundle) async {
    final entries = await Future.wait(languages.map((lang) async {
      final raw = jsonDecode(await bundle.loadString('assets/l10n/content_$lang.arb')) as Map<String, Object?>;
      final map = <String, String>{
        for (final e in raw.entries)
          if (!e.key.startsWith('@')) e.key: e.value as String,
      };
      return MapEntry(lang, map);
    }));
    return ContentCatalog(Map.fromEntries(entries));
  }

  ContentStrings forLanguage(String lang) =>
      ContentStrings(_byLanguage[lang] ?? _byLanguage['az']!, _byLanguage['en']!);
}

class ContentStrings {
  ContentStrings(this._strings, this._fallback);

  final Map<String, String> _strings;
  final Map<String, String> _fallback;

  bool has(String key) => _strings.containsKey(key);

  /// Returns the text for [key]. Falls back to English, then to the key
  /// itself so a missing translation is visible but never crashes. The
  /// test suite fails if any key is missing in any language.
  String call(String key) {
    final value = _strings[key] ?? _fallback[key];
    if (value == null) {
      debugPrint('Missing content string: $key');
      return key;
    }
    return value;
  }

  String? maybe(String key) => _strings[key];
}

/// Overridden in main() with the preloaded catalog.
final contentCatalogProvider = Provider<ContentCatalog>((ref) => throw UnimplementedError('preloaded in main'));

final contentStringsProvider = Provider<ContentStrings>((ref) {
  final lang = ref.watch(settingsProvider.select((s) => s.language));
  return ref.watch(contentCatalogProvider).forLanguage(lang);
});
