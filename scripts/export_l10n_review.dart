import 'dart:convert';
import 'dart:io';

void main() {
  final root = Directory.current.path;
  final arbDir = Directory('$root/lib/l10n');
  final outputDir = Directory('$root/output/l10n_review');

  final ptFile = File('${arbDir.path}/app_pt.arb');
  final enFile = File('${arbDir.path}/app_en.arb');

  if (!ptFile.existsSync()) {
    stderr.writeln('Arquivo nao encontrado: ${ptFile.path}');
    exitCode = 1;
    return;
  }

  final ptData = _readArb(ptFile);
  final enData = enFile.existsSync() ? _readArb(enFile) : <String, dynamic>{};

  outputDir.createSync(recursive: true);

  final rows = _buildRows(ptData, enData);

  final ptOnlyCsv = StringBuffer()
    ..writeln('key,descricao,pt_atual,pt_revisado,observacoes');
  final fullCsv = StringBuffer()
    ..writeln('key,descricao,pt_atual,pt_revisado,en_atual,observacoes');
  final markdown = StringBuffer()
    ..writeln('# Revisao de textos do app')
    ..writeln()
    ..writeln('- Fonte: `lib/l10n/app_pt.arb` e `lib/l10n/app_en.arb`')
    ..writeln('- Exportado em: ${DateTime.now().toIso8601String()}')
    ..writeln('- Total de chaves: ${rows.length}')
    ..writeln()
    ..writeln('## Como revisar')
    ..writeln()
    ..writeln('Abra o CSV no Numbers e preencha a coluna `pt_revisado`.')
    ..writeln('Use `observacoes` para contexto ou duvidas.')
    ..writeln()
    ..writeln('## Preview')
    ..writeln();

  for (final row in rows) {
    ptOnlyCsv.writeln(
      [row.key, row.description, row.ptCurrent, '', ''].map(_csvCell).join(','),
    );

    fullCsv.writeln(
      [
        row.key,
        row.description,
        row.ptCurrent,
        '',
        row.enCurrent,
        '',
      ].map(_csvCell).join(','),
    );
  }

  for (final row in rows.take(40)) {
    markdown
      ..writeln('### `${row.key}`')
      ..writeln()
      ..writeln('- PT atual: ${row.ptCurrent}')
      ..writeln('- EN atual: ${row.enCurrent.isEmpty ? '-' : row.enCurrent}')
      ..writeln(
        '- Descricao: ${row.description.isEmpty ? '-' : row.description}',
      )
      ..writeln();
  }

  _writeUtf8Bom(
    File('${outputDir.path}/mube_l10n_review_pt.csv'),
    ptOnlyCsv.toString(),
  );
  _writeUtf8Bom(
    File('${outputDir.path}/mube_l10n_review_full.csv'),
    fullCsv.toString(),
  );
  File(
    '${outputDir.path}/mube_l10n_review_preview.md',
  ).writeAsStringSync(markdown.toString(), encoding: utf8);

  stdout.writeln('Arquivos gerados em: ${outputDir.path}');
}

Map<String, dynamic> _readArb(File file) {
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

List<_Row> _buildRows(
  Map<String, dynamic> ptData,
  Map<String, dynamic> enData,
) {
  final keys = ptData.keys.where((key) => !key.startsWith('@')).toList()
    ..sort();

  return [
    for (final key in keys)
      _Row(
        key: key,
        description: _extractDescription(ptData, key, enData),
        ptCurrent: _normalizeValue(ptData[key]),
        enCurrent: _normalizeValue(enData[key]),
      ),
  ];
}

String _extractDescription(
  Map<String, dynamic> ptData,
  String key,
  Map<String, dynamic> enData,
) {
  final ptMeta = ptData['@$key'];
  if (ptMeta is Map<String, dynamic>) {
    final description = ptMeta['description'];
    if (description is String && description.trim().isNotEmpty) {
      return description.trim();
    }
  }

  final enMeta = enData['@$key'];
  if (enMeta is Map<String, dynamic>) {
    final description = enMeta['description'];
    if (description is String && description.trim().isNotEmpty) {
      return description.trim();
    }
  }

  return '';
}

String _normalizeValue(Object? value) {
  if (value == null) return '';
  if (value is String) {
    return value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  }
  return value.toString();
}

String _csvCell(String value) {
  final escaped = value.replaceAll('"', '""');
  return '"$escaped"';
}

void _writeUtf8Bom(File file, String contents) {
  final bytes = <int>[0xEF, 0xBB, 0xBF, ...utf8.encode(contents)];
  file.writeAsBytesSync(bytes);
}

class _Row {
  const _Row({
    required this.key,
    required this.description,
    required this.ptCurrent,
    required this.enCurrent,
  });

  final String key;
  final String description;
  final String ptCurrent;
  final String enCurrent;
}
