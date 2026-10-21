import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Acceptance criterion: "The Gemini key is not present anywhere in the app
/// bundle." The app must never talk to Gemini directly; only the askHomeSafe
/// and generateLetter Cloud Functions do, with a Firebase secret.
void main() {
  test('no Gemini key, Gemini endpoint or Google API key in app code or assets', () {
    final patterns = [
      RegExp('GEMINI_API_KEY'),
      RegExp(r'AIza[0-9A-Za-z_\-]{20,}'), // Google API key format.
      RegExp('generativelanguage\\.googleapis'),
      RegExp('google_generative_ai|firebase_ai|firebase_vertexai'),
    ];
    final roots = ['lib', 'assets', 'android/app/src', 'ios/Runner', 'web', 'pubspec.yaml'];
    final hits = <String>[];
    for (final root in roots) {
      final entity = FileSystemEntity.typeSync(root);
      if (entity == FileSystemEntityType.notFound) continue;
      final files = entity == FileSystemEntityType.file
          ? [File(root)]
          : Directory(root).listSync(recursive: true).whereType<File>();
      for (final f in files) {
        final String text;
        try {
          text = f.readAsStringSync();
        } catch (_) {
          continue; // Binary file.
        }
        for (final p in patterns) {
          if (p.hasMatch(text)) hits.add('${f.path}: ${p.pattern}');
        }
      }
    }
    expect(hits, isEmpty);
  });
}
