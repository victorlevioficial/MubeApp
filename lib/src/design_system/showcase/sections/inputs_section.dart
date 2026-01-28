import 'package:flutter/material.dart';

import '../../../common_widgets/app_checkbox.dart'; // Reusing existing checkbox
import '../../components/inputs/app_text_input.dart';
import '../../foundations/app_colors.dart';
import '../../foundations/app_spacing.dart';
import '../../foundations/app_typography.dart';

class InputsSection extends StatelessWidget {
  const InputsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _InputGroup(
          title: 'Text Inputs',
          children: [
            AppTextInput(
              label: 'Email Address',
              hint: 'Enter your email',
              prefixIcon: Icon(
                Icons.email_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
            SizedBox(height: AppSpacing.s16),
            AppTextInput(
              label: 'Password',
              hint: '••••••••',
              obscureText: true,
              suffixIcon: Icon(
                Icons.visibility_off_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
            SizedBox(height: AppSpacing.s16),
            AppTextInput(
              label: 'Error State',
              hint: 'Enter something',
              errorText: 'This field is required',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s24),

        _InputGroup(
          title: 'Selection Controls',
          children: [
            // Checkbox demo needs state, using a simple stateful wrapper or just standard checklist
            AppCheckbox(label: 'Remember me', value: true, onChanged: (v) {}),
            const SizedBox(height: AppSpacing.s8),
            AppCheckbox(
              label: 'Subscribe to newsletter',
              value: false,
              onChanged: (v) {},
            ),
            const SizedBox(height: AppSpacing.s16),
            Row(
              children: [
                Switch(
                  value: true,
                  onChanged: (v) {},
                  activeThumbColor: AppColors.brandPrimary,
                ),
                const SizedBox(width: AppSpacing.s8),
                Text(
                  'Notifications',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _InputGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InputGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        ...children,
      ],
    );
  }
}
