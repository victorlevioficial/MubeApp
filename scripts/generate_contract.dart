import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() async {
  final pdf = pw.Document();

  // --- Mube Design Tokens (Approximate for proper PDF rendering) ---
  final PdfColor brandPrimary = PdfColor.fromInt(0xFFD40055); // Razzmatazz
  final PdfColor bgDeep = PdfColor.fromInt(0xFF0A0A0A); // Deepest Black
  final PdfColor bgSurface = PdfColor.fromInt(0xFF161616); // Surface
  final PdfColor textWhite = PdfColor.fromInt(0xFFFFFFFF);
  final PdfColor textGray = PdfColor.fromInt(0xFFB3B3B3);

  final theme = pw.ThemeData.withFont(
    base: pw.Font.helvetica(),
    bold: pw.Font.helveticaBold(),
  );

  // --- Content Data ---
  final String title = 'MODELO ESTRUTURAL DE ACORDO DE SÓCIOS';
  final String companyName = 'MUBE TECNOLOGIA LTDA';
  final String date = 'Fevereiro, 2026';

  // --- Pages ---

  // 1. Cover Page
  pdf.addPage(
    pw.Page(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return pw.Container(
          color: bgDeep,
          alignment: pw.Alignment.center,
            padding: const pw.EdgeInsets.all(40),
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                companyName,
                style: pw.TextStyle(
                  color: brandPrimary,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Divider(color: brandPrimary, thickness: 2),
              pw.SizedBox(height: 40),
              pw.Text(
                title,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  color: textWhite,
                  fontSize: 36,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Spacer(),
              pw.Text(date, style: pw.TextStyle(color: textGray, fontSize: 18)),
            ],
          ),
        );
      },
    ),
  );

  // 2. Content Pages
  pdf.addPage(
    pw.MultiPage(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      // We will wrap content in a dark container for visual consistency if possible,
      // but MultiPage expects widgets that can span pages.
      // A common PDF trick for background color in MultiPage is using `pageTheme`.
      pageTheme: pw.PageTheme(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        buildBackground: (context) => pw.FullPage(
          ignoreMargins: true,
          child: pw.Container(color: bgDeep),
        ),
      ),
      build: (context) {
        return [
          _buildSectionHeader('1. CAPITAL SOCIAL E DISTRIBUIÇÃO', brandPrimary),
          _buildText('Capital dividido em 100.000 quotas.', textWhite),
          pw.SizedBox(height: 8),
          _buildBulletPoint('Victor: 50.000 quotas (50%)', textGray),
          _buildBulletPoint('Igor: 15.000 quotas (15%)', textGray),
          _buildBulletPoint('Diogo: 8.000 quotas (8%)', textGray),
          _buildBulletPoint(
            'Bruninha: 22.000 quotas (22%) - sujeitas a vesting',
            textGray,
          ),
          _buildBulletPoint('Pool estratégico: 5.000 quotas (5%)', textGray),
          pw.SizedBox(height: 16),

          _buildSectionHeader('2. VESTING', brandPrimary),
          _buildSubHeader('Bruninha:', textWhite),
          _buildBulletPoint('4 anos com cliff de 12 meses.', textGray),
          _buildBulletPoint(
            'Após 12 meses: 25% adquirido (5.500 quotas).',
            textGray,
          ),
          _buildBulletPoint(
            'Restante adquirido mensalmente até completar 48 meses.',
            textGray,
          ),
          pw.SizedBox(height: 8),
          _buildSubHeader('Diogo:', textWhite),
          _buildBulletPoint('3% fixo com cliff de 12 meses.', textGray),
          _buildBulletPoint(
            '5% condicionado a metas objetivas de crescimento e divulgação.',
            textGray,
          ),
          pw.SizedBox(height: 8),
          _buildSubHeader('Igor:', textWhite),
          _buildBulletPoint('10% fixo imediato.', textGray),
          _buildBulletPoint(
            '5% condicionado a aporte mínimo definido contratualmente.',
            textGray,
          ),
          _buildBulletPoint('Aportes futuros via Mútuo Conversível.', textGray),
          pw.SizedBox(height: 16),

          _buildSectionHeader('3. GOVERNANÇA', brandPrimary),
          _buildBulletPoint('Decisões simples: maioria simples.', textGray),
          _buildBulletPoint('Decisões estratégicas: 75% dos votos.', textGray),
          pw.SizedBox(height: 16),

          _buildSectionHeader('4. NÃO CONCORRÊNCIA', brandPrimary),
          _buildText('Prazo de 24 meses após saída.', textGray),
          pw.SizedBox(height: 16),

          _buildSectionHeader('5. CONFIDENCIALIDADE', brandPrimary),
          _buildText(
            'Proteção integral de código, base de dados e estratégia.',
            textGray,
          ),
          pw.SizedBox(height: 16),

          pw.Divider(color: brandPrimary),
          pw.SizedBox(height: 16),

          _buildSectionHeader('CAP TABLE EVOLUTIVA', brandPrimary),
          pw.SizedBox(height: 8),
          _buildCapTable(textWhite, textGray, brandPrimary, bgSurface),
        ];
      },
    ),
  );

  final file = File('partners_agreement.pdf');
  await file.writeAsBytes(await pdf.save());
  print('PDF successfully generated at: ${file.absolute.path}');
}

pw.Widget _buildSectionHeader(String text, PdfColor color) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 8, top: 8),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        color: color,
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
      ),
    ),
  );
}

pw.Widget _buildSubHeader(String text, PdfColor color) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4, left: 8),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: pw.FontWeight.bold,
      ),
    ),
  );
}

pw.Widget _buildText(String text, PdfColor color) {
  return pw.Text(text, style: pw.TextStyle(color: color, fontSize: 12));
}

pw.Widget _buildBulletPoint(String text, PdfColor color) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(left: 16, bottom: 2),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 4,
          height: 4,
          margin: const pw.EdgeInsets.only(top: 4, right: 4),
          decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
        ),
        pw.Expanded(
          child: pw.Text(text, style: pw.TextStyle(color: color, fontSize: 12)),
        ),
      ],
    ),
  );
}

pw.Widget _buildCapTable(
  PdfColor headerColor,
  PdfColor textColor,
  PdfColor borderColor,
  PdfColor headerBg,
) {
  final headers = [
    'Rodada',
    'Victor',
    'Bruninha',
    'Igor',
    'Diogo',
    'Pool',
    'Inv.',
  ];
  final data = [
    ['Fase Inicial', '50%', '22%', '15%', '8%', '5%', '-'],
    ['Seed (20%)', '40%', '17.6%', '12%', '6.4%', '4%', '20%'],
    ['Série A (25%)', '30%', '13.2%', '9%', '4.8%', '3%', '40%*'], // *Combined
  ];

  return pw.TableHelper.fromTextArray(
    headers: headers,
    data: data,
    border: pw.TableBorder.all(color: borderColor, width: 0.5),
    headerStyle: pw.TextStyle(
      color: borderColor,
      fontWeight: pw.FontWeight.bold,
      fontSize: 10,
    ),
    cellStyle: pw.TextStyle(color: textColor, fontSize: 10),
    headerDecoration: pw.BoxDecoration(color: headerBg),
    cellAlignment: pw.Alignment.center,
    headerAlignment: pw.Alignment.center,
  );
}
