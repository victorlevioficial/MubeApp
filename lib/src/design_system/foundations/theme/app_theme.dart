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
      primaryColor: AppColors.brandPrimary,

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.brandPrimary,
        secondary: AppColors.brandGlow, // Secondary is now the Glow color
        surface: AppColors.surface,
        onPrimary: AppColors.textPrimary,
        onSecondary: AppColors.background,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textPlaceholder,
        tertiary: AppColors.semanticAction,
        outline: AppColors.border,
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

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AppColors.semanticAction),
          textStyle: WidgetStateProperty.all(
            AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          overlayColor: WidgetStateProperty.all(
            AppColors.semanticAction.withValues(alpha: 0.1),
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
          AppColors.semanticAction.withValues(alpha: 0.1),
        ),
        todayBackgroundColor: WidgetStateProperty.all(
          AppColors.surfaceHighlight,
        ),
        todayForegroundColor: WidgetStateProperty.all(AppColors.semanticAction),
        dayStyle: AppTypography.bodyMedium,
        confirmButtonStyle: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AppColors.semanticAction),
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
        dialHandColor: AppColors.brandPrimary,
        dialBackgroundColor: AppColors.surfaceHighlight,
        dayPeriodTextColor: AppColors.textPrimary,
        dayPeriodColor: AppColors.surfaceHighlight,
        helpTextStyle: AppTypography.bodySmall,
        entryModeIconColor: AppColors.semanticAction,
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ), // Pro Radius
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
        actionTextColor: AppColors.semanticAction,
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
          borderSide: BorderSide(color: AppColors.brandPrimary, width: 1.5),
        ),
      ),

      // Elevated Button (Premium Glow)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.primaryDisabled;
            }
            return AppColors.brandPrimary;
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
            Colors.transparent,
          ), // Removed glow
          overlayColor: WidgetStateProperty.all(
            AppColors.textPrimary.withValues(alpha: 0.1),
          ),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(28)), // Pill shape
            ),
          ),
          textStyle: WidgetStateProperty.all(
            AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AppColors.textPrimary),
          side: WidgetStateProperty.all(
            const BorderSide(
              color: AppColors.textPrimary,
              width: 1,
            ), // White - High Contrast as requested
          ),
          minimumSize: WidgetStateProperty.all(const Size(64, 48)),
          overlayColor: WidgetStateProperty.all(
            AppColors.textPrimary.withValues(alpha: 0.05),
          ),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(28)),
            ),
          ),
          textStyle: WidgetStateProperty.all(
            AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.brandPrimary;
          }
          return null;
        }),
        checkColor: WidgetStateProperty.all(AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: AppColors.textSecondary, width: 2),
      ),
    );
  }
}
