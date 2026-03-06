import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/design_system/components/feedback/app_refresh_indicator.dart';

void main() {
  group('AppRefreshIndicator', () {
    testWidgets(
      'triggers refresh even when content is shorter than the viewport',
      (tester) async {
        var refreshCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppRefreshIndicator(
                onRefresh: () async {
                  refreshCount++;
                },
                child: ListView(
                  physics: AppRefreshIndicator.defaultScrollPhysics,
                  children: const [
                    SizedBox(
                      height: 120,
                      child: Center(child: Text('Conteudo curto')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.drag(find.text('Conteudo curto'), const Offset(0, 300));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(refreshCount, 1);
      },
    );
  });
}
