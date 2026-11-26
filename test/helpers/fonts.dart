import 'dart:io';

import 'package:flutter/services.dart';

const _families = <String, List<String>>{
  'Vazirmatn': [
    'Vazirmatn-Regular.ttf',
    'Vazirmatn-Medium.ttf',
    'Vazirmatn-SemiBold.ttf',
    'Vazirmatn-Bold.ttf',
  ],
  'NotoNaskhArabic': [
    'NotoNaskhArabic-Medium.ttf',
    'NotoNaskhArabic-SemiBold.ttf',
    'NotoNaskhArabic-Bold.ttf',
  ],
  'Lalezar': ['Lalezar-Regular.ttf'],
};

bool _loaded = false;

/// Loads the bundled static TTFs under the same family names as pubspec.yaml,
/// so goldens render real glyphs instead of Ahem boxes. Call in `setUpAll`.
Future<void> loadAppFonts() async {
  if (_loaded) return;
  for (final entry in _families.entries) {
    final loader = FontLoader(entry.key);
    for (final file in entry.value) {
      final bytes = File('assets/fonts/$file').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
  _loaded = true;
}
