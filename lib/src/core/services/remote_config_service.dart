import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import '../../utils/app_logger.dart';

/// Serviço de Feature Flags usando Firebase Remote Config.
///
/// Permite ativar/desativar features remotamente sem necessidade de novo deploy.
///
/// Flags disponíveis:
/// - `enable_matchpoint`: Ativa/desativa o MatchPoint
/// - `enable_chat`: Ativa/desativa o chat
/// - `enable_search_filters`: Ativa/desativa filtros avançados de busca
/// - `enable_push_notifications`: Ativa/desativa notificações push
/// - `maintenance_mode`: Coloca o app em modo de manutenção
/// - `max_feed_items`: Número máximo de itens no feed (configurável)
/// - `search_radius_km`: Raio de busca padrão em km
class RemoteConfigService {
  static final FirebaseRemoteConfig _remoteConfig =
      FirebaseRemoteConfig.instance;

  static bool _initialized = false;

  /// Inicializa o Remote Config com valores padrão
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: kDebugMode
              ? const Duration(seconds: 30) // Atualiza rápido em debug
              : const Duration(hours: 1), // Atualiza a cada hora em produção
        ),
      );

      // Define valores padrão
      await _remoteConfig.setDefaults(const {
        'enable_matchpoint': true,
        'enable_chat': true,
        'enable_search_filters': true,
        'enable_push_notifications': true,
        'maintenance_mode': false,
        'max_feed_items': 50,
        'search_radius_km': 50.0,
        'enable_new_onboarding': false,
        'max_upload_size_mb': 10,
      });

      // Fetch e ativa as configurações
      await _remoteConfig.fetchAndActivate();

      _initialized = true;
      AppLogger.info('✅ Remote Config inicializado');

      // Log das configurações atuais
      _logCurrentConfig();
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao inicializar Remote Config', e, stackTrace);
      // Continua com valores padrão mesmo se falhar
      _initialized = true;
    }
  }

  /// Força uma atualização das configurações
  static Future<bool> fetchAndActivate() async {
    try {
      final updated = await _remoteConfig.fetchAndActivate();
      if (updated) {
        AppLogger.info('🔄 Remote Config atualizado');
        _logCurrentConfig();
      }
      return updated;
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao fetch Remote Config', e, stackTrace);
      return false;
    }
  }

  /// Log das configurações atuais (apenas em debug)
  static void _logCurrentConfig() {
    if (kDebugMode) {
      AppLogger.info('''
📊 Remote Config atual:
  - MatchPoint: $enableMatchPoint
  - Chat: $enableChat
  - Search Filters: $enableSearchFilters
  - Push Notifications: $enablePushNotifications
  - Maintenance Mode: $maintenanceMode
  - Max Feed Items: $maxFeedItems
  - Search Radius: ${searchRadiusKm}km
  - Max Upload Size: ${maxUploadSizeMb}MB
      ''');
    }
  }

  // ============ FEATURE FLAGS ============

  /// Ativa/desativa o MatchPoint
  static bool get enableMatchPoint =>
      _remoteConfig.getBool('enable_matchpoint');

  /// Ativa/desativa o chat
  static bool get enableChat => _remoteConfig.getBool('enable_chat');

  /// Ativa/desativa filtros avançados de busca
  static bool get enableSearchFilters =>
      _remoteConfig.getBool('enable_search_filters');

  /// Ativa/desativa notificações push
  static bool get enablePushNotifications =>
      _remoteConfig.getBool('enable_push_notifications');

  /// Modo de manutenção - quando true, mostra tela de manutenção
  static bool get maintenanceMode => _remoteConfig.getBool('maintenance_mode');

  /// Mensagem de manutenção (opcional)
  static String get maintenanceMessage =>
      _remoteConfig.getString('maintenance_message').isEmpty
      ? 'Estamos em manutenção. Voltamos em breve!'
      : _remoteConfig.getString('maintenance_message');

  // ============ CONFIGURAÇÕES NUMÉRICAS ============

  /// Número máximo de itens no feed
  static int get maxFeedItems => _remoteConfig.getInt('max_feed_items');

  /// Raio de busca padrão em km
  static double get searchRadiusKm =>
      _remoteConfig.getDouble('search_radius_km');

  /// Tamanho máximo de upload em MB
  static int get maxUploadSizeMb => _remoteConfig.getInt('max_upload_size_mb');

  /// Ativa o novo fluxo de onboarding (feature futura)
  static bool get enableNewOnboarding =>
      _remoteConfig.getBool('enable_new_onboarding');

  // ============ MÉTODOS DE STRING ============

  /// Obtém uma string do Remote Config
  static String getString(String key, {String defaultValue = ''}) {
    try {
      final value = _remoteConfig.getString(key);
      return value.isEmpty ? defaultValue : value;
    } catch (e) {
      return defaultValue;
    }
  }

  /// Obtém um inteiro do Remote Config
  static int getInt(String key, {int defaultValue = 0}) {
    try {
      return _remoteConfig.getInt(key);
    } catch (e) {
      return defaultValue;
    }
  }

  /// Obtém um double do Remote Config
  static double getDouble(String key, {double defaultValue = 0.0}) {
    try {
      return _remoteConfig.getDouble(key);
    } catch (e) {
      return defaultValue;
    }
  }

  /// Obtém um boolean do Remote Config
  static bool getBool(String key, {bool defaultValue = false}) {
    try {
      return _remoteConfig.getBool(key);
    } catch (e) {
      return defaultValue;
    }
  }
}
