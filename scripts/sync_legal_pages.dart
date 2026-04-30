import 'dart:convert';
import 'dart:io';

import 'package:mube/src/features/legal/data/legal_content.dart';

const _pages = <_LegalPage>[
  _LegalPage(
    outputPath: 'landing_page/termosdeuso/index.html',
    markdown: LegalContent.termsOfUse,
  ),
  _LegalPage(
    outputPath: 'landing_page/politicadeprivacidade/index.html',
    markdown: LegalContent.privacyPolicy,
  ),
];

void main(List<String> args) {
  final checkOnly = args.contains('--check');
  final changed = <String>[];

  for (final page in _pages) {
    final file = File(page.outputPath);
    final existing = file.readAsStringSync();
    final next = _replaceContainerBody(existing, _renderBody(page.markdown));
    if (existing == next) {
      continue;
    }

    changed.add(page.outputPath);
    if (!checkOnly) {
      file.writeAsStringSync(next);
    }
  }

  if (changed.isEmpty) {
    stdout.writeln('Legal pages are in sync.');
    return;
  }

  if (checkOnly) {
    stderr.writeln('Legal pages are out of sync: ${changed.join(', ')}');
    exitCode = 1;
    return;
  }

  stdout.writeln('Updated legal pages: ${changed.join(', ')}');
}

String _replaceContainerBody(String html, String body) {
  final pattern = RegExp(
    r'(<body>\s*<div class="container">)([\s\S]*?)(\s*</div>\s*</body>)',
    multiLine: true,
  );
  final match = pattern.firstMatch(html);
  if (match == null) {
    throw StateError('Could not find legal page container.');
  }

  return html.replaceRange(
    match.start,
    match.end,
    '${match.group(1)}\n$body${match.group(3)}',
  );
}

String _renderBody(String markdown) {
  return [
    '        <a href="/" class="back-link">← Voltar para o site</a>',
    ..._renderMarkdown(markdown).map((line) => '        $line'),
  ].join('\n');
}

List<String> _renderMarkdown(String markdown) {
  final renderer = _MarkdownRenderer();
  for (final line in const LineSplitter().convert(markdown.trim())) {
    renderer.consume(line);
  }
  return renderer.finish();
}

class _MarkdownRenderer {
  final List<String> _html = [];
  final List<String> _paragraph = [];
  final List<String> _blockquote = [];
  final List<String> _bullets = [];
  final List<String> _table = [];

  void consume(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      _flushAll();
      return;
    }

    if (trimmed == '---') {
      _flushAll();
      _html.add('<hr>');
      return;
    }

    if (trimmed.startsWith('|') && trimmed.endsWith('|')) {
      _flushParagraph();
      _flushBlockquote();
      _flushBullets();
      _table.add(trimmed);
      return;
    }

    _flushTable();

    final headingLevel = _headingLevel(trimmed);
    if (headingLevel != null) {
      _flushAll();
      final text = trimmed.substring(headingLevel + 1).trim();
      _html.add('<h$headingLevel>${_inline(text)}</h$headingLevel>');
      return;
    }

    if (trimmed.startsWith('>')) {
      _flushParagraph();
      _flushBullets();
      _blockquote.add(trimmed.substring(1).trim());
      return;
    }

    if (trimmed.startsWith('• ')) {
      _flushParagraph();
      _flushBlockquote();
      _bullets.add(trimmed.substring(2).trim());
      return;
    }

    _flushBlockquote();
    _flushBullets();
    _paragraph.add(trimmed);
  }

  List<String> finish() {
    _flushAll();
    return _html;
  }

  void _flushAll() {
    _flushParagraph();
    _flushBlockquote();
    _flushBullets();
    _flushTable();
  }

  void _flushParagraph() {
    if (_paragraph.isEmpty) return;

    final joined = _paragraph.map(_inline).join('<br>\n');
    if (_paragraph.length == 1 &&
        _paragraph.single.startsWith('**MUBE Application')) {
      _html.add(
        '<p style="text-align: center; font-size: 14px; color: var(--text-tertiary);">$joined</p>',
      );
    } else {
      _html.add('<p>$joined</p>');
    }
    _paragraph.clear();
  }

  void _flushBlockquote() {
    if (_blockquote.isEmpty) return;

    final lines = _blockquote.map(_inline).join('<br>\n');
    _html.add('<blockquote>$lines</blockquote>');
    _blockquote.clear();
  }

  void _flushBullets() {
    if (_bullets.isEmpty) return;

    _html.add('<ul>');
    for (final bullet in _bullets) {
      _html.add('  <li>${_inline(bullet)}</li>');
    }
    _html.add('</ul>');
    _bullets.clear();
  }

  void _flushTable() {
    if (_table.isEmpty) return;

    final rows = _table
        .where((row) => !_isTableSeparator(row))
        .map(_tableCells)
        .where((row) => row.isNotEmpty)
        .toList(growable: false);
    if (rows.isEmpty) {
      _table.clear();
      return;
    }

    _html.add('<table>');
    _html.add('  <thead>');
    _html.add('    <tr>');
    for (final cell in rows.first) {
      _html.add('      <th>${_inline(cell)}</th>');
    }
    _html.add('    </tr>');
    _html.add('  </thead>');
    if (rows.length > 1) {
      _html.add('  <tbody>');
      for (final row in rows.skip(1)) {
        _html.add('    <tr>');
        for (final cell in row) {
          _html.add('      <td>${_inline(cell)}</td>');
        }
        _html.add('    </tr>');
      }
      _html.add('  </tbody>');
    }
    _html.add('</table>');
    _table.clear();
  }
}

int? _headingLevel(String line) {
  if (line.startsWith('### ')) return 3;
  if (line.startsWith('## ')) return 2;
  if (line.startsWith('# ')) return 1;
  return null;
}

bool _isTableSeparator(String row) {
  final cells = _tableCells(row);
  return cells.isNotEmpty &&
      cells.every((cell) => RegExp(r'^:?-{3,}:?$').hasMatch(cell.trim()));
}

List<String> _tableCells(String row) {
  final trimmed = row.trim();
  final withoutEdges = trimmed.substring(1, trimmed.length - 1);
  return withoutEdges.split('|').map((cell) => cell.trim()).toList();
}

String _inline(String text) {
  var value = const HtmlEscape(HtmlEscapeMode.element).convert(text);
  value = value.replaceAllMapped(
    RegExp(r'\*\*(.+?)\*\*'),
    (match) => '<strong>${match.group(1)}</strong>',
  );
  value = value.replaceAllMapped(RegExp(r'https://[^\s<]+'), (match) {
    final url = match.group(0)!;
    final trailing = url.endsWith('.') ? '.' : '';
    final cleanUrl = trailing.isEmpty ? url : url.substring(0, url.length - 1);
    return '<a href="$cleanUrl" style="color: var(--primary);">$cleanUrl</a>$trailing';
  });
  return value;
}

class _LegalPage {
  const _LegalPage({required this.outputPath, required this.markdown});

  final String outputPath;
  final String markdown;
}
