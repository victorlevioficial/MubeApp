import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../foundations/app_colors.dart';
import '../foundations/app_radius.dart';
import '../foundations/app_spacing.dart';
import '../foundations/app_typography.dart';

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
        secondary: AppColors.textPrimary,
        surface: AppColors.surface,
        onPrimary: AppColors.textPrimary,
        onSecondary: AppColors.background,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textPlaceholder, // Fixes Input Hint Color
        tertiary: AppColors.accent, // Mapped for Interactive Elements / Links
        outline: AppColors.surfaceHighlight,
        error: AppColors.error,
      ),

      // Typography
      textTheme: GoogleFonts.interTextTheme()
          .copyWith(
            headlineLarge: AppTypography.headlineLarge,
            headlineMedium: AppTypography.headlineMedium,
            titleLarge: AppTypography.titleLarge,
            titleMedium: AppTypography.titleMedium,
            bodyMedium: AppTypography.bodyMedium,
            bodySmall: AppTypography.bodySmall,
          )
          .apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
            decorationColor: AppColors.textPrimary,
          ),

      // Text Button (Used for Dialog Actions like OK/Cancel)
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AppColors.accent),
          textStyle: WidgetStateProperty.all(
            AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          overlayColor: WidgetStateProperty.all(
            AppColors.accent.withValues(alpha: 0.1),
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
          AppColors.accent.withValues(alpha: 0.1),
        ),
        todayBackgroundColor: WidgetStateProperty.all(
          AppColors.surfaceHighlight,
        ),
        todayForegroundColor: WidgetStateProperty.all(AppColors.accent),
        dayStyle: AppTypography.bodyMedium,
        confirmButtonStyle: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AppColors.accent),
          textStyle: WidgetStateProperty.all(
            AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        cancelButtonStyle: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AppColors.textSecondary),
          textStyle: WidgetStateProperty.all(
            AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
          ),
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
        dayPeriodColor: AppColors.surfaceHighlight, // Selected AM/PM background
        helpTextStyle: AppTypography.bodySmall,
        entryModeIconColor: AppColors.accent,
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors
            .surfaceHighlight, // Mapped from undefined surfaceContainerHighest
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPrimary, // Mapped from undefined onSurface
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.all8),
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.all(AppSpacing.s16),
        actionTextColor: AppColors.accent,
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
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
          vertical: 14, // Custom visual alignment
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.all12,
          borderSide: BorderSide(color: AppColors.surfaceHighlight),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.all12,
          borderSide: BorderSide(color: AppColors.surfaceHighlight),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.all12,
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.primaryDisabled;
            }
            return AppColors.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.textDisabled;
            }
            return AppColors.textPrimary;
          }),
          minimumSize: WidgetStateProperty.all(const Size(double.infinity, 56)),
          elevation: WidgetStateProperty.all(0),
          shadowColor: WidgetStateProperty.all(Colors.transparent),
          overlayColor: WidgetStateProperty.all(
            Colors.transparent,
          ), // No hover/splash
          splashFactory: NoSplash.splashFactory, // No ripple
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(28)),
            ),
          ),
          textStyle: WidgetStateProperty.all(
            AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),

      // Outlined Button (New Default for Secondary/Social)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(
            AppColors.textPrimary,
          ), // Fixed: Use textPrimary (which is white)
          side: WidgetStateProperty.all(
            const BorderSide(color: AppColors.surfaceHighlight, width: 1),
          ),
          minimumSize: WidgetStateProperty.all(const Size(double.infinity, 48)),
          overlayColor: WidgetStateProperty.all(Colors.transparent), // No hover
          splashFactory: NoSplash.splashFactory, // No ripple
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(28)),
            ),
          ),
          textStyle: WidgetStateProperty.all(
            AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w400),
          ),
        ),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return null; // Default (usually transparent/surface)
        }),
        checkColor: WidgetStateProperty.all(AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: AppColors.textSecondary, width: 2),
      ),
    );
  }
}
