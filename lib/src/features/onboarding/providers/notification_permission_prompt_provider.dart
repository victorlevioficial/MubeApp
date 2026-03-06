import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';

const String notificationPermissionPromptKey = 'notification_permission_shown';

class NotificationPermissionPromptNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await ref.read(sharedPreferencesLoaderProvider)();
    return prefs.getBool(notificationPermissionPromptKey) ?? false;
  }

  Future<void> markAsShown() async {
    final prefs = await ref.read(sharedPreferencesLoaderProvider)();
    await prefs.setBool(notificationPermissionPromptKey, true);
    state = const AsyncValue.data(true);
  }
}

final notificationPermissionPromptProvider =
    AsyncNotifierProvider<NotificationPermissionPromptNotifier, bool>(
      NotificationPermissionPromptNotifier.new,
    );
