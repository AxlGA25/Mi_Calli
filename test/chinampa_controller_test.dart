// Tests para ChinampaController usando SQLite FFI real.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mi_calli/core/database/local_database_service.dart';
import 'package:mi_calli/core/database/secure_storage_mock.dart';
import 'package:mi_calli/features/2_gamification/controllers/chinampa_controller.dart';
import 'package:mi_calli/features/2_gamification/models/seed_catalog_item.dart';

void main() {
  // Inicializar binding de Flutter para usar rootBundle
  TestWidgetsFlutterBinding.ensureInitialized();

  // Inicializar sqflite FFI para tests de escritorio
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempDir;
  late SecureStorageMock mockStorage;
  late LocalDatabaseService databaseService;
  late ChinampaController controller;
  late Map<String, SeedCatalogItem> seedCatalog;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Cargar catálogo real desde assets una sola vez
    final jsonString = await rootBundle.loadString('assets/data/seeds_catalog.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    seedCatalog = <String, SeedCatalogItem>{};
    for (final item in jsonList) {
      final seed = SeedCatalogItem.fromJson(item as Map<String, dynamic>);
      seedCatalog[seed.seedId] = seed;
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mi_calli_chinampa_test_');
    mockStorage = SecureStorageMock();
    databaseService = LocalDatabaseService.createForTesting(
      secureStorage: mockStorage,
      databasePath: path.join(tempDir.path, 'test.db'),
      databaseFactory: databaseFactoryFfi,
    );
    await databaseService.initialize();

    controller = ChinampaController(databaseService, seedCatalog);
  });

  tearDown(() async {
    await databaseService.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Estado inicial de los 4 slots en SQLite', () {
    test('getSlots() devuelve exactamente 4 slots (0,1,2,3) vacíos', () async {
      final slots = await controller.getSlots();

      expect(slots.length, equals(4));
      for (int i = 0; i < 4; i++) {
        final slot = slots[i];
        expect(slot.slotIndex, equals(i));
        expect(slot.isEmpty, isTrue);
        expect(slot.seedId, isNull);
        expect(slot.currentWaterings, equals(0));
        expect(slot.isHarvested, isFalse);
        expect(slot.plantedAt, isNull);
        expect(slot.growthProgress, equals(0.0));
        expect(slot.currentSpriteStage, isNull);
        expect(slot.isReadyToBloom, isFalse);
        expect(slot.catalogItem, isNull);
      }
    });
  });

  group('Plantar semilla con y sin inventario (plantSeedInSlot)', () {
    test('con consumeFromInventory=true y semilla en inventario: planta y descuenta', () async {
      // Verificar que seed_cempasuchil viene con quantity 1 en la DB inicial
      // (Nota: la DB inicial no tiene semillas por defecto, así que insertamos una)
      await databaseService.upsertInventoryItem(
        itemId: 'seed_cempasuchil',
        itemType: 'SEED',
        quantity: 1,
        unlockedAt: DateTime.now().toUtc(),
      );

      final result = await controller.plantSeedInSlot(
        slotIndex: 0,
        seedId: 'seed_cempasuchil',
        consumeFromInventory: true,
      );

      expect(result.slotIndex, equals(0));
      expect(result.seedId, equals('seed_cempasuchil'));
      expect(result.currentWaterings, equals(0));
      expect(result.isHarvested, isFalse);
      expect(result.catalogItem?.seedId, equals('seed_cempasuchil'));
      expect(result.catalogItem?.wateringsNeeded, equals(3));
      expect(result.catalogItem?.affinityEmotion, equals('tlaloc_lluvia'));

      // Verificar que el inventario se descontó a 0
      final inventory = await databaseService.getInventory();
      final seedEntry = inventory.firstWhere(
        (item) => item['item_id'] == 'seed_cempasuchil' && item['item_type'] == 'SEED',
        orElse: () => <String, dynamic>{},
      );
      expect(seedEntry['quantity'], equals(0));
    });

    test('con consumeFromInventory=true y quantity=0: lanza ChinampaStateError', () async {
      // Asegurar que el inventario está en 0
      await databaseService.upsertInventoryItem(
        itemId: 'seed_cempasuchil',
        itemType: 'SEED',
        quantity: 0,
        unlockedAt: DateTime.now().toUtc(),
      );

      expect(
        () => controller.plantSeedInSlot(
          slotIndex: 0,
          seedId: 'seed_cempasuchil',
          consumeFromInventory: true,
        ),
        throwsA(isA<ChinampaStateError>()),
      );
    });

    test('con consumeFromInventory=false: planta sin tocar inventario', () async {
      // No insertar nada en inventario
      final result = await controller.plantSeedInSlot(
        slotIndex: 1,
        seedId: 'seed_nopal_tunas',
        consumeFromInventory: false,
      );

      expect(result.slotIndex, equals(1));
      expect(result.seedId, equals('seed_nopal_tunas'));

      // Inventario no debe haberse modificado (sigue vacío)
      final inventory = await databaseService.getInventory();
      final seedEntry = inventory.firstWhere(
        (item) => item['item_id'] == 'seed_nopal_tunas' && item['item_type'] == 'SEED',
        orElse: () => <String, dynamic>{},
      );
      expect(seedEntry.isEmpty, isTrue);
    });

    test('slot con planta activa sin cosechar: lanza ChinampaStateError', () async {
      // Plantar primera semilla
      await controller.plantSeedInSlot(
        slotIndex: 0,
        seedId: 'seed_cempasuchil',
        consumeFromInventory: false,
      );

      // Intentar plantar otra en el mismo slot
      expect(
        () => controller.plantSeedInSlot(
          slotIndex: 0,
          seedId: 'seed_maiz_morado',
          consumeFromInventory: false,
        ),
        throwsA(isA<ChinampaStateError>()),
      );
    });

    test('slot cosechado (isHarvested=true) permite plantar encima', () async {
      // Plantar y regar hasta florecer
      await controller.plantSeedInSlot(
        slotIndex: 0,
        seedId: 'seed_cempasuchil',
        consumeFromInventory: false,
      );
      await controller.waterActivePlants(emotionId: 'tlaloc_lluvia'); // +2 -> 2/3
      await controller.waterActivePlants(emotionId: 'tlaloc_lluvia'); // +2 -> 4/3 (florece)

      // Cosechar con clearImmediately=true
      await controller.harvestAndClearSlot(0, clearImmediately: true);

      // Ahora plantar nueva semilla
      final result = await controller.plantSeedInSlot(
        slotIndex: 0,
        seedId: 'seed_maiz_morado',
        consumeFromInventory: false,
      );

      expect(result.seedId, equals('seed_maiz_morado'));
    });

    test('slotIndex fuera de 0..3: lanza ArgumentError', () async {
      expect(
        () => controller.plantSeedInSlot(
          slotIndex: -1,
          seedId: 'seed_cempasuchil',
          consumeFromInventory: false,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => controller.plantSeedInSlot(
          slotIndex: 4,
          seedId: 'seed_cempasuchil',
          consumeFromInventory: false,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('seedId inexistente en catálogo: lanza ArgumentError', () async {
      expect(
        () => controller.plantSeedInSlot(
          slotIndex: 0,
          seedId: 'seed_inexistente',
          consumeFromInventory: false,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('Riego normal (+1) vs. riego doble por afinidad emocional (+2)', () {
    test('waterActivePlants aplica afinidad correctamente en 3 slots simultáneos', () async {
      // Plantar 3 semillas con distintas afinidades
      await controller.plantSeedInSlot(
        slotIndex: 0,
        seedId: 'seed_cempasuchil', // wateringsNeeded: 3, affinity: tlaloc_lluvia
        consumeFromInventory: false,
      );
      await controller.plantSeedInSlot(
        slotIndex: 1,
        seedId: 'seed_maiz_morado', // wateringsNeeded: 3, affinity: tonatiuh_sol
        consumeFromInventory: false,
      );
      await controller.plantSeedInSlot(
        slotIndex: 2,
        seedId: 'seed_maguey', // wateringsNeeded: 4, affinity: ehecatl_viento
        consumeFromInventory: false,
      );

      // Riego con emoción tlaloc_lluvia (afín a cempasúchil)
      final summary = await controller.waterActivePlants(emotionId: 'tlaloc_lluvia');

      // Verificar resumen
      expect(summary.wateredSlots.length, equals(3));
      expect(summary.newlyBloomedSlots.length, equals(0));

      // Slot 0: seed_cempasuchil -> afinidad SÍ -> +2
      final slot0Result = summary.wateredSlots.firstWhere((r) => r.slotIndex == 0);
      expect(slot0Result.seedId, equals('seed_cempasuchil'));
      expect(slot0Result.hadAffinity, isTrue);
      expect(slot0Result.waterAdded, equals(2));
      expect(slot0Result.previousWaterings, equals(0));
      expect(slot0Result.newWaterings, equals(2));
      expect(slot0Result.wateringsNeeded, equals(3));
      expect(slot0Result.justBloomed, isFalse);

      // Slot 1: seed_maiz_morado -> afinidad NO -> +1
      final slot1Result = summary.wateredSlots.firstWhere((r) => r.slotIndex == 1);
      expect(slot1Result.seedId, equals('seed_maiz_morado'));
      expect(slot1Result.hadAffinity, isFalse);
      expect(slot1Result.waterAdded, equals(1));
      expect(slot1Result.previousWaterings, equals(0));
      expect(slot1Result.newWaterings, equals(1));
      expect(slot1Result.wateringsNeeded, equals(3));
      expect(slot1Result.justBloomed, isFalse);

      // Slot 2: seed_maguey -> afinidad NO -> +1
      final slot2Result = summary.wateredSlots.firstWhere((r) => r.slotIndex == 2);
      expect(slot2Result.seedId, equals('seed_maguey'));
      expect(slot2Result.hadAffinity, isFalse);
      expect(slot2Result.waterAdded, equals(1));
      expect(slot2Result.previousWaterings, equals(0));
      expect(slot2Result.newWaterings, equals(1));
      expect(slot2Result.wateringsNeeded, equals(4));
      expect(slot2Result.justBloomed, isFalse);

      // Slot 3 (vacío) no aparece en wateredSlots
      expect(summary.wateredSlots.any((r) => r.slotIndex == 3), isFalse);

      // Verificar estados de slots actualizados
      final updatedSlots = summary.slots;
      expect(updatedSlots[0].currentWaterings, equals(2));
      expect(updatedSlots[1].currentWaterings, equals(1));
      expect(updatedSlots[2].currentWaterings, equals(1));
      expect(updatedSlots[3].isEmpty, isTrue);
    });

    test('slot vacío no se riega ni aparece en wateredSlots', () async {
      // Solo plantar en slot 0
      await controller.plantSeedInSlot(
        slotIndex: 0,
        seedId: 'seed_cempasuchil',
        consumeFromInventory: false,
      );

      final summary = await controller.waterActivePlants(emotionId: 'tlaloc_lluvia');

      expect(summary.wateredSlots.length, equals(1));
      expect(summary.wateredSlots.first.slotIndex, equals(0));
    });
  });

  group('Floración (justBloomed, newlyBloomedSlots y wateringsNeeded 3 y 4)', () {
    test('segundo riego con afinidad correcta hace florecer y marca justBloomed', () async {
      // Plantar: cempasúchil (afín a tlaloc_lluvia, needs 3), maíz morado (afín a tonatiuh_sol, needs 3), maguey (afín a ehecatl_viento, needs 4)
      await controller.plantSeedInSlot(slotIndex: 0, seedId: 'seed_cempasuchil', consumeFromInventory: false);
      await controller.plantSeedInSlot(slotIndex: 1, seedId: 'seed_maiz_morado', consumeFromInventory: false);
      await controller.plantSeedInSlot(slotIndex: 2, seedId: 'seed_maguey', consumeFromInventory: false);

      // Primer riego: tlaloc_lluvia
      // cempasúchil: +2 -> 2/3
      // maíz morado: +1 -> 1/3
      // maguey: +1 -> 1/4
      await controller.waterActivePlants(emotionId: 'tlaloc_lluvia');

      // Segundo riego: tonatiuh_sol
      // cempasúchil (2/3): +1 -> 3/3 -> FLORECE (justBloomed)
      // maíz morado (1/3): +2 (afín) -> 3/3 -> FLORECE (justBloomed)
      // maguey (1/4): +1 -> 2/4 -> NO florece
      final summary = await controller.waterActivePlants(emotionId: 'tonatiuh_sol');

      expect(summary.newlyBloomedSlots.length, equals(2));

      // Slot 0: cempasúchil florece
      final cempasuchilResult = summary.newlyBloomedSlots.firstWhere((r) => r.slotIndex == 0);
      expect(cempasuchilResult.seedId, equals('seed_cempasuchil'));
      expect(cempasuchilResult.previousWaterings, equals(2));
      expect(cempasuchilResult.newWaterings, equals(3));
      expect(cempasuchilResult.justBloomed, isTrue);
      expect(cempasuchilResult.hadAffinity, isFalse); // tlaloc_lluvia != tonatiuh_sol

      // Slot 1: maíz morado florece
      final maizResult = summary.newlyBloomedSlots.firstWhere((r) => r.slotIndex == 1);
      expect(maizResult.seedId, equals('seed_maiz_morado'));
      expect(maizResult.previousWaterings, equals(1));
      expect(maizResult.newWaterings, equals(3));
      expect(maizResult.justBloomed, isTrue);
      expect(maizResult.hadAffinity, isTrue); // tonatiuh_sol == tonatiuh_sol

      // Slot 2: maguey NO florece
      expect(summary.newlyBloomedSlots.any((r) => r.slotIndex == 2), isFalse);

      final magueyResult = summary.wateredSlots.firstWhere((r) => r.slotIndex == 2);
      expect(magueyResult.previousWaterings, equals(1));
      expect(magueyResult.newWaterings, equals(2));
      expect(magueyResult.justBloomed, isFalse);

      // Verificar isReadyToBloom en slots actualizados
      final slots = summary.slots;
      expect(slots[0].isReadyToBloom, isTrue);
      expect(slots[1].isReadyToBloom, isTrue);
      expect(slots[2].isReadyToBloom, isFalse);
    });

    test('planta que ya había florecido no vuelve a marcar justBloomed en riego posterior', () async {
      await controller.plantSeedInSlot(slotIndex: 0, seedId: 'seed_cempasuchil', consumeFromInventory: false);

      // Primer riego: 0 -> 2/3 (no florece)
      var summary = await controller.waterActivePlants(emotionId: 'tlaloc_lluvia');
      expect(summary.newlyBloomedSlots.length, equals(0));

      // Segundo riego: 2 -> 4/3 (FLORECE por primera vez)
      summary = await controller.waterActivePlants(emotionId: 'tlaloc_lluvia');
      expect(summary.newlyBloomedSlots.length, equals(1));
      final bloomResult = summary.newlyBloomedSlots.firstWhere((r) => r.slotIndex == 0);
      expect(bloomResult.justBloomed, isTrue);
      expect(bloomResult.previousWaterings, equals(2));
      expect(bloomResult.newWaterings, equals(4));

      // Tercer riego (ya florecida): 4 -> 6/3 (NO debe marcar justBloomed)
      summary = await controller.waterActivePlants(emotionId: 'tlaloc_lluvia');
      final slot0Result = summary.wateredSlots.firstWhere((r) => r.slotIndex == 0);
      expect(slot0Result.justBloomed, isFalse);
      expect(slot0Result.previousWaterings, equals(4));
      expect(slot0Result.newWaterings, equals(6));
      // newlyBloomedSlots no debe incluirla
      expect(summary.newlyBloomedSlots.any((r) => r.slotIndex == 0), isFalse);
    });
  });

  group('Etapas de sprites (currentSpriteStage) y growthProgress', () {
    test('progresión de sprites seed_cacao (4 riegos) con riegos +1', () async {
      await controller.plantSeedInSlot(
        slotIndex: 0,
        seedId: 'seed_cacao', // wateringsNeeded: 4, affinity: tonatiuh_sol, sprites: [cacao_0, cacao_1, cacao_2, cacao_3_full]
        consumeFromInventory: false,
      );

      // 0 riegos -> cacao_0.png
      var slots = await controller.getSlots();
      expect(slots[0].currentSpriteStage, equals('cacao_0.png'));

      // 1 riego (sin afinidad: metztli_noche) -> cacao_1.png
      await controller.waterActivePlants(emotionId: 'metztli_noche');
      slots = await controller.getSlots();
      expect(slots[0].currentWaterings, equals(1));
      expect(slots[0].currentSpriteStage, equals('cacao_1.png'));
      expect(slots[0].growthProgress, closeTo(0.25, 0.01));

      // 2 riegos -> cacao_1.png o cacao_2.png (índice 1 o 2)
      await controller.waterActivePlants(emotionId: 'metztli_noche');
      slots = await controller.getSlots();
      expect(slots[0].currentWaterings, equals(2));
      expect(['cacao_1.png', 'cacao_2.png'], contains(slots[0].currentSpriteStage));
      expect(slots[0].growthProgress, closeTo(0.5, 0.01));

      // 3 riegos -> cacao_2.png (índice 2, NUNCA cacao_3_full.png)
      await controller.waterActivePlants(emotionId: 'metztli_noche');
      slots = await controller.getSlots();
      expect(slots[0].currentWaterings, equals(3));
      expect(slots[0].currentSpriteStage, equals('cacao_2.png'));
      expect(slots[0].growthProgress, closeTo(0.75, 0.01));
      expect(slots[0].isReadyToBloom, isFalse);

      // 4 riegos -> cacao_3_full.png (flor completa)
      await controller.waterActivePlants(emotionId: 'metztli_noche');
      slots = await controller.getSlots();
      expect(slots[0].currentWaterings, equals(4));
      expect(slots[0].currentSpriteStage, equals('cacao_3_full.png'));
      expect(slots[0].growthProgress, equals(1.0));
      expect(slots[0].isReadyToBloom, isTrue);
    });

    test('progresión de sprites seed_cempasuchil (3 riegos) con riegos +1', () async {
      await controller.plantSeedInSlot(
        slotIndex: 0,
        seedId: 'seed_cempasuchil', // wateringsNeeded: 3, sprites: [cemp_0, cemp_1, cemp_2, cemp_3_full]
        consumeFromInventory: false,
      );

      // 0 riegos -> cemp_0.png
      var slots = await controller.getSlots();
      expect(slots[0].currentSpriteStage, equals('cemp_0.png'));

      // 1 riego -> cemp_1.png
      await controller.waterActivePlants(emotionId: 'metztli_noche'); // sin afinidad
      slots = await controller.getSlots();
      expect(slots[0].currentWaterings, equals(1));
      expect(slots[0].currentSpriteStage, equals('cemp_1.png'));

      // 2 riegos -> cemp_1.png o cemp_2.png
      await controller.waterActivePlants(emotionId: 'metztli_noche');
      slots = await controller.getSlots();
      expect(slots[0].currentWaterings, equals(2));
      expect(['cemp_1.png', 'cemp_2.png'], contains(slots[0].currentSpriteStage));

      // 3 riegos -> cemp_3_full.png (florece)
      await controller.waterActivePlants(emotionId: 'metztli_noche');
      slots = await controller.getSlots();
      expect(slots[0].currentWaterings, equals(3));
      expect(slots[0].currentSpriteStage, equals('cemp_3_full.png'));
      expect(slots[0].isReadyToBloom, isTrue);
    });

    test('isHarvested=true devuelve sprite final (full)', () async {
      await controller.plantSeedInSlot(
        slotIndex: 0,
        seedId: 'seed_cempasuchil',
        consumeFromInventory: false,
      );
      await controller.waterActivePlants(emotionId: 'tlaloc_lluvia'); // +2 -> 2/3
      await controller.waterActivePlants(emotionId: 'tlaloc_lluvia'); // +2 -> 4/3 (florece)

      // Cosechar sin limpiar
      await controller.harvestAndClearSlot(0, clearImmediately: false);

      final slots = await controller.getSlots();
      expect(slots[0].isHarvested, isTrue);
      expect(slots[0].currentSpriteStage, equals('cemp_3_full.png'));
    });
  });

  group('Cosecha, limpieza y replantado (harvestAndClearSlot)', () {
    test('cosechar slot vacío: lanza ChinampaStateError', () async {
      expect(
        () => controller.harvestAndClearSlot(0),
        throwsA(isA<ChinampaStateError>()),
      );
    });

    test('cosechar planta sin wateringsNeeded: lanza ChinampaStateError', () async {
      await controller.plantSeedInSlot(
        slotIndex: 0,
        seedId: 'seed_cempasuchil', // needs 3
        consumeFromInventory: false,
      );
      // Solo 1 riego -> 1/3
      await controller.waterActivePlants(emotionId: 'metztli_noche');

      expect(
        () => controller.harvestAndClearSlot(0),
        throwsA(isA<ChinampaStateError>()),
      );
    });

    test('cosechar planta lista con clearImmediately=false: marca isHarvested, no se riega luego', () async {
      await controller.plantSeedInSlot(
        slotIndex: 0,
        seedId: 'seed_cempasuchil',
        consumeFromInventory: false,
      );
      await controller.waterActivePlants(emotionId: 'tlaloc_lluvia'); // 2/3
      await controller.waterActivePlants(emotionId: 'tlaloc_lluvia'); // 4/3 (florece)

      await controller.harvestAndClearSlot(0, clearImmediately: false);

      // Verificar estado cosechado
      var slots = await controller.getSlots();
      expect(slots[0].isHarvested, isTrue);
      expect(slots[0].seedId, equals('seed_cempasuchil'));
      expect(slots[0].currentWaterings, equals(4));

      // Riego posterior NO debe regar la planta cosechada
      final summary = await controller.waterActivePlants(emotionId: 'tlaloc_lluvia');
      expect(summary.wateredSlots.any((r) => r.slotIndex == 0), isFalse);

      // Slot 0 sigue cosechado
      slots = await controller.getSlots();
      expect(slots[0].isHarvested, isTrue);
    });

    test('cosechar con clearImmediately=true: limpia slot y permite replantar', () async {
      await controller.plantSeedInSlot(
        slotIndex: 0,
        seedId: 'seed_cempasuchil',
        consumeFromInventory: false,
      );
      await controller.waterActivePlants(emotionId: 'tlaloc_lluvia');
      await controller.waterActivePlants(emotionId: 'tlaloc_lluvia');

      await controller.harvestAndClearSlot(0, clearImmediately: true);

      // Slot limpio
      var slots = await controller.getSlots();
      expect(slots[0].isEmpty, isTrue);
      expect(slots[0].seedId, isNull);
      expect(slots[0].isHarvested, isFalse);

      // Replantar nueva semilla
      final result = await controller.plantSeedInSlot(
        slotIndex: 0,
        seedId: 'seed_maiz_morado',
        consumeFromInventory: false,
      );
      expect(result.seedId, equals('seed_maiz_morado'));
    });

    test('plantar encima de slot con isHarvested=true (sin clearImmediately) limpia y replanta', () async {
      await controller.plantSeedInSlot(
        slotIndex: 0,
        seedId: 'seed_cempasuchil',
        consumeFromInventory: false,
      );
      await controller.waterActivePlants(emotionId: 'tlaloc_lluvia');
      await controller.waterActivePlants(emotionId: 'tlaloc_lluvia');

      await controller.harvestAndClearSlot(0, clearImmediately: false);

      // Plantar directamente encima (debe funcionar porque isHarvested=true)
      final result = await controller.plantSeedInSlot(
        slotIndex: 0,
        seedId: 'seed_nopal_tunas',
        consumeFromInventory: false,
      );
      expect(result.seedId, equals('seed_nopal_tunas'));
      expect(result.currentWaterings, equals(0));
      expect(result.isHarvested, isFalse);
    });

    test('slotIndex inválido en harvestAndClearSlot: lanza ArgumentError', () async {
      expect(
        () => controller.harvestAndClearSlot(-1),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => controller.harvestAndClearSlot(4),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('Integración completa: ciclo de vida de una chinampa', () {
    test('ciclo completo: plantar -> regar -> florecer -> cosechar -> limpiar -> replantar', () async {
      // 1. Estado inicial
      var slots = await controller.getSlots();
      expect(slots.every((s) => s.isEmpty), isTrue);

      // 2. Plantar 4 semillas distintas
      await controller.plantSeedInSlot(slotIndex: 0, seedId: 'seed_cempasuchil', consumeFromInventory: false);
      await controller.plantSeedInSlot(slotIndex: 1, seedId: 'seed_nopal_tunas', consumeFromInventory: false);
      await controller.plantSeedInSlot(slotIndex: 2, seedId: 'seed_maiz_morado', consumeFromInventory: false);
      await controller.plantSeedInSlot(slotIndex: 3, seedId: 'seed_dalia', consumeFromInventory: false);

      slots = await controller.getSlots();
      expect(slots.every((s) => !s.isEmpty), isTrue);

      // 3. Riego múltiple hasta florecer todas
      // cempasúchil (afín tlaloc_lluvia, needs 3): +2 cada riego tlaloc
      // nopal (afín mixcoatl_tormenta, needs 3): +2 cada riego mixcoatl
      // maíz (afín tonatiuh_sol, needs 3): +2 cada riego tonatiuh
      // dalia (afín tlaloc_lluvia, needs 3): +2 cada riego tlaloc

      // Riego 1: tlaloc_lluvia
      // cempasúchil: +2 (2/3), nopal: +1 (1/3), maíz: +1 (1/3), dalia: +2 (2/3)
      await controller.waterActivePlants(emotionId: 'tlaloc_lluvia');

      // Riego 2: mixcoatl_tormenta
      // cempasúchil: +1 (3/3 FLORECE), nopal: +2 (3/3 FLORECE), maíz: +1 (2/3), dalia: +1 (3/3 FLORECE)
      var summary = await controller.waterActivePlants(emotionId: 'mixcoatl_tormenta');
      expect(summary.newlyBloomedSlots.length, equals(3)); // slots 0, 1, 3

      // Riego 3: tonatiuh_sol
      // maíz: +2 (4/3 FLORECE)
      summary = await controller.waterActivePlants(emotionId: 'tonatiuh_sol');
      expect(summary.newlyBloomedSlots.length, equals(1)); // slot 2

      // 4. Verificar todas listas para cosechar
      slots = await controller.getSlots();
      expect(slots.every((s) => s.isReadyToBloom), isTrue);

      // 5. Cosechar todas con clearImmediately=true
      for (int i = 0; i < 4; i++) {
        await controller.harvestAndClearSlot(i, clearImmediately: true);
      }

      // 6. Verificar slots vacíos
      slots = await controller.getSlots();
      expect(slots.every((s) => s.isEmpty), isTrue);

      // 7. Replantar nuevas semillas
      await controller.plantSeedInSlot(slotIndex: 0, seedId: 'seed_maguey', consumeFromInventory: false);
      await controller.plantSeedInSlot(slotIndex: 1, seedId: 'seed_cacao', consumeFromInventory: false);
      await controller.plantSeedInSlot(slotIndex: 2, seedId: 'seed_vainilla', consumeFromInventory: false);
      await controller.plantSeedInSlot(slotIndex: 3, seedId: 'seed_nopal_tunas', consumeFromInventory: false);

      slots = await controller.getSlots();
      expect(slots[0].seedId, equals('seed_maguey'));
      expect(slots[1].seedId, equals('seed_cacao'));
      expect(slots[2].seedId, equals('seed_vainilla'));
      expect(slots[3].seedId, equals('seed_nopal_tunas'));
    });
  });
}