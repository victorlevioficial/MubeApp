import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../design_system/design_system.dart';

/// Design System de Categorias - Cores fixas para cada tipo
class CategoryColors {
  // Cores fixas por tipo
  static const Color profissional = Color(0xFF3B82F6); // Azul
  static const Color banda = Color(0xFFFF7F7F); // Coral
  static const Color estudio = Color(0xFF22C55E); // Verde
  static const Color contratante = Color(0xFFFACC15); // Amarelo
  static const Color oportunidade = Color(0xFFF97316); // Laranja
  
  // Método para obter cor baseada no tipo
  static Color getColor(String type) {
    switch (type.toLowerCase()) {
      case 'profissional':
        return profissional;
      case 'banda':
        return banda;
      case 'estúdio':
      case 'estudio':
        return estudio;
      case 'contratante':
        return contratante;
      case 'oportunidade':
        return oportunidade;
      default:
        return AppColors.brandPrimary;
    }
  }
  
  // Ícones consistentes por tipo
  static IconData getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'profissional':
        return Icons.person;
      case 'banda':
        return Icons.group;
      case 'estúdio':
      case 'estudio':
        return Icons.headphones;
      case 'contratante':
        return Icons.work;
      case 'oportunidade':
        return Icons.local_fire_department;
      default:
        return Icons.music_note;
    }
  }
  
  // Nome formatado por tipo
  static String getLabel(String type) {
    switch (type.toLowerCase()) {
      case 'profissional':
        return 'Profissional';
      case 'banda':
        return 'Banda';
      case 'estúdio':
      case 'estudio':
        return 'Estúdio';
      case 'contratante':
        return 'Contratante';
      case 'oportunidade':
        return 'Oportunidade';
      default:
        return type;
    }
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  String _selectedFilter = 'todos';
  bool _isLoading = true;
  bool _isScrolled = false;
  int _notificationCount = 3;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<String> _quickFilters = [
    'todos',
    'profissionais',
    'bandas',
    'estudios',
    'oportunidades',
    'proximos',
  ];

  final List<Map<String, dynamic>> _sections = [
    {
      'title': '🔥 Em Alta',
      'subtitle': 'Os mais populares da semana',
      'type': 'mixed',
    },
    {
      'title': '🎸 Profissionais',
      'subtitle': 'Músicos disponíveis agora',
      'type': 'profissionais',
    },
    {
      'title': '🎤 Bandas',
      'subtitle': 'Grupos procurando membros',
      'type': 'bandas',
    },
    {
      'title': '🎧 Estúdios',
      'subtitle': 'Com horários disponíveis',
      'type': 'estudios',
    },
  ];

  // Mock data com tipo e imagens reais do Unsplash - SEM cores dinâmicas
  final List<Map<String, dynamic>> _profiles = [
    {
      'name': 'João Silva',
      'role': 'Guitarrista',
      'type': 'Profissional',
      'distance': 2.5,
      'generos': ['Rock', 'Blues', 'Pop'],
      'habilidades': ['Violão', 'Guitarra'],
      'image': 'https://images.unsplash.com/photo-1510915361894-db8b60106cb1?w=400&h=400&fit=crop',
    },
    {
      'name': 'Maria Santos',
      'role': 'Vocalista',
      'type': 'Profissional',
      'distance': 5.2,
      'generos': ['Jazz', 'Soul', 'R&B'],
      'habilidades': ['Voz', 'Piano'],
      'image': 'https://images.unsplash.com/photo-1594744803329-e58b31de8bf5?w=400&h=400&fit=crop',
    },
    {
      'name': 'Banda Rock City',
      'role': 'Banda Completa',
      'type': 'Banda',
      'distance': 8.0,
      'generos': ['Rock', 'Hard Rock'],
      'habilidades': ['Banda 4 membros'],
      'image': 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&h=400&fit=crop',
    },
    {
      'name': 'Pedro Oliveira',
      'role': 'Baterista',
      'type': 'Profissional',
      'distance': 1.8,
      'generos': ['Rock', 'Pop', 'Funk'],
      'habilidades': ['Bateria', 'Percussão'],
      'image': 'https://images.unsplash.com/photo-1519892300165-cb5542fb47c7?w=400&h=400&fit=crop',
    },
    {
      'name': 'Studio Central SP',
      'role': 'Estúdio de Gravação',
      'type': 'Estúdio',
      'distance': 12.3,
      'generos': ['Todos'],
      'habilidades': ['Gravação', 'Mixagem', 'Master'],
      'image': 'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=400&h=400&fit=crop',
    },
    {
      'name': 'Ana Costa',
      'role': 'Tecladista',
      'type': 'Profissional',
      'distance': 3.7,
      'generos': ['Pop', 'Eletrônica'],
      'habilidades': ['Teclado', 'Sintetizador'],
      'image': 'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=400&h=400&fit=crop',
    },
    {
      'name': 'Jazz Trio',
      'role': 'Banda Instrumental',
      'type': 'Banda',
      'distance': 15.0,
      'generos': ['Jazz', 'Bossa Nova'],
      'habilidades': ['Trio instrumental'],
      'image': 'https://images.unsplash.com/photo-1415201364774-f6f0bb35f28f?w=400&h=400&fit=crop',
    },
    {
      'name': 'Beat Maker Studio',
      'role': 'Produção Musical',
      'type': 'Estúdio',
      'distance': 6.4,
      'generos': ['Hip Hop', 'Trap', 'Pop'],
      'habilidades': ['Produção', 'Beatmaking'],
      'image': 'https://images.unsplash.com/photo-1598653222000-6b7b7a55261a?w=400&h=400&fit=crop',
    },
    {
      'name': 'Lucas Mendes',
      'role': 'Baixista',
      'type': 'Profissional',
      'distance': 4.2,
      'generos': ['Rock', 'Reggae', 'Funk'],
      'habilidades': ['Baixo', 'Contrabaixo'],
      'image': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop',
    },
    {
      'name': 'Orquestra Sinfônica',
      'role': 'Orquestra Completa',
      'type': 'Banda',
      'distance': 25.0,
      'generos': ['Clássica', 'Erudita'],
      'habilidades': ['Orquestra 40 membros'],
      'image': 'https://images.unsplash.com/photo-1465847899078-b413929f7120?w=400&h=400&fit=crop',
    },
    {
      'name': 'DJ Carlos Silva',
      'role': 'DJ Profissional',
      'type': 'Profissional',
      'distance': 9.1,
      'generos': ['Eletrônica', 'House', 'Techno'],
      'habilidades': ['DJ', 'Mixagem'],
      'image': 'https://images.unsplash.com/photo-1571266028243-3716f02d2d2e?w=400&h=400&fit=crop',
    },
    {
      'name': 'Home Studio Pro',
      'role': 'Estúdio Home',
      'type': 'Estúdio',
      'distance': 3.3,
      'generos': ['Indie', 'Pop', 'Acústico'],
      'habilidades': ['Gravação vocal', 'Podcast'],
      'image': 'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=400&h=400&fit=crop',
    },
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadData();
    
    _scrollController.addListener(() {
      if (_scrollController.offset > 100 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 100 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isLoading = false);
      _fadeController.forward();
    }
  }

  Future<void> _onRefresh() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.brandPrimary,
        backgroundColor: AppColors.surface,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildHeader(),
            _buildStickyFilters(),
            _isLoading
                ? _buildShimmerLoading()
                : _buildMainContent(),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isScrolled
                ? [AppColors.surface, AppColors.surface]
                : [
                    AppColors.brandPrimary.withAlpha(30),
                    AppColors.brandSecondary.withAlpha(20),
                    AppColors.background,
                  ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar
                Row(
                  children: [
                    // Logo Mube
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.brandGradientStart, AppColors.brandGradientEnd],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'MUBE',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    
                    // Busca
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.search,
                          color: AppColors.textSecondary,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    
                    // Notificações
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                      },
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: AppColors.textSecondary,
                              size: 24,
                            ),
                          ),
                          if (_notificationCount > 0)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.brandPrimary,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  _notificationCount.toString(),
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textPrimary,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Bem-vindo + Preview do perfil
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Foto do perfil
                    Hero(
                      tag: 'profile-avatar',
                      child: GestureDetector(
                        onTap: () {},
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: _isScrolled ? 44 : 56,
                          height: _isScrolled ? 44 : 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.brandGradientStart, AppColors.brandGradientEnd],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.brandPrimary.withAlpha(100),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.brandPrimary.withAlpha(40),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: CachedNetworkImage(
                              imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop',
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppColors.brandPrimary,
                                child: const Icon(Icons.person, color: AppColors.textPrimary),
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.person,
                                color: AppColors.textPrimary,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    
                    // Texto de boas-vindas
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Olá, Victor! 👋',
                            style: _isScrolled
                                ? AppTypography.titleMedium.copyWith(
                                    color: AppColors.textPrimary,
                                  )
                                : AppTypography.headlineSmall.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Pronto para tocar hoje?',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Mini card do perfil
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.brandPrimary, AppColors.brandSecondary],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandPrimary.withAlpha(60),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Avatar pequeno
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.textPrimary.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                            image: const DecorationImage(
                              image: NetworkImage('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        
                        // Info do perfil
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Seu Perfil',
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.textPrimary.withAlpha(200),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Profissional • Guitarrista',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '95% completo',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textPrimary.withAlpha(180),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Ícone de seta
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.textPrimary.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios,
                            color: AppColors.textPrimary,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStickyFilters() {
    return SliverPersistentHeader(
      delegate: _StickyFiltersDelegate(
        quickFilters: _quickFilters,
        selectedFilter: _selectedFilter,
        onFilterChanged: (filter) {
          HapticFeedback.selectionClick();
          setState(() => _selectedFilter = filter);
        },
      ),
      pinned: true,
    );
  }

  Widget _buildShimmerLoading() {
    return SliverFillRemaining(
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandPrimary),
          backgroundColor: AppColors.surfaceVariant,
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index < _sections.length) {
            return _buildHorizontalSection(
              _sections[index]['title'],
              _sections[index]['subtitle'],
              _sections[index]['type'],
            );
          } else if (index == _sections.length) {
            return _buildOportunidadesSection();
          } else {
            return _buildCompactFeed();
          }
        },
        childCount: _sections.length + 2,
      ),
    );
  }

  // Seção horizontal com cards quadrados e sombras sutis
  Widget _buildHorizontalSection(String title, String subtitle, String type) {
    final items = _getFilteredProfiles(type).take(6).toList();
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header da seção
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Ver todos',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.brandPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Lista horizontal
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildHorizontalCard(item, index);
              },
            ),
          ),
          
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  // Card horizontal quadrado com cantos arredondados e sombra sutil
  Widget _buildHorizontalCard(Map<String, dynamic> item, int index) {
    final categoryColor = CategoryColors.getColor(item['type'] as String);
    final categoryIcon = CategoryColors.getIcon(item['type'] as String);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: AppSpacing.md),
      width: 160,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem quadrada com sombra sutil
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: categoryColor.withAlpha(25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: item['image'] as String,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppColors.surfaceVariant,
                    child: Icon(
                      categoryIcon,
                      size: 48,
                      color: categoryColor,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.surfaceVariant,
                    child: Icon(
                      categoryIcon,
                      size: 48,
                      color: categoryColor,
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: AppSpacing.sm),
            
            // Título
            Text(
              item['name'] as String,
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 2),
            
            // Role
            Text(
              item['role'] as String,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Seção de oportunidades com cor fixa laranja
  Widget _buildOportunidadesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: CategoryColors.oportunidade.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: CategoryColors.oportunidade.withAlpha(50),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.local_fire_department,
                          color: CategoryColors.oportunidade,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Oportunidades',
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Vagas e shows disponíveis agora',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: CategoryColors.oportunidade.withAlpha(15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: CategoryColors.oportunidade.withAlpha(50),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: CategoryColors.oportunidade,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '12 novas',
                      style: AppTypography.labelMedium.copyWith(
                        color: CategoryColors.oportunidade,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Cards de oportunidades
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            itemCount: 5,
            itemBuilder: (context, index) {
              return _buildOportunidadeCard(index);
            },
          ),
        ),
        
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildOportunidadeCard(int index) {
    final oportunidades = [
      {
        'title': 'Guitarrista para Bar',
        'local': 'São Paulo, SP',
        'valor': 'R\$ 150/hora',
        'data': 'Hoje, 20h',
        'icon': Icons.local_bar,
      },
      {
        'title': 'Banda para Casamento',
        'local': 'Rio de Janeiro, RJ',
        'valor': 'R\$ 3.000',
        'data': 'Sábado',
        'icon': Icons.favorite,
      },
      {
        'title': 'DJ para Festa',
        'local': 'Belo Horizonte, MG',
        'valor': 'R\$ 800',
        'data': 'Sexta, 23h',
        'icon': Icons.music_note,
      },
      {
        'title': 'Vocalista para Evento',
        'local': 'Curitiba, PR',
        'valor': 'R\$ 500',
        'data': 'Domingo, 18h',
        'icon': Icons.mic,
      },
      {
        'title': 'Baterista para Banda',
        'local': 'Salvador, BA',
        'valor': 'R\$ 200/show',
        'data': 'Quarta, 21h',
        'icon': Icons.album,
      },
    ];

    final item = oportunidades[index % oportunidades.length];

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: AppSpacing.md),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: CategoryColors.oportunidade.withAlpha(40),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: CategoryColors.oportunidade.withAlpha(15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CategoryColors.oportunidade.withAlpha(15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: CategoryColors.oportunidade.withAlpha(50),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: CategoryColors.oportunidade,
                      size: 20,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: CategoryColors.oportunidade.withAlpha(15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: CategoryColors.oportunidade.withAlpha(40),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      item['data'] as String,
                      style: AppTypography.labelSmall.copyWith(
                        color: CategoryColors.oportunidade,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] as String,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: AppColors.textSecondary,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item['local'] as String,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.attach_money,
                        color: CategoryColors.oportunidade,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item['valor'] as String,
                        style: AppTypography.bodySmall.copyWith(
                          color: CategoryColors.oportunidade,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Feed compacto com design system consistente
  Widget _buildCompactFeed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Explorar Todos',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.filter_list,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Filtrar',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Lista compacta
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          itemCount: _profiles.length,
          itemBuilder: (context, index) {
            return _buildCompactCard(index);
          },
        ),
        
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  // Card compacto elegante com badge transparente e borda colorida
  Widget _buildCompactCard(int index) {
    final item = _profiles[index % _profiles.length];
    final categoryColor = CategoryColors.getColor(item['type'] as String);
    final categoryIcon = CategoryColors.getIcon(item['type'] as String);
    final generos = (item['generos'] as List<String>).take(2).join(', ');
    final habilidades = (item['habilidades'] as List<String>).join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar com imagem real
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: item['image'] as String,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 60,
                    height: 60,
                    color: AppColors.surfaceVariant,
                    child: Icon(
                      categoryIcon,
                      color: categoryColor,
                      size: 28,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 60,
                    height: 60,
                    color: AppColors.surfaceVariant,
                    child: Icon(
                      categoryIcon,
                      color: categoryColor,
                      size: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              
              // Info expandida
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Linha superior: Nome + Badge tipo
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['name'] as String,
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // Badge do tipo com fundo transparente e borda colorida
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: categoryColor.withAlpha(180),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                categoryIcon,
                                size: 12,
                                color: categoryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                CategoryColors.getLabel(item['type'] as String),
                                style: AppTypography.labelSmall.copyWith(
                                  color: categoryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 2),
                    
                    // Role
                    Text(
                      item['role'] as String,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: AppSpacing.sm),
                    
                    // Linha de metadados: distância + gêneros
                    Row(
                      children: [
                        // Distância
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brandPrimary.withAlpha(15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 12,
                                color: AppColors.brandPrimary,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${item['distance']} km',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.brandPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // Gêneros
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.music_note,
                                size: 12,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  generos,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Habilidades
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 12,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            habilidades,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Botão de favoritar
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.favorite_border,
                    color: AppColors.textTertiary,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandGradientStart, AppColors.brandGradientEnd],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPrimary.withAlpha(60),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showCreatePostBottomSheet();
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add, color: AppColors.textPrimary),
        label: Text(
          'Publicar',
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showCreatePostBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppBorderRadius.bottomSheet),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indicador de arrastar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(AppBorderRadius.pill),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Título
                  Text(
                    'Criar Publicação',
                    style: AppTypography.headlineSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Escolha o tipo de publicação',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Opções com cores fixas do design system
                  _buildPostOption(
                    icon: Icons.person,
                    title: 'Sou um Profissional',
                    subtitle: 'Divulgue seus serviços como músico',
                    color: CategoryColors.profissional,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildPostOption(
                    icon: Icons.group,
                    title: 'Sou uma Banda',
                    subtitle: 'Encontre membros ou divulgue sua banda',
                    color: CategoryColors.banda,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildPostOption(
                    icon: Icons.headphones,
                    title: 'Sou um Estúdio',
                    subtitle: 'Ofereça serviços de gravação e mixagem',
                    color: CategoryColors.estudio,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildPostOption(
                    icon: Icons.work,
                    title: 'Tenho uma Vaga',
                    subtitle: 'Anuncie oportunidades para músicos',
                    color: CategoryColors.oportunidade,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPostOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppBorderRadius.card),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withAlpha(60),
                    width: 1.5,
                  ),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredProfiles(String type) {
    switch (type) {
      case 'profissionais':
        return _profiles.where((p) => p['type'] == 'Profissional').toList();
      case 'bandas':
        return _profiles.where((p) => p['type'] == 'Banda').toList();
      case 'estudios':
        return _profiles.where((p) => p['type'] == 'Estúdio').toList();
      default:
        return _profiles;
    }
  }
}

// Delegate para filtros sticky
class _StickyFiltersDelegate extends SliverPersistentHeaderDelegate {
  final List<String> quickFilters;
  final String selectedFilter;
  final Function(String) onFilterChanged;

  _StickyFiltersDelegate({
    required this.quickFilters,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
        child: Row(
          children: quickFilters.map((filter) {
            final isSelected = selectedFilter == filter;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              child: GestureDetector(
                onTap: () => onFilterChanged(filter),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [AppColors.brandGradientStart, AppColors.brandGradientEnd],
                          )
                        : null,
                    color: isSelected ? null : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? null
                        : Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    filter.toUpperCase(),
                    style: AppTypography.labelMedium.copyWith(
                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 56;

  @override
  double get minExtent => 56;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}
