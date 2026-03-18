import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get darkTheme => _buildDarkTheme();

  static ThemeData get highContrastDarkTheme =>
      _buildDarkTheme(highContrast: true);

  static ThemeData _buildDarkTheme({bool highContrast = false}) {
    final outlineColor = highContrast
        ? AppColors.textSecondary.withValues(alpha: 0.95)
        : AppColors.border;
    final fieldBorderColor = highContrast
        ? AppColors.textPrimary
        : AppColors.border;
    final appBarColor = highContrast
        ? AppColors.background
        : AppColors.background.withValues(alpha: 0.8);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,

      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primary,
        surface: AppColors.surface,
        onPrimary: AppColors.textPrimary,
        onSecondary: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textPlaceholder,
        tertiary: AppColors.primary,
        outline: outlineColor,
        error: AppColors.error,
      ),

      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all24),
      ),

      cardTheme: const CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        shadowColor: AppColors.transparent,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        shadowColor: AppColors.background.withValues(alpha: 0.42),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.all12),
        textStyle: AppTypography.bodyMedium,
      ),

      textTheme: GoogleFonts.interTextTheme()
          .copyWith(
            headlineLarge: AppTypography.headlineLarge,
            headlineMedium: AppTypography.headlineMedium,
            headlineSmall: AppTypography.headlineSmall,
            titleLarge: AppTypography.titleLarge,
            titleMedium: AppTypography.titleMedium,
            titleSmall: AppTypography.titleSmall,
            bodyLarge: AppTypography.bodyLarge,
            bodyMedium: AppTypography.bodyMedium,
            bodySmall: AppTypography.bodySmall,
          )
          .apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
            decorationColor: AppColors.textPrimary,
          ),

      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AppColors.primary),
          textStyle: WidgetStateProperty.all(AppTypography.link),
          overlayColor: WidgetStateProperty.all(
            AppColors.primary.withValues(alpha: highContrast ? 0.18 : 0.12),
          ),
        ),
      ),

      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.surface,
        headerBackgroundColor: AppColors.surface,
        headerForegroundColor: AppColors.textPrimary,
        dayForegroundColor: WidgetStateProperty.all(AppColors.textPrimary),
        yearForegroundColor: WidgetStateProperty.all(AppColors.textPrimary),
        dayOverlayColor: WidgetStateProperty.all(
          AppColors.primary.withValues(alpha: highContrast ? 0.18 : 0.12),
        ),
        todayBackgroundColor: WidgetStateProperty.all(
          AppColors.surfaceHighlight,
        ),
        todayForegroundColor: WidgetStateProperty.all(AppColors.primary),
        dayStyle: AppTypography.bodyMedium,
        confirmButtonStyle: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AppColors.primary),
          textStyle: WidgetStateProperty.all(AppTypography.buttonSecondary),
        ),
        cancelButtonStyle: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AppColors.textSecondary),
          textStyle: WidgetStateProperty.all(AppTypography.buttonSecondary),
        ),
      ),

      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.surface,
        hourMinuteTextColor: AppColors.textPrimary,
        hourMinuteColor: AppColors.surfaceHighlight,
        dialHandColor: AppColors.primary,
        dialBackgroundColor: AppColors.surfaceHighlight,
        dayPeriodTextColor: AppColors.textPrimary,
        dayPeriodColor: AppColors.surfaceHighlight,
        helpTextStyle: AppTypography.bodySmall,
        entryModeIconColor: AppColors.primary,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        shadowColor: AppColors.background.withValues(alpha: 0.42),
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.top24),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceHighlight,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.all8),
        behavior: SnackBarBehavior.fixed,
        actionTextColor: AppColors.primary,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: appBarColor,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTypography.headlineMedium,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPlaceholder,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.all12,
          borderSide: BorderSide(color: fieldBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.all12,
          borderSide: BorderSide(color: fieldBorderColor),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.all12,
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.primaryDisabled;
            }
            if (states.contains(WidgetState.pressed)) {
              return AppColors.primaryPressed;
            }
            return AppColors.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.textDisabled;
            }
            return AppColors.textPrimary;
          }),
          minimumSize: WidgetStateProperty.all(const Size(64, 56)),
          elevation: WidgetStateProperty.all(0),
          shadowColor: WidgetStateProperty.all(AppColors.transparent),
          overlayColor: WidgetStateProperty.all(
            AppColors.textPrimary.withValues(alpha: highContrast ? 0.14 : 0.08),
          ),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(borderRadius: AppRadius.pill),
          ),
          textStyle: WidgetStateProperty.all(AppTypography.buttonPrimary),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AppColors.textPrimary),
          side: WidgetStateProperty.all(
            BorderSide(color: outlineColor, width: highContrast ? 1.5 : 1),
          ),
          minimumSize: WidgetStateProperty.all(const Size(64, 48)),
          overlayColor: WidgetStateProperty.all(
            AppColors.textPrimary.withValues(alpha: highContrast ? 0.10 : 0.05),
          ),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(borderRadius: AppRadius.pill),
          ),
          textStyle: WidgetStateProperty.all(AppTypography.buttonSecondary),
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return null;
        }),
        checkColor: WidgetStateProperty.all(AppColors.textPrimary),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.all4),
        side: BorderSide(
          color: highContrast ? AppColors.textPrimary : AppColors.textSecondary,
          width: highContrast ? 2.5 : 2,
        ),
      ),
    );
  }
}
