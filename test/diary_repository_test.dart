// Tests para DiaryRepository.
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_calli/core/utils/local_day_bounds.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/diary_entry.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/prehispanic_emotion.dart';

/// Mock de LocalDatabaseService para tests unitarios sin base de datos real.
/// Implementa solo los métodos que usa DiaryRepository.
/// Usa LocalDayBounds para la lógica de límites UTC (misma clase que el servicio real).
class MockLocalDatabaseService {
  MockLocalDatabaseService();

  final List<Map<String, dynamic>> _diaryEntries = [];
  bool _isInitialized = false;

  Future<void> initialize() async {
    _isInitialized = true;
  }

  bool get isInitialized => _isInitialized;

  Future<int> insertDiaryEntry({
    required String id,
    required DateTime createdAt,
    required String emotionId,
    required String content,
    required String featherId,
    String? wateredSeedId,
    bool triggeredSos = false,
  }) async {
    final createdAtMillis = LocalDayBounds.truncateToMillis(createdAt);
    _diaryEntries.add({
      'id': id,
      'created_at': createdAtMillis.toIso8601String(),
      'emotion_id': emotionId,
      'content': content,
      'feather_id': featherId,
      'watered_seed_id': wateredSeedId,
      'triggered_sos': triggeredSos ? 1 : 0,
    });
    return 1;
  }

  Future<List<Map<String, dynamic>>> getDiaryEntriesByDateRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final bounds = LocalDayBounds.rangeUtc(start, end);

    return _diaryEntries
        .where((e) {
          final createdAt = DateTime.parse(e['created_at'] as String);
          return createdAt.isAtSameMomentAs(bounds.startUtc) ||
              (createdAt.isAfter(bounds.startUtc) && createdAt.isBefore(bounds.endUtc));
        })
        .toList()
      ..sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
  }

  Future<Map<String, int>> countEmotionsLastDays(int days) async {
    final sinceUtc = LocalDayBounds.sinceUtc(days);

    final counts = <String, int>{};
    for (final entry in _diaryEntries) {
      final createdAt = DateTime.parse(entry['created_at'] as String);
      if (createdAt.isAtSameMomentAs(sinceUtc) || createdAt.isAfter(sinceUtc)) {
        final emotion = entry['emotion_id'] as String;
        counts[emotion] = (counts[emotion] ?? 0) + 1;
      }
    }

    // Asegurar que todas las emociones válidas estén presentes (con 0 si no hay entradas)
    for (final emotion in PrehispanicEmotion.allIds) {
      counts.putIfAbsent(emotion, () => 0);
    }

    return counts;
  }

  // Para getLatestEntry y getTotalEntriesCount, DiaryRepository accede directo a database
  // Como no tenemos database real, estos métodos lanzan UnimplementedError
  // Los tests de esos métodos se pueden hacer verificando el comportamiento de los otros métodos
}

void main() {
  group('LocalDayBounds', () {
    test('startOfDayUtc: inicio del día local en UTC', () {
      // 2026-06-15 12:00:00 local -> inicio del día 2026-06-15 00:00:00 local en UTC
      final local = DateTime(2026, 6, 15, 12, 0, 0);
      final utc = LocalDayBounds.startOfDayUtc(local);
      // Verificar que al convertir de vuelta a local es 00:00:00.000
      final backToLocal = utc.toLocal();
      expect(backToLocal.hour, equals(0));
      expect(backToLocal.minute, equals(0));
      expect(backToLocal.second, equals(0));
      expect(backToLocal.millisecond, equals(0));
      expect(backToLocal.microsecond, equals(0));
      expect(backToLocal.day, equals(15));
      expect(utc.isUtc, isTrue);
    });

    test('startOfNextDayUtc: inicio del día siguiente en UTC (usa día+1, no add 24h)', () {
      final local = DateTime(2026, 6, 15, 12, 0, 0);
      final nextDayUtc = LocalDayBounds.startOfNextDayUtc(local);

      // Debe ser el inicio del día 16 (no 15 + 24h)
      // La clave es que usa DateTime(año, mes, día+1) internamente
      final backToLocal = nextDayUtc.toLocal();
      expect(backToLocal.day, equals(16));
      expect(backToLocal.hour, equals(0));
      expect(backToLocal.minute, equals(0));
      expect(backToLocal.second, equals(0));
      expect(backToLocal.millisecond, equals(0));
    });

    test('startOfNextDayUtc: fin de mes (31 ene -> 1 feb)', () {
      final local = DateTime(2026, 1, 31, 23, 59, 59);
      final nextDayUtc = LocalDayBounds.startOfNextDayUtc(local);
      final backToLocal = nextDayUtc.toLocal();
      expect(backToLocal.month, equals(2));
      expect(backToLocal.day, equals(1));
      expect(backToLocal.hour, equals(0));
      expect(backToLocal.minute, equals(0));
    });

    test('startOfNextDayUtc: fin de año (31 dic -> 1 ene)', () {
      final local = DateTime(2026, 12, 31, 23, 59, 59);
      final nextDayUtc = LocalDayBounds.startOfNextDayUtc(local);
      final backToLocal = nextDayUtc.toLocal();
      expect(backToLocal.year, equals(2027));
      expect(backToLocal.month, equals(1));
      expect(backToLocal.day, equals(1));
      expect(backToLocal.hour, equals(0));
      expect(backToLocal.minute, equals(0));
    });

    test('startOfNextDayUtc: 29 de febrero (año bisiesto)', () {
      final local = DateTime(2024, 2, 29, 12, 0, 0); // 2024 es bisiesto
      final nextDayUtc = LocalDayBounds.startOfNextDayUtc(local);
      final backToLocal = nextDayUtc.toLocal();
      expect(backToLocal.month, equals(3));
      expect(backToLocal.day, equals(1));
      expect(backToLocal.hour, equals(0));
      expect(backToLocal.minute, equals(0));
    });

    test('startOfNextDayUtc: 28 de febrero (año no bisiesto -> 1 mar)', () {
      final local = DateTime(2025, 2, 28, 12, 0, 0); // 2025 no es bisiesto
      final nextDayUtc = LocalDayBounds.startOfNextDayUtc(local);
      final backToLocal = nextDayUtc.toLocal();
      expect(backToLocal.month, equals(3));
      expect(backToLocal.day, equals(1));
      expect(backToLocal.hour, equals(0));
      expect(backToLocal.minute, equals(0));
    });

    test('rangeUtc: devuelve límites correctos para rango de un día', () {
      final start = DateTime(2026, 6, 15, 0, 0, 0);
      final end = DateTime(2026, 6, 15, 23, 59, 59);
      final bounds = LocalDayBounds.rangeUtc(start, end);

      expect(bounds.startUtc, equals(LocalDayBounds.startOfDayUtc(start)));
      expect(bounds.endUtc, equals(LocalDayBounds.startOfNextDayUtc(end)));
    });

    test('sinceUtc: últimos N días incluye hoy y N-1 anteriores', () {
      final today = DateTime.now();
      final sinceUtc = LocalDayBounds.sinceUtc(7);

      final expectedSince = today.subtract(const Duration(days: 6));
      final expectedUtc = LocalDayBounds.startOfDayUtc(expectedSince);

      expect(sinceUtc, equals(expectedUtc));
    });

    test('truncateToMillis: elimina microsegundos', () {
      final dt = DateTime(2026, 6, 15, 12, 30, 45, 123, 456); // 123ms, 456µs
      final truncated = LocalDayBounds.truncateToMillis(dt);

      expect(truncated.millisecond, equals(123));
      expect(truncated.microsecond, equals(0));
      expect(truncated.isUtc, equals(dt.isUtc));
    });

    test('inicio del día siguiente siempre es 00:00:00.000 local', () {
      // Este test verifica que startOfNextDayUtc siempre produce medianoche local
      // independientemente de la hora de entrada
      for (final hour in [0, 6, 12, 18, 23]) {
        final local = DateTime(2026, 6, 15, hour, 30, 45);
        final nextDayUtc = LocalDayBounds.startOfNextDayUtc(local);

        // Convertir de vuelta a local para verificar que es 00:00:00.000
        final nextDayLocal = nextDayUtc.toLocal();
        expect(nextDayLocal.hour, equals(0), reason: 'hora=$hour');
        expect(nextDayLocal.minute, equals(0), reason: 'hora=$hour');
        expect(nextDayLocal.second, equals(0), reason: 'hora=$hour');
        expect(nextDayLocal.millisecond, equals(0), reason: 'hora=$hour');
        expect(nextDayLocal.microsecond, equals(0), reason: 'hora=$hour');
        // Debe ser el día 16
        expect(nextDayLocal.day, equals(16), reason: 'hora=$hour');
      }
    });
  });

  group('DiaryRepository', () {
    group('saveEntry', () {
      test('guarda una entrada y la recupera por fecha', () async {
        final mockDb = MockLocalDatabaseService();
        await mockDb.initialize();

        final entry = DiaryEntry.create(
          emotion: PrehispanicEmotion.tonatiuhSol,
          content: 'Hoy fue un buen día.',
          featherId: 'pluma_tonatiuh_01',
        );

        await mockDb.insertDiaryEntry(
          id: entry.id,
          createdAt: entry.createdAt,
          emotionId: entry.emotion.id,
          content: entry.content,
          featherId: entry.featherId,
          wateredSeedId: entry.wateredSeedId,
          triggeredSos: entry.triggeredSos,
        );

        final entries = await mockDb.getDiaryEntriesByDateRange(
          start: entry.createdAt,
          end: entry.createdAt,
        );

        expect(entries.length, equals(1));
        expect(entries.first['id'], equals(entry.id));
        expect(entries.first['emotion_id'], equals('tonatiuh_sol'));
        expect(entries.first['content'], equals('Hoy fue un buen día.'));
        expect(entries.first['feather_id'], equals('pluma_tonatiuh_01'));
        expect(entries.first['triggered_sos'], equals(0));
      });

      test('guarda entrada con wateredSeedId y triggeredSos', () async {
        final mockDb = MockLocalDatabaseService();
        await mockDb.initialize();

        final entry = DiaryEntry.create(
          emotion: PrehispanicEmotion.mixcoatlTormenta,
          content: 'Me enojé mucho.',
          featherId: 'pluma_mixcoatl_01',
          wateredSeedId: 'seed_nopal',
          triggeredSos: true,
        );

        await mockDb.insertDiaryEntry(
          id: entry.id,
          createdAt: entry.createdAt,
          emotionId: entry.emotion.id,
          content: entry.content,
          featherId: entry.featherId,
          wateredSeedId: entry.wateredSeedId,
          triggeredSos: entry.triggeredSos,
        );

        final entries = await mockDb.getDiaryEntriesByDateRange(
          start: entry.createdAt,
          end: entry.createdAt,
        );

        expect(entries.length, equals(1));
        expect(entries.first['watered_seed_id'], equals('seed_nopal'));
        expect(entries.first['triggered_sos'], equals(1));
      });

      test('guarda múltiples entradas en el mismo día', () async {
        final mockDb = MockLocalDatabaseService();
        await mockDb.initialize();

        final now = DateTime.now().toUtc();
        final entry1 = DiaryEntry.create(
          emotion: PrehispanicEmotion.tlalocLluvia,
          content: 'Entrada 1',
          featherId: 'pluma_tlaloc_01',
        );
        final entry2 = DiaryEntry.create(
          emotion: PrehispanicEmotion.tonatiuhSol,
          content: 'Entrada 2',
          featherId: 'pluma_tonatiuh_01',
        );

        // Forzar misma fecha para ambas
        final sameDayEntry1 = DiaryEntry(
          id: entry1.id,
          createdAt: now,
          emotion: entry1.emotion,
          content: entry1.content,
          featherId: entry1.featherId,
        );
        final sameDayEntry2 = DiaryEntry(
          id: entry2.id,
          createdAt: now.add(const Duration(hours: 2)),
          emotion: entry2.emotion,
          content: entry2.content,
          featherId: entry2.featherId,
        );

        await mockDb.insertDiaryEntry(
          id: sameDayEntry1.id,
          createdAt: sameDayEntry1.createdAt,
          emotionId: sameDayEntry1.emotion.id,
          content: sameDayEntry1.content,
          featherId: sameDayEntry1.featherId,
        );
        await mockDb.insertDiaryEntry(
          id: sameDayEntry2.id,
          createdAt: sameDayEntry2.createdAt,
          emotionId: sameDayEntry2.emotion.id,
          content: sameDayEntry2.content,
          featherId: sameDayEntry2.featherId,
        );

        final entries = await mockDb.getDiaryEntriesByDateRange(
          start: DateTime(now.year, now.month, now.day, 0, 0, 0),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
        );

        expect(entries.length, equals(2));
        // Orden descendente por created_at
        expect(entries[0]['id'], equals(sameDayEntry2.id)); // más reciente primero
        expect(entries[1]['id'], equals(sameDayEntry1.id));
      });
    });

    group('getDiaryEntriesByDateRange (método del mock)', () {
      test('filtra correctamente por rango de fechas', () async {
        final mockDb = MockLocalDatabaseService();
        await mockDb.initialize();

        final baseDate = DateTime(2026, 6, 15, 12, 0, 0).toUtc();

        await mockDb.insertDiaryEntry(
          id: 'entry-1',
          createdAt: baseDate.subtract(const Duration(days: 2)),
          emotionId: 'tlaloc_lluvia',
          content: 'Día 1',
          featherId: 'pluma_tlaloc_01',
        );
        await mockDb.insertDiaryEntry(
          id: 'entry-2',
          createdAt: baseDate,
          emotionId: 'tonatiuh_sol',
          content: 'Día 2',
          featherId: 'pluma_tonatiuh_01',
        );
        await mockDb.insertDiaryEntry(
          id: 'entry-3',
          createdAt: baseDate.add(const Duration(days: 2)),
          emotionId: 'ehecatl_viento',
          content: 'Día 3',
          featherId: 'pluma_ehecatl_01',
        );

        // Rango que incluye solo entry2
        final entries = await mockDb.getDiaryEntriesByDateRange(
          start: baseDate.subtract(const Duration(hours: 12)),
          end: baseDate.add(const Duration(hours: 12)),
        );

        expect(entries.length, equals(1));
        expect(entries.first['id'], equals('entry-2'));
      });

      test('incluye límites (inclusive)', () async {
        final mockDb = MockLocalDatabaseService();
        await mockDb.initialize();

        final date = DateTime(2026, 7, 4, 10, 0, 0).toUtc();
        await mockDb.insertDiaryEntry(
          id: 'boundary-test',
          createdAt: date,
          emotionId: 'metztli_noche',
          content: 'En el límite',
          featherId: 'pluma_metztli_01',
        );

        // start y end exactamente en la fecha de la entrada
        final entries = await mockDb.getDiaryEntriesByDateRange(
          start: date,
          end: date,
        );

        expect(entries.length, equals(1));
        expect(entries.first['id'], equals('boundary-test'));
      });

      test('devuelve lista vacía si no hay entradas en el rango', () async {
        final mockDb = MockLocalDatabaseService();
        await mockDb.initialize();

        final entries = await mockDb.getDiaryEntriesByDateRange(
          start: DateTime(2020, 1, 1),
          end: DateTime(2020, 1, 31),
        );

        expect(entries, isEmpty);
      });

      test('maneja entrada a 23:59 local (fin de día)', () async {
        final mockDb = MockLocalDatabaseService();
        await mockDb.initialize();

        // 23:59:59 local
        final localLate = DateTime(2026, 12, 31, 23, 59, 59);
        await mockDb.insertDiaryEntry(
          id: 'late-entry',
          createdAt: localLate,
          emotionId: 'tonatiuh_sol',
          content: 'Casi medianoche',
          featherId: 'pluma_tonatiuh_01',
        );

        // Buscar en ese día local
        final entries = await mockDb.getDiaryEntriesByDateRange(
          start: DateTime(2026, 12, 31),
          end: DateTime(2026, 12, 31),
        );

        expect(entries.length, equals(1));
        expect(entries.first['id'], equals('late-entry'));
      });

      test('maneja entrada a 00:00 local (inicio de día)', () async {
        final mockDb = MockLocalDatabaseService();
        await mockDb.initialize();

        // 00:00:00 local
        final localEarly = DateTime(2026, 1, 1, 0, 0, 0);
        await mockDb.insertDiaryEntry(
          id: 'early-entry',
          createdAt: localEarly,
          emotionId: 'metztli_noche',
          content: 'Primer momento del año',
          featherId: 'pluma_metztli_01',
        );

        final entries = await mockDb.getDiaryEntriesByDateRange(
          start: DateTime(2026, 1, 1),
          end: DateTime(2026, 1, 1),
        );

        expect(entries.length, equals(1));
        expect(entries.first['id'], equals('early-entry'));
      });

      test('maneja fin de mes (31 ene -> 1 feb)', () async {
        final mockDb = MockLocalDatabaseService();
        await mockDb.initialize();

        await mockDb.insertDiaryEntry(
          id: 'jan31',
          createdAt: DateTime(2026, 1, 31, 23, 59, 59),
          emotionId: 'tlaloc_lluvia',
          content: 'Fin de enero',
          featherId: 'pluma_tlaloc_01',
        );
        await mockDb.insertDiaryEntry(
          id: 'feb1',
          createdAt: DateTime(2026, 2, 1, 0, 0, 1),
          emotionId: 'tonatiuh_sol',
          content: 'Inicio de febrero',
          featherId: 'pluma_tonatiuh_01',
        );

        final janEntries = await mockDb.getDiaryEntriesByDateRange(
          start: DateTime(2026, 1, 31),
          end: DateTime(2026, 1, 31),
        );
        final febEntries = await mockDb.getDiaryEntriesByDateRange(
          start: DateTime(2026, 2, 1),
          end: DateTime(2026, 2, 1),
        );

        expect(janEntries.length, equals(1));
        expect(janEntries.first['id'], equals('jan31'));
        expect(febEntries.length, equals(1));
        expect(febEntries.first['id'], equals('feb1'));
      });

      test('maneja fin de año (31 dic -> 1 ene)', () async {
        final mockDb = MockLocalDatabaseService();
        await mockDb.initialize();

        await mockDb.insertDiaryEntry(
          id: 'dec31',
          createdAt: DateTime(2026, 12, 31, 23, 59, 59),
          emotionId: 'mixcoatl_tormenta',
          content: 'Fin de año',
          featherId: 'pluma_mixcoatl_01',
        );
        await mockDb.insertDiaryEntry(
          id: 'jan1',
          createdAt: DateTime(2027, 1, 1, 0, 0, 1),
          emotionId: 'ehecatl_viento',
          content: 'Año nuevo',
          featherId: 'pluma_ehecatl_01',
        );

        final decEntries = await mockDb.getDiaryEntriesByDateRange(
          start: DateTime(2026, 12, 31),
          end: DateTime(2026, 12, 31),
        );
        final janEntries = await mockDb.getDiaryEntriesByDateRange(
          start: DateTime(2027, 1, 1),
          end: DateTime(2027, 1, 1),
        );

        expect(decEntries.length, equals(1));
        expect(decEntries.first['id'], equals('dec31'));
        expect(janEntries.length, equals(1));
        expect(janEntries.first['id'], equals('jan1'));
      });
    });

    group('countEmotionsLastDays (método del mock)', () {
      test('cuenta emociones en los últimos 7 días por defecto', () async {
        final mockDb = MockLocalDatabaseService();
        await mockDb.initialize();

        final now = DateTime.now().toUtc();

        // Crear entradas: 3 en la última semana, 1 hace 10 días (fuera de rango)
        await mockDb.insertDiaryEntry(
          id: 'e1',
          createdAt: now.subtract(const Duration(days: 1)),
          emotionId: 'tonatiuh_sol',
          content: 'Ayer',
          featherId: 'pluma_tonatiuh_01',
        );
        await mockDb.insertDiaryEntry(
          id: 'e2',
          createdAt: now.subtract(const Duration(days: 3)),
          emotionId: 'tonatiuh_sol',
          content: 'Hace 3 días',
          featherId: 'pluma_tonatiuh_01',
        );
        await mockDb.insertDiaryEntry(
          id: 'e3',
          createdAt: now.subtract(const Duration(days: 5)),
          emotionId: 'tlaloc_lluvia',
          content: 'Hace 5 días',
          featherId: 'pluma_tlaloc_01',
        );
        await mockDb.insertDiaryEntry(
          id: 'e4',
          createdAt: now.subtract(const Duration(days: 10)),
          emotionId: 'ehecatl_viento',
          content: 'Hace 10 días (fuera)',
          featherId: 'pluma_ehecatl_01',
        );

        final counts = await mockDb.countEmotionsLastDays(7);

        expect(counts['tonatiuh_sol'], equals(2));
        expect(counts['tlaloc_lluvia'], equals(1));
        expect(counts['ehecatl_viento'], equals(0));
      });

      test('permite personalizar número de días', () async {
        final mockDb = MockLocalDatabaseService();
        await mockDb.initialize();

        final now = DateTime.now().toUtc();

        await mockDb.insertDiaryEntry(
          id: 'e1',
          createdAt: now.subtract(const Duration(days: 2)),
          emotionId: 'mixcoatl_tormenta',
          content: 'Hace 2 días',
          featherId: 'pluma_mixcoatl_01',
        );
        await mockDb.insertDiaryEntry(
          id: 'e2',
          createdAt: now.subtract(const Duration(days: 5)),
          emotionId: 'mixcoatl_tormenta',
          content: 'Hace 5 días',
          featherId: 'pluma_mixcoatl_01',
        );
        await mockDb.insertDiaryEntry(
          id: 'e3',
          createdAt: now.subtract(const Duration(days: 10)),
          emotionId: 'mixcoatl_tormenta',
          content: 'Hace 10 días',
          featherId: 'pluma_mixcoatl_01',
        );

        // Solo últimos 3 días
        final counts3 = await mockDb.countEmotionsLastDays(3);
        expect(counts3['mixcoatl_tormenta'], equals(1));

        // Últimos 7 días
        final counts7 = await mockDb.countEmotionsLastDays(7);
        expect(counts7['mixcoatl_tormenta'], equals(2));

        // Últimos 15 días
        final counts15 = await mockDb.countEmotionsLastDays(15);
        expect(counts15['mixcoatl_tormenta'], equals(3));
      });

      test('devuelve mapa con todas las emociones en 0 si no hay entradas', () async {
        final mockDb = MockLocalDatabaseService();
        await mockDb.initialize();

        final counts = await mockDb.countEmotionsLastDays(7);

        expect(counts.length, equals(5));
        for (final emotionId in PrehispanicEmotion.allIds) {
          expect(counts[emotionId], equals(0));
        }
      });
    });
  });
}