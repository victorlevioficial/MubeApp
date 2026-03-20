part of 'package:mube/src/app.dart';

extension _MubeAppView on _MubeAppState {
  Widget _buildAppView(BuildContext context) {
    final goRouter = ref.watch(goRouterProvider);
    final displayPreferences = ref.watch(appDisplayPreferencesProvider);

    return MaterialApp.router(
      scaffoldMessengerKey: scaffoldMessengerKey,
      scrollBehavior: const AppScrollBehavior(),
      title: 'Mube',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      highContrastTheme: AppTheme.highContrastDarkTheme,
      highContrastDarkTheme: AppTheme.highContrastDarkTheme,
      themeMode: displayPreferences.themeMode,
      routerConfig: goRouter,

      // Wrap all screens with offline indicator banner.
      builder: (context, child) {
        return DismissKeyboardOnTap(
          child: OfflineIndicator(child: child ?? const SizedBox.shrink()),
        );
      },

      // Localization configuration.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: displayPreferences.locale,
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return const Locale('pt');

        for (final supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale.languageCode) {
            return supportedLocale;
          }
        }

        return const Locale('pt');
      },
    );
  }
}
