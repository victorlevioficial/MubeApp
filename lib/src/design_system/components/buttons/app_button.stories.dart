import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'app_button.dart';
import '../../foundations/tokens/app_spacing.dart';

@widgetbook.UseCase(name: 'Default', type: AppButton)
Widget buildAppButton(BuildContext context) {
  return Padding(
    padding: AppSpacing.all16,
    child: Center(
      child: AppButton(
        text: context.knobs.string(label: 'Text', initialValue: 'Click Me'),
        variant: context.knobs.object.dropdown(
          label: 'Variant',
          options: AppButtonVariant.values,
          initialOption: AppButtonVariant.primary,
        ),
        size: context.knobs.object.dropdown(
          label: 'Size',
          options: AppButtonSize.values,
          initialOption: AppButtonSize.medium,
        ),
        isLoading: context.knobs.boolean(label: 'Loading', initialValue: false),
        isFullWidth: context.knobs.boolean(
          label: 'Full Width',
          initialValue: false,
        ),
        onPressed: () {},
      ),
    ),
  );
}

@widgetbook.UseCase(name: 'Variants', type: AppButton)
Widget buildAppButtonVariants(BuildContext context) {
  return const Padding(
    padding: AppSpacing.all16,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppButton.primary(text: 'Primary Button', onPressed: null),
          SizedBox(height: AppSpacing.s16),
          AppButton.secondary(text: 'Secondary Button', onPressed: null),
          SizedBox(height: AppSpacing.s16),
          AppButton.outline(text: 'Outline Button', onPressed: null),
          SizedBox(height: AppSpacing.s16),
          AppButton.ghost(text: 'Ghost Button', onPressed: null),
        ],
      ),
    ),
  );
}
