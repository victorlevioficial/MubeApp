/// Geohash utility for spatial queries.
///
/// Implements geohashing algorithm for efficient location-based queries.
/// Used by FeedRepository for proximity searches without loading all documents.
///
/// Precision levels:
/// - 4: ~20km × 20km (city level)
/// - 5: ~5km × 5km (neighborhood level) ← Recommended
/// - 6: ~1km × 1km (street level)
class GeohashHelper {
  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  /// Encodes lat/lng coordinates into a geohash string.
  ///
  /// [lat]: Latitude (-90 to 90)
  /// [lng]: Longitude (-180 to 180)
  /// [precision]: Hash length (4-7). Default 5 (~5km squares)
  static String encode(double lat, double lng, {int precision = 5}) {
    final latRange = [-90.0, 90.0];
    final lngRange = [-180.0, 180.0];
    var geohash = '';
    var isEven = true;
    var bit = 0;
    var ch = 0;

    while (geohash.length < precision) {
      if (isEven) {
        // longitude
        final mid = (lngRange[0] + lngRange[1]) / 2;
        if (lng > mid) {
          ch |= (1 << (4 - bit));
          lngRange[0] = mid;
        } else {
          lngRange[1] = mid;
        }
      } else {
        // latitude
        final mid = (latRange[0] + latRange[1]) / 2;
        if (lat > mid) {
          ch |= (1 << (4 - bit));
          latRange[0] = mid;
        } else {
          latRange[1] = mid;
        }
      }

      isEven = !isEven;

      if (bit < 4) {
        bit++;
      } else {
        geohash += _base32[ch];
        bit = 0;
        ch = 0;
      }
    }

    return geohash;
  }

  /// Returns the 9 neighboring geohashes (including center).
  ///
  /// This expands the search area to ensure we capture all nearby locations.
  ///
  /// Example:
  /// ```dart
  /// final hash = encode(-23.5505, -46.6333); // "6gyf4"
  /// final neighbors = neighbors(hash);
  /// // Returns: ["6gyf4", "6gyf5", "6gyf6", "6gyf1", ...]
  /// ```
  static List<String> neighbors(String geohash) {
    if (geohash.isEmpty) return [geohash];

    final center = geohash;
    final north = _adjacent(center, 'top');
    final south = _adjacent(center, 'bottom');
    final east = _adjacent(center, 'right');
    final west = _adjacent(center, 'left');

    final northeast = _adjacent(north, 'right');
    final northwest = _adjacent(north, 'left');
    final southeast = _adjacent(south, 'right');
    final southwest = _adjacent(south, 'left');

    return [
      center,
      north,
      south,
      east,
      west,
      northeast,
      northwest,
      southeast,
      southwest,
    ];
  }

  /// Gets estimated radius in kilometers for a given precision level.
  ///
  /// Useful for understanding query coverage area.
  static double estimatedRadiusKm(int precision) {
    switch (precision) {
      case 3:
        return 78.0; // ~156km × 156km
      case 4:
        return 10.0; // ~20km × 20km
      case 5:
        return 2.5; // ~5km × 5km (recommended)
      case 6:
        return 0.5; // ~1km × 1km
      case 7:
        return 0.15; // ~300m × 300m
      default:
        return 5.0;
    }
  }

  // Helper to calculate adjacent geohash
  static String _adjacent(String geohash, String direction) {
    if (geohash.isEmpty) return '';

    final lastChar = geohash[geohash.length - 1];
    final parent = geohash.substring(0, geohash.length - 1);
    final type = geohash.length % 2 == 0 ? 'even' : 'odd';

    // Border lookup tables
    final borders = {
      'right': {'even': 'bcfguvyz', 'odd': 'prxz'},
      'left': {'even': '0145hjnp', 'odd': '028b'},
      'top': {'even': 'prxz', 'odd': 'bcfguvyz'},
      'bottom': {'even': '028b', 'odd': '0145hjnp'},
    };

    final neighbors = {
      'right': {
        'even': 'p0r21436x8zb9dcf5h7kjnmqesgutwvy',
        'odd': 'bc01fg45238967deuvhjyznpkmstqrwx',
      },
      'left': {
        'even': '14365h7k9dcfesgujnmqp0r2twvyx8zb',
        'odd': '238967debc01fg45kmstqrwxuvhjyznp',
      },
      'top': {
        'even': 'bc01fg45238967deuvhjyznpkmstqrwx',
        'odd': 'p0r21436x8zb9dcf5h7kjnmqesgutwvy',
      },
      'bottom': {
        'even': '238967debc01fg45kmstqrwxuvhjyznp',
        'odd': '14365h7k9dcfesgujnmqp0r2twvyx8zb',
      },
    };

    if (borders[direction]![type]!.contains(lastChar) && parent.isNotEmpty) {
      return _adjacent(parent, direction) +
          _base32[neighbors[direction]![type]!.indexOf(lastChar)];
    }

    return parent + _base32[neighbors[direction]![type]!.indexOf(lastChar)];
  }
}
