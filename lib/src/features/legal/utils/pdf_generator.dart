import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../data/legal_content.dart';

class PdfGenerator {
  static Future<void> generateAndShare(
    String title,
    String content, {
    String filename = 'document.pdf',
  }) async {
    final doc = pw.Document();

    // Simple font for text
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                title,
                style: pw.TextStyle(font: fontBold, fontSize: 24),
              ),
            ),
            pw.SizedBox(height: 16),
            // We are simply displaying the content as text for now
            // A full markdown parser for PDF is complex, better to just show clean text
            // or we could replace Headers (#) with pw.Header logic if we want to be fancy.
            pw.Text(
              content.replaceAll(
                RegExp(r'#+\s'),
                '',
              ), // Strip markdown headers hash for cleaner look
              style: pw.TextStyle(font: font, fontSize: 12, lineSpacing: 1.5),
            ),
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.Footer(
              leading: pw.Text('Mube'),
              trailing: pw.Text(
                'Página ${context.pageNumber} de ${context.pagesCount}',
              ),
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(bytes: await doc.save(), filename: filename);
  }

  static Future<void> shareTermsOfUse() async {
    await generateAndShare(
      'Termos de Uso - Mube',
      LegalContent.termsOfUse,
      filename: 'termos_de_uso_mube.pdf',
    );
  }

  static Future<void> sharePrivacyPolicy() async {
    await generateAndShare(
      'Política de Privacidade - Mube',
      LegalContent.privacyPolicy,
      filename: 'politica_privacidade_mube.pdf',
    );
  }
}
