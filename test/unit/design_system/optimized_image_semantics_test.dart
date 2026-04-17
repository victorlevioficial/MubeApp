import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/design_system/components/data_display/optimized_image.dart';

void main() {
  testWidgets('wraps optimized images with semantic labels', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OptimizedImage(
            imageUrl: null,
            width: 100,
            height: 100,
            semanticLabel: 'Foto de perfil',
            semanticHint: 'Imagem do usuario',
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Foto de perfil'), findsOneWidget);
  });
}
