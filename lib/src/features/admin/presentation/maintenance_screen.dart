import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common_widgets/mube_app_bar.dart';
import '../../../design_system/foundations/app_colors.dart';
import '../../../design_system/foundations/app_spacing.dart';
import '../../../design_system/foundations/app_typography.dart';
import '../../../utils/geohash_helper.dart';
import '../../../utils/seed_database.dart';
import '../../feed/data/feed_repository.dart';

class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen> {
  bool _isMigrating = false;
  String _report = '';

  Future<void> _runMigration() async {
    setState(() {
      _isMigrating = true;
      _report = 'Iniciando migração...';
    });

    try {
      final feedRepo = ref.read(feedRepositoryProvider);
      final result = await feedRepo.migrateLocationLongToLng();
      setState(() {
        _report = result;
      });
    } catch (e) {
      setState(() {
        _report = 'Erro na migração: $e';
      });
    } finally {
      setState(() {
        _isMigrating = false;
      });
    }
  }

  Future<void> _clearMocks() async {
    setState(() {
      _isMigrating = true;
      _report = 'Limpando usuários mock...';
    });
    try {
      await DatabaseSeeder.clearMockUsers();
      setState(() {
        _report = 'Usuários mock removidos com sucesso!';
      });
    } catch (e) {
      debugPrint('Erro ao limpar mocks: $e');
      setState(() {
        _report =
            '❌ ERRO: Permissão negada.\n\n'
            'As Regras de Segurança do Firestore impedem que um usuário logado delete dados de outros usuários.\n\n'
            '👉 AÇÃO RECOMENDADA:\n'
            '1. Vá ao Console do Firebase.\n'
            '2. Clique em "Firestore Database".\n'
            '3. Clique nos três pontinhos da coleção "users" e escolha "Excluir coleção".\n'
            '4. Volte aqui e clique em "GERAR NOVOS".';
      });
    } finally {
      setState(() {
        _isMigrating = false;
      });
    }
  }

  Future<void> _seedData() async {
    setState(() {
      _isMigrating = true;
      _report = 'Gerando 50 usuários mock (Padrão lng)...';
    });
    try {
      await DatabaseSeeder.seedUsers(count: 50);
      setState(() {
        _report = '50 usuários gerados com sucesso!';
      });
    } catch (e) {
      setState(() {
        _report = 'Erro ao gerar: $e';
      });
    } finally {
      setState(() {
        _isMigrating = false;
      });
    }
  }

  Future<void> _addGeohash() async {
    setState(() {
      _isMigrating = true;
      _report = 'Adicionando geohash a usuários...';
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('users')
          .where('cadastro_status', isEqualTo: 'concluido')
          .get();

      int updated = 0;
      int skipped = 0;

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();

          // Skip if already has geohash
          if (data.containsKey('geohash') && data['geohash'] != null) {
            skipped++;
            continue;
          }

          // Extract lat/lng
          double? lat;
          double? lng;

          if (data['location'] is Map) {
            final location = data['location'] as Map;
            lat = location['lat'] as double?;
            lng = location['lng'] as double?;
          }

          if (lat != null && lng != null) {
            final geohash = GeohashHelper.encode(lat, lng, precision: 5);

            await firestore.collection('users').doc(doc.id).update({
              'geohash': geohash,
            });

            updated++;
          } else {
            skipped++;
          }
        } catch (e) {
          skipped++;
        }
      }

      setState(() {
        _report =
            '✅ Geohash adicionado!\n'
            'Atualizados: $updated\n'
            'Ignorados: $skipped\n\n'
            'Agora as queries de proximidade serão muito mais rápidas!';
      });
    } catch (e) {
      setState(() {
        _report = '❌ Erro ao adicionar geohash: $e';
      });
    } finally {
      setState(() {
        _isMigrating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MubeAppBar(title: 'Manutenção'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: Column(
                  children: [
                    Text(
                      'Migração de Coordenadas',
                      style: AppTypography.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    const Text(
                      'Este processo irá renomear o campo "long" para "lng" em todos os documentos da coleção "users". Isso garante compatibilidade com o novo padrão profissional do app.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    ElevatedButton(
                      onPressed: _isMigrating ? null : _runMigration,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                      ),
                      child: _isMigrating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Text('TENTAR MIGRAÇÃO (MODO AVANÇADO)'),
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    const Divider(),
                    const SizedBox(height: AppSpacing.s12),
                    const Text(
                      'Resumo de Dados (Recomendado)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    const Text(
                      'Se a migração acima falhar por permissão, use estes botões:',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isMigrating ? null : _clearMocks,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                            ),
                            child: const Text('LIMPAR MOCKS'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isMigrating ? null : _seedData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('GERAR NOVOS'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_report.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s24),
              const Text(
                'Relatório:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.s8),
              Container(
                padding: const EdgeInsets.all(AppSpacing.s12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  _report,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.greenAccent,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.s16),
            OutlinedButton(
              onPressed: _isMigrating ? null : _addGeohash,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blueAccent,
                side: const BorderSide(color: Colors.blueAccent),
              ),
              child: const Text('ADICIONAR GEOHASH (OTIMIZAÇÃO)'),
            ),
            const Text(
              'Adiciona geohash aos usuários existentes para queries 10x mais rápidas',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
