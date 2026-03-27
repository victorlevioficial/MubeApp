import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import '../../../../design_system/components/navigation/app_app_bar.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../routing/route_paths.dart';
import '../../../auth/data/auth_repository.dart';
import '../providers/gig_filters_controller.dart';
import '../providers/gig_streams.dart';
import 'gigs_screen.dart';
import 'my_applications_screen.dart';
import 'my_gigs_screen.dart';

enum GigsTab { gigs, myApplications, myGigs }

class GigsHubScreen extends ConsumerStatefulWidget {
  const GigsHubScreen({
    super.key,
    this.initialTab = GigsTab.gigs,
    this.showBackButton = false,
  });

  final GigsTab initialTab;
  final bool showBackButton;

  @override
  ConsumerState<GigsHubScreen> createState() => _GigsHubScreenState();
}

class _GigsHubScreenState extends ConsumerState<GigsHubScreen> {
  late int _selectedIndex;

  final List<Widget> _screens = const [
    GigsScreen(embedded: true),
    MyApplicationsScreen(embedded: true),
    MyGigsScreen(embedded: true),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab.index;
    _refreshApplicationsIfNeeded(_selectedIndex);
  }

  @override
  void didUpdateWidget(covariant GigsHubScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _selectedIndex = widget.initialTab.index;
      _refreshApplicationsIfNeeded(_selectedIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(gigFiltersControllerProvider);
    final profile = ref.watch(currentUserProfileProvider).value;
    final canCreateGig = profile?.isCadastroConcluido == true;
    final showCreateFab =
        canCreateGig && _selectedIndex != GigsTab.myApplications.index;
    final applicationsLabel = MediaQuery.sizeOf(context).width >= 390
        ? 'Candidaturas'
        : 'Aplic.';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        title: 'Gigs',
        showBackButton: widget.showBackButton,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.s8),
            child: IconButton(
              tooltip: 'Filtros',
              onPressed: () => _openAdvancedFilters(context),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    color: AppColors.textSecondary,
                  ),
                  if (filters.activeFilterCount > 0)
                    Positioned(
                      right: -5,
                      top: -5,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s4,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: AppRadius.pill,
                        ),
                        child: Center(
                          child: Text(
                            '${filters.activeFilterCount}',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const _GigsCompactHeader(),
          Container(
            margin: const EdgeInsets.fromLTRB(
              AppSpacing.s16,
              AppSpacing.s8,
              AppSpacing.s16,
              AppSpacing.s8,
            ),
            padding: AppSpacing.all4,
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight.withValues(alpha: 0.3),
              borderRadius: AppRadius.pill,
              border: Border.all(
                color: AppColors.textPrimary.withValues(alpha: 0.05),
              ),
            ),
            child: GNav(
              gap: AppSpacing.s8,
              backgroundColor: AppColors.transparent,
              color: AppColors.textSecondary,
              activeColor: AppColors.textPrimary,
              tabBackgroundColor: AppColors.primary,
              padding: AppSpacing.h16v12,
              duration: const Duration(milliseconds: 300),
              selectedIndex: _selectedIndex,
              onTabChange: (index) {
                _refreshApplicationsIfNeeded(index);
                setState(() => _selectedIndex = index);
              },
              tabs: [
                _buildTabButton(
                  icon: Icons.work_outline_rounded,
                  text: 'Abertas',
                ),
                _buildTabButton(
                  icon: Icons.how_to_reg_rounded,
                  text: applicationsLabel,
                ),
                _buildTabButton(
                  icon: Icons.folder_shared_outlined,
                  text: 'Minhas',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Expanded(
            child: IndexedStack(index: _selectedIndex, children: _screens),
          ),
        ],
      ),
      floatingActionButton: !showCreateFab
          ? null
          : FloatingActionButton.extended(
              heroTag: 'gigs_hub_create_fab',
              onPressed: () => context.push(RoutePaths.gigCreate),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
              elevation: 8,
              extendedPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s24,
              ),
              shape: const StadiumBorder(),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                _selectedIndex == GigsTab.myGigs.index
                    ? 'Publicar gig'
                    : 'Nova gig',
                style: AppTypography.buttonPrimary.copyWith(fontSize: 14),
              ),
            ),
    );
  }

  GButton _buildTabButton({required IconData icon, required String text}) {
    return GButton(
      icon: icon,
      text: text,
      textStyle: AppTypography.labelLarge.copyWith(
        color: AppColors.textPrimary,
        fontWeight: AppTypography.buttonPrimary.fontWeight,
      ),
    );
  }

  void _refreshApplicationsIfNeeded(int index) {
    if (index != GigsTab.myApplications.index) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(myApplicationsProvider);
    });
  }

  Future<void> _openAdvancedFilters(BuildContext context) async {
    if (_selectedIndex != GigsTab.gigs.index) {
      setState(() => _selectedIndex = GigsTab.gigs.index);
    }
    await showGigFiltersSheet(context, ref);
  }
}

class _GigsCompactHeader extends StatelessWidget {
  const _GigsCompactHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s16,
        AppSpacing.s16,
        AppSpacing.s4,
      ),
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tudo sobre gigs', style: AppTypography.headlineSmall),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'Acompanhe vagas, candidaturas e publicacoes em um lugar so.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
