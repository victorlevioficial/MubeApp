import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common_widgets/mube_app_bar.dart';
import '../../../design_system/foundations/app_colors.dart';
import '../../../design_system/foundations/app_spacing.dart';
import '../../../design_system/foundations/app_typography.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_type.dart';

/// Navigation hub for Edit Profile - Instagram Settings Pattern
/// Each option leads to a focused editing screen
class EditProfileMenuScreen extends ConsumerWidget {
  const EditProfileMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: const MubeAppBar(title: 'Editar Perfil'),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erro: $err')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Usuário não encontrado'));
          }
          return _buildMenuList(context, user);
        },
      ),
    );
  }

  Widget _buildMenuList(BuildContext context, AppUser user) {
    final menuItems = _getMenuItemsForUser(user);

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.s16),
      itemCount: menuItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s8),
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return _MenuTile(
          icon: item.icon,
          title: item.title,
          subtitle: item.subtitle,
          onTap: () => context.push(item.route),
        );
      },
    );
  }

  List<_MenuItem> _getMenuItemsForUser(AppUser user) {
    final items = <_MenuItem>[
      // Common for all
      _MenuItem(
        icon: Icons.person_outline,
        title: 'Dados Básicos',
        subtitle: 'Nome, bio, foto e contato',
        route: '/settings/profile/basic',
      ),
    ];

    final tipoPerfil = user.tipoPerfil;

    if (tipoPerfil == AppUserType.professional) {
      final prof = user.dadosProfissional ?? {};
      final categorias =
          (prof['categorias'] as List<dynamic>?)?.cast<String>() ?? [];

      items.addAll([
        _MenuItem(
          icon: Icons.category_outlined,
          title: 'Categorias',
          subtitle: _getCategoriesSummary(categorias),
          route: '/settings/profile/categories',
        ),
        if (categorias.contains('instrumentalist'))
          _MenuItem(
            icon: Icons.piano_outlined,
            title: 'Instrumentos',
            subtitle: _getListSummary(
              (prof['instrumentos'] as List<dynamic>?)?.cast<String>() ?? [],
            ),
            route: '/settings/profile/instruments',
          ),
        if (categorias.contains('crew'))
          _MenuItem(
            icon: Icons.build_outlined,
            title: 'Funções Técnicas',
            subtitle: _getListSummary(
              (prof['funcoes'] as List<dynamic>?)?.cast<String>() ?? [],
            ),
            route: '/settings/profile/roles',
          ),
        _MenuItem(
          icon: Icons.music_note_outlined,
          title: 'Gêneros Musicais',
          subtitle: _getListSummary(
            (prof['generos_musicais'] as List<dynamic>?)?.cast<String>() ?? [],
          ),
          route: '/settings/profile/genres',
        ),
      ]);
    } else if (tipoPerfil == AppUserType.band) {
      final band = user.dadosBanda ?? {};
      items.add(
        _MenuItem(
          icon: Icons.music_note_outlined,
          title: 'Gêneros Musicais',
          subtitle: _getListSummary(
            (band['generos_musicais'] as List<dynamic>?)?.cast<String>() ?? [],
          ),
          route: '/settings/profile/genres',
        ),
      );
    } else if (tipoPerfil == AppUserType.studio) {
      final studio = user.dadosEstudio ?? {};
      items.add(
        _MenuItem(
          icon: Icons.room_service_outlined,
          title: 'Serviços',
          subtitle: _getListSummary(
            (studio['servicos_oferecidos'] as List<dynamic>?)?.cast<String>() ??
                [],
          ),
          route: '/settings/profile/services',
        ),
      );
    }

    // Media for most profile types
    if (tipoPerfil != AppUserType.contractor) {
      items.add(
        _MenuItem(
          icon: Icons.photo_library_outlined,
          title: 'Mídia & Portfólio',
          subtitle: 'Fotos e vídeos',
          route: '/settings/profile/media',
        ),
      );
    }

    return items;
  }

  String _getCategoriesSummary(List<String> cats) {
    if (cats.isEmpty) return 'Nenhuma selecionada';
    return cats.take(2).join(', ') + (cats.length > 2 ? '...' : '');
  }

  String _getListSummary(List<String> items) {
    if (items.isEmpty) return 'Nenhum selecionado';
    return items.take(2).join(', ') + (items.length > 2 ? '...' : '');
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s8,
        ),
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.s8),
          decoration: BoxDecoration(
            color: AppColors.surfaceHighlight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.semanticAction, size: 24),
        ),
        title: Text(title, style: AppTypography.titleMedium),
        subtitle: Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textTertiary,
        ),
        onTap: onTap,
      ),
    );
  }
}
