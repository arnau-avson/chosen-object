import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GeocodingService {
  GeocodingService._();
  static final GeocodingService instance = GeocodingService._();

  final Map<String, LatLng?> _cache = {};

  /// Geocode a city name to coordinates using Nominatim.
  /// Returns cached result if available, otherwise queries the API.
  /// Returns null if the city cannot be resolved.
  Future<LatLng?> geocode(String city) async {
    final key = city.toLowerCase().trim();
    if (key.isEmpty) return null;

    if (_cache.containsKey(key)) return _cache[key];

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(city)}'
        '&format=json&limit=1',
      );

      final response = await http.get(uri, headers: {
        'User-Agent': 'ChosenObject/1.0 (contact@chosenobject.com)',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat'] as String);
          final lon = double.parse(data[0]['lon'] as String);
          final coords = LatLng(lat, lon);
          _cache[key] = coords;
          return coords;
        }
      }
    } catch (_) {
      // Network error — cache null so we don't retry endlessly
    }

    _cache[key] = null;
    return null;
  }

  /// Geocode multiple cities in parallel. Returns a map of city → LatLng.
  Future<Map<String, LatLng>> geocodeAll(List<String> cities) async {
    final unique = cities
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();

    final results = <String, LatLng>{};

    // Process in batches of 5 to respect Nominatim rate limits
    for (var i = 0; i < unique.length; i += 5) {
      final batch = unique.skip(i).take(5).toList();
      final futures = batch.map((city) async {
        final coords = await geocode(city);
        if (coords != null) {
          results[city.toLowerCase().trim()] = coords;
        }
      });
      await Future.wait(futures);

      // Nominatim asks for max 1 req/sec; small delay between batches
      if (i + 5 < unique.length) {
        await Future.delayed(const Duration(milliseconds: 1100));
      }
    }

    return results;
  }

  void clearCache() => _cache.clear();
}
