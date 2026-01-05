import 'package:flutter/material.dart';

import '../../../common_widgets/app_date_picker_field.dart';
import '../../../common_widgets/app_dropdown_field.dart';
import '../../../common_widgets/app_filter_chip.dart';
import '../../../common_widgets/app_snackbar.dart';
import '../../../common_widgets/app_text_field.dart';
import '../../../common_widgets/onboarding_progress_bar.dart';
import '../../../common_widgets/or_divider.dart';
import '../../../common_widgets/primary_button.dart';
import '../../../common_widgets/secondary_button.dart';
import '../../../common_widgets/social_login_button.dart';
import '../../../design_system/foundations/app_colors.dart';
import '../../../design_system/foundations/app_radius.dart';
import '../../../design_system/foundations/app_spacing.dart';
import '../../../design_system/foundations/app_typography.dart';

class DesignSystemGalleryScreen extends StatefulWidget {
  const DesignSystemGalleryScreen({super.key});

  @override
  State<DesignSystemGalleryScreen> createState() =>
      _DesignSystemGalleryScreenState();
}

class _DesignSystemGalleryScreenState extends State<DesignSystemGalleryScreen> {
  final _textController = TextEditingController();
  final _dateController = TextEditingController();
  String? _dropdownValue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text(
                    'DESIGN SYSTEM',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 20), // Balance back button
                ],
              ),
              const SizedBox(height: 40),

              _buildSectionHeader('Typography'),
              Text('Headline Large', style: AppTypography.headlineLarge),
              const SizedBox(height: AppSpacing.s8),
              Text('Headline Medium', style: AppTypography.headlineMedium),
              const SizedBox(height: AppSpacing.s8),
              Text('Title Large', style: AppTypography.titleLarge),
              const SizedBox(height: AppSpacing.s8),
              Text('Title Medium', style: AppTypography.titleMedium),
              const SizedBox(height: AppSpacing.s8),
              Text('Body Medium', style: AppTypography.bodyMedium),
              const SizedBox(height: AppSpacing.s8),
              Text('Body Small', style: AppTypography.bodySmall),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Interactive / Link',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.accent,
                ),
              ),

              _buildSectionHeader('Colors'),
              Wrap(
                spacing: AppSpacing.s8,
                runSpacing: AppSpacing.s8,
                children: [
                  _buildColorBox(AppColors.primary, 'Primary'),
                  _buildColorBox(AppColors.primaryDark, 'Primary Dk'),
                  _buildColorBox(AppColors.accent, 'Accent'),
                  _buildColorBox(AppColors.background, 'Background'),
                  _buildColorBox(AppColors.surface, 'Surface'),
                  _buildColorBox(AppColors.surfaceHighlight, 'Surface Hl'),
                  _buildColorBox(AppColors.textPrimary, 'Text Pri'),
                  _buildColorBox(AppColors.textSecondary, 'Text Sec'),
                  _buildColorBox(AppColors.textPlaceholder, 'Placeholder'),
                  _buildColorBox(AppColors.textPlaceholder, 'Placeholder'),
                  // Removed textInverse and border
                  _buildColorBox(AppColors.error, 'Error'),
                  _buildColorBox(AppColors.success, 'Success'),
                ],
              ),

              _buildSectionHeader('Spacing'),
              const Text(
                'Base Unit: 4px. Scale: 4, 8, 12, 16, 24, 32, 48.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.s16),
              Wrap(
                spacing: AppSpacing.s16,
                runSpacing: AppSpacing.s16,
                children: [
                  _buildSpacingBox(AppSpacing.s4, 'xs (4)'),
                  _buildSpacingBox(AppSpacing.s8, 's (8)'),
                  _buildSpacingBox(AppSpacing.s12, 'm (12)'),
                  _buildSpacingBox(AppSpacing.s16, 'l (16)'),
                  _buildSpacingBox(AppSpacing.s24, 'xl (24)'),
                  _buildSpacingBox(AppSpacing.s32, '2xl (32)'),
                  _buildSpacingBox(AppSpacing.s48, '3xl (48)'),
                ],
              ),
              const SizedBox(height: AppSpacing.s24),
              const Text(
                'Spacing Scenarios (Context)',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              Container(
                padding: AppSpacing.all16,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.surfaceHighlight),
                  borderRadius: AppRadius.all12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildScenarioRow(
                      'Tight (4px)',
                      'Icon + Text',
                      AppSpacing.s4,
                    ),
                    const Divider(
                      height: 32,
                      color: AppColors.surfaceHighlight,
                    ),
                    _buildScenarioRow(
                      'Related (8px)',
                      'Title + Subtitle',
                      AppSpacing.s8,
                    ),
                    const Divider(
                      height: 32,
                      color: AppColors.surfaceHighlight,
                    ),
                    _buildScenarioRow(
                      'Standard (16px)',
                      'Component Gap',
                      AppSpacing.s16,
                    ),
                    const Divider(
                      height: 32,
                      color: AppColors.surfaceHighlight,
                    ),
                    _buildScenarioRow(
                      'Section (24px)',
                      'Major Break',
                      AppSpacing.s24,
                    ),
                  ],
                ),
              ),

              _buildSectionHeader('Radius'),
              Wrap(
                spacing: AppSpacing.s16,
                runSpacing: AppSpacing.s16,
                children: [
                  _buildRadiusBox(AppRadius.r8, 'r8'),
                  _buildRadiusBox(AppRadius.r12, 'r12'),
                  _buildRadiusBox(AppRadius.r16, 'r16'),
                  _buildRadiusBox(AppRadius.r24, 'r24'),
                  _buildRadiusBox(AppRadius.rPill, 'Pill'),
                ],
              ),

              _buildSectionHeader('Icons'),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Icon(Icons.arrow_forward_ios, color: AppColors.textPrimary),
                  Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
                  Icon(Icons.keyboard_arrow_down, color: AppColors.textPrimary),
                  Icon(Icons.check_circle_outline, color: AppColors.success),
                  Icon(Icons.error_outline, color: AppColors.error),
                ],
              ),

              _buildSectionHeader('Inputs'),
              AppTextField(
                controller: _textController,
                label: 'Text Field',
                hint: 'Type something...',
              ),
              const SizedBox(height: AppSpacing.s16),
              AppDatePickerField(
                label: 'Date Picker',
                controller: _dateController,
              ),
              const SizedBox(height: AppSpacing.s16),
              AppDropdownField<String>(
                label: 'Dropdown',
                value: _dropdownValue,
                items: const [
                  DropdownMenuItem(value: 'Option 1', child: Text('Option 1')),
                  DropdownMenuItem(value: 'Option 2', child: Text('Option 2')),
                ],
                onChanged: (val) => setState(() => _dropdownValue = val),
              ),

              _buildSectionHeader('Chips'),
              Wrap(
                spacing: 8,
                children: [
                  AppFilterChip(
                    label: 'Selected',
                    isSelected: true,
                    onSelected: (v) {},
                  ),
                  const SizedBox(width: 8),
                  AppFilterChip(
                    label: 'Unselected',
                    isSelected: false,
                    onSelected: (v) {},
                  ),
                  const SizedBox(width: 8),
                  AppFilterChip(
                    label: 'With Remove',
                    isSelected: true,
                    onSelected: (v) {},
                    onRemove: () {},
                  ),
                ],
              ),

              _buildSectionHeader('Buttons'),
              PrimaryButton(text: 'Primary Button', onPressed: () {}),
              const SizedBox(height: AppSpacing.s16),
              SecondaryButton(text: 'Secondary Button', onPressed: () {}),
              const SizedBox(height: AppSpacing.s16),
              SocialLoginButton(type: SocialType.google, onPressed: () {}),
              const SizedBox(height: AppSpacing.s8),
              SocialLoginButton(type: SocialType.apple, onPressed: () {}),

              _buildSectionHeader('Feedback'),
              PrimaryButton(
                text: 'Show Snackbar (Success)',
                onPressed: () {
                  AppSnackBar.show(
                    context,
                    'This is a success message',
                    isError: false,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.s8),
              PrimaryButton(
                text: 'Show Snackbar (Error)',
                onPressed: () {
                  AppSnackBar.show(
                    context,
                    'This is an error message',
                    isError: true,
                  );
                },
              ),

              _buildSectionHeader('Progress'),
              const OnboardingProgressBar(currentStep: 1, totalSteps: 3),
              const SizedBox(height: AppSpacing.s8),
              const OnboardingProgressBar(currentStep: 2, totalSteps: 3),
              const OnboardingProgressBar(currentStep: 2, totalSteps: 3),

              _buildSectionHeader('Divider'),
              const OrDivider(),
              const SizedBox(height: AppSpacing.s16),
              const OrDivider(text: 'Ou entre com'),

              const SizedBox(height: AppSpacing.s24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: AppColors.surfaceHighlight),
          const SizedBox(height: AppSpacing.s8),
          Text(title, style: AppTypography.headlineMedium),
          const SizedBox(height: AppSpacing.s16),
        ],
      ),
    );
  }

  Widget _buildColorBox(Color color, String name) {
    return Column(
      children: [
        Container(
          height: AppSpacing.s48,
          width: 80, // Fixed width for alignment, acceptable for gallery
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppRadius.all8,
            border: Border.all(color: AppColors.surfaceHighlight),
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(name, style: AppTypography.bodySmall),
      ],
    );
  }

  Widget _buildSpacingBox(double size, String label) {
    return Column(
      children: [
        Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(size / 4),
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(label, style: AppTypography.bodySmall),
      ],
    );
  }

  Widget _buildRadiusBox(double radius, String label) {
    return Column(
      children: [
        Container(
          height: AppSpacing.s48,
          width: AppSpacing.s48,
          decoration: BoxDecoration(
            color: AppColors.surfaceHighlight,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.primary),
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(label, style: AppTypography.bodySmall),
      ],
    );
  }

  Widget _buildScenarioRow(String name, String contextObj, double spacing) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(color: AppColors.success, fontSize: 12),
              ),
              Text(
                contextObj,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        Container(height: 24, width: spacing, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          '${spacing.toInt()}px',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
        ),
        const Spacer(),
        // Example visualization
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.surfaceHighlight),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Container(width: 16, height: 16, color: AppColors.textSecondary),
              SizedBox(width: spacing),
              Container(width: 16, height: 16, color: AppColors.textSecondary),
            ],
          ),
        ),
      ],
    );
  }
}
