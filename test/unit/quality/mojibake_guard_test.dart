import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('source files must not contain mojibake sequences', () {
    final root = Directory('lib/src');
    expect(root.existsSync(), isTrue, reason: 'Directory lib/src not found');

    const suspiciousTokens = <String>[
      'Ã¡',
      'Ã ',
      'Ã¢',
      'Ã£',
      'Ã¤',
      'Ã©',
      'Ã¨',
      'Ãª',
      'Ã«',
      'Ã­',
      'Ã¬',
      'Ã®',
      'Ã¯',
      'Ã³',
      'Ã²',
      'Ã´',
      'Ãµ',
      'Ã¶',
      'Ãº',
      'Ã¹',
      'Ã»',
      'Ã¼',
      'Ã§',
      'Ã‰',
      'Ã“',
      'Ã‡',
      'ÃƒÂ',
      'Ã¢Â',
      'ÃÂ',
      'â€¢',
      'â€“',
      'â€”',
      'â€œ',
      'â€',
      'â€˜',
      'â€™',
      'â€¦',
      'Â ',
    ];

    final issues = <String>[];

    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File) continue;
      final path = entity.path;

      if (!path.endsWith('.dart')) continue;
      if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) continue;

      final content = entity.readAsStringSync();
      for (final token in suspiciousTokens) {
        if (content.contains(token)) {
          issues.add('$path contains "$token"');
        }
      }
    }

    expect(issues, isEmpty, reason: issues.join('\n'));
  });
}
