import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../common_widgets/app_text_field.dart';
import '../../../common_widgets/app_refresh_indicator.dart';
import '../../../design_system/foundations/app_colors.dart';
import '../../../design_system/foundations/app_spacing.dart';
import '../../../design_system/foundations/app_typography.dart';
import '../../auth/data/auth_repository.dart';
import '../data/feed_repository.dart';
import '../domain/feed_item.dart';
import '../domain/feed_section.dart';
import 'widgets/feed_section_widget.dart';

/// Main feed/home screen with horizontal sections.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _searchController = TextEditingController();

  // Section data
  Map<FeedSectionType, List<FeedItem>> _sectionItems = {};
  bool _isLoading = true;

  // User location (for distance calculation)
  double? _userLat;
  double? _userLong;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) return;

    // Get user location
    _userLat = user.location?['lat'] as double?;
    _userLong = user.location?['long'] as double?;

    print('DEBUG: User location -> lat: $_userLat, long: $_userLong');
    if (_userLat == null || _userLong == null) {
      print(
        'DEBUG: "Perto de mim" não aparecerá - Usuário sem localização definida.',
      );
    }

    final feedRepo = ref.read(feedRepositoryProvider);
    final items = <FeedSectionType, List<FeedItem>>{};

    try {
      // Load each section
      if (_userLat != null && _userLong != null) {
        items[FeedSectionType.nearby] = await feedRepo.getNearbyUsers(
          lat: _userLat!,
          long: _userLong!,
          radiusKm: 20,
          currentUserId: user.uid,
          limit: 10,
        );
      }

      items[FeedSectionType.artists] = await feedRepo.getArtists(
        currentUserId: user.uid,
        userLat: _userLat,
        userLong: _userLong,
        limit: 10,
      );

      items[FeedSectionType.bands] = await feedRepo.getUsersByType(
        type: 'banda',
        currentUserId: user.uid,
        userLat: _userLat,
        userLong: _userLong,
        limit: 10,
      );

      items[FeedSectionType.technicians] = await feedRepo.getTechnicians(
        currentUserId: user.uid,
        userLat: _userLat,
        userLong: _userLong,
        limit: 10,
      );

      items[FeedSectionType.studios] = await feedRepo.getUsersByType(
        type: 'estudio',
        currentUserId: user.uid,
        userLat: _userLat,
        userLong: _userLong,
        limit: 10,
      );

      if (mounted) {
        setState(() {
          _sectionItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onItemTap(FeedItem item) {
    context.push('/profile/${item.uid}');
  }

  void _onSeeAllTap(FeedSectionType type) {
    context.push('/feed/list', extra: {'type': type});
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AppRefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // Header
              SliverToBoxAdapter(child: _buildHeader(userAsync.value)),
              // Sections
              SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: AppSpacing.s16),
                  ..._buildSections(),
                  const SizedBox(height: AppSpacing.s32),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic user) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        children: [
          // Top row: Avatar + Greeting + Notifications
          Row(
            children: [
              // Avatar
              GestureDetector(
                onTap: () => context.go('/profile'),
                child: ClipOval(
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: user?.foto != null && user.foto.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: user.foto,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: AppColors.surface,
                            child: const Icon(
                              Icons.person,
                              color: AppColors.textSecondary,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              // Greeting
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, ${user?.nome?.split(' ').first ?? 'Usuário'}',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Notifications
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () {
                      // TODO: Navigate to notifications
                    },
                  ),
                  // Badge (placeholder)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          // Search bar
          GestureDetector(
            onTap: () => context.push('/search'),
            child: AbsorbPointer(
              child: AppTextField(
                controller: _searchController,
                label: '',
                hint: 'Buscar músicos, bandas...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSections() {
    final sections = <Widget>[];

    // Check if we have any data at all
    bool hasAnyData = false;
    for (final section in FeedSection.homeSections) {
      if ((_sectionItems[section.type]?.isNotEmpty ?? false)) {
        hasAnyData = true;
        break;
      }
    }

    if (!hasAnyData && !_isLoading) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Column(
              children: [
                const Text(
                  'Nenhum item encontrado no feed.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _runDiagnostics,
                  icon: const Icon(Icons.bug_report, size: 16),
                  label: const Text('Diagnosticar Problema'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    for (final section in FeedSection.homeSections) {
      final items = _sectionItems[section.type] ?? [];

      // Skip "Nearby" section if no location
      if (section.type == FeedSectionType.nearby &&
          (_userLat == null || _userLong == null)) {
        continue;
      }

      // Skip empty sections (except if we want to show empty state per section, but here hiding is cleaner)
      if (items.isEmpty) continue;

      sections.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s24),
          child: FeedSectionWidget(
            title: section.title,
            items: items,
            isLoading: _isLoading,
            onSeeAllTap: () => _onSeeAllTap(section.type),
            onItemTap: _onItemTap,
          ),
        ),
      );
    }

    return sections;
  }

  void _runDiagnostics() async {
    setState(() => _isLoading = true);
    try {
      final report = await ref
          .read(feedRepositoryProvider)
          .debugDiagnose(
            currentUserId:
                ref.read(currentUserProfileProvider).value?.uid ?? '',
          );

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Diagnóstico do Feed'),
          content: SingleChildScrollView(
            child: Text(
              report,
              style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
