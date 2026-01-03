import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'design_system/theme/app_theme.dart';
import 'routing/app_router.dart';
import 'design_system/foundations/app_scroll_behavior.dart';

class MubeApp extends ConsumerWidget {
  const MubeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Remove splash screen when the widget tree is built

    final goRouter = ref.watch(goRouterProvider);

    return MaterialApp.router(
      scrollBehavior: const AppScrollBehavior(),
      title: 'Mube',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: goRouter,
    );
  }
}
