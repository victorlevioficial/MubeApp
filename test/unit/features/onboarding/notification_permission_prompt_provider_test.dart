import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/onboarding/providers/notification_permission_prompt_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('notificationPermissionPromptProvider', () {
    test('returns false when the prompt has not been shown yet', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();

      addTearDown(container.dispose);

      final result = await container.read(
        notificationPermissionPromptProvider.future,
      );

      expect(result, isFalse);
    });

    test('markAsShown persists and updates the provider state', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();

      addTearDown(container.dispose);

      await container.read(notificationPermissionPromptProvider.future);
      await container
          .read(notificationPermissionPromptProvider.notifier)
          .markAsShown();

      expect(
        container.read(notificationPermissionPromptProvider).value,
        isTrue,
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(notificationPermissionPromptKey), isTrue);
    });
  });
}
