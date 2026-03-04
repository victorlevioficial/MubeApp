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
import '../../bands/domain/band_activation_rules.dart';

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
  bool _forceVideoRetranscode = false;

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

  String _formatPercent(int value, int total) {
    if (total <= 0) return '0%';
    final percent = (value / total) * 100;
    return '${percent.toStringAsFixed(percent >= 10 ? 0 : 1)}%';
  }

  String _formatBucketStart(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    return '$day/$month $hour:00';
  }

  Widget _buildRankingSummaryMetric({
    required String label,
    required String value,
    String? subtitle,
  }) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.all12,
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(value, style: AppTypography.titleLarge),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s4),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMatchpointRankingAuditCard() {
    final stream = FirebaseFirestore.instance
        .collection('matchpointStats')
        .where('type', isEqualTo: 'ranking_audit_hourly')
        .orderBy('bucket_start', descending: true)
        .limit(24)
        .snapshots();

    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Auditoria de Ranking MatchPoint',
                    style: AppTypography.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    'Erro ao carregar buckets: ${snapshot.error}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              );
            }

            if (!snapshot.hasData) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Auditoria de Ranking MatchPoint',
                    style: AppTypography.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  const Center(child: CircularProgressIndicator()),
                ],
              );
            }

            final buckets = snapshot.data!.docs
                .map(_MatchpointRankingBucket.fromDoc)
                .toList();

            if (buckets.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Auditoria de Ranking MatchPoint',
                    style: AppTypography.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    'Ainda nao existem buckets de auditoria. Eles comecam a aparecer apos buscas reais no MatchPoint.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              );
            }

            final summary = _MatchpointRankingSummary.fromBuckets(buckets);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auditoria de Ranking MatchPoint',
                  style: AppTypography.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  'Buckets horarios espelhados do evento matchpoint_ranking_audit para leitura rapida no painel interno.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                Wrap(
                  spacing: AppSpacing.s12,
                  runSpacing: AppSpacing.s12,
                  children: [
                    _buildRankingSummaryMetric(
                      label: 'Eventos (24h)',
                      value: '${summary.totalEvents}',
                      subtitle:
                          '${summary.totalReturned} perfis retornados no total',
                    ),
                    _buildRankingSummaryMetric(
                      label: 'Media por busca',
                      value: summary.averageReturnedPerEvent.toStringAsFixed(1),
                      subtitle:
                          '${summary.averagePoolPerEvent.toStringAsFixed(1)} perfis no pool',
                    ),
                    _buildRankingSummaryMetric(
                      label: 'Busca com geohash',
                      value: _formatPercent(
                        summary.geohashUsedCount,
                        summary.totalEvents,
                      ),
                      subtitle:
                          '${summary.geohashUsedCount}/${summary.totalEvents} eventos',
                    ),
                    _buildRankingSummaryMetric(
                      label: 'Mix retornado',
                      value:
                          'P ${_formatPercent(summary.returnedProximity, summary.totalReturned)}',
                      subtitle:
                          'H ${_formatPercent(summary.returnedHashtag, summary.totalReturned)} | G ${_formatPercent(summary.returnedGenre, summary.totalReturned)} | F ${_formatPercent(summary.returnedFallback, summary.totalReturned)}',
                    ),
                    _buildRankingSummaryMetric(
                      label: 'Locais com afinidade',
                      value:
                          'H ${summary.returnedLocalHashtag} | G ${summary.returnedLocalGenre}',
                      subtitle:
                          '${summary.returnedLocalTotal} perfis dentro do raio',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s20),
                Text('Ultimos buckets', style: AppTypography.titleSmall),
                const SizedBox(height: AppSpacing.s8),
                ...buckets
                    .take(8)
                    .map(
                      (bucket) => Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.s8),
                        padding: const EdgeInsets.all(AppSpacing.s12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: AppRadius.all12,
                          border: Border.all(color: AppColors.surfaceHighlight),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatBucketStart(bucket.bucketStart),
                                    style: AppTypography.titleSmall,
                                  ),
                                  const SizedBox(height: AppSpacing.s4),
                                  Text(
                                    '${bucket.totalEvents} buscas | ${bucket.returnedTotal} perfis retornados | ${bucket.poolTotal} no pool',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s12),
                            SizedBox(
                              width: 180,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'P ${bucket.returnedProximity} | H ${bucket.returnedHashtag} | G ${bucket.returnedGenre} | F ${bucket.returnedFallback}',
                                    textAlign: TextAlign.right,
                                    style: AppTypography.bodySmall.copyWith(
                                      fontFamily: 'monospace',
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.s4),
                                  Text(
                                    'Locais ${bucket.returnedLocalTotal} | H ${bucket.returnedLocalHashtag} | G ${bucket.returnedLocalGenre}',
                                    textAlign: TextAlign.right,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatBackfillReport(Map<String, dynamic> data) {
    final lines = <String>[
      'Backfill de videos - resultado:',
      'dryRun: ${data['dryRun'] == true ? 'true' : 'false'}',
      'forceRetranscode: ${data['forceRetranscode'] == true ? 'true' : 'false'}',
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
      'forceRetranscode': _forceVideoRetranscode,
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

  Future<void> _recalculateBandStatuses() async {
    setState(() {
      _isMigrating = true;
      _report = 'Recalculando status das bandas...';
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('users')
          .where('tipo_perfil', isEqualTo: 'banda')
          .where('cadastro_status', isEqualTo: 'concluido')
          .get();

      var updated = 0;
      var skipped = 0;
      var pendingWrites = 0;
      var batch = firestore.batch();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final rawMembers = data['members'];
        final acceptedMembers = rawMembers is List
            ? rawMembers.whereType<String>().toSet().length
            : 0;
        final nextStatus = isBandEligibleForActivation(acceptedMembers)
            ? profileActiveStatus
            : profileDraftStatus;

        if (data['status'] == nextStatus) {
          skipped++;
          continue;
        }

        batch.update(doc.reference, {'status': nextStatus});
        updated++;
        pendingWrites++;

        if (pendingWrites == 400) {
          await batch.commit();
          batch = firestore.batch();
          pendingWrites = 0;
        }
      }

      if (pendingWrites > 0) {
        await batch.commit();
      }

      setState(() {
        _report =
            'Status de bandas recalculado!\n'
            'Atualizados: $updated\n'
            'Sem mudanca: $skipped';
      });
    } catch (e) {
      setState(() {
        _report = 'Erro ao recalcular status das bandas: $e';
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
            AppButton.outline(
              onPressed: isBusy ? null : _recalculateBandStatuses,
              text: 'RECALCULAR STATUS DE BANDAS',
              isFullWidth: true,
            ),
            Text(
              'Reprocessa bandas concluidas e ajusta status para ativo ou rascunho conforme a quantidade de integrantes aceitos.',
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
                    const SizedBox(height: AppSpacing.s8),
                    SwitchListTile.adaptive(
                      value: _forceVideoRetranscode,
                      onChanged: isBusy
                          ? null
                          : (value) {
                              setState(() {
                                _forceVideoRetranscode = value;
                              });
                            },
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Forcar re-transcode'),
                      subtitle: Text(
                        'Reprocessa videos ja transcodados para corrigir formato antigo.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
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
            const SizedBox(height: AppSpacing.s24),
            _buildMatchpointRankingAuditCard(),
          ],
        ),
      ),
    );
  }
}

class _MatchpointRankingBucket {
  final DateTime bucketStart;
  final int totalEvents;
  final int poolTotal;
  final int returnedTotal;
  final int returnedProximity;
  final int returnedHashtag;
  final int returnedGenre;
  final int returnedFallback;
  final int returnedLocalTotal;
  final int returnedLocalHashtag;
  final int returnedLocalGenre;
  final int geohashUsedCount;

  const _MatchpointRankingBucket({
    required this.bucketStart,
    required this.totalEvents,
    required this.poolTotal,
    required this.returnedTotal,
    required this.returnedProximity,
    required this.returnedHashtag,
    required this.returnedGenre,
    required this.returnedFallback,
    required this.returnedLocalTotal,
    required this.returnedLocalHashtag,
    required this.returnedLocalGenre,
    required this.geohashUsedCount,
  });

  factory _MatchpointRankingBucket.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final bucketStartRaw = data['bucket_start'];
    final bucketStart = bucketStartRaw is Timestamp
        ? bucketStartRaw.toDate()
        : DateTime.now();

    int readInt(String key) {
      final value = data[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return 0;
    }

    return _MatchpointRankingBucket(
      bucketStart: bucketStart,
      totalEvents: readInt('total_events'),
      poolTotal: readInt('pool_total_sum'),
      returnedTotal: readInt('returned_total_sum'),
      returnedProximity: readInt('returned_proximity_sum'),
      returnedHashtag: readInt('returned_hashtag_sum'),
      returnedGenre: readInt('returned_genre_sum'),
      returnedFallback: readInt('returned_fallback_sum'),
      returnedLocalTotal: readInt('returned_local_total_sum'),
      returnedLocalHashtag: readInt('returned_local_hashtag_sum'),
      returnedLocalGenre: readInt('returned_local_genre_sum'),
      geohashUsedCount: readInt('geohash_used_count'),
    );
  }
}

class _MatchpointRankingSummary {
  final int totalEvents;
  final int totalPool;
  final int totalReturned;
  final int returnedProximity;
  final int returnedHashtag;
  final int returnedGenre;
  final int returnedFallback;
  final int returnedLocalTotal;
  final int returnedLocalHashtag;
  final int returnedLocalGenre;
  final int geohashUsedCount;

  const _MatchpointRankingSummary({
    required this.totalEvents,
    required this.totalPool,
    required this.totalReturned,
    required this.returnedProximity,
    required this.returnedHashtag,
    required this.returnedGenre,
    required this.returnedFallback,
    required this.returnedLocalTotal,
    required this.returnedLocalHashtag,
    required this.returnedLocalGenre,
    required this.geohashUsedCount,
  });

  double get averagePoolPerEvent =>
      totalEvents == 0 ? 0 : totalPool / totalEvents;
  double get averageReturnedPerEvent =>
      totalEvents == 0 ? 0 : totalReturned / totalEvents;

  factory _MatchpointRankingSummary.fromBuckets(
    List<_MatchpointRankingBucket> buckets,
  ) {
    var totalEvents = 0;
    var totalPool = 0;
    var totalReturned = 0;
    var returnedProximity = 0;
    var returnedHashtag = 0;
    var returnedGenre = 0;
    var returnedFallback = 0;
    var returnedLocalTotal = 0;
    var returnedLocalHashtag = 0;
    var returnedLocalGenre = 0;
    var geohashUsedCount = 0;

    for (final bucket in buckets) {
      totalEvents += bucket.totalEvents;
      totalPool += bucket.poolTotal;
      totalReturned += bucket.returnedTotal;
      returnedProximity += bucket.returnedProximity;
      returnedHashtag += bucket.returnedHashtag;
      returnedGenre += bucket.returnedGenre;
      returnedFallback += bucket.returnedFallback;
      returnedLocalTotal += bucket.returnedLocalTotal;
      returnedLocalHashtag += bucket.returnedLocalHashtag;
      returnedLocalGenre += bucket.returnedLocalGenre;
      geohashUsedCount += bucket.geohashUsedCount;
    }

    return _MatchpointRankingSummary(
      totalEvents: totalEvents,
      totalPool: totalPool,
      totalReturned: totalReturned,
      returnedProximity: returnedProximity,
      returnedHashtag: returnedHashtag,
      returnedGenre: returnedGenre,
      returnedFallback: returnedFallback,
      returnedLocalTotal: returnedLocalTotal,
      returnedLocalHashtag: returnedLocalHashtag,
      returnedLocalGenre: returnedLocalGenre,
      geohashUsedCount: geohashUsedCount,
    );
  }
}
