import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import '../../utils/app_logger.dart';

/// Serviço centralizado para analytics do aplicativo.
/// 
/// Rastreia eventos importantes do funil de conversão e comportamento do usuário.
/// 
/// Eventos principais:
/// - user_registration: Novo usuário cadastrado
/// - onboarding_complete: Onboarding finalizado
/// - profile_view: Visualização de perfil
/// - match_interaction: Interação no MatchPoint (like/dislike)
/// - chat_initiated: Conversa iniciada
/// - favorite_added: Perfil favoritado
/// - search_performed: Busca realizada
/// - support_ticket_created: Ticket de suporte criado
class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static bool _isEnabled = false;

  /// Inicializa o serviço de analytics
  static Future<void> initialize() async {
    if (!kDebugMode) {
      await _analytics.setAnalyticsCollectionEnabled(true);
      _isEnabled = true;
      AppLogger.info('📊 Analytics inicializado');
    } else {
      AppLogger.info('📊 Analytics em modo debug (logs apenas)');
    }
  }

  /// Loga um evento customizado
  static Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    final normalized = _normalizeParameters(parameters);

    if (_isEnabled) {
      await _analytics.logEvent(
        name: name,
        parameters: normalized,
      );
    }
    
    AppLogger.info('📊 Evento: $name | Params: $normalized');
  }

  static Map<String, Object>? _normalizeParameters(
    Map<String, Object>? parameters,
  ) {
    if (parameters == null) return null;

    return parameters.map((key, value) {
      if (value is String || value is num) {
        return MapEntry(key, value);
      }

      if (value is bool) {
        return MapEntry(key, value ? 1 : 0);
      }

      return MapEntry(key, value.toString());
    });
  }

  /// Define o user ID para rastreamento cross-device
  static Future<void> setUserId(String userId) async {
    if (_isEnabled) {
      await _analytics.setUserId(id: userId);
    }
  }

  /// Define propriedades do usuário
  static Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    if (_isEnabled) {
      await _analytics.setUserProperty(name: name, value: value);
    }
  }

  // ============ EVENTOS DO FUNIL DE CONVERSÃO ============

  /// Registra quando um usuário completa o cadastro
  static Future<void> logRegistration({
    required String method,
    required String userType,
  }) async {
    await logEvent(
      name: 'user_registration',
      parameters: {
        'method': method,
        'user_type': userType,
      },
    );
  }

  /// Registra quando o onboarding é completado
  static Future<void> logOnboardingComplete({
    required String userType,
    required int stepsCompleted,
  }) async {
    await logEvent(
      name: 'onboarding_complete',
      parameters: {
        'user_type': userType,
        'steps_completed': stepsCompleted,
      },
    );
  }

  /// Registra visualização de perfil
  static Future<void> logProfileView({
    required String viewedUserId,
    required String source,
  }) async {
    await logEvent(
      name: 'profile_view',
      parameters: {
        'viewed_user_id': viewedUserId,
        'source': source,
      },
    );
  }

  /// Registra interação no MatchPoint
  static Future<void> logMatchInteraction({
    required String targetUserId,
    required String action,
    required bool isMatch,
  }) async {
    await logEvent(
      name: 'match_interaction',
      parameters: {
        'target_user_id': targetUserId,
        'action': action,
        'is_match': isMatch,
      },
    );
  }

  /// Registra início de conversa
  static Future<void> logChatInitiated({
    required String conversationId,
    required String otherUserId,
    required String source,
  }) async {
    await logEvent(
      name: 'chat_initiated',
      parameters: {
        'conversation_id': conversationId,
        'other_user_id': otherUserId,
        'source': source,
      },
    );
  }

  /// Registra mensagem enviada
  static Future<void> logMessageSent({
    required String conversationId,
    required bool hasMedia,
  }) async {
    await logEvent(
      name: 'message_sent',
      parameters: {
        'conversation_id': conversationId,
        'has_media': hasMedia,
      },
    );
  }

  /// Registra quando um perfil é favoritado
  static Future<void> logFavoriteAdded({
    required String targetUserId,
  }) async {
    await logEvent(
      name: 'favorite_added',
      parameters: {
        'target_user_id': targetUserId,
      },
    );
  }

  /// Registra busca realizada
  static Future<void> logSearch({
    required String query,
    required int resultsCount,
    required Map<String, dynamic> filters,
  }) async {
    await logEvent(
      name: 'search_performed',
      parameters: {
        'query': query,
        'results_count': resultsCount,
        'has_filters': filters.isNotEmpty,
      },
    );
  }

  /// Registra quando um ticket de suporte é criado
  static Future<void> logSupportTicketCreated({
    required String category,
    required String priority,
  }) async {
    await logEvent(
      name: 'support_ticket_created',
      parameters: {
        'category': category,
        'priority': priority,
      },
    );
  }

  /// Registra erro capturado
  static Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? screenName,
  }) async {
    await logEvent(
      name: 'app_error',
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage,
        'screen': screenName ?? 'unknown',
      },
    );
  }

  /// Registra quando usuário convida alguém para a banda
  static Future<void> logBandInviteSent({
    required String bandId,
    required String targetUserId,
  }) async {
    await logEvent(
      name: 'band_invite_sent',
      parameters: {
        'band_id': bandId,
        'target_user_id': targetUserId,
      },
    );
  }

  /// Registra quando convite é aceito
  static Future<void> logBandInviteAccepted({
    required String bandId,
    required String userId,
  }) async {
    await logEvent(
      name: 'band_invite_accepted',
      parameters: {
        'band_id': bandId,
        'user_id': userId,
      },
    );
  }

  /// Registra uso de ferramentas (ex: afinador)
  static Future<void> logToolUsed({
    required String toolName,
    required int durationSeconds,
  }) async {
    await logEvent(
      name: 'tool_used',
      parameters: {
        'tool_name': toolName,
        'duration_seconds': durationSeconds,
      },
    );
  }
}
