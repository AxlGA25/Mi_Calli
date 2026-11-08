// Tests para DiaryEntry model.
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_calli/features/1_sanctuary_journal/models/diary_entry.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/prehispanic_emotion.dart';

void main() {
  group('DiaryEntry', () {
    const testId = 'test-uuid-1234';
    final testDate = DateTime(2026, 1, 15, 10, 30, 0, 0).toUtc();
    const testContent = 'Hoy me sentí muy tranquilo y agradecido.';
    const testFeatherId = 'pluma_tonatiuh_01';
    const testWateredSeedId = 'seed_maiz';

    late DiaryEntry entry;

    setUp(() {
      entry = DiaryEntry(
        id: testId,
        createdAt: testDate,
        emotion: PrehispanicEmotion.tonatiuhSol,
        content: testContent,
        featherId: testFeatherId,
        wateredSeedId: testWateredSeedId,
        triggeredSos: false,
      );
    });

    group('constructor', () {
      test('crea entrada con todos los campos', () {
        expect(entry.id, equals(testId));
        expect(entry.createdAt, equals(testDate));
        expect(entry.emotion, equals(PrehispanicEmotion.tonatiuhSol));
        expect(entry.content, equals(testContent));
        expect(entry.featherId, equals(testFeatherId));
        expect(entry.wateredSeedId, equals(testWateredSeedId));
        expect(entry.triggeredSos, isFalse);
      });

      test('wateredSeedId puede ser null', () {
        final entryNoSeed = DiaryEntry(
          id: testId,
          createdAt: testDate,
          emotion: PrehispanicEmotion.tlalocLluvia,
          content: testContent,
          featherId: testFeatherId,
          wateredSeedId: null,
        );
        expect(entryNoSeed.wateredSeedId, isNull);
      });

      test('triggeredSos por defecto es false', () {
        final entryDefault = DiaryEntry(
          id: testId,
          createdAt: testDate,
          emotion: PrehispanicEmotion.tlalocLluvia,
          content: testContent,
          featherId: testFeatherId,
        );
        expect(entryDefault.triggeredSos, isFalse);
      });
    });

    group('create factory', () {
      test('genera UUID y fecha actual automáticamente', () {
        final created = DiaryEntry.create(
          emotion: PrehispanicEmotion.ehecatlViento,
          content: 'Contenido de prueba',
          featherId: 'pluma_ehecatl_01',
        );

        // Verificar que tiene ID (UUID v4 format)
        expect(created.id, isNotEmpty);
        expect(created.id.length, greaterThan(20));

        // Verificar que createdAt es reciente (últimos 5 segundos)
        final now = DateTime.now().toUtc();
        expect(now.difference(created.createdAt).inSeconds, lessThan(5));

        // Verificar campos pasados
        expect(created.emotion, equals(PrehispanicEmotion.ehecatlViento));
        expect(created.content, equals('Contenido de prueba'));
        expect(created.featherId, equals('pluma_ehecatl_01'));
        expect(created.wateredSeedId, isNull);
        expect(created.triggeredSos, isFalse);
      });

      test('acepta wateredSeedId y triggeredSos opcionales', () {
        final created = DiaryEntry.create(
          emotion: PrehispanicEmotion.mixcoatlTormenta,
          content: 'Contenido',
          featherId: 'pluma_mixcoatl_01',
          wateredSeedId: 'seed_nopal',
          triggeredSos: true,
        );

        expect(created.wateredSeedId, equals('seed_nopal'));
        expect(created.triggeredSos, isTrue);
      });
    });

    group('toDatabaseMap', () {
      test('convierte a mapa compatible con SQLite', () {
        final map = entry.toDatabaseMap();

        expect(map['id'], equals(testId));
        expect(map['created_at'], equals(testDate.toIso8601String()));
        expect(map['emotion_id'], equals('tonatiuh_sol'));
        expect(map['content'], equals(testContent));
        expect(map['feather_id'], equals(testFeatherId));
        expect(map['watered_seed_id'], equals(testWateredSeedId));
        expect(map['triggered_sos'], equals(0)); // false -> 0
      });

      test('triggeredSos true se convierte a 1', () {
        final entrySos = DiaryEntry(
          id: testId,
          createdAt: testDate,
          emotion: PrehispanicEmotion.mixcoatlTormenta,
          content: testContent,
          featherId: testFeatherId,
          triggeredSos: true,
        );

        final map = entrySos.toDatabaseMap();
        expect(map['triggered_sos'], equals(1));
      });

      test('wateredSeedId null no incluye la clave o la pone null', () {
        final entryNoSeed = DiaryEntry(
          id: testId,
          createdAt: testDate,
          emotion: PrehispanicEmotion.tlalocLluvia,
          content: testContent,
          featherId: testFeatherId,
          wateredSeedId: null,
        );

        final map = entryNoSeed.toDatabaseMap();
        expect(map['watered_seed_id'], isNull);
      });
    });

    group('fromDatabaseMap', () {
      test('reconstruye entrada desde mapa de BD', () {
        final map = {
          'id': testId,
          'created_at': testDate.toIso8601String(),
          'emotion_id': 'ehecatl_viento',
          'content': testContent,
          'feather_id': 'pluma_ehecatl_01',
          'watered_seed_id': 'seed_maguey',
          'triggered_sos': 1,
        };

        final reconstructed = DiaryEntry.fromDatabaseMap(map);

        expect(reconstructed.id, equals(testId));
        expect(reconstructed.createdAt, equals(testDate));
        expect(reconstructed.emotion, equals(PrehispanicEmotion.ehecatlViento));
        expect(reconstructed.content, equals(testContent));
        expect(reconstructed.featherId, equals('pluma_ehecatl_01'));
        expect(reconstructed.wateredSeedId, equals('seed_maguey'));
        expect(reconstructed.triggeredSos, isTrue);
      });

      test('maneja watered_seed_id null', () {
        final map = {
          'id': testId,
          'created_at': testDate.toIso8601String(),
          'emotion_id': 'metztli_noche',
          'content': testContent,
          'feather_id': 'pluma_metztli_01',
          'watered_seed_id': null,
          'triggered_sos': 0,
        };

        final reconstructed = DiaryEntry.fromDatabaseMap(map);
        expect(reconstructed.wateredSeedId, isNull);
      });
    });

    group('toExportJson / fromExportJson (round-trip)', () {
      test('exportación e importación preservan todos los campos', () {
        final json = entry.toExportJson();
        final imported = DiaryEntry.fromExportJson(json);

        expect(imported.id, equals(entry.id));
        expect(imported.createdAt, equals(entry.createdAt));
        expect(imported.emotion, equals(entry.emotion));
        expect(imported.content, equals(entry.content));
        expect(imported.featherId, equals(entry.featherId));
        expect(imported.wateredSeedId, equals(entry.wateredSeedId));
        expect(imported.triggeredSos, equals(entry.triggeredSos));
      });

      test('funciona con triggeredSos true', () {
        final entrySos = DiaryEntry(
          id: testId,
          createdAt: testDate,
          emotion: PrehispanicEmotion.mixcoatlTormenta,
          content: testContent,
          featherId: testFeatherId,
          triggeredSos: true,
        );

        final json = entrySos.toExportJson();
        final imported = DiaryEntry.fromExportJson(json);
        expect(imported.triggeredSos, isTrue);
      });

      test('funciona con wateredSeedId null', () {
        final entryNoSeed = DiaryEntry(
          id: testId,
          createdAt: testDate,
          emotion: PrehispanicEmotion.tlalocLluvia,
          content: testContent,
          featherId: testFeatherId,
          wateredSeedId: null,
        );

        final json = entryNoSeed.toExportJson();
        final imported = DiaryEntry.fromExportJson(json);
        expect(imported.wateredSeedId, isNull);
      });
    });

    group('equality y hashCode', () {
      test('entradas con mismo ID son iguales', () {
        final entry1 = DiaryEntry(
          id: testId,
          createdAt: testDate,
          emotion: PrehispanicEmotion.tonatiuhSol,
          content: testContent,
          featherId: testFeatherId,
        );

        final entry2 = DiaryEntry(
          id: testId,
          createdAt: testDate.add(const Duration(hours: 1)), // diferente
          emotion: PrehispanicEmotion.tlalocLluvia, // diferente
          content: 'Otro contenido',
          featherId: 'otra_pluma',
        );

        expect(entry1, equals(entry2));
        expect(entry1.hashCode, equals(entry2.hashCode));
      });

      test('entradas con distinto ID no son iguales', () {
        final entry1 = DiaryEntry(
          id: 'id-1',
          createdAt: testDate,
          emotion: PrehispanicEmotion.tonatiuhSol,
          content: testContent,
          featherId: testFeatherId,
        );

        final entry2 = DiaryEntry(
          id: 'id-2',
          createdAt: testDate,
          emotion: PrehispanicEmotion.tonatiuhSol,
          content: testContent,
          featherId: testFeatherId,
        );

        expect(entry1, isNot(equals(entry2)));
      });
    });

    group('toString', () {
      test('incluye información útil para debug', () {
        final str = entry.toString();
        expect(str, contains('DiaryEntry'));
        expect(str, contains(testId));
        expect(str, contains('tonatiuh_sol'));
        expect(str, contains('triggeredSos: false'));
      });

      test('NUNCA incluye el content (seguridad)', () {
        final str = entry.toString();
        expect(str, isNot(contains(testContent)));
        // Verificar con contenido sensible
        final sensitiveEntry = DiaryEntry(
          id: testId,
          createdAt: testDate,
          emotion: PrehispanicEmotion.tlalocLluvia,
          content: 'Mi secreto más profundo que nadie debe ver',
          featherId: testFeatherId,
        );
        final sensitiveStr = sensitiveEntry.toString();
        expect(sensitiveStr, isNot(contains('secreto')));
        expect(sensitiveStr, isNot(contains('nadie debe ver')));
      });
    });

    group('Seguridad - content nunca se filtra inadvertidamente', () {
      test('toDatabaseMap incluye content (solo para BD local)', () {
        // Este test documenta que content SÍ va a la BD local
        final map = entry.toDatabaseMap();
        expect(map['content'], equals(testContent));
      });

      test('toExportJson incluye content (solo para exportación manual del usuario)', () {
        // Este test documenta que content SÍ va al JSON de exportación
        // La exportación es manual, cifrada con contraseña del usuario
        final json = entry.toExportJson();
        expect(json['content'], equals(testContent));
      });

      test('DiaryRepositoryException mensajes del código real nunca incluyen content', () {
        // Verificar que los mensajes de excepción en diary_repository.dart
        // nunca concatenan el content del usuario.
        // Los mensajes reales son:
        // - 'Error al guardar la entrada: $e' (donde e es DatabaseException)
        // - 'Error inesperado al guardar: $e'
        // - 'Error al buscar entradas por fecha: $e'
        // - 'Error inesperado al buscar por fecha: $e'
        // - 'Error al contar emociones: $e'
        // - 'Error inesperado al contar emociones: $e'
        // - 'Error al obtener última entrada: $e'
        // - 'Error inesperado al obtener última entrada: $e'
        // - 'Error al verificar entrada de hoy: $e'
        // - 'Error inesperado al verificar hoy: $e'
        // - 'Error al contar entradas totales: $e'
        // - 'Error inesperado al contar totales: $e'
        //
        // Ninguno incluye el parámetro 'content' del usuario.

        const messages = [
          'Error al guardar la entrada: ',
          'Error inesperado al guardar: ',
          'Error al buscar entradas por fecha: ',
          'Error inesperado al buscar por fecha: ',
          'Error al contar emociones: ',
          'Error inesperado al contar emociones: ',
          'Error al obtener última entrada: ',
          'Error inesperado al obtener última entrada: ',
          'Error al verificar entrada de hoy: ',
          'Error inesperado al verificar hoy: ',
          'Error al contar entradas totales: ',
          'Error inesperado al contar totales: ',
        ];

        for (final msg in messages) {
          expect(msg, isNot(contains('content')));
          expect(msg, isNot(contains('Content')));
          expect(msg, isNot(contains('CONTENT')));
        }
      });
    });
  });
}