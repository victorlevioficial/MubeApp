import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common_widgets/app_refresh_indicator.dart';
import '../../../common_widgets/app_text_field.dart';
import '../../../design_system/foundations/app_colors.dart';
import '../../../design_system/foundations/app_spacing.dart';
import '../../../design_system/foundations/app_typography.dart';
import '../../auth/data/auth_repository.dart';
import '../data/feed_items_provider.dart';
import '../data/feed_repository.dart';
import '../domain/feed_item.dart';
import '../domain/feed_section.dart';
import 'widgets/feed_card_vertical.dart';
import 'widgets/feed_section_widget.dart';
import 'widgets/feed_skeleton.dart';
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

  // Vertical Feed Data - local sorted list approach
  List<FeedItem> _allSortedUsers = []; // All users sorted by distance
  final List<FeedItem> _mainItems = []; // Currently displayed items
  bool _isLoadingMain = false;
  bool _hasMoreMain = true;
  int _currentPage = 0;
  static const int _pageSize = 10;
  String _currentFilter = 'Todos';

  // Unified initial loading state
  bool _isInitialLoading = true;

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
    setState(() => _isInitialLoading = true);

    // Load data from Firestore in parallel
    await Future.wait([_loadSections(), _loadMainFeed(reset: true)]);

    // Precache avatar images with a 5-second timeout
    await _precacheAvatarImages();

    if (mounted) setState(() => _isInitialLoading = false);
  }

  /// Precaches avatar images for smooth display.
  Future<void> _precacheAvatarImages() async {
    final imageUrls = <String>{};

    // 1. Add current user's header photo
    final currentUser = ref.read(currentUserProfileProvider).value;
    if (currentUser?.foto != null && currentUser!.foto!.isNotEmpty) {
      imageUrls.add(currentUser.foto!);
    }

    // 2. Collect URLs from horizontal sections
    for (final items in _sectionItems.values) {
      for (final item in items) {
        if (item.foto != null && item.foto!.isNotEmpty) {
          imageUrls.add(item.foto!);
        }
      }
    }

    // 3. Collect URLs from vertical feed (first page)
    for (final item in _mainItems) {
      if (item.foto != null && item.foto!.isNotEmpty) {
        imageUrls.add(item.foto!);
      }
    }

    await _precacheUrls(imageUrls, timeout: const Duration(seconds: 5));
  }

  /// Precaches images for newly loaded pagination items.
  Future<void> _precacheNewItems(List<FeedItem> newItems) async {
    final imageUrls = <String>{};
    for (final item in newItems) {
      if (item.foto != null && item.foto!.isNotEmpty) {
        imageUrls.add(item.foto!);
      }
    }
    // Shorter timeout for pagination to not block scroll
    await _precacheUrls(imageUrls, timeout: const Duration(seconds: 3));
  }

  /// Helper to precache a set of URLs with a timeout.
  Future<void> _precacheUrls(
    Set<String> urls, {
    required Duration timeout,
  }) async {
    if (urls.isEmpty || !mounted) return;

    try {
      await Future.wait(
        urls.map(
          (url) => precacheImage(
            CachedNetworkImageProvider(url),
            context,
          ).catchError((_) {}),
        ),
      ).timeout(timeout, onTimeout: () => []);
    } catch (_) {
      // Ignore errors
    }
  }

  Future<void> _loadSections() async {
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
          radiusKm: 50,
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

      // Register all items in the centralized provider
      final allItems = items.values.expand((list) => list).toList();
      ref.read(feedItemsProvider.notifier).loadItems(allItems);

      if (mounted) {
        setState(() {
          _sectionItems = items;
        });
      }
    } catch (_) {
      // Error handling done by _isInitialLoading
    }
  }

  Future<void> _loadMainFeed({bool reset = false}) async {
    if (_isLoadingMain) return;
    if (!reset && !_hasMoreMain) return;

    setState(() {
      _isLoadingMain = true;
      if (reset) {
        _currentPage = 0;
        _hasMoreMain = true;
      }
    });

    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) return;

    try {
      if (reset) {
        // Load ALL users sorted by distance
        String? filterType;
        if (_currentFilter == 'Músicos') filterType = 'profissional';
        if (_currentFilter == 'Bandas') filterType = 'banda';
        if (_currentFilter == 'Estúdios') filterType = 'estudio';
        // 'Todos' and 'Perto de mim' both show all types

        if (_userLat != null && _userLong != null) {
          _allSortedUsers = await ref
              .read(feedRepositoryProvider)
              .getAllUsersSortedByDistance(
                currentUserId: user.uid,
                userLat: _userLat!,
                userLong: _userLong!,
                filterType: filterType,
              );
        } else {
          // Fallback: no location, use old paginated method without distance
          _allSortedUsers = [];
        }
      }

      // Get next page from local cache
      final startIndex = _currentPage * _pageSize;
      final endIndex = (startIndex + _pageSize).clamp(
        0,
        _allSortedUsers.length,
      );
      final newItems = _allSortedUsers.sublist(startIndex, endIndex);

      if (mounted) {
        // Precache new items' images before showing
        await _precacheNewItems(newItems);

        // Register items in centralized provider for reactive updates
        ref.read(feedItemsProvider.notifier).loadItems(newItems);

        setState(() {
          if (reset) {
            _mainItems
              ..clear()
              ..addAll(newItems);
          } else {
            _mainItems.addAll(newItems);
          }
          _currentPage++;
          _hasMoreMain = endIndex < _allSortedUsers.length;
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
              // Show shimmer skeleton during initial load
              if (_isInitialLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: FeedLoadingSkeleton(),
                )
              else ...[
                // Header
                SliverToBoxAdapter(child: _buildHeader(userAsync.value)),

                // Horizontal Sections
                ..._buildHorizontalSectionsSlivers(),

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
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : const SizedBox(height: 80); // Bottom padding
                      }
                      final item = _mainItems[index];
                      return FeedCardVertical(
                        item: item,
                        onTap: () => _onItemTap(item),
                      );
                    }, childCount: _mainItems.length + 1),
                  ),
              ],
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
