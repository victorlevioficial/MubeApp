import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

// Importar principais componentes para o generator
import 'foundations/tokens/app_colors.dart';
// O arquivo gerado será criado aqui
import 'widgetbook_app.directories.g.dart';

void main() {
  runApp(const WidgetbookApp());
}

@widgetbook.App()
class WidgetbookApp extends StatelessWidget {
  const WidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      // Use the generated directories variable
      directories: directories,
      addons: [
        MaterialThemeAddon(
          themes: [
            WidgetbookTheme(
              name: 'Dark',
              data: ThemeData.dark().copyWith(
                scaffoldBackgroundColor: AppColors.background,
                primaryColor: AppColors.brandPrimary,
                colorScheme: const ColorScheme.dark(
                  primary: AppColors.brandPrimary,
                  secondary: AppColors.brandGlow,
                ),
              ),
            ),
          ],
        ),
        // ignore: deprecated_member_use
        TextScaleAddon(scales: [1.0, 1.5, 2.0]),
        // ignore: deprecated_member_use
        DeviceFrameAddon(
          devices: [
            Devices.ios.iPhone13,
            Devices.ios.iPad,
            Devices.android.samsungGalaxyS20,
          ],
        ),
      ],
    );
  }
}
