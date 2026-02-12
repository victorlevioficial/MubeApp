import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../design_system/components/buttons/app_button.dart';
import '../../../design_system/components/feedback/app_snackbar.dart';
import '../../../design_system/components/loading/app_loading_indicator.dart';
import '../../../design_system/components/navigation/responsive_center.dart';
import '../../../design_system/components/patterns/full_width_selection_card.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import 'onboarding_controller.dart';

/// Enhanced onboarding type selection screen with full-width cards.
///
/// Redesigned to match the modern UI of the login screen with:
/// - Full-width selection cards instead of grid
/// - Icons and descriptions for each category
/// - Smooth animations
/// - Better visual hierarchy
class OnboardingTypeScreen extends ConsumerStatefulWidget {
  const OnboardingTypeScreen({super.key});

  @override
  ConsumerState<OnboardingTypeScreen> createState() =>
      _OnboardingTypeScreenState();
}

class _OnboardingTypeScreenState extends ConsumerState<OnboardingTypeScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedType;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, dynamic>> _types = [
    {
      'value': 'profissional',
      'label': 'Profissional',
      'description': 'Músico, cantor, DJ, técnico',
      'icon': FontAwesomeIcons.music,
    },
    {
      'value': 'banda',
      'label': 'Banda',
      'description': 'Grupo musical, orquestra',
      'icon': FontAwesomeIcons.users,
    },
    {
      'value': 'estudio',
      'label': 'Estúdio',
      'description': 'Gravação, mixagem, masterização',
      'icon': FontAwesomeIcons.compactDisc,
    },
    {
      'value': 'contratante',
      'label': 'Contratante',
      'description': 'Eventos, casas de show, produtoras',
      'icon': FontAwesomeIcons.briefcase,
    },
  ];

  @override
  void initState() {
    super.initState();

    // Setup animations (similar to login screen)
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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
      backgroundColor: AppColors.background,
      body: userAsync.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: AppLoadingIndicator.medium()),
        error: (err, stack) => Center(
          child: Text(
            'Erro: $err',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
          ),
        ),
        data: (user) {
          if (user == null) {
            return Center(
              child: Text(
                'Usuário não autenticado.',
                style: AppTypography.bodyMedium,
              ),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ResponsiveCenter(
                maxContentWidth: 600,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s24,
                  vertical: AppSpacing.s48,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header with logo and welcome message
                        _buildHeader(),

                        const SizedBox(height: AppSpacing.s48),

                        // Full-width selection cards
                        ...List.generate(_types.length, (index) {
                          final type = _types[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index < _types.length - 1
                                  ? AppSpacing.s16
                                  : 0,
                            ),
                            child: FullWidthSelectionCard(
                              icon: type['icon'],
                              title: type['label'],
                              description: type['description'],
                              isSelected: _selectedType == type['value'],
                              onTap: () {
                                setState(() => _selectedType = type['value']);
                              },
                            ),
                          );
                        }),

                        const SizedBox(height: AppSpacing.s48),

                        // Continue Button
                        SizedBox(
                          height: 56,
                          child: AppButton.primary(
                            text: 'Continuar',
                            size: AppButtonSize.large,
                            isLoading: state.isLoading,
                            onPressed: _selectedType != null
                                ? () => _submit(user)
                                : null,
                            isFullWidth: true,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.s24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Welcome title
        Text(
          'Bem-vindo ao Mube!',
          textAlign: TextAlign.center,
          style: AppTypography.headlineLarge.copyWith(
            fontSize: 32,
            letterSpacing: -1,
            height: 1.2,
          ),
        ),

        const SizedBox(height: AppSpacing.s12),

        // Subtitle
        Text(
          'Como você quer usar a plataforma?',
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
