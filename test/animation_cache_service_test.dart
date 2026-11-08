// Pruebas para AnimationCacheService.
//
// Verifica:
// 1. Archivo ausente: devuelve null sin error ni log
// 2. Caché reutilizada: segunda llamada retorna dato cacheado
// 3. Inicialización idempotente: múltiples initialize no duplican trabajo

import 'package:flutter_test/flutter_test.dart';

import 'package:mi_calli/core/performance/animation_cache_service.dart';

void main() {
  group('AnimationCacheService', () {
    late AnimationCacheService cache;

    setUp(() {
      cache = AnimationCacheService();
      // Limpiar estado singleton entre tests
      cache.clearCache();
    });

    group('Archivo ausente', () {
      test('loadAsset devuelve null para asset inexistente sin lanzar error', () async {
        final result = await cache.loadAsset('assets/animations/nonexistent.riv');
        expect(result, isNull);
      });

      test('getAsset devuelve null para asset no cacheado', () {
        final result = cache.getAsset('assets/animations/nonexistent.riv');
        expect(result, isNull);
      });

      test('hasAsset devuelve false para asset no cacheado', () {
        final result = cache.hasAsset('assets/animations/nonexistent.riv');
        expect(result, isFalse);
      });
    });

    group('Caché reutilizada', () {
      test('initialize con lista vacía no falla y es idempotente', () async {
        await cache.initialize([]);
        await cache.initialize([]); // Segunda llamada no debe fallar
        expect(cache.knownAssets, isEmpty);
      });

      test('initialize intenta pre-cargar assets de la lista', () async {
        // Assets inexistentes -> no deben fallar ni llenar caché
        await cache.initialize(['assets/animations/missing1.riv', 'assets/animations/missing2.json']);
        expect(cache.knownAssets, containsAll(['assets/animations/missing1.riv', 'assets/animations/missing2.json']));
        expect(cache.hasAsset('assets/animations/missing1.riv'), isFalse);
        expect(cache.hasAsset('assets/animations/missing2.json'), isFalse);
      });
    });

    group('Inicialización y limpieza', () {
      test('clearCache limpia todo el estado', () async {
        await cache.initialize(['assets/test.riv']);
        cache.clearCache();
        expect(cache.knownAssets, isEmpty);
        expect(cache.hasAsset('assets/test.riv'), isFalse);
      });

      test('inicialización es idempotente: segunda llamada no agrega assets duplicados', () async {
        // La primera llamada registra los assets, la segunda retorna temprano
        // porque _preloadAttempted = true
        await cache.initialize(['assets/a.riv']);
        await cache.initialize(['assets/b.riv']);
        // Solo los assets de la primera llamada se registran
        expect(cache.knownAssets.length, equals(1));
        expect(cache.knownAssets, contains('assets/a.riv'));
      });
    });
  });
}