// Servicio para evaluar y desbloquear visitas de deidades y reliquias (Tarea 3.3 Parte A).
//
// Evalúa las 3 condiciones exactas de la Etapa 2 (docs/etapa_2_gamificacion_teotihuacan.md sección 5):
// - Tláloc: 3+ entradas de diario con emotion_id == 'tlaloc_lluvia'
// - Xochiquétzal: 3+ plantas cosechadas históricamente (contador persistente)
// - Xólotl: entrada después de 21:00 local O 2+ entradas con emotion_id == 'metztli_noche'
//
// Regla de idempotencia: antes de insertar en user_inventory, verifica si ya existe.
// Si existe, conserva su unlocked_at original y NO la incluye en newlyUnlockedRelics.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_calli/core/database/local_database_service.dart';
import 'package:mi_calli/features/1_sanctuary_journal/data/diary_repository_provider.dart';
import 'package:mi_calli/features/2_gamification/models/deity_relic_models.dart';

/// Servicio para gestionar visitas de deidades y desbloqueo de reliquias.
class DeityVisitsAndRelicsService {
  DeityVisitsAndRelicsService(this._db);

  final LocalDatabaseService _db;

  /// Obtiene todas las reliquias desbloqueadas actualmente en user_inventory.
  ///
  /// Filtra items con item_type == 'RELIC' y los mapea a [UnlockedRelic].
  Future<List<UnlockedRelic>> getUnlockedRelics() async {
    final inventory = await _db.getInventory();
    final relics = <UnlockedRelic>[];

    for (final item in inventory) {
      if (item['item_type'] == 'RELIC') {
        final itemId = item['item_id'] as String;
        final catalog = DeityRelicCatalog.fromRelicId(itemId);
        if (catalog != null) {
          final unlockedAtStr = item['unlocked_at'] as String;
          final unlockedAt = DateTime.parse(unlockedAtStr).toUtc();
          final quantity = (item['quantity'] as int? ?? 1);
          relics.add(UnlockedRelic(
            catalog: catalog,
            unlockedAt: unlockedAt,
            quantity: quantity,
          ));
        }
      }
    }

    // Ordenar por fecha de desbloqueo (más antiguas primero)
    relics.sort((a, b) => a.unlockedAt.compareTo(b.unlockedAt));
    return relics;
  }

  /// Verifica si una reliquia específica ya está desbloqueada.
  ///
  /// Busca en user_inventory con item_type == 'RELIC'.
  Future<bool> isRelicUnlocked(String relicId) async {
    final item = await _db.getInventoryItem(relicId);
    return item != null && item['item_type'] == 'RELIC';
  }

  /// Evalúa las 3 condiciones de desbloqueo y desbloquea las reliquias que falten.
  ///
  /// Parámetros opcionales para tests y casos edge:
  /// - [latestEntryLocalTime]: hora local de la última entrada de diario (para Xólotl).
  /// - [totalHarvestedOverride]: override del contador de cosechas (para tests).
  /// - [now]: timestamp actual (para tests, por defecto DateTime.now()).
  ///
  /// Retorna [DeityVisitEvaluationResult] con todas las reliquias desbloqueadas
  /// y las que se acaban de desbloquear en esta evaluación.
  Future<DeityVisitEvaluationResult> evaluateAndUnlockRelics({
    DateTime? latestEntryLocalTime,
    int? totalHarvestedOverride,
    DateTime? now,
  }) async {
    final currentTime = (now ?? DateTime.now()).toUtc();

    // Leer reliquias ya desbloqueadas
    final alreadyUnlocked = await getUnlockedRelics();
    final alreadyUnlockedIds = alreadyUnlocked.map((r) => r.relicId).toSet();

    final newlyUnlocked = <UnlockedRelic>[];

    // ─── Condición 1: Tláloc (relic_vasija_tlaloc) ───
    // 3+ entradas en diary_entries con emotion_id == 'tlaloc_lluvia'
    if (!alreadyUnlockedIds.contains('relic_vasija_tlaloc')) {
      final tlalocCount = await _countEmotionEntries('tlaloc_lluvia');
      if (tlalocCount >= 3) {
        await _db.upsertInventoryItem(
          itemId: 'relic_vasija_tlaloc',
          itemType: 'RELIC',
          quantity: 1,
          unlockedAt: currentTime,
        );
        newlyUnlocked.add(UnlockedRelic(
          catalog: DeityRelicCatalog.vasijaTlaloc,
          unlockedAt: currentTime,
          quantity: 1,
        ));
      }
    }

    // ─── Condición 2: Xochiquétzal (relic_mariposas_xochiquetzal) ───
    // 3+ plantas cosechadas históricamente (contador persistente)
    if (!alreadyUnlockedIds.contains('relic_mariposas_xochiquetzal')) {
      final totalHarvested = totalHarvestedOverride ?? await _db.getHarvestCounter();
      if (totalHarvested >= 3) {
        await _db.upsertInventoryItem(
          itemId: 'relic_mariposas_xochiquetzal',
          itemType: 'RELIC',
          quantity: 1,
          unlockedAt: currentTime,
        );
        newlyUnlocked.add(UnlockedRelic(
          catalog: DeityRelicCatalog.mariposasXochiquetzal,
          unlockedAt: currentTime,
          quantity: 1,
        ));
      }
    }

    // ─── Condición 3: Xólotl (relic_xolotl_companion) ───
    // Entrada después de 21:00 local O 2+ entradas con emotion_id == 'metztli_noche'
    if (!alreadyUnlockedIds.contains('relic_xolotl_companion')) {
      bool xolotlConditionMet = false;

      // Condición A: última entrada después de 21:00 hora local (por parámetro)
      // O cualquier entrada guardada en diary_entries con hora local >= 21
      if (latestEntryLocalTime != null) {
        final localHour = latestEntryLocalTime.hour;
        if (localHour >= 21) {
          xolotlConditionMet = true;
        }
      }

      // También consultar diary_entries para ver si alguna entrada tiene hora local >= 21
      if (!xolotlConditionMet) {
        final hasLateEntry = await _hasDiaryEntryAfter21Local();
        if (hasLateEntry) {
          xolotlConditionMet = true;
        }
      }

      // Condición B: 2+ entradas con emotion_id == 'metztli_noche'
      if (!xolotlConditionMet) {
        final metztliCount = await _countEmotionEntries('metztli_noche');
        if (metztliCount >= 2) {
          xolotlConditionMet = true;
        }
      }

      if (xolotlConditionMet) {
        await _db.upsertInventoryItem(
          itemId: 'relic_xolotl_companion',
          itemType: 'RELIC',
          quantity: 1,
          unlockedAt: currentTime,
        );
        newlyUnlocked.add(UnlockedRelic(
          catalog: DeityRelicCatalog.xolotlCompanion,
          unlockedAt: currentTime,
          quantity: 1,
        ));
      }
    }

    // Re-leer todas las reliquias desbloqueadas (incluye las nuevas)
    final allUnlocked = await getUnlockedRelics();

    return DeityVisitEvaluationResult(
      allUnlockedRelics: allUnlocked,
      newlyUnlockedRelics: newlyUnlocked,
    );
  }

  /// Verifica si existe alguna entrada en diary_entries con hora local >= 21.
  ///
  /// Lee todas las entradas y parsea created_at a hora local.
  Future<bool> _hasDiaryEntryAfter21Local() async {
    final entries = await _db.getDiaryEntriesByDateRange(
      start: DateTime(2000), // Muy temprano para cubrir todo el historial
      end: DateTime.now().add(const Duration(days: 1)), // Hasta mañana
    );

    for (final entry in entries) {
      final createdAtStr = entry['created_at'] as String;
      final createdAtUtc = DateTime.parse(createdAtStr).toUtc();
      final localHour = createdAtUtc.toLocal().hour;
      if (localHour >= 21) {
        return true;
      }
    }
    return false;
  }

  /// Cuenta entradas en diary_entries con un emotion_id específico.
  Future<int> _countEmotionEntries(String emotionId) async {
    final counts = await _db.countEmotionsLastDays(999999); // Un número muy grande = todo el historial
    return counts[emotionId] ?? 0;
  }
}

/// Provider del servicio de visitas de deidades y reliquias.
///
/// Recibe [LocalDatabaseService] y expone la lógica de evaluación y desbloqueo.
final deityVisitsAndRelicsServiceProvider = Provider<DeityVisitsAndRelicsService>((ref) {
  final databaseService = ref.watch(localDatabaseServiceProvider);
  return DeityVisitsAndRelicsService(databaseService);
});

/// Provider reactivo de la lista de reliquias desbloqueadas.
///
/// Se actualiza automáticamente cuando se desbloquea una nueva reliquia.
final unlockedRelicsProvider = FutureProvider<List<UnlockedRelic>>((ref) async {
  final service = ref.watch(deityVisitsAndRelicsServiceProvider);
  return service.getUnlockedRelics();
});