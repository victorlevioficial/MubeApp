import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primary,
        surface: AppColors.surface,
        onPrimary: AppColors.textPrimary,
        onSecondary: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textPlaceholder,
        tertiary: AppColors.primary,
        outline: AppColors.border,
        error: AppColors.error,
      ),

      // Typography
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

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AppColors.primary),
          textStyle: WidgetStateProperty.all(AppTypography.link),
          overlayColor: WidgetStateProperty.all(
            AppColors.primary.withValues(alpha: 0.12),
          ),
        ),
      ),

      // Date Picker Theme
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.surface,
        headerBackgroundColor: AppColors.surface,
        headerForegroundColor: AppColors.textPrimary,
        dayForegroundColor: WidgetStateProperty.all(AppColors.textPrimary),
        yearForegroundColor: WidgetStateProperty.all(AppColors.textPrimary),
        dayOverlayColor: WidgetStateProperty.all(
          AppColors.primary.withValues(alpha: 0.12),
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

      // Time Picker Theme
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

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.top24, // Pro Radius
        ),
      ),

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceHighlight,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.all8),
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.all(AppSpacing.s16),
        actionTextColor: AppColors.primary,
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background.withValues(
          alpha: 0.8,
        ), // Glass-ready
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTypography.headlineMedium,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPlaceholder,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: 16, // More breathing room
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.all12,
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.all12,
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.all12,
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),

      // Elevated Button (Premium Glow)
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
          elevation: WidgetStateProperty.all(0), // Removed elevation
          shadowColor: WidgetStateProperty.all(
            AppColors.transparent,
          ), // Removed glow
          overlayColor: WidgetStateProperty.all(
            AppColors.textPrimary.withValues(alpha: 0.08),
          ),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(borderRadius: AppRadius.pill),
          ),
          textStyle: WidgetStateProperty.all(AppTypography.buttonPrimary),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AppColors.textPrimary),
          side: WidgetStateProperty.all(
            const BorderSide(color: AppColors.border, width: 1),
          ),
          minimumSize: WidgetStateProperty.all(const Size(64, 48)),
          overlayColor: WidgetStateProperty.all(
            AppColors.textPrimary.withValues(alpha: 0.05),
          ),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(borderRadius: AppRadius.pill),
          ),
          textStyle: WidgetStateProperty.all(AppTypography.buttonSecondary),
        ),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return null;
        }),
        checkColor: WidgetStateProperty.all(AppColors.textPrimary),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.all4),
        side: const BorderSide(color: AppColors.textSecondary, width: 2),
      ),
    );
  }
}
