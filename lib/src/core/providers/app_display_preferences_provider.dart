import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_providers.dart';

const String appLocaleCodePreferenceKey = 'app_locale_code';
const String appThemeModePreferenceKey = 'app_theme_mode';

@immutable
class AppDisplayPreferences {
  const AppDisplayPreferences({this.locale, this.themeMode = ThemeMode.system});

  final Locale? locale;
  final ThemeMode themeMode;

  static const Object _noLocaleChange = Object();

  AppDisplayPreferences copyWith({
    Object? locale = _noLocaleChange,
    ThemeMode? themeMode,
  }) {
    return AppDisplayPreferences(
      locale: identical(locale, _noLocaleChange)
          ? this.locale
          : locale as Locale?,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

class AppDisplayPreferencesNotifier extends Notifier<AppDisplayPreferences> {
  @override
  AppDisplayPreferences build() {
    unawaited(_load());
    return const AppDisplayPreferences();
  }

  Future<void> setLocaleOverride(Locale? locale) async {
    state = state.copyWith(locale: locale);
    final prefs = await ref.read(sharedPreferencesLoaderProvider)();
    final languageCode = locale?.languageCode.trim();
    if (languageCode == null || languageCode.isEmpty) {
      await prefs.remove(appLocaleCodePreferenceKey);
      return;
    }
    await prefs.setString(appLocaleCodePreferenceKey, languageCode);
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    state = state.copyWith(themeMode: themeMode);
    final prefs = await ref.read(sharedPreferencesLoaderProvider)();
    await prefs.setString(appThemeModePreferenceKey, themeMode.name);
  }

  Future<void> _load() async {
    final prefs = await ref.read(sharedPreferencesLoaderProvider)();
    final savedLocaleCode = prefs.getString(appLocaleCodePreferenceKey);
    final savedThemeMode = prefs.getString(appThemeModePreferenceKey);

    state = AppDisplayPreferences(
      locale: _localeFromCode(savedLocaleCode),
      themeMode: _themeModeFromName(savedThemeMode),
    );
  }

  Locale? _localeFromCode(String? code) {
    final normalized = code?.trim().toLowerCase();
    switch (normalized) {
      case 'en':
        return const Locale('en');
      case 'pt':
        return const Locale('pt');
      default:
        return null;
    }
  }

  ThemeMode _themeModeFromName(String? rawName) {
    final normalized = rawName?.trim().toLowerCase();
    switch (normalized) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      case 'light':
      default:
        return ThemeMode.system;
    }
  }
}

final appDisplayPreferencesProvider =
    NotifierProvider<AppDisplayPreferencesNotifier, AppDisplayPreferences>(
      AppDisplayPreferencesNotifier.new,
    );
