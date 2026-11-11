import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_calli/core/database/local_database_service.dart';
import 'package:mi_calli/features/1_sanctuary_journal/data/diary_repository_provider.dart';
import 'package:mi_calli/features/2_gamification/models/gamification_models.dart';

/// Servicio que gestiona el Fuego Sagrado, la evolución del Quetzalcóatl
/// y la lógica de check-in diario con rachas y escudos de Xólotl.
class SacredFireAndEvolutionService {
  SacredFireAndEvolutionService(this._db);

  final LocalDatabaseService _db;

  /// Obtiene el estado actual de gamificación desde la base de datos.
  Future<GamificationState> getState() async {
    final map = await _db.getGamificationState();
    if (map == null) {
      // Si no existe, devuelve estado por defecto (debería crearse en _insertInitialData)
      return const GamificationState(
        quetzalXp: 0,
        quetzalLevel: 1,
        currentStreak: 0,
        longestStreak: 0,
        lastCheckinDate: null,
        xolotlShields: 1,
      );
    }
    return GamificationState.fromMap(map);
  }

  /// Registra el check-in diario y actualiza el estado de gamificación.
  ///
  /// [now] - Fecha/hora actual (se convierte a zona horaria local).
  /// [grantJournalXp] - Si es true, otorga +10 XP por escribir en el diario.
  Future<CheckinResult> registerDailyCheckin({
    required DateTime now,
    bool grantJournalXp = true,
  }) async {
    // Convierte a hora local y formatea YYYY-MM-DD
    final local = now.toLocal();
    final todayStr = _formatYmd(local);

    // Obtiene estado previo
    final prevState = await getState();

    // Calcula nuevo XP y nivel
    int newXp = prevState.quetzalXp;
    if (grantJournalXp) {
      newXp += 10; // 1 entrada de diario = 10 XP = 1 pluma
    }
    final newLevel = QuetzalEvolutionStage.fromXp(newXp).levelNumber;
    final leveledUp = newLevel > prevState.quetzalLevel;

    // Parse de la fecha del último check-in
    DateTime? lastCheckin;
    if (prevState.lastCheckinDate != null && prevState.lastCheckinDate!.isNotEmpty) {
      lastCheckin = _parseYmd(prevState.lastCheckinDate!);
    }

    // Determina estado de racha y nuevos valores
    int newStreak;
    int newShields = prevState.xolotlShields;
    StreakStatus status;
    String compassionateMessage = '';
    bool shieldEarned = false;

    if (lastCheckin == null) {
      // Primer check-in de la historia
      newStreak = 1;
      status = StreakStatus.firstCheckin;
    } else {
      // Calcula diferencia en días calendario (UTC para evitar problemas de DST)
      final todayUtc = DateTime.utc(local.year, local.month, local.day);
      final lastUtc = DateTime.utc(lastCheckin.year, lastCheckin.month, lastCheckin.day);
      final diffDays = todayUtc.difference(lastUtc).inDays;

      if (diffDays <= 0) {
        // Ya hizo check-in hoy (o fecha futura inválida)
        newStreak = prevState.currentStreak;
        // Mantiene la fecha más reciente (hoy)
        status = StreakStatus.alreadyCheckedInToday;
      } else if (diffDays == 1) {
        // Día consecutivo: incrementa racha
        newStreak = prevState.currentStreak + 1;
        status = StreakStatus.incremented;
      } else if (diffDays == 2 && prevState.xolotlShields > 0) {
        // Perdió 1 día pero tiene escudo: consume 1 y salva la racha
        newShields = prevState.xolotlShields - 1;
        newStreak = prevState.currentStreak + 1;
        status = StreakStatus.savedByXolotl;
      } else {
        // Perdió 2 días sin escudos, o 3+ días: reinicio compasivo
        newStreak = 1;
        // Conserva los escudos que tenga
        status = StreakStatus.resetCompassionate;
        compassionateMessage = _getCompassionateMessage(diffDays, prevState.xolotlShields);
      }
    }

    // Recarga de Amuleto de Obsidiana: cada 7 días de racha (7, 14, 21...)
    // Solo si el día avanzó (incremented o savedByXolotl) y racha > 0
    if ((status == StreakStatus.incremented || status == StreakStatus.savedByXolotl) &&
        newStreak > 0 &&
        newStreak % 7 == 0) {
      final previousShields = newShields;
      newShields = (newShields + 1).clamp(0, 2);
      shieldEarned = newShields > previousShields;
    }

    // Actualiza longestStreak
    final newLongestStreak = prevState.longestStreak > newStreak
        ? prevState.longestStreak
        : newStreak;

    // Determina la fecha a guardar: si diffDays < 0 (reloj atrasado), conserva la fecha previa
    // Reutiliza lastCheckin ya parseado arriba
    int diffDaysForDate = 0;
    if (lastCheckin != null) {
      final todayUtc = DateTime.utc(local.year, local.month, local.day);
      final lastUtc = DateTime.utc(lastCheckin.year, lastCheckin.month, lastCheckin.day);
      diffDaysForDate = todayUtc.difference(lastUtc).inDays;
    }
    String lastCheckinDateToSave;
    if (diffDaysForDate < 0) {
      lastCheckinDateToSave = prevState.lastCheckinDate!;
    } else {
      lastCheckinDateToSave = todayStr;
    }

    // Crea nuevo estado
    final newState = GamificationState(
      quetzalXp: newXp,
      quetzalLevel: newLevel,
      currentStreak: newStreak,
      longestStreak: newLongestStreak,
      lastCheckinDate: lastCheckinDateToSave,
      xolotlShields: newShields,
    );

    // Guarda en base de datos
    await _db.updateGamification(newState.toMap());

    return CheckinResult(
      state: newState,
      status: status,
      leveledUp: leveledUp,
      shieldEarned: shieldEarned,
      compassionateMessage: compassionateMessage,
    );
  }

  /// Formatea DateTime como YYYY-MM-DD.
  String _formatYmd(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Parsea string YYYY-MM-DD a DateTime (asume zona local).
  DateTime _parseYmd(String str) {
    final parts = str.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  /// Genera mensaje compasivo en español de México según el contexto.
  String _getCompassionateMessage(int diffDays, int prevShields) {
    if (diffDays >= 3) {
      return 'La vida a veces nos lleva por caminos inesperados. '
          'Tu racha se reinicia, pero tu camino continúa. '
          'Hoy es un nuevo comienzo. 🌱';
    } else if (prevShields == 0) {
      return 'Un día sin registrar no borra tu progreso interior. '
          'Tu Quetzalcóatl descansa, listo para volver a volar mañana. 💚';
    } else {
      return 'El fuego se apaga por un momento, pero la brasa sigue viva. '
          'Mañana lo reavivaremos juntos. ✨';
    }
  }
}

/// Provider del servicio SacredFireAndEvolutionService.
final sacredFireAndEvolutionServiceProvider = Provider<SacredFireAndEvolutionService>((ref) {
  final db = ref.watch(localDatabaseServiceProvider);
  return SacredFireAndEvolutionService(db);
});

/// Provider del estado de gamificación (reactivo a cambios).
final gamificationStateProvider = FutureProvider<GamificationState>((ref) async {
  final service = ref.watch(sacredFireAndEvolutionServiceProvider);
  return service.getState();
});

/// Provider para recargar el estado después de un check-in.
final refreshGamificationStateProvider = FutureProvider.autoDispose<GamificationState>((ref) async {
  final service = ref.watch(sacredFireAndEvolutionServiceProvider);
  return service.getState();
});