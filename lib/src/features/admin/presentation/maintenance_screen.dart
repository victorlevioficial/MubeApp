import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/components/buttons/app_button.dart';
import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../../utils/geohash_helper.dart';
// import '../../../utils/seed_database.dart'; // Deleted
// import '../../feed/data/feed_repository.dart';

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
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('users')
          .where('cadastro_status', isEqualTo: 'concluido')
          .get();

      int updated = 0;
      int skipped = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['location'] is Map) {
          final location = Map<String, dynamic>.from(data['location'] as Map);
          if (location.containsKey('long')) {
            final val = location.remove('long');
            location['lng'] = val;
            await firestore.collection('users').doc(doc.id).update({
              'location': location,
            });
            updated++;
          } else {
            skipped++;
          }
        } else {
          skipped++;
        }
      }

      setState(() {
        _report =
            '✅ Migração concluída!\n'
            'Atualizados: $updated\n'
            'Pulados: $skipped';
      });
    } catch (e) {
      setState(() {
        _report = '❌ Erro na migração: $e';
      });
    } finally {
      setState(() {
        _isMigrating = false;
      });
    }
  }

  Future<void> _clearMocks() async {
    // DatabaseSeeder removed
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Funcionalidade removida (SeedDatabase apagado)'),
        ),
      );
    }
  }

  Future<void> _seedData() async {
    // DatabaseSeeder removed
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Funcionalidade removida (SeedDatabase apagado)'),
        ),
      );
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
      appBar: const AppAppBar(title: 'Manutenção', showBackButton: true),
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
                    AppButton.primary(
                      onPressed: _isMigrating ? null : _runMigration,
                      isLoading: _isMigrating,
                      text: 'TENTAR MIGRAÇÃO (MODO AVANÇADO)',
                      isFullWidth: true,
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    const Divider(),
                    const SizedBox(height: AppSpacing.s12),
                    Text(
                      'Resumo de Dados (Recomendado)',
                      style: AppTypography.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      'Se a migração acima falhar por permissão, use estes botões:',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton.outline(
                            onPressed: _isMigrating ? null : _clearMocks,
                            text: 'LIMPAR MOCKS',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s12),
                        Expanded(
                          child: AppButton.primary(
                            onPressed: _isMigrating ? null : _seedData,
                            text: 'GERAR NOVOS',
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
              Text(
                'Relatório:',
                style: AppTypography.titleSmall,
              ),
              const SizedBox(height: AppSpacing.s8),
              Container(
                padding: const EdgeInsets.all(AppSpacing.s12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: AppRadius.all8,
                  border: Border.all(
                    color: AppColors.textPrimary.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  _report,
                  style: AppTypography.bodySmall.copyWith(
                    fontFamily: 'monospace',
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.s16),
            AppButton.outline(
              onPressed: _isMigrating ? null : _addGeohash,
              text: 'ADICIONAR GEOHASH (OTIMIZAÇÃO)',
              isFullWidth: true,
            ),
            Text(
              'Adiciona geohash aos usuários existentes para queries 10x mais rápidas',
              textAlign: TextAlign.center,
              style: AppTypography.chipLabel.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
