import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/design_system/components/patterns/or_divider.dart';

void main() {
  Future<List<String>> renderAt(
    WidgetTester tester,
    double width, {
    String text = 'Ou cadastre-se com',
  }) async {
    final overflows = <String>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final message = details.exception.toString();
      if (message.contains('overflowed')) {
        overflows.add(message.split('\n').first);
      } else {
        previousOnError?.call(details);
      }
    };

    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: OrDivider(text: text),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    } finally {
      FlutterError.onError = previousOnError;
    }

    return overflows;
  }

  group('OrDivider', () {
    testWidgets('shows the full label when there is room', (tester) async {
      final overflows = await renderAt(tester, 360);

      expect(overflows, isEmpty);
      final label = tester.widget<Text>(find.text('Ou cadastre-se com'));
      final painter = TextPainter(
        text: TextSpan(text: label.data, style: label.style),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();
      final rendered = tester.getSize(find.text('Ou cadastre-se com'));

      // The label must keep its natural width; the rules take what is left.
      expect(rendered.width, greaterThanOrEqualTo(painter.width - 1));
    });

    testWidgets('shrinks instead of overflowing on a narrow row', (
      tester,
    ) async {
      final overflows = await renderAt(tester, 140);

      expect(overflows, isEmpty);
    });
  });
}
