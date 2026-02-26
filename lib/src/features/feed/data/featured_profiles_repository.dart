import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../utils/app_logger.dart';
import '../domain/feed_item.dart';

part 'featured_profiles_repository.g.dart';

/// Repository para ler perfis em destaque configurados pelo admin.
///
/// Lê o documento `config/featuredProfiles` no Firestore, que contém
/// uma lista de UIDs definidos manualmente pelo painel admin.
@Riverpod(keepAlive: true)
FeaturedProfilesRepository featuredProfilesRepository(Ref ref) {
  return FeaturedProfilesRepository(FirebaseFirestore.instance);
}

class FeaturedProfilesRepository {
  final FirebaseFirestore _firestore;

  FeaturedProfilesRepository(this._firestore);

  /// Retorna os UIDs dos perfis em destaque definidos pelo admin.
  ///
  /// Retorna lista vazia se não houver configuração ou se houver erro.
  Future<List<String>> getFeaturedUids() async {
    try {
      final doc = await _firestore
          .collection('config')
          .doc('featuredProfiles')
          .get();

      AppLogger.debug('Featured doc exists: ${doc.exists}');
      if (!doc.exists) return [];

      final data = doc.data();
      if (data == null) return [];

      final uids = data['uids'];
      AppLogger.debug('Featured raw uids: $uids (type: ${uids.runtimeType})');
      if (uids is! List) return [];

      final result = uids
          .cast<String>()
          .where((uid) => uid.isNotEmpty)
          .toList();
      AppLogger.debug('Featured UIDs filtrados: $result');
      return result;
    } catch (e, stack) {
      AppLogger.error('Erro ao buscar featured profiles', e, stack);
      return [];
    }
  }

  /// Busca os [FeedItem]s correspondentes aos UIDs em destaque.
  ///
  /// Mantém a ordem dos UIDs conforme configurado no admin.
  /// Ignora UIDs que não existem ou cujo perfil está incompleto.
  Future<List<FeedItem>> getFeaturedProfiles() async {
    final uids = await getFeaturedUids();
    AppLogger.debug('getFeaturedProfiles: uids=$uids');
    if (uids.isEmpty) return [];

    final profiles = <FeedItem>[];

    for (final uid in uids) {
      try {
        final doc = await _firestore.collection('users').doc(uid).get();
        AppLogger.debug('Featured user $uid exists: ${doc.exists}');
        if (!doc.exists) continue;

        final data = doc.data();
        if (data == null) continue;

        final item = FeedItem.fromFirestore(data, doc.id);
        AppLogger.debug(
          'Featured FeedItem criado: ${item.nome} (${item.tipoPerfil})',
        );
        profiles.add(item);
      } catch (e, stack) {
        AppLogger.error('Featured profile $uid erro ao parsear', e, stack);
      }
    }

    AppLogger.debug('getFeaturedProfiles retornando ${profiles.length} perfis');
    return profiles;
  }
}
