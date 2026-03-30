part of 'package:mube/src/app.dart';

extension _MubeAppView on _MubeAppState {
  Widget _buildAppView(BuildContext context) {
    final goRouter = ref.watch(goRouterProvider);
    final displayPreferences = ref.watch(appDisplayPreferencesProvider);
    final appUpdateNotice = ref.watch(appUpdateNoticeProvider).asData?.value;

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
      locale: displayPreferences.locale ?? const Locale('pt'),

      // Wrap all screens with offline indicator banner.
      builder: (context, child) {
        Widget content = DismissKeyboardOnTap(
          child: OfflineIndicator(child: child ?? const SizedBox.shrink()),
        );

        if (appUpdateNotice != null) {
          content = Stack(
            children: [
              content,
              Positioned.fill(
                child: ColoredBox(
                  color: AppColors.background.withValues(alpha: 0.82),
                  child: SafeArea(
                    child: Center(
                      child: Padding(
                        padding: AppSpacing.all24,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Material(
                            type: MaterialType.transparency,
                            child: AppUpdateNoticeDialog(
                              notice: appUpdateNotice,
                              onOpenStore: appUpdateNotice.storeUri == null
                                  ? null
                                  : (uri) => ref.read(
                                      appUpdateLauncherProvider,
                                    )(uri),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return content;
      },

      // Localization configuration.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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
