import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/route_paths.dart';

void handleMatchpointBack(BuildContext context) {
  final router = GoRouter.maybeOf(context);
  if (router?.canPop() ?? false) {
    context.pop();
    return;
  }

  final navigator = Navigator.maybeOf(context);
  if (navigator?.canPop() ?? false) {
    navigator!.pop();
    return;
  }

  router?.go(RoutePaths.settings);
}
