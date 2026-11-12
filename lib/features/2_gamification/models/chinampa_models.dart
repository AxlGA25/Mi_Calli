// Modelos para la Chinampa Sagrada (jardín de semillas emocionales).
//
// Cada slot puede contener una semilla que crece con riegos emocionales.
// Al alcanzar `wateringsNeeded`, la planta florece y puede cosecharse.

import 'seed_catalog_item.dart';

/// Estado inmutable de un slot de la chinampa.
class ChinampaSlotState {
  /// Crea un estado de slot de chinampa.
  const ChinampaSlotState({
    required this.slotIndex,
    this.seedId,
    this.currentWaterings = 0,
    this.isHarvested = false,
    this.plantedAt,
    this.catalogItem,
  });

  /// Índice del slot (0 a 3).
  final int slotIndex;

  /// ID de la semilla plantada, o null si está vacío.
  final String? seedId;

  /// Número de riegos actuales aplicados.
  final int currentWaterings;

  /// Si la planta ya fue cosechada (esperando clearSlot).
  final bool isHarvested;

  /// Momento en que se plantó la semilla (UTC).
  final DateTime? plantedAt;

  /// Ítem del catálogo enlazado (null si no hay semilla o no se encontró en catálogo).
  final SeedCatalogItem? catalogItem;

  /// Si el slot está vacío (sin semilla plantada).
  bool get isEmpty => seedId == null;

  /// Riegos necesarios para que florezca (desde catálogo, default 3).
  int get wateringsNeeded => catalogItem?.wateringsNeeded ?? 3;

  /// Si la planta está lista para cosechar (alcanzó wateringsNeeded y no está cosechada).
  bool get isReadyToBloom =>
      !isEmpty && !isHarvested && currentWaterings >= wateringsNeeded;

  /// Progreso de crecimiento 0.0–1.0 (1.0 = listo para florecer).
  double get growthProgress =>
      isEmpty ? 0.0 : (currentWaterings / wateringsNeeded).clamp(0.0, 1.0);

  /// Etapa de sprite actual según progreso.
  ///
  /// - null si está vacío.
  /// - spriteStages[0] = recién plantado (0 riegos).
  /// - spriteStages[length-1] = flor completa (SOLO cuando isHarvested || currentWaterings >= wateringsNeeded).
  /// - Para 0 < currentWaterings < wateringsNeeded y stages.length > 2:
  ///   índice intermedio entre 1 y stages.length - 2 (nunca el último antes de florecer).
  String? get currentSpriteStage {
    if (isEmpty || catalogItem == null) return null;
    final stages = catalogItem!.spriteStages;
    if (stages.isEmpty) return null;

    // Flor completa: SOLO cuando cosechada o alcanzó wateringsNeeded
    if (isHarvested || currentWaterings >= wateringsNeeded) {
      return stages.last;
    }

    // Recién plantado: 0 riegos -> primer sprite
    if (currentWaterings == 0) {
      return stages.first;
    }

    // Etapas intermedias: 0 < currentWaterings < wateringsNeeded
    if (stages.length > 2) {
      // Mapea a índice entre 1 y stages.length - 2 (excluye primero y último)
      final progress = currentWaterings / wateringsNeeded;
      final index = (progress * (stages.length - 1))
          .floor()
          .clamp(1, stages.length - 2);
      return stages[index];
    }

    // Fallback para catálogos con solo 2 sprites: usa el primero hasta florecer
    return stages.first;
  }

  /// Crea desde mapa de base de datos + catálogo opcional.
  factory ChinampaSlotState.fromMap(
    Map<String, dynamic> map, {
    SeedCatalogItem? catalogItem,
  }) {
    return ChinampaSlotState(
      slotIndex: map['slot_index'] as int,
      seedId: map['seed_id'] as String?,
      currentWaterings: map['current_waterings'] as int? ?? 0,
      isHarvested: (map['is_harvested'] as int? ?? 0) == 1,
      plantedAt: map['planted_at'] != null
          ? DateTime.parse(map['planted_at'] as String).toUtc()
          : null,
      catalogItem: catalogItem,
    );
  }

  /// Copia con campos modificados.
  ChinampaSlotState copyWith({
    int? slotIndex,
    String? seedId,
    int? currentWaterings,
    bool? isHarvested,
    DateTime? plantedAt,
    SeedCatalogItem? catalogItem,
    // Usa un valor sentinel para permitir poner a null explícitamente
    bool clearCatalogItem = false,
  }) {
    return ChinampaSlotState(
      slotIndex: slotIndex ?? this.slotIndex,
      seedId: seedId ?? this.seedId,
      currentWaterings: currentWaterings ?? this.currentWaterings,
      isHarvested: isHarvested ?? this.isHarvested,
      plantedAt: plantedAt ?? this.plantedAt,
      catalogItem: clearCatalogItem ? null : (catalogItem ?? this.catalogItem),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChinampaSlotState &&
          runtimeType == other.runtimeType &&
          slotIndex == other.slotIndex &&
          seedId == other.seedId &&
          currentWaterings == other.currentWaterings &&
          isHarvested == other.isHarvested &&
          plantedAt == other.plantedAt &&
          catalogItem == other.catalogItem;

  @override
  int get hashCode => Object.hash(
        slotIndex,
        seedId,
        currentWaterings,
        isHarvested,
        plantedAt,
        catalogItem,
      );

  @override
  String toString() =>
      'ChinampaSlotState(slotIndex: $slotIndex, seedId: $seedId, '
      'waterings: $currentWaterings/$wateringsNeeded, harvested: $isHarvested, '
      'ready: $isReadyToBloom)';
}

/// Resultado del riego de un slot individual.
class SlotWateringResult {
  /// Crea un resultado de riego.
  const SlotWateringResult({
    required this.slotIndex,
    required this.seedId,
    required this.waterAdded,
    required this.previousWaterings,
    required this.newWaterings,
    required this.wateringsNeeded,
    required this.hadAffinity,
    required this.justBloomed,
  });

  /// Índice del slot regado.
  final int slotIndex;

  /// ID de la semilla en el slot.
  final String seedId;

  /// Cantidad de agua añadida (1 o 2).
  final int waterAdded;

  /// Riegos antes del riego.
  final int previousWaterings;

  /// Riegos después del riego.
  final int newWaterings;

  /// Riegos necesarios para florecer.
  final int wateringsNeeded;

  /// Si la emoción coincidió con la afinidad (riego doble).
  final bool hadAffinity;

  /// Si con este riego la planta acaba de alcanzar/superar wateringsNeeded.
  final bool justBloomed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlotWateringResult &&
          runtimeType == other.runtimeType &&
          slotIndex == other.slotIndex &&
          seedId == other.seedId &&
          waterAdded == other.waterAdded &&
          previousWaterings == other.previousWaterings &&
          newWaterings == other.newWaterings &&
          wateringsNeeded == other.wateringsNeeded &&
          hadAffinity == other.hadAffinity &&
          justBloomed == other.justBloomed;

  @override
  int get hashCode => Object.hash(
        slotIndex,
        seedId,
        waterAdded,
        previousWaterings,
        newWaterings,
        wateringsNeeded,
        hadAffinity,
        justBloomed,
      );

  @override
  String toString() =>
      'SlotWateringResult(slot: $slotIndex, seed: $seedId, +$waterAdded '
      '($previousWaterings->$newWaterings/$wateringsNeeded), affinity: $hadAffinity, bloomed: $justBloomed)';
}

/// Resumen completo de una operación de riego en la chinampa.
class ChinampaWateringSummary {
  /// Crea un resumen de riego.
  const ChinampaWateringSummary({
    required this.slots,
    required this.wateredSlots,
    required this.newlyBloomedSlots,
  });

  /// Estado actual de los 4 slots después del riego.
  final List<ChinampaSlotState> slots;

  /// Slots que recibieron riego (activos antes del riego).
  final List<SlotWateringResult> wateredSlots;

  /// Subconjunto de wateredSlots que acaban de florecer con este riego.
  final List<SlotWateringResult> newlyBloomedSlots;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChinampaWateringSummary &&
          runtimeType == other.runtimeType &&
          _listEquals(slots, other.slots) &&
          _listEquals(wateredSlots, other.wateredSlots) &&
          _listEquals(newlyBloomedSlots, other.newlyBloomedSlots);

  @override
  int get hashCode => Object.hashAll([
        Object.hashAll(slots),
        Object.hashAll(wateredSlots),
        Object.hashAll(newlyBloomedSlots),
      ]);

  @override
  String toString() =>
      'ChinampaWateringSummary(watered: ${wateredSlots.length}, '
      'newlyBloomed: ${newlyBloomedSlots.length})';

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}