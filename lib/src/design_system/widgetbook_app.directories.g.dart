// dart format width=80
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AppGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:mube/src/design_system/components/buttons/app_button.stories.dart'
    as _mube_src_design_system_components_buttons_app_button_stories;
import 'package:widgetbook/widgetbook.dart' as _widgetbook;

final directories = <_widgetbook.WidgetbookNode>[
  _widgetbook.WidgetbookFolder(
    name: 'design_system',
    children: [
      _widgetbook.WidgetbookFolder(
        name: 'components',
        children: [
          _widgetbook.WidgetbookFolder(
            name: 'buttons',
            children: [
              _widgetbook.WidgetbookComponent(
                name: 'AppButton',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'Default',
                    builder:
                        _mube_src_design_system_components_buttons_app_button_stories
                            .buildAppButton,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Variants',
                    builder:
                        _mube_src_design_system_components_buttons_app_button_stories
                            .buildAppButtonVariants,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  ),
];
