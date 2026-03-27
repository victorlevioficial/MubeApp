import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/utils/app_logger.dart';
import 'package:timeago/timeago.dart' as timeago;

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.setDebugConsoleMirroringEnabled(false);
  timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());
  await testMain();
}
