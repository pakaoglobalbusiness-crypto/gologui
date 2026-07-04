import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Découpage administratif du Sénégal : Région → Département → Communes.
/// Source : décret n° 2008-1025 (senegalouvert/Decoupage-Administratif).
class Senegal {
  static Map<String, Map<String, List<String>>> _data = {};
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/data/senegal.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _data = json.map(
      (region, deps) => MapEntry(
        region,
        (deps as Map<String, dynamic>).map(
          (dep, communes) => MapEntry(
            dep,
            (communes as List).cast<String>(),
          ),
        ),
      ),
    );
    _loaded = true;
  }

  static List<String> get regions => _data.keys.toList()..sort();

  static List<String> departments(String? region) =>
      region == null ? [] : (_data[region]?.keys.toList() ?? [])
        ..sort();

  static List<String> communes(String? region, String? department) =>
      (region == null || department == null)
          ? []
          : (_data[region]?[department] ?? []);
}
