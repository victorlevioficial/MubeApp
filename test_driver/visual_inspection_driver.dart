import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final outputDir = Directory('artifacts/impeccable_visual');
  await outputDir.create(recursive: true);

  await integrationDriver(
    onScreenshot: (name, image, [args]) async {
      final file = File('${outputDir.path}/$name.png');
      await file.writeAsBytes(image);
      return true;
    },
  );
}
