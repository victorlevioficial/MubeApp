import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/components/buttons/app_button.dart';
import '../../../design_system/components/feedback/app_snackbar.dart';
import '../../../design_system/components/loading/app_loading.dart';
import '../../../design_system/components/navigation/responsive_center.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import 'onboarding_controller.dart';

class OnboardingTypeScreen extends ConsumerStatefulWidget {
  const OnboardingTypeScreen({super.key});

  @override
  ConsumerState<OnboardingTypeScreen> createState() =>
      _OnboardingTypeScreenState();
}

class _OnboardingTypeScreenState extends ConsumerState<OnboardingTypeScreen> {
  String? _selectedType;

  // Mapa de configuração dos cards (Label + Icon + Value)
  // Icons estão usando Material Icons como fallback, aproximado do design.
  final List<Map<String, dynamic>> _types = [
    {
      'label': 'Contratante',
      'value': 'contratante',
      'icon': Icons.business_center, // Briefcase
    },
    {
      'label': 'Profissional',
      'value': 'profissional',
      'icon': Icons.music_note, // Note
    },
    {
      'label': 'Estúdio',
      'value': 'estudio',
      'icon': Icons.headphones, // Headphones
    },
    {
      'label': 'Banda',
      'value': 'banda',
      'icon': Icons.people, // Group (closest generic to band)
    },
  ];

  void _submit(AppUser currentUser) {
    if (_selectedType != null) {
      ref
          .read(onboardingControllerProvider.notifier)
          .selectProfileType(
            selectedType: _selectedType!,
            currentUser: currentUser,
          );
    } else {
      AppSnackBar.warning(context, 'Por favor, selecione uma opção.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final userAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      // backgroundColor: Use default Scaffold background from Theme
      body: userAsync.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: AppLoading.medium()),
        error: (err, stack) => Center(child: Text('Erro: $err')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Usuário não autenticado.'));
          }

          return SafeArea(
            child: SingleChildScrollView(
              child: ResponsiveCenter(
                maxContentWidth: 600,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s24,
                  vertical: AppSpacing.s40,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Spacing to center content vertically roughly if needed,
                    // or just let it start from top like LoginScreen.
                    // Login uses: padding: const EdgeInsets.fromLTRB(24, 80, 24, 40)
                    // We will match spacing logic but allow scrolling.
                    const SizedBox(height: AppSpacing.s48),

                    Text(
                      'Bem-vindo ao Mube!',
                      textAlign: TextAlign.center,
                      style: AppTypography.headlineLarge.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      'Como você quer usar a plataforma?',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s32),

                    // Grid 2x2 with shrinkWrap
                    GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true, // Key fix: takes only needed space
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: AppSpacing.s16,
                            mainAxisSpacing: AppSpacing.s16,
                            childAspectRatio: 1.5,
                          ),
                      itemCount: _types.length,
                      itemBuilder: (context, index) {
                        final type = _types[index];
                        final isSelected = _selectedType == type['value'];

                        return _buildCard(
                          label: type['label'],
                          icon: type['icon'],
                          isSelected: isSelected,
                          onTap: () =>
                              setState(() => _selectedType = type['value']),
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.s48),
                    // Button
                    SizedBox(
                      height: AppSpacing.s48,
                      child: AppButton.primary(
                        text: 'Continuar',
                        isLoading: state.isLoading,
                        onPressed: _selectedType != null
                            ? () => _submit(user)
                            : null,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.s24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    // Colors based on state
    final Color backgroundColor = isSelected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.surface;
    final Color iconColor = isSelected
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.primary;
    final Color textColor = isSelected
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurface;
    final BoxBorder? border = isSelected
        ? null
        : Border.all(color: Theme.of(context).colorScheme.outline, width: 1);

    // Shadow removed explicitly as requested ("remove o shadow externo dos cards")

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: AppRadius.all16,
          border: border,
          // BoxShadow removed
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon larger and colored
            Icon(
              icon,
              size: 56, // Increased to 56 as requested ("maiores ainda")
              color: iconColor,
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              label,
              style: AppTypography.titleMedium.copyWith(color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}
