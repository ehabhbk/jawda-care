import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PlaceResult {
  final String name;
  final double latitude;
  final double longitude;

  const PlaceResult({
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

class GeocodingService {
  static const String _webKey = 'AIzaSyDOPO-46knmNVsn_1SWJDQ-9sTUhw2WMB0';
  static const String _androidKey = 'AIzaSyAqrtMqsr40-vvNjHGRJvSJhLkoAdD8Fkk';

  static String get _apiKey => kIsWeb ? _webKey : _androidKey;

  static Future<List<PlaceResult>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) return [];

    final uri = Uri.parse('https://maps.googleapis.com/maps/api/geocode/json')
        .replace(
          queryParameters: {
            'address': trimmed,
            'key': _apiKey,
            'language': 'ar',
            'region': 'eg',
          },
        );

    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final results = data['results'] as List? ?? [];
      return results
          .take(6)
          .map((r) {
            try {
              final loc =
                  (r['geometry'] as Map)['location'] as Map<dynamic, dynamic>;
              return PlaceResult(
                name: r['formatted_address']?.toString() ?? '',
                latitude: (loc['lat'] as num).toDouble(),
                longitude: (loc['lng'] as num).toDouble(),
              );
            } catch (_) {
              return null;
            }
          })
          .whereType<PlaceResult>()
          .toList();
    } catch (_) {
      return [];
    }
  }
}
