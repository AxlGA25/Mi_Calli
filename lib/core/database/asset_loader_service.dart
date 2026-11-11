// Servicio para cargar y parsear assets JSON locales.
//
// Verifica que los archivos JSON se carguen y se parsen correctamente
// a sus respectivos modelos Dart.
import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:mi_calli/features/1_sanctuary_journal/models/wisdom_feather.dart';
import 'package:mi_calli/features/2_gamification/models/seed_catalog_item.dart';

class AssetLoaderService {
  AssetLoaderService._();

  static final AssetLoaderService _instance = AssetLoaderService._();

  static AssetLoaderService get instance => _instance;

  // Cache para evitar recargas
  List<WisdomFeather>? _cachedFeathers;
  List<SeedCatalogItem>? _cachedSeeds;

  /// Carga y parsea el catálogo de Plumas de Sabiduría.
  ///
  /// Lanza [AssetLoadException] si falla la carga o el parseo.
  Future<List<WisdomFeather>> loadFeathers() async {
    if (_cachedFeathers != null) {
      return _cachedFeathers!;
    }

    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/feathers.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;

      if (jsonList.isEmpty) {
        throw AssetLoadException('feathers.json está vacío');
      }

      _cachedFeathers = jsonList
          .map((e) => WisdomFeather.fromJson(e as Map<String, dynamic>))
          .toList();

      // Validación adicional: verificar que hay 5 plumas y emociones únicas
      if (_cachedFeathers!.length != 5) {
        throw AssetLoadException(
          'Se esperaban 5 plumas, se encontraron ${_cachedFeathers!.length}',
        );
      }

      final emotionIds = _cachedFeathers!.map((f) => f.emotionId).toSet();
      const expectedEmotions = {
        'tlaloc_lluvia',
        'tonatiuh_sol',
        'ehecatl_viento',
        'mixcoatl_tormenta',
        'metztli_noche',
      };
      if (!emotionIds.containsAll(expectedEmotions)) {
        throw AssetLoadException(
          'Faltan emociones en feathers.json. Esperadas: $expectedEmotions, '
          'encontradas: $emotionIds',
        );
      }

      return _cachedFeathers!;
    } on FormatException catch (e) {
      throw AssetLoadException('Error parseando feathers.json: $e');
    } on PlatformException catch (e) {
      throw AssetLoadException('No se encontró feathers.json: ${e.message}');
    }
  }

  /// Carga y parsea el catálogo de Semillas de la Chinampa.
  ///
  /// Lanza [AssetLoadException] si falla la carga o el parseo.
  Future<List<SeedCatalogItem>> loadSeedsCatalog() async {
    if (_cachedSeeds != null) {
      return _cachedSeeds!;
    }

    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/seeds_catalog.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;

      if (jsonList.isEmpty) {
        throw AssetLoadException('seeds_catalog.json está vacío');
      }

      _cachedSeeds = jsonList
          .map((e) => SeedCatalogItem.fromJson(e as Map<String, dynamic>))
          .toList();

      // Validación adicional: verificar que hay 7 semillas
      if (_cachedSeeds!.length != 7) {
        throw AssetLoadException(
          'Se esperaban 7 semillas, se encontraron ${_cachedSeeds!.length}',
        );
      }

      // Verificar que cada semilla tiene waterings_needed y affinity_emotion
      for (final seed in _cachedSeeds!) {
        if (seed.wateringsNeeded < 1) {
          throw AssetLoadException(
            'Semilla ${seed.seedId} tiene waterings_needed inválido: ${seed.wateringsNeeded}',
          );
        }
        if (seed.affinityEmotion.isEmpty) {
          throw AssetLoadException(
            'Semilla ${seed.seedId} no tiene affinity_emotion definido',
          );
        }
      }

      // Verificar semillas esperadas
      final seedIds = _cachedSeeds!.map((s) => s.seedId).toSet();
      const expectedSeedIds = {
        'seed_cempasuchil',
        'seed_nopal_tunas',
        'seed_maiz_morado',
        'seed_maguey',
        'seed_cacao',
        'seed_dalia',
        'seed_vainilla',
      };
      if (!seedIds.containsAll(expectedSeedIds)) {
        throw AssetLoadException(
          'Faltan semillas en seeds_catalog.json. Esperadas: $expectedSeedIds, '
          'encontradas: $seedIds',
        );
      }

      return _cachedSeeds!;
    } on FormatException catch (e) {
      throw AssetLoadException('Error parseando seeds_catalog.json: $e');
    } on PlatformException catch (e) {
      throw AssetLoadException(
        'No se encontró seeds_catalog.json: ${e.message}',
      );
    }
  }

  /// Precarga ambos catálogos (útil en splash screen).
  Future<void> preloadAll() async {
    await Future.wait([
      loadFeathers(),
      loadSeedsCatalog(),
    ]);
  }

  /// Obtiene una pluma por su emotionId.
  ///
  /// Debe llamarse después de loadFeathers() o preloadAll().
  /// Lanza [AssetLoadException] si no se encuentra la pluma para la emoción.
  Future<WisdomFeather> getFeatherByEmotion(String emotionId) async {
    final feathers = await loadFeathers();
    try {
      return feathers.firstWhere((f) => f.emotionId == emotionId);
    } on StateError {
      throw AssetLoadException('No se encontró pluma para emotionId: $emotionId');
    }
  }

  /// Limpia la caché (útil para tests).
  void clearCache() {
    _cachedFeathers = null;
    _cachedSeeds = null;
  }

  /// Establece la caché de plumas directamente (solo para tests).
  ///
  /// Evita la carga de assets en entornos de test donde rootBundle no está disponible.
  void setFeathersCacheForTesting(List<WisdomFeather> feathers) {
    _cachedFeathers = feathers;
  }

  /// Establece la caché de semillas directamente (solo para tests).
  void setSeedsCacheForTesting(List<SeedCatalogItem> seeds) {
    _cachedSeeds = seeds;
  }
}

/// Excepción personalizada para errores de carga de assets.
class AssetLoadException implements Exception {
  final String message;

  const AssetLoadException(this.message);

  @override
  String toString() => 'AssetLoadException: $message';
}