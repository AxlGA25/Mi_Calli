import 'package:sqflite_sqlcipher/sqflite.dart' as sql;

import '../../../../core/database/local_database_service.dart';
import '../models/diary_entry.dart';
import '../models/prehispanic_emotion.dart';

/// Excepción para errores del repositorio de diario.
class DiaryRepositoryException implements Exception {
  final String message;
  const DiaryRepositoryException(this.message);
  @override
  String toString() => 'DiaryRepositoryException: $message';
}

/// Repositorio para operaciones de diario emocional.
///
/// Encapsula el acceso a la tabla `diary_entries` a través de
/// `LocalDatabaseService`. No expone detalles de SQL ni de la base de datos
/// directamente a la capa de presentación.
///
/// NOTA: Las pruebas de integración con base de datos real (SQLCipher en dispositivo)
/// se realizarán en el punto de control 1 (checkpoint 1) usando un dispositivo físico.
/// Los tests unitarios actuales usan mocks que replican la lógica de límites UTC.
class DiaryRepository {
  DiaryRepository({
    required LocalDatabaseService databaseService,
  }) : _databaseService = databaseService;

  final LocalDatabaseService _databaseService;

  /// Guarda una nueva entrada en el diario.
  ///
  /// Lanza [DiaryRepositoryException] si falla la inserción.
  Future<void> saveEntry(DiaryEntry entry) async {
    try {
      await _databaseService.insertDiaryEntry(
        id: entry.id,
        createdAt: entry.createdAt,
        emotionId: entry.emotion.id,
        content: entry.content,
        featherId: entry.featherId,
        wateredSeedId: entry.wateredSeedId,
        triggeredSos: entry.triggeredSos,
      );
    } on sql.DatabaseException catch (e) {
      throw DiaryRepositoryException('Error al guardar la entrada: $e');
    } catch (e) {
      throw DiaryRepositoryException('Error inesperado al guardar: $e');
    }
  }

  /// Obtiene todas las entradas dentro de un rango de fechas (inclusive).
  ///
  /// - [start]: Fecha inicial (inclusive), se compara solo la fecha (sin hora).
  /// - [end]: Fecha final (inclusive), se compara solo la fecha (sin hora).
  ///
  /// Las entradas se devuelven ordenadas de la más reciente a la más antigua.
  Future<List<DiaryEntry>> getEntriesByDateRange({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      // Normalizar a inicio y fin de día para comparación inclusiva
      final startOfDay = DateTime(start.year, start.month, start.day, 0, 0, 0);
      final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);

      final rows = await _databaseService.getDiaryEntriesByDateRange(
        start: startOfDay,
        end: endOfDay,
      );

      return rows.map(DiaryEntry.fromDatabaseMap).toList();
    } on sql.DatabaseException catch (e) {
      throw DiaryRepositoryException('Error al buscar entradas por fecha: $e');
    } catch (e) {
      throw DiaryRepositoryException('Error inesperado al buscar por fecha: $e');
    }
  }

  /// Obtiene las entradas de un día específico.
  Future<List<DiaryEntry>> getEntriesForDay(DateTime day) async {
    return getEntriesByDateRange(start: day, end: day);
  }

  /// Cuenta cuántas entradas hay por emoción en los últimos [days] días.
  ///
  /// Por defecto cuenta los últimos 7 días (semana) según `CONTEXT.md`.
  /// El conteo incluye el día de hoy y va hacia atrás [days] días completos.
  ///
  /// Devuelve un mapa `emotion_id -> cantidad`.
  Future<Map<PrehispanicEmotion, int>> countEmotionsLastDays({
    int days = 7,
  }) async {
    try {
      final counts = await _databaseService.countEmotionsLastDays(days);

      // Convertir keys de String a PrehispanicEmotion
      final result = <PrehispanicEmotion, int>{};
      for (final entry in counts.entries) {
        if (PrehispanicEmotion.isValidId(entry.key)) {
          result[PrehispanicEmotion.fromId(entry.key)] = entry.value;
        }
      }

      // Asegurar que todas las emociones estén presentes (con 0 si no hay entradas)
      for (final emotion in PrehispanicEmotion.values) {
        result.putIfAbsent(emotion, () => 0);
      }

      return result;
    } on sql.DatabaseException catch (e) {
      throw DiaryRepositoryException('Error al contar emociones: $e');
    } catch (e) {
      throw DiaryRepositoryException('Error inesperado al contar emociones: $e');
    }
  }

  /// Obtiene la entrada más reciente (para mostrar en el Códice, etc.).
  Future<DiaryEntry?> getLatestEntry() async {
    try {
      final db = _databaseService.database;
      final rows = await db.query(
        'diary_entries',
        orderBy: 'created_at DESC',
        limit: 1,
      );

      if (rows.isEmpty) return null;
      return DiaryEntry.fromDatabaseMap(rows.first);
    } on sql.DatabaseException catch (e) {
      throw DiaryRepositoryException('Error al obtener última entrada: $e');
    } catch (e) {
      throw DiaryRepositoryException('Error inesperado al obtener última entrada: $e');
    }
  }

  /// Obtiene el total de entradas guardadas.
  Future<int> getTotalEntriesCount() async {
    try {
      final db = _databaseService.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM diary_entries');
      return result.first['count'] as int;
    } on sql.DatabaseException catch (e) {
      throw DiaryRepositoryException('Error al contar entradas totales: $e');
    } catch (e) {
      throw DiaryRepositoryException('Error inesperado al contar totales: $e');
    }
  }

  /// Obtiene TODAS las entradas ordenadas por created_at descendente (más recientes primero).
  ///
  /// Devuelve la lista completa de entradas para la pantalla de historial provisional.
  /// Orden: más reciente primero (DESC).
  Future<List<DiaryEntry>> getAllEntries() async {
    try {
      final db = _databaseService.database;
      final rows = await db.query(
        'diary_entries',
        orderBy: 'created_at DESC',
      );

      return rows.map(DiaryEntry.fromDatabaseMap).toList();
    } on sql.DatabaseException catch (e) {
      throw DiaryRepositoryException('Error al obtener todas las entradas: $e');
    } catch (e) {
      throw DiaryRepositoryException('Error inesperado al obtener entradas: $e');
    }
  }
}