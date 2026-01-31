import 'dart:math';

/// Classe utilitária para cálculos de distância geográfica.
///
/// Usa a fórmula Haversine que considera a curvatura da Terra.
abstract class DistanceCalculator {
  /// Raio médio da Terra em quilômetros
  static const double _earthRadiusKm = 6371.0;

  /// Calcula a distância em km entre dois pontos geográficos.
  ///
  /// Usa a fórmula Haversine para precisão em distâncias curtas e longas.
  ///
  /// Exemplo:
  /// ```dart
  /// final distancia = DistanceCalculator.haversine(
  ///   fromLat: -23.5505,
  ///   fromLng: -46.6333,
  ///   toLat: -22.9068,
  ///   toLng: -43.1729,
  /// ); // ~357 km (SP -> RJ)
  /// ```
  static double haversine({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    final dLat = _toRadians(toLat - fromLat);
    final dLng = _toRadians(toLng - fromLng);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(fromLat)) *
            cos(_toRadians(toLat)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return _earthRadiusKm * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;
}
