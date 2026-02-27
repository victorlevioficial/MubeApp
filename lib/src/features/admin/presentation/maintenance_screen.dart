import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/components/buttons/app_button.dart';
import '../../../design_system/components/inputs/app_text_field.dart';
import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../../utils/geohash_helper.dart';

class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen> {
  bool _isMigrating = false;
  bool _isBackfillRunning = false;
  String _backfillAction = '';

  String _report = '';
  String _videoBackfillReport = '';
  bool _videoBackfillHasMore = false;
  String? _videoBackfillCursor;

  final TextEditingController _backfillLimitController = TextEditingController(
    text: '20',
  );

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  @override
  void dispose() {
    _backfillLimitController.dispose();
    super.dispose();
  }

  int _parseBackfillLimit() {
    final raw = int.tryParse(_backfillLimitController.text.trim()) ?? 20;
    if (raw < 1) return 1;
    if (raw > 100) return 100;
    return raw;
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) {
      return value.map((key, dynamic item) => MapEntry('$key', item));
    }
    return <String, dynamic>{};
  }

  String _formatBackfillReport(Map<String, dynamic> data) {
    final lines = <String>[
      'Backfill de videos - resultado:',
      'dryRun: ${data['dryRun'] == true ? 'true' : 'false'}',
      'usersScanned: ${_asInt(data['usersScanned'])}',
      'usersWithVideos: ${_asInt(data['usersWithVideos'])}',
      'videosDiscovered: ${_asInt(data['videosDiscovered'])}',
      'alreadyTranscodedUrl: ${_asInt(data['alreadyTranscodedUrl'])}',
      'alreadyTranscodedFile: ${_asInt(data['alreadyTranscodedFile'])}',
      'updatedFromExistingFile: ${_asInt(data['updatedFromExistingFile'])}',
      'wouldTranscode: ${_asInt(data['wouldTranscode'])}',
      'transcodeTriggered: ${_asInt(data['transcodeTriggered'])}',
      'transcodeFailures: ${_asInt(data['transcodeFailures'])}',
      'missingSource: ${_asInt(data['missingSource'])}',
      'hasMore: ${data['hasMore'] == true ? 'true' : 'false'}',
      'nextCursor: ${data['nextCursor'] ?? '-'}',
    ];

    final failuresRaw = (data['failures'] as List?) ?? const [];
    final failures = failuresRaw.map(_asMap).where((item) => item.isNotEmpty);

    if (failures.isNotEmpty) {
      lines.add('');
      lines.add('Failures (max 5):');
      for (final failure in failures.take(5)) {
        lines.add(
          '- user=${failure['userId'] ?? '-'} media=${failure['mediaId'] ?? '-'} error=${failure['error'] ?? '-'}',
        );
      }
    }

    return lines.join('\n');
  }

  Future<void> _runVideoBackfill({
    required bool dryRun,
    required bool resetCursor,
  }) async {
    if (_isBackfillRunning || _isMigrating) return;

    final limit = _parseBackfillLimit();
    final currentCursor = _videoBackfillCursor;

    final payload = <String, dynamic>{
      'dryRun': dryRun,
      'limit': limit,
      if (!resetCursor && currentCursor != null && currentCursor.isNotEmpty)
        'startAfterUserId': currentCursor,
    };

    setState(() {
      _isBackfillRunning = true;
      _backfillAction = dryRun ? 'dryRun' : 'run';
      _videoBackfillReport =
          'Executando ${dryRun ? 'simulacao' : 'lote real'}...';

      if (resetCursor) {
        _videoBackfillCursor = null;
        _videoBackfillHasMore = false;
      }
    });

    try {
      final callable = _functions.httpsCallable(
        'backfillGalleryVideoTranscodes',
      );
      final response = await callable.call(payload);
      final data = _asMap(response.data);

      setState(() {
        _videoBackfillHasMore = data['hasMore'] == true;
        final cursor = data['nextCursor'];
        _videoBackfillCursor = cursor is String ? cursor : null;
        _videoBackfillReport = _formatBackfillReport(data);
      });
    } on FirebaseFunctionsException catch (e) {
      final message = e.message ?? (e.details?.toString() ?? 'sem detalhes');
      setState(() {
        _videoBackfillReport = 'Erro callable (${e.code}): $message';
      });
    } catch (e) {
      setState(() {
        _videoBackfillReport = 'Erro ao executar backfill: $e';
      });
    } finally {
      setState(() {
        _isBackfillRunning = false;
        _backfillAction = '';
      });
    }
  }

  Future<void> _runVideoBackfillDryRun() async {
    await _runVideoBackfill(dryRun: true, resetCursor: true);
  }

  Future<void> _runVideoBackfillBatch() async {
    await _runVideoBackfill(dryRun: false, resetCursor: false);
  }

  void _resetBackfillCursor() {
    if (_isBackfillRunning) return;
    setState(() {
      _videoBackfillCursor = null;
      _videoBackfillHasMore = false;
      _videoBackfillReport = 'Cursor reiniciado. Proximo lote volta do inicio.';
    });
  }

  Future<void> _runMigration() async {
    setState(() {
      _isMigrating = true;
      _report = 'Iniciando migracao...';
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
            'Migracao concluida!\n'
            'Atualizados: $updated\n'
            'Pulados: $skipped';
      });
    } catch (e) {
      setState(() {
        _report = 'Erro na migracao: $e';
      });
    } finally {
      setState(() {
        _isMigrating = false;
      });
    }
  }

  Future<void> _clearMocks() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade removida (SeedDatabase apagado)'),
      ),
    );
  }

  Future<void> _seedData() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade removida (SeedDatabase apagado)'),
      ),
    );
  }

  Future<void> _addGeohash() async {
    setState(() {
      _isMigrating = true;
      _report = 'Adicionando geohash a usuarios...';
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

          if (data.containsKey('geohash') && data['geohash'] != null) {
            skipped++;
            continue;
          }

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
        } catch (_) {
          skipped++;
        }
      }

      setState(() {
        _report =
            'Geohash adicionado!\n'
            'Atualizados: $updated\n'
            'Ignorados: $skipped\n\n'
            'Agora as queries de proximidade serao mais rapidas.';
      });
    } catch (e) {
      setState(() {
        _report = 'Erro ao adicionar geohash: $e';
      });
    } finally {
      setState(() {
        _isMigrating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _isMigrating || _isBackfillRunning;

    return Scaffold(
      appBar: const AppAppBar(title: 'Manutencao', showBackButton: true),
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
                      'Migracao de Coordenadas',
                      style: AppTypography.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    const Text(
                      'Renomeia o campo "long" para "lng" em documentos da colecao "users".',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    AppButton.primary(
                      onPressed: isBusy ? null : _runMigration,
                      isLoading: _isMigrating,
                      text: 'TENTAR MIGRACAO (MODO AVANCADO)',
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
                      'Se a migracao acima falhar por permissao, use estes botoes:',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton.outline(
                            onPressed: isBusy ? null : _clearMocks,
                            text: 'LIMPAR MOCKS',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s12),
                        Expanded(
                          child: AppButton.primary(
                            onPressed: isBusy ? null : _seedData,
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
              Text('Relatorio:', style: AppTypography.titleSmall),
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
              onPressed: isBusy ? null : _addGeohash,
              text: 'ADICIONAR GEOHASH (OTIMIZACAO)',
              isFullWidth: true,
            ),
            Text(
              'Adiciona geohash aos usuarios existentes para queries mais rapidas',
              textAlign: TextAlign.center,
              style: AppTypography.chipLabel.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Backfill de Videos Antigos',
                      style: AppTypography.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      'Use apenas para videos antigos, enviados antes da pipeline automatica. Videos novos ja sao processados automaticamente.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    AppTextField(
                      controller: _backfillLimitController,
                      label: 'Tamanho do lote (1-100)',
                      hint: '20',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton.outline(
                            onPressed: isBusy ? null : _runVideoBackfillDryRun,
                            isLoading:
                                _isBackfillRunning &&
                                _backfillAction == 'dryRun',
                            text: 'SIMULAR (DRY RUN)',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s12),
                        Expanded(
                          child: AppButton.primary(
                            onPressed: isBusy ? null : _runVideoBackfillBatch,
                            isLoading:
                                _isBackfillRunning && _backfillAction == 'run',
                            text: _videoBackfillHasMore
                                ? 'PROXIMO LOTE'
                                : 'EXECUTAR LOTE',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    AppButton.ghost(
                      onPressed: isBusy ? null : _resetBackfillCursor,
                      text: 'REINICIAR CURSOR',
                      isFullWidth: true,
                    ),
                    if (_videoBackfillCursor != null) ...[
                      const SizedBox(height: AppSpacing.s8),
                      Text(
                        'Cursor atual: $_videoBackfillCursor',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_videoBackfillReport.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s16),
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
                  _videoBackfillReport,
                  style: AppTypography.bodySmall.copyWith(
                    fontFamily: 'monospace',
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
