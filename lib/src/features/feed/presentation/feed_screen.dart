import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common_widgets/app_refresh_indicator.dart';
import '../../../common_widgets/app_text_field.dart';
import '../../../design_system/foundations/app_colors.dart';
import '../../../design_system/foundations/app_spacing.dart';
import '../../../design_system/foundations/app_typography.dart';
import '../../auth/data/auth_repository.dart';
import '../data/feed_repository.dart';
import '../domain/feed_item.dart';
import '../domain/feed_section.dart';
import 'widgets/feed_card_vertical.dart';
import 'widgets/feed_section_widget.dart';
import 'widgets/quick_filter_bar.dart';

/// Main feed/home screen with horizontal sections and vertical infinite list.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  // Horizontal Section data
  Map<FeedSectionType, List<FeedItem>> _sectionItems = {};
  bool _isLoadingSections = true;

  // Vertical Feed Data
  final List<FeedItem> _mainItems = [];
  bool _isLoadingMain = false;
  bool _hasMoreMain = true;
  DocumentSnapshot? _lastDocumentMain;
  String _currentFilter = 'Todos';

  // User location
  double? _userLat;
  double? _userLong;

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreMainFeed();
    }
  }

  Future<void> _loadAllData() async {
    // Load top sections and first page of main feed
    await Future.wait([_loadSections(), _loadMainFeed(reset: true)]);
  }

  Future<void> _loadSections() async {
    setState(() => _isLoadingSections = true);

    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) return;

    _userLat = user.location?['lat'] as double?;
    _userLong = user.location?['lng'] as double?;

    final feedRepo = ref.read(feedRepositoryProvider);
    final items = <FeedSectionType, List<FeedItem>>{};

    try {
      // Load standard horizontal sections
      if (_userLat != null && _userLong != null) {
        items[FeedSectionType.nearby] = await feedRepo.getNearbyUsers(
          lat: _userLat!,
          long: _userLong!,
          radiusKm: 50, // Increased radius for better fill
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
      // Removed technicians/studios from horizontal to clean up,
      // they can be found in vertical feed with filters.
      // Or keep them if essential. Keeping bands and artists as main discovery.

      if (mounted) {
        setState(() {
          _sectionItems = items;
          _isLoadingSections = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSections = false);
    }
  }

  Future<void> _loadMainFeed({bool reset = false}) async {
    if (_isLoadingMain) return;
    if (!reset && !_hasMoreMain) return;

    setState(() {
      _isLoadingMain = true;
      if (reset) {
        _mainItems.clear();
        _lastDocumentMain = null;
        _hasMoreMain = true;
      }
    });

    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) return;

    try {
      // Map display filter to internal API filter
      String? filterType;
      if (_currentFilter == 'Músicos') filterType = 'profissional';
      if (_currentFilter == 'Bandas') filterType = 'banda';
      if (_currentFilter == 'Estúdios') filterType = 'estudio';
      if (_currentFilter == 'Perto de mim') filterType = 'Perto de mim';

      final result = await ref
          .read(feedRepositoryProvider)
          .getMainFeedPaginated(
            currentUserId: user.uid,
            limit: 10,
            startAfter: _lastDocumentMain,
            filterType: filterType,
            userLat: _userLat,
            userLong: _userLong,
          );

      if (mounted) {
        setState(() {
          _mainItems.addAll(result.items);
          _lastDocumentMain = result.lastDocument;
          _hasMoreMain = result.hasMore;
          _isLoadingMain = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMain = false);
    }
  }

  void _loadMoreMainFeed() {
    _loadMainFeed(reset: false);
  }

  void _onFilterChanged(String filter) {
    if (_currentFilter == filter) return;
    setState(() {
      _currentFilter = filter;
    });
    _loadMainFeed(reset: true);
  }

  void _onItemTap(FeedItem item) {
    context.push('/user/${item.uid}');
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
          onRefresh: _loadAllData,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // Header
              SliverToBoxAdapter(child: _buildHeader(userAsync.value)),

              // Horizontal Sections
              if (!_isLoadingSections) ..._buildHorizontalSectionsSlivers(),

              // Quick Filters (Sticky)
              SliverPersistentHeader(
                pinned: true,
                delegate: _QuickFilterHeaderDelegate(
                  child: QuickFilterBar(
                    selectedFilter: _currentFilter,
                    onFilterSelected: _onFilterChanged,
                  ),
                ),
              ),

              // Vertical Main Feed
              if (_mainItems.isEmpty && _isLoadingMain)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (_mainItems.isEmpty && !_isLoadingMain)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'Nenhum resultado encontrado.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index == _mainItems.length) {
                      // Bottom loader
                      return _hasMoreMain
                          ? const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : const SizedBox(height: 80); // Bottom padding
                    }
                    final item = _mainItems[index];
                    return FeedCardVertical(
                      item: item,
                      onTap: () => _onItemTap(item),
                      onFavorite: () async {
                        // Optimistic toggle could be implemented here
                        await ref
                            .read(feedRepositoryProvider)
                            .toggleFavorite(
                              userId: userAsync.value!.uid,
                              targetId: item.uid,
                            );
                      },
                    );
                  }, childCount: _mainItems.length + 1),
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
          Row(
            children: [
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
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.textPrimary,
                ),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          // Search bar is just visual/entry point
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

  List<Widget> _buildHorizontalSectionsSlivers() {
    final slivers = <Widget>[];

    void addSection(FeedSectionType type, String title) {
      final items = _sectionItems[type] ?? [];
      if (items.isNotEmpty) {
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s24),
              child: FeedSectionWidget(
                title: title,
                items: items,
                isLoading: false,
                onSeeAllTap: () => _onSeeAllTap(type),
                onItemTap: _onItemTap,
              ),
            ),
          ),
        );
      }
    }

    addSection(FeedSectionType.nearby, 'Perto de você');
    addSection(FeedSectionType.artists, 'Artistas em destaque');
    addSection(FeedSectionType.bands, 'Bandas');

    return slivers;
  }
}

class _QuickFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _QuickFilterHeaderDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  double get maxExtent => 60.0;

  @override
  double get minExtent => 60.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
