// Tests para DeityVisitsAndRelicsService usando SQLite FFI real (sqflite_common_ffi).
//
// Cubre todas las condiciones de desbloqueo de reliquias (Tarea 3.3 Parte B):
// - Estado inicial vacío
// - Tláloc: 3+ entradas tlaloc_lluvia
// - Xochiquétzal: ciclo real con ChinampaController (plantar, regar, florecer, cosechar 3 veces)
// - Xólotl Vía A: entrada después de 21:00 local
// - Xólotl Vía B: 2+ entradas metztli_noche
// - Idempotencia: segunda evaluación no duplica reliquias

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mi_calli/core/database/local_database_service.dart';
import 'package:mi_calli/core/database/secure_storage_mock.dart';
import 'package:mi_calli/features/2_gamification/services/deity_visits_and_relics_service.dart';
import 'package:mi_calli/features/2_gamification/controllers/chinampa_controller.dart';
import 'package:mi_calli/features/2_gamification/models/seed_catalog_item.dart'
    show SeedCatalogItem, SeedRarity;

void main() {
  // Configurar SQLite FFI para tests de escritorio
  sqfliteFfiInit();
  final databaseFactory = databaseFactoryFfi;

  group('DeityVisitsAndRelicsService - SQLite FFI Real', () {
    late LocalDatabaseService db;
    late DeityVisitsAndRelicsService service;
    late Directory tempDir;
    late Map<String, SeedCatalogItem> seedCatalog;
    late ChinampaController chinampaController;

    setUp(() async {
      // Crear directorio temporal para la BD de test
      tempDir = await Directory.systemTemp.createTemp('mi_calli_test_');
      final dbPath = '${tempDir.path}/test.db';

      // Crear BD con factory FFI
      final secureStorage = SecureStorageMock();
      db = LocalDatabaseService.createForTesting(
        secureStorage: secureStorage,
        databasePath: dbPath,
        databaseFactory: databaseFactory,
      );
      await db.initialize();

      // Cargar catálogo de semillas para el controlador
      seedCatalog = await _loadTestSeedCatalog();
      chinampaController = ChinampaController(db, seedCatalog);

      service = DeityVisitsAndRelicsService(db);
    });

    tearDown(() async {
      await db.close();
      // Limpiar directorio temporal
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {
        // Ignorar errores de limpieza
      }
    });

    // Helper para insertar entrada de diario con hora local específica
    Future<void> insertDiaryEntryWithLocalTime({
      required String id,
      required DateTime localTime,
      required String emotionId,
      String content = 'Test entry',
      String featherId = 'feather_test',
    }) async {
      // Convertir hora local a UTC para almacenamiento
      final utcTime = localTime.toUtc();
      await db.insertDiaryEntry(
        id: id,
        createdAt: utcTime,
        emotionId: emotionId,
        content: content,
        featherId: featherId,
      );
    }

    test('Estado inicial: getUnlockedRelics() devuelve lista vacía e isRelicUnlocked() false', () async {
      final unlocked = await service.getUnlockedRelics();
      expect(unlocked, isEmpty);

      expect(await service.isRelicUnlocked('relic_vasija_tlaloc'), isFalse);
      expect(await service.isRelicUnlocked('relic_mariposas_xochiquetzal'), isFalse);
      expect(await service.isRelicUnlocked('relic_xolotl_companion'), isFalse);
    });

    group('Tláloc (relic_vasija_tlaloc): 3+ entradas tlaloc_lluvia', () {
      test('Con 0, 1 y 2 entradas NO se desbloquea', () async {
        // 0 entradas
        var result = await service.evaluateAndUnlockRelics();
        expect(result.newlyUnlockedRelics, isEmpty);
        expect(result.allUnlockedRelics, isEmpty);

        // 1 entrada
        await insertDiaryEntryWithLocalTime(
          id: 'entry_1',
          localTime: DateTime(2024, 1, 15, 10, 0),
          emotionId: 'tlaloc_lluvia',
        );
        result = await service.evaluateAndUnlockRelics();
        expect(result.newlyUnlockedRelics, isEmpty);

        // 2 entradas
        await insertDiaryEntryWithLocalTime(
          id: 'entry_2',
          localTime: DateTime(2024, 1, 16, 10, 0),
          emotionId: 'tlaloc_lluvia',
        );
        result = await service.evaluateAndUnlockRelics();
        expect(result.newlyUnlockedRelics, isEmpty);
      });

      test('Al insertar la 3.ª entrada tlaloc_lluvia se desbloquea', () async {
        await insertDiaryEntryWithLocalTime(
          id: 'entry_1',
          localTime: DateTime(2024, 1, 15, 10, 0),
          emotionId: 'tlaloc_lluvia',
        );
        await insertDiaryEntryWithLocalTime(
          id: 'entry_2',
          localTime: DateTime(2024, 1, 16, 10, 0),
          emotionId: 'tlaloc_lluvia',
        );
        await insertDiaryEntryWithLocalTime(
          id: 'entry_3',
          localTime: DateTime(2024, 1, 17, 10, 0),
          emotionId: 'tlaloc_lluvia',
        );

        final result = await service.evaluateAndUnlockRelics();

        expect(result.hasNewVisits, isTrue);
        expect(result.newlyUnlockedRelics.length, 1);
        expect(result.newlyUnlockedRelics.first.relicId, 'relic_vasija_tlaloc');
        expect(result.allUnlockedRelics.length, 1);

        // Verificar en inventario
        final inventoryItem = await db.getInventoryItem('relic_vasija_tlaloc');
        expect(inventoryItem, isNotNull);
        expect(inventoryItem!['item_type'], 'RELIC');
        expect(inventoryItem['quantity'], 1);
      });
    });

    group('Xochiquétzal (relic_mariposas_xochiquetzal): 3+ cosechas históricas', () {
      test('Ciclo real: plantar, regar hasta florecer y cosechar+limpiar 3 plantas secuencialmente', () async {
        // Usar semilla que necesita 3 riegos y tiene afinidad con tlaloc_lluvia
        const seedId = 'semilla_maiz_azul'; // wateringsNeeded: 3, affinity: tlaloc_lluvia

        // --- Planta 1 ---
        await chinampaController.plantSeedInSlot(
          slotIndex: 0, seedId: seedId, consumeFromInventory: false);
        await chinampaController.waterActivePlants(emotionId: 'tlaloc_lluvia'); // +2 (afinidad) = 2
        await chinampaController.waterActivePlants(emotionId: 'tlaloc_lluvia'); // +2 = 4 (florece en 3)
        await chinampaController.harvestAndClearSlot(0, clearImmediately: true);

        // --- Planta 2 ---
        await chinampaController.plantSeedInSlot(
          slotIndex: 1, seedId: seedId, consumeFromInventory: false);
        await chinampaController.waterActivePlants(emotionId: 'tlaloc_lluvia'); // +2 = 2
        await chinampaController.waterActivePlants(emotionId: 'tlaloc_lluvia'); // +2 = 4
        await chinampaController.harvestAndClearSlot(1, clearImmediately: true);

        // --- Planta 3 ---
        await chinampaController.plantSeedInSlot(
          slotIndex: 2, seedId: seedId, consumeFromInventory: false);
        await chinampaController.waterActivePlants(emotionId: 'tlaloc_lluvia'); // +2 = 2
        await chinampaController.waterActivePlants(emotionId: 'tlaloc_lluvia'); // +2 = 4
        await chinampaController.harvestAndClearSlot(2, clearImmediately: true);

        // Verificar contador en BD
        final counter = await db.getHarvestCounter();
        expect(counter, 3);

        // Evaluar desbloqueo
        final result = await service.evaluateAndUnlockRelics();

        expect(result.hasNewVisits, isTrue);
        expect(result.newlyUnlockedRelics.length, 1);
        expect(result.newlyUnlockedRelics.first.relicId, 'relic_mariposas_xochiquetzal');
        expect(result.allUnlockedRelics.length, 1);
      });

      test('Llamar harvestAndClearSlot dos veces sobre la misma planta (primero sin limpiar y luego limpiando) solo suma +1', () async {
        const seedId = 'semilla_maiz_azul';

        // Plantar y regar hasta florecer
        await chinampaController.plantSeedInSlot(
          slotIndex: 0, seedId: seedId, consumeFromInventory: false);
        await chinampaController.waterActivePlants(emotionId: 'tlaloc_lluvia');
        await chinampaController.waterActivePlants(emotionId: 'tlaloc_lluvia');

        // Primera cosecha SIN limpiar
        await chinampaController.harvestAndClearSlot(0, clearImmediately: false);

        // Segunda cosecha CON limpiar (misma planta ya cosechada)
        await chinampaController.harvestAndClearSlot(0, clearImmediately: true);

        // El contador debe ser 1, no 2
        final counter = await db.getHarvestCounter();
        expect(counter, 1);
      });
    });

    group('Xólotl (relic_xolotl_companion) - Vía A: entrada después de 21:00 local', () {
      test('Insertar entrada con hora local 21:00 desbloquea a Xólotl', () async {
        await insertDiaryEntryWithLocalTime(
          id: 'entry_1',
          localTime: DateTime(2024, 1, 15, 21, 0), // Exactamente 21:00
          emotionId: 'alegría',
        );

        final result = await service.evaluateAndUnlockRelics();

        expect(result.hasNewVisits, isTrue);
        expect(result.newlyUnlockedRelics.length, 1);
        expect(result.newlyUnlockedRelics.first.relicId, 'relic_xolotl_companion');
      });

      test('Insertar entrada con hora local 23:30 desbloquea a Xólotl', () async {
        await insertDiaryEntryWithLocalTime(
          id: 'entry_1',
          localTime: DateTime(2024, 1, 15, 23, 30),
          emotionId: 'tristeza',
        );

        final result = await service.evaluateAndUnlockRelics();

        expect(result.hasNewVisits, isTrue);
        expect(result.newlyUnlockedRelics.first.relicId, 'relic_xolotl_companion');
      });

      test('Entrada a las 20:59 con otra emoción NO desbloquea a Xólotl', () async {
        await insertDiaryEntryWithLocalTime(
          id: 'entry_1',
          localTime: DateTime(2024, 1, 15, 20, 59), // 20:59 < 21
          emotionId: 'alegría',
        );

        final result = await service.evaluateAndUnlockRelics();

        expect(result.hasNewVisits, isFalse);
        expect(result.newlyUnlockedRelics, isEmpty);
      });

      test('Evaluar con latestEntryLocalTime >= 21 desbloquea sin entrada en BD', () async {
        // Sin entradas en BD, pero pasando parámetro
        final result = await service.evaluateAndUnlockRelics(
          latestEntryLocalTime: DateTime(2024, 1, 15, 22, 0),
        );

        expect(result.hasNewVisits, isTrue);
        expect(result.newlyUnlockedRelics.first.relicId, 'relic_xolotl_companion');
      });

      test('Evaluar con latestEntryLocalTime 20:59 NO desbloquea', () async {
        final result = await service.evaluateAndUnlockRelics(
          latestEntryLocalTime: DateTime(2024, 1, 15, 20, 59),
        );

        expect(result.hasNewVisits, isFalse);
      });
    });

    group('Xólotl (relic_xolotl_companion) - Vía B: 2+ entradas metztli_noche', () {
      test('Con 1 entrada metztli_noche en horario diurno NO se desbloquea', () async {
        await insertDiaryEntryWithLocalTime(
          id: 'entry_1',
          localTime: DateTime(2024, 1, 15, 14, 0), // 14:00 (diurno)
          emotionId: 'metztli_noche',
        );

        final result = await service.evaluateAndUnlockRelics();

        expect(result.hasNewVisits, isFalse);
        expect(result.newlyUnlockedRelics, isEmpty);
      });

      test('Con 2.ª entrada metztli_noche en horario diurno SÍ se desbloquea', () async {
        await insertDiaryEntryWithLocalTime(
          id: 'entry_1',
          localTime: DateTime(2024, 1, 15, 14, 0),
          emotionId: 'metztli_noche',
        );
        await insertDiaryEntryWithLocalTime(
          id: 'entry_2',
          localTime: DateTime(2024, 1, 16, 14, 0),
          emotionId: 'metztli_noche',
        );

        final result = await service.evaluateAndUnlockRelics();

        expect(result.hasNewVisits, isTrue);
        expect(result.newlyUnlockedRelics.length, 1);
        expect(result.newlyUnlockedRelics.first.relicId, 'relic_xolotl_companion');
      });
    });

    group('Idempotencia: segunda evaluación no duplica reliquias', () {
      test('Tláloc: segunda llamada mantiene unlockedAt original y newlyUnlockedRelics vacío', () async {
        // Insertar 3 entradas tlaloc_lluvia
        for (int i = 1; i <= 3; i++) {
          await insertDiaryEntryWithLocalTime(
            id: 'entry_$i',
            localTime: DateTime(2024, 1, 14 + i, 10, 0),
            emotionId: 'tlaloc_lluvia',
          );
        }

        // Primera evaluación
        final result1 = await service.evaluateAndUnlockRelics();
        expect(result1.hasNewVisits, isTrue);
        final firstUnlockedAt = result1.newlyUnlockedRelics.first.unlockedAt;

        // Segunda evaluación
        final result2 = await service.evaluateAndUnlockRelics();
        expect(result2.hasNewVisits, isFalse);
        expect(result2.newlyUnlockedRelics, isEmpty);
        expect(result2.allUnlockedRelics.length, 1);

        // Verificar que unlockedAt no cambió
        expect(result2.allUnlockedRelics.first.unlockedAt, firstUnlockedAt);

        // Verificar en inventario que quantity sigue siendo 1
        final inventoryItem = await db.getInventoryItem('relic_vasija_tlaloc');
        expect(inventoryItem!['quantity'], 1);
      });

      test('Xochiquétzal: segunda llamada mantiene unlockedAt original', () async {
        const seedId = 'semilla_maiz_azul';

        // 3 cosechas
        for (int slot = 0; slot < 3; slot++) {
          await chinampaController.plantSeedInSlot(
            slotIndex: slot, seedId: seedId, consumeFromInventory: false);
          await chinampaController.waterActivePlants(emotionId: 'tlaloc_lluvia');
          await chinampaController.waterActivePlants(emotionId: 'tlaloc_lluvia');
          await chinampaController.harvestAndClearSlot(slot, clearImmediately: true);
        }

        final result1 = await service.evaluateAndUnlockRelics();
        final firstUnlockedAt = result1.newlyUnlockedRelics.first.unlockedAt;

        final result2 = await service.evaluateAndUnlockRelics();
        expect(result2.hasNewVisits, isFalse);
        expect(result2.allUnlockedRelics.first.unlockedAt, firstUnlockedAt);
      });

      test('Xólotl: segunda llamada mantiene unlockedAt original', () async {
        await insertDiaryEntryWithLocalTime(
          id: 'entry_1',
          localTime: DateTime(2024, 1, 15, 22, 0),
          emotionId: 'alegría',
        );

        final result1 = await service.evaluateAndUnlockRelics();
        final firstUnlockedAt = result1.newlyUnlockedRelics.first.unlockedAt;

        final result2 = await service.evaluateAndUnlockRelics();
        expect(result2.hasNewVisits, isFalse);
        expect(result2.allUnlockedRelics.first.unlockedAt, firstUnlockedAt);
      });
    });
  });
}

/// Carga un catálogo de semillas mínimo para tests.
Future<Map<String, SeedCatalogItem>> _loadTestSeedCatalog() async {
  // Semilla de maíz azul: 3 riegos, afinidad con tlaloc_lluvia
  return {
    'semilla_maiz_azul': SeedCatalogItem(
      seedId: 'semilla_maiz_azul',
      name: 'Maíz Azul Sagrado',
      rarity: SeedRarity.sagrada,
      wateringsNeeded: 3,
      affinityEmotion: 'tlaloc_lluvia',
      description: 'Crece con la bendición de Tláloc.',
      spriteStages: const ['semilla', 'brote', 'planta', 'flor'],
    ),
  };
}