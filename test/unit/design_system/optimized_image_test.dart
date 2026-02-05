import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/design_system/components/data_display/optimized_image.dart';

void main() {
  group('OptimizedImage', () {
    group('ImageResolution enum', () {
      test('deve ter valores corretos', () {
        expect(ImageResolution.thumbnail.maxDimension, 150);
        expect(ImageResolution.medium.maxDimension, 400);
        expect(ImageResolution.large.maxDimension, 800);
        expect(ImageResolution.full.maxDimension, null);
      });
    });

    group('Factory constructors', () {
      test('avatarSmall deve criar widget correto', () {
        final widget = OptimizedImage.avatarSmall(
          imageUrl: 'https://example.com/avatar.jpg',
          size: 40,
        );

        expect(widget.width, 40);
        expect(widget.height, 40);
        expect(widget.resolution, ImageResolution.thumbnail);
        expect(widget.fit, BoxFit.cover);
      });

      test('avatarMedium deve criar widget correto', () {
        final widget = OptimizedImage.avatarMedium(
          imageUrl: 'https://example.com/avatar.jpg',
          size: 80,
        );

        expect(widget.width, 80);
        expect(widget.height, 80);
        expect(widget.resolution, ImageResolution.large);
      });

      test('avatarLarge deve criar widget correto', () {
        final widget = OptimizedImage.avatarLarge(
          imageUrl: 'https://example.com/avatar.jpg',
          size: 120,
        );

        expect(widget.width, 120);
        expect(widget.height, 120);
        expect(widget.resolution, ImageResolution.large);
      });

      test('card deve criar widget correto', () {
        final widget = OptimizedImage.card(
          imageUrl: 'https://example.com/image.jpg',
          width: 200,
          height: 150,
        );

        expect(widget.width, 200);
        expect(widget.height, 150);
        expect(widget.resolution, ImageResolution.medium);
      });

      test('fullscreen deve criar widget correto', () {
        final widget = OptimizedImage.fullscreen(
          imageUrl: 'https://example.com/image.jpg',
        );

        expect(widget.resolution, ImageResolution.full);
        expect(widget.fit, BoxFit.contain);
      });
    });

    group('Cache width calculation', () {
      test('width deve ser acessível', () {
        const widget = OptimizedImage(
          imageUrl: 'https://example.com/image.jpg',
          width: 1000,
          resolution: ImageResolution.medium,
        );

        // Medium tem maxDimension de 400, mas width é 1000
        expect(widget.width, 1000);
      });

      test('width deve ser acessível quando menor que resolução', () {
        const widget = OptimizedImage(
          imageUrl: 'https://example.com/image.jpg',
          width: 200,
          resolution: ImageResolution.medium,
        );

        expect(widget.width, 200);
      });
    });

    group('Widget rendering', () {
      testWidgets('deve mostrar error widget quando URL é nula', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: OptimizedImage(imageUrl: null, width: 100, height: 100),
          ),
        );

        expect(find.byType(Container), findsOneWidget);
      });

      testWidgets('deve mostrar error widget quando URL é vazia', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: OptimizedImage(imageUrl: '', width: 100, height: 100),
          ),
        );

        expect(find.byType(Container), findsOneWidget);
      });
    });
  });

  group('OptimizedImageList', () {
    testWidgets('deve renderizar GridView', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OptimizedImageList(
            imageUrls: [
              'https://example.com/1.jpg',
              'https://example.com/2.jpg',
            ],
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
    });
  });

  group('OptimizedImageHero', () {
    testWidgets('deve renderizar Hero widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OptimizedImageHero(
            tag: 'hero-tag',
            imageUrl: 'https://example.com/image.jpg',
          ),
        ),
      );

      expect(find.byType(Hero), findsOneWidget);
    });
  });
}
