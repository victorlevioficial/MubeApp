import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/core/providers/app_display_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('appDisplayPreferencesProvider', () {
    test('loads persisted locale and theme mode', () async {
      SharedPreferences.setMockInitialValues({
        appLocaleCodePreferenceKey: 'en',
        appThemeModePreferenceKey: 'dark',
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(appDisplayPreferencesProvider);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final preferences = container.read(appDisplayPreferencesProvider);
      expect(preferences.locale, const Locale('en'));
      expect(preferences.themeMode, ThemeMode.dark);
    });

    test('persists updates and can clear locale override', () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appDisplayPreferencesProvider.notifier);
      await notifier.setLocaleOverride(const Locale('pt'));
      await notifier.setThemeMode(ThemeMode.system);
      await notifier.setLocaleOverride(null);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(appLocaleCodePreferenceKey), isNull);
      expect(prefs.getString(appThemeModePreferenceKey), ThemeMode.system.name);
      expect(container.read(appDisplayPreferencesProvider).locale, isNull);
      expect(
        container.read(appDisplayPreferencesProvider).themeMode,
        ThemeMode.system,
      );
    });
  });
}
