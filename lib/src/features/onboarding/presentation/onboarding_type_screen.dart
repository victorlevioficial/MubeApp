import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/components/buttons/app_button.dart';
import '../../../design_system/components/feedback/app_snackbar.dart';
import '../../../design_system/components/loading/app_loading_indicator.dart';
import '../../../design_system/components/navigation/responsive_center.dart';
import '../../../design_system/components/patterns/full_width_selection_card.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_effects.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../../routing/route_paths.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../bands/domain/band_activation_rules.dart';
import 'onboarding_controller.dart';
import 'widgets/band_profile_tutorial_dialog.dart';

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
  ProviderSubscription<AsyncValue<void>>? _controllerSubscription;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, dynamic>> _types = [
    {
      'value': 'profissional',
      'label': 'Perfil Individual',
      'description':
          'Cantor, instrumentista, DJ, produção, audiovisual, fotografia, design gráfico, social media, educação, luthier, performance ou técnica de palco',
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

    _controllerSubscription = ref.listenManual<AsyncValue<void>>(
      onboardingControllerProvider,
      (previous, next) {
        if (!mounted || !next.hasError || previous?.hasError == true) {
          return;
        }
        AppSnackBar.error(
          context,
          'Não foi possível continuar o cadastro. Tente novamente.',
        );
      },
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _controllerSubscription?.close();
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

  Future<void> _handleTypeSelection(Map<String, dynamic> type) async {
    final selectedValue = type['value'] as String;

    if (selectedValue != 'banda') {
      setState(() => _selectedType = selectedValue);
      return;
    }

    if (_selectedType == selectedValue) {
      return;
    }

    final previousSelection = _selectedType;
    final shouldContinue = await BandProfileTutorialDialog.show(
      context: context,
      minimumMembers: minimumBandMembersForActivation,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedType = shouldContinue ? selectedValue : previousSelection;
    });
  }

  Future<void> _signOutAndGoToLogin() async {
    await ref.read(authRepositoryProvider).signOut();
    if (!mounted) return;
    context.go(RoutePaths.login);
  }

  void _handleLockedBackNavigation() {
    if (ref.read(onboardingControllerProvider).isLoading) {
      return;
    }
    unawaited(_signOutAndGoToLogin());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final userAsync = ref.watch(currentUserProfileProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleLockedBackNavigation();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: userAsync.when(
            skipLoadingOnReload: true,
            loading: () => const Center(child: AppLoadingIndicator.medium()),
            error: (err, stack) => Center(
              child: Text(
                'Erro: $err',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
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

              return Column(
                children: [
                  Expanded(
                    child: SafeArea(
                      bottom: false,
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: ResponsiveCenter(
                          maxContentWidth: 600,
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.s24,
                            AppSpacing.s32,
                            AppSpacing.s24,
                            AppSpacing.s24,
                          ),
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildHeader(),
                                  const SizedBox(height: AppSpacing.s32),
                                  ...List.generate(_types.length, (index) {
                                    final type = _types[index];
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        bottom: index < _types.length - 1
                                            ? AppSpacing.s12
                                            : 0,
                                      ),
                                      child: FullWidthSelectionCard(
                                        icon: type['icon'] as IconData,
                                        title: type['label'] as String,
                                        description:
                                            type['description'] as String?,
                                        isSelected:
                                            _selectedType == type['value'],
                                        onTap: () => _handleTypeSelection(type),
                                        density: SelectionCardDensity.compact,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        border: const Border(
                          top: BorderSide(color: AppColors.border),
                        ),
                        boxShadow: AppEffects.subtleShadow,
                      ),
                      child: ResponsiveCenter(
                        maxContentWidth: 600,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.s24,
                          AppSpacing.s16,
                          AppSpacing.s24,
                          AppSpacing.s24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
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
                            const SizedBox(height: AppSpacing.s12),
                            Center(
                              child: TextButton(
                                onPressed: state.isLoading
                                    ? null
                                    : _handleLockedBackNavigation,
                                child: Text(
                                  'Sair e usar outra conta',
                                  style: AppTypography.link,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
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
        Text(
          'Como você quer usar a plataforma?',
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.s20),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s14,
            vertical: AppSpacing.s12,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.all16,
            border: Border.all(color: AppColors.border.withValues(alpha: 0.85)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.s2),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Text(
                  'Se escolher o tipo errado, você ainda pode voltar e alterar isso antes de concluir o cadastro.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
