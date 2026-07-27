import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/legal/presentation/legal_detail_screen.dart';

void main() {
  testWidgets('renders legal content with the maintained markdown widget', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LegalDetailScreen(type: LegalDocumentType.termsOfUse),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Termos de Uso'), findsWidgets);
    expect(find.byType(Markdown), findsOneWidget);
    expect(find.byTooltip('Baixar/Compartilhar PDF'), findsOneWidget);
  });
}
