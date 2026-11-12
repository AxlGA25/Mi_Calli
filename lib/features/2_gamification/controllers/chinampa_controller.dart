// Controlador de la Chinampa Sagrada (jardín de 4 slots).
//
// Gestiona plantado, riego emocional, cosecha y limpieza de slots.
// Usa [LocalDatabaseService] para persistencia y catálogo de semillas para reglas de juego.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

import 'package:mi_calli/core/database/local_database_service.dart';
import 'package:mi_calli/features/1_sanctuary_journal/data/diary_repository_provider.dart';
import 'package:mi_calli/features/2_gamification/models/chinampa_models.dart';
import 'package:mi_calli/features/2_gamification/models/seed_catalog_item.dart';

/// Excepción para errores de estado inválido en la chinampa.
class ChinampaStateError extends StateError {
  ChinampaStateError(super.message);
}

/// Servicio/Controlador principal de la Chinampa Sagrada.
class ChinampaController {
  ChinampaController(this._db, this._seedCatalog);

  final LocalDatabaseService _db;
  final Map<String, SeedCatalogItem> _seedCatalog;

  /// Mapa de afinidades: seedId -> affinityEmotion (para db.waterPlants).
  Map<String, String> get _seedAffinities =>
      _seedCatalog.map((k, v) => MapEntry(k, v.affinityEmotion));

  /// Obtiene los 4 slots actuales con su catálogo enlazado.
  ///
  /// Siempre devuelve lista de 4 elementos ordenados por slotIndex (0..3).
  Future<List<ChinampaSlotState>> getSlots() async {
    final rows = await _db.getAllChinampaSlots();
    final slots = <ChinampaSlotState>[];

    for (int i = 0; i < 4; i++) {
      final row = rows.firstWhere(
        (r) => r['slot_index'] == i,
        orElse: () => <String, dynamic>{
          'slot_index': i,
          'seed_id': null,
          'current_waterings': 0,
          'is_harvested': 0,
          'planted_at': null,
        },
      );
      final catalogItem = row['seed_id'] != null
          ? _seedCatalog[row['seed_id'] as String]
          : null;
      slots.add(ChinampaSlotState.fromMap(row, catalogItem: catalogItem));
    }

    return slots;
  }

  /// Planta una semilla en un slot.
  ///
  /// - [slotIndex]: 0 a 3.
  /// - [seedId]: debe existir en el catálogo.
  /// - [now]: timestamp de plantado (UTC), por defecto ahora.
  /// - [consumeFromInventory]: si true (default), descuenta 1 del inventario.
  ///
  /// Lanza [ArgumentError] si slotIndex inválido o seedId no existe.
  /// Lanza [ChinampaStateError] si el slot tiene planta activa sin cosechar.
  /// Lanza [ChinampaStateError] si consumeFromInventory=true y no hay semillas en inventario.
  Future<ChinampaSlotState> plantSeedInSlot({
    required int slotIndex,
    required String seedId,
    DateTime? now,
    bool consumeFromInventory = true,
  }) async {
    // Validar slotIndex
    if (slotIndex < 0 || slotIndex > 3) {
      throw ArgumentError('slotIndex debe estar entre 0 y 3, recibido: $slotIndex');
    }

    // Validar seedId en catálogo
    final catalogItem = _seedCatalog[seedId];
    if (catalogItem == null) {
      throw ArgumentError('seedId no existe en catálogo: $seedId');
    }

    // Verificar estado actual del slot
    final currentSlot = await _db.getChinampaSlot(slotIndex);
    final currentSeedId = currentSlot?['seed_id'] as String?;
    final isHarvested = (currentSlot?['is_harvested'] as int? ?? 0) == 1;

    if (currentSeedId != null && !isHarvested) {
      throw ChinampaStateError(
        'Slot $slotIndex ya tiene una planta activa ($currentSeedId). '
        'Cosecha y limpia antes de plantar otra.',
      );
    }

    // Verificar y consumir inventario
    if (consumeFromInventory) {
      final inventory = await _db.getInventory();
      final seedEntry = inventory.firstWhere(
        (item) => item['item_id'] == seedId && item['item_type'] == 'SEED',
        orElse: () => <String, dynamic>{},
      );
      final quantity = seedEntry['quantity'] as int? ?? 0;

      if (quantity <= 0) {
        throw ChinampaStateError('No tienes semillas "$seedId" en el inventario.');
      }

      // Decrementar quantity en 1
      await _db.upsertInventoryItem(
        itemId: seedId,
        itemType: 'SEED',
        quantity: quantity - 1,
        unlockedAt: DateTime.now().toUtc(),
      );
    }

    // Plantar en BD
    final plantedAt = (now ?? DateTime.now()).toUtc();
    await _db.plantSeed(
      slotIndex: slotIndex,
      seedId: seedId,
      plantedAt: plantedAt,
    );

    // Devolver estado actualizado
    return ChinampaSlotState(
      slotIndex: slotIndex,
      seedId: seedId,
      currentWaterings: 0,
      isHarvested: false,
      plantedAt: plantedAt,
      catalogItem: catalogItem,
    );
  }

  /// Riega todas las plantas activas según la emoción actual.
  ///
  /// - [emotionId]: ID de la emoción del check-in diario (ej. 'tlaloc_lluvia').
  ///
  /// Regla de afinidad (CONTEXT.md punto 4):
  /// - Si catalogItem.hasAffinityWith(emotionId) == true -> +2 riegos.
  /// - Sino -> +1 riego.
  ///
  /// Devuelve resumen con slots actualizados, cuáles se regaron y cuáles florecieron.
  Future<ChinampaWateringSummary> waterActivePlants({
    required String emotionId,
  }) async {
    // Obtener slots actuales
    final currentSlots = await getSlots();

    // Identificar slots activos (tienen semilla, no cosechados)
    final activeIndexes = <int>[];
    for (final slot in currentSlots) {
      if (!slot.isEmpty && !slot.isHarvested) {
        activeIndexes.add(slot.slotIndex);
      }
    }

    if (activeIndexes.isEmpty) {
      // No hay plantas activas para regar
      return ChinampaWateringSummary(
        slots: currentSlots,
        wateredSlots: [],
        newlyBloomedSlots: [],
      );
    }

    // Guardar estado previo para detectar florecimiento
    final previousWateringsMap = <int, int>{};
    final previousWateringsNeededMap = <int, int>{};
    final seedIdMap = <int, String>{};
    final catalogItemMap = <int, SeedCatalogItem>{};

    for (final slot in currentSlots) {
      if (activeIndexes.contains(slot.slotIndex)) {
        previousWateringsMap[slot.slotIndex] = slot.currentWaterings;
        previousWateringsNeededMap[slot.slotIndex] = slot.wateringsNeeded;
        if (slot.seedId != null) seedIdMap[slot.slotIndex] = slot.seedId!;
        if (slot.catalogItem != null) catalogItemMap[slot.slotIndex] = slot.catalogItem!;
      }
    }

    // Llamar a BD para regar (aplica +1/+2 según afinidad)
    await _db.waterPlants(
      slotIndexes: activeIndexes,
      currentEmotionId: emotionId,
      seedAffinities: _seedAffinities,
    );

    // Obtener slots actualizados
    final updatedSlots = await getSlots();

    // Construir resultados de riego
    final wateredResults = <SlotWateringResult>[];
    final newlyBloomedResults = <SlotWateringResult>[];

    for (final slot in updatedSlots) {
      if (!activeIndexes.contains(slot.slotIndex)) continue;

      final prevWaterings = previousWateringsMap[slot.slotIndex] ?? 0;
      final wateringsNeeded = previousWateringsNeededMap[slot.slotIndex] ?? 3;
      final seedId = seedIdMap[slot.slotIndex] ?? '';
      final catalogItem = catalogItemMap[slot.slotIndex];
      final hadAffinity = catalogItem?.hasAffinityWith(emotionId) ?? false;
      final waterAdded = hadAffinity ? 2 : 1;
      final newWaterings = slot.currentWaterings;
      final justBloomed = prevWaterings < wateringsNeeded && newWaterings >= wateringsNeeded;

      final result = SlotWateringResult(
        slotIndex: slot.slotIndex,
        seedId: seedId,
        waterAdded: waterAdded,
        previousWaterings: prevWaterings,
        newWaterings: newWaterings,
        wateringsNeeded: wateringsNeeded,
        hadAffinity: hadAffinity,
        justBloomed: justBloomed,
      );

      wateredResults.add(result);
      if (justBloomed) {
        newlyBloomedResults.add(result);
      }
    }

    return ChinampaWateringSummary(
      slots: updatedSlots,
      wateredSlots: wateredResults,
      newlyBloomedSlots: newlyBloomedResults,
    );
  }

  /// Cosecha (y opcionalmente limpia) un slot listo.
  ///
  /// - [slotIndex]: 0 a 3.
  /// - [clearImmediately]: si true, llama clearSlot después de harvestSlot.
  ///
  /// Lanza [ArgumentError] si slotIndex inválido.
  /// Lanza [ChinampaStateError] si el slot no tiene planta lista para cosechar.
  Future<ChinampaSlotState> harvestAndClearSlot(
    int slotIndex, {
    bool clearImmediately = false,
  }) async {
    if (slotIndex < 0 || slotIndex > 3) {
      throw ArgumentError('slotIndex debe estar entre 0 y 3, recibido: $slotIndex');
    }

    final currentSlot = await _db.getChinampaSlot(slotIndex);
    if (currentSlot == null) {
      throw ChinampaStateError('Slot $slotIndex no existe.');
    }

    final seedId = currentSlot['seed_id'] as String?;
    final isHarvested = (currentSlot['is_harvested'] as int? ?? 0) == 1;
    final currentWaterings = currentSlot['current_waterings'] as int? ?? 0;

    if (seedId == null) {
      throw ChinampaStateError('Slot $slotIndex está vacío, nada que cosechar.');
    }

    final catalogItem = _seedCatalog[seedId];
    final wateringsNeeded = catalogItem?.wateringsNeeded ?? 3;

    if (!isHarvested && currentWaterings < wateringsNeeded) {
      throw ChinampaStateError(
        'La planta en slot $slotIndex aún no está lista para cosechar '
        '($currentWaterings/$wateringsNeeded riegos).',
      );
    }

    final wasAlreadyHarvested = isHarvested;

    // Marcar como cosechado
    await _db.harvestSlot(slotIndex);

    // Incrementar contador histórico de cosechas (para reliquia de Xochiquétzal)
    // Solo si la planta NO estaba cosechada antes (evita doble conteo al llamar
    // harvestAndClearSlot dos veces: primero sin limpiar y luego limpiando).
    if (!wasAlreadyHarvested) {
      await _db.incrementHarvestCounter();
    }

    // Limpiar si se pide
    if (clearImmediately) {
      await _db.clearSlot(slotIndex);
    }

    // Devolver estado actualizado
    final updatedSlot = await _db.getChinampaSlot(slotIndex);
    final updatedCatalogItem = updatedSlot?['seed_id'] != null
        ? _seedCatalog[updatedSlot!['seed_id'] as String]
        : null;

    return ChinampaSlotState.fromMap(
      updatedSlot ?? currentSlot,
      catalogItem: updatedCatalogItem,
    );
  }

  /// Carga el catálogo de semillas desde assets/data/seeds_catalog.json.
  static Future<Map<String, SeedCatalogItem>> loadSeedCatalog() async {
    final jsonString = await rootBundle.loadString('assets/data/seeds_catalog.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    final catalog = <String, SeedCatalogItem>{};
    for (final item in jsonList) {
      final seed = SeedCatalogItem.fromJson(item as Map<String, dynamic>);
      catalog[seed.seedId] = seed;
    }
    return catalog;
  }
}

/// Provider del catálogo de semillas (cargado una vez al inicio).
final seedCatalogProvider = FutureProvider<Map<String, SeedCatalogItem>>((ref) async {
  return ChinampaController.loadSeedCatalog();
});

/// Provider del ChinampaController (requiere catálogo cargado).
final chinampaControllerProvider = Provider<ChinampaController>((ref) {
  final db = ref.watch(localDatabaseServiceProvider);
  final catalogAsync = ref.watch(seedCatalogProvider);
  // El catálogo se carga de forma síncrona aquí porque FutureProvider ya lo resolvió
  // En tiempo de build, usamos maybeWhen para manejar loading/error
  final catalog = catalogAsync.maybeWhen(
    data: (data) => data,
    orElse: () => <String, SeedCatalogItem>{},
  );
  return ChinampaController(db, catalog);
});

/// Provider reactivo de los 4 slots de la chinampa.
final chinampaSlotsProvider = FutureProvider<List<ChinampaSlotState>>((ref) async {
  final controller = ref.watch(chinampaControllerProvider);
  return controller.getSlots();
});

/// Provider para recargar slots tras operaciones (plantar, regar, cosechar).
final refreshChinampaSlotsProvider =
    FutureProvider.autoDispose<List<ChinampaSlotState>>((ref) async {
  final controller = ref.watch(chinampaControllerProvider);
  return controller.getSlots();
});