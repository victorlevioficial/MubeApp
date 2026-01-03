import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common_widgets/primary_button.dart';
import '../../../common_widgets/responsive_center.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione uma opção.')),
      );
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
        loading: () => const Center(child: CircularProgressIndicator()),
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
                  horizontal: 24.0,
                  vertical: 40.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Spacing to center content vertically roughly if needed,
                    // or just let it start from top like LoginScreen.
                    // Login uses: padding: const EdgeInsets.fromLTRB(24, 80, 24, 40)
                    // We will match spacing logic but allow scrolling.
                    const SizedBox(
                      height: 48,
                    ), // Top spacing matching visual approximation

                    Text(
                      'Bem-vindo ao Mube!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Como você quer usar a plataforma?',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Grid 2x2 with shrinkWrap
                    GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true, // Key fix: takes only needed space
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
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

                    const SizedBox(
                      height: 48,
                    ), // Increased spacing as requested
                    // Button
                    SizedBox(
                      height: 56, // Match Login button height
                      child: PrimaryButton(
                        text: 'Continuar',
                        isLoading: state.isLoading,
                        onPressed: _selectedType != null
                            ? () => _submit(user)
                            : null,
                      ),
                    ),

                    const SizedBox(height: 24),
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
          borderRadius: BorderRadius.circular(16),
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
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
