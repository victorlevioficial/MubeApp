import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String notificationPermissionPromptKey = 'notification_permission_shown';

class NotificationPermissionPromptNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(notificationPermissionPromptKey) ?? false;
  }

  Future<void> markAsShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(notificationPermissionPromptKey, true);
    state = const AsyncValue.data(true);
  }
}

final notificationPermissionPromptProvider =
    AsyncNotifierProvider<NotificationPermissionPromptNotifier, bool>(
      NotificationPermissionPromptNotifier.new,
    );
