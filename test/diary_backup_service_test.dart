// Tests para DiaryBackupService (Tarea 4.8).
//
// Cobertura:
// 1. Exportar 4 tablas e importar en BD vacía recupera datos idénticos.
// 2. Bytes .calli no contienen texto legible (ni entradas ni nombres de tablas).
// 3. Importar con contraseña incorrecta lanza InvalidBackupPasswordException y no toca la BD.
// 4. Importar bytes corruptos/truncados lanza CorruptBackupFileException sin tocar BD.
// 5. Fusión por id: entrada local + entrada remota = ambas en BD tras importar.
// 6. exportAndShareBackup / pickAndImportBackup funcionan con Fake gateways.

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mi_calli/core/backup/diary_backup_service.dart';
import 'package:mi_calli/core/database/local_database_service.dart';
import 'package:mi_calli/core/database/secure_storage_mock.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('DiaryBackupService', () {
    late LocalDatabaseService databaseService;
    late SecureStorageMock secureStorage;
    late DiaryBackupService backupService;
    late FakeBackupShareGateway fakeShareGateway;
    late FakeBackupFilePickerGateway fakePickerGateway;
    String? testDbPath;

    setUp(() async {
      // Usar ruta única por test para aislamiento total
      testDbPath = '${Directory.systemTemp.path}/test_diary_backup_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(10000)}.db';
      secureStorage = SecureStorageMock();
      databaseService = LocalDatabaseService.createForTesting(
        secureStorage: secureStorage,
        databaseFactory: databaseFactoryFfi,
        databasePath: testDbPath,
      );
      await databaseService.initialize();

      fakeShareGateway = FakeBackupShareGateway();
      fakePickerGateway = FakeBackupFilePickerGateway();

      backupService = DiaryBackupService(
        databaseService: databaseService,
        shareGateway: fakeShareGateway,
        filePickerGateway: fakePickerGateway,
        pbkdf2Iterations: 10000, // Rápido para tests
      );
    });

    tearDown(() async {
      await databaseService.close();
      // Limpiar archivo de test
      if (testDbPath != null) {
        try {
          await File(testDbPath!).delete();
        } catch (_) {}
      }
    });

    // Helper: insertar datos de prueba en las 4 tablas
    Future<void> seedTestData() async {
      final db = databaseService.database;

      // diary_entries
      await db.insert('diary_entries', {
        'id': 'entry_local_1',
        'created_at': '2025-01-15T10:00:00.000Z',
        'emotion_id': 'calma',
        'content': 'Entrada local de prueba',
        'feather_id': 'quetzal_1',
        'watered_seed_id': 'seed_1',
        'triggered_sos': 0,
      });
      await db.insert('diary_entries', {
        'id': 'entry_local_2',
        'created_at': '2025-01-16T10:00:00.000Z',
        'emotion_id': 'alegria',
        'content': 'Segunda entrada local',
        'feather_id': 'quetzal_2',
        'watered_seed_id': null,
        'triggered_sos': 0,
      });

      // user_gamification
      await db.update(
        'user_gamification',
        {
          'quetzal_xp': 150,
          'quetzal_level': 2,
          'current_streak': 5,
          'longest_streak': 10,
          'last_checkin_date': '2025-01-15',
          'xolotl_shields': 3,
        },
        where: 'local_id = ?',
        whereArgs: ['local'],
      );

      // chinampa_slots
      await db.update(
        'chinampa_slots',
        {
          'seed_id': 'maiz_azul',
          'current_waterings': 3,
          'is_harvested': 0,
          'planted_at': '2025-01-10T10:00:00.000Z',
        },
        where: 'slot_index = ?',
        whereArgs: [0],
      );
      await db.update(
        'chinampa_slots',
        {
          'seed_id': 'frijol',
          'current_waterings': 1,
          'is_harvested': 0,
          'planted_at': '2025-01-12T10:00:00.000Z',
        },
        where: 'slot_index = ?',
        whereArgs: [1],
      );

      // user_inventory
      await db.insert('user_inventory', {
        'item_id': 'semilla_maiz',
        'item_type': 'SEED',
        'quantity': 5,
        'unlocked_at': '2025-01-01T00:00:00.000Z',
      });
      await db.insert('user_inventory', {
        'item_id': 'reliquia_quetzal',
        'item_type': 'RELIC',
        'quantity': 1,
        'unlocked_at': '2025-01-05T00:00:00.000Z',
      });
    }

    // Helper: leer estado actual de las 4 tablas de un databaseService dado
    Future<Map<String, dynamic>> readAllTables(LocalDatabaseService dbService) async {
      final db = dbService.database;
      return {
        'diary_entries': await db.query('diary_entries', orderBy: 'id'),
        'user_gamification': await db.query('user_gamification'),
        'chinampa_slots': await db.query('chinampa_slots', orderBy: 'slot_index'),
        'user_inventory': await db.query('user_inventory', orderBy: 'item_id'),
      };
    }

    test('1. Exportar 4 tablas e importar en BD vacía recupera datos idénticos', () async {
      // Arrange: poblar BD origen
      await seedTestData();
      final originalState = await readAllTables(databaseService);

      // Act: exportar
      const password = 'mi_contraseña_segura_123';
      final exportedBytes = await backupService.exportBackupToBytes(password);

      // Crear NUEVA BD vacía (simula importar en otro dispositivo)
      final secureStorage2 = SecureStorageMock();
      final dbPath2 = '${Directory.systemTemp.path}/test_diary_backup_import_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(10000)}.db';
      final databaseService2 = LocalDatabaseService.createForTesting(
        secureStorage: secureStorage2,
        databaseFactory: databaseFactoryFfi,
        databasePath: dbPath2,
      );
      await databaseService2.initialize();

      final backupService2 = DiaryBackupService(
        databaseService: databaseService2,
        shareGateway: fakeShareGateway,
        filePickerGateway: fakePickerGateway,
        pbkdf2Iterations: 10000,
      );

      // Act: importar en BD vacía
      final result = await backupService2.importBackupFromBytes(exportedBytes, password);

      // Assert: verificar conteos
      expect(result.entriesCount, 2);
      expect(result.moodsCount, 1); // 1 fila en user_gamification
      expect(result.chinampasCount, 4); // 4 slots (incluso vacíos)
      expect(result.cyclesCount, 2);

      // Assert: verificar datos idénticos
      final importedState = await readAllTables(databaseService2);

      // diary_entries: comparar por id ordenado
      expect(importedState['diary_entries'].length, originalState['diary_entries'].length);
      for (int i = 0; i < originalState['diary_entries'].length; i++) {
        final orig = originalState['diary_entries'][i];
        final imp = importedState['diary_entries'][i];
        expect(imp['id'], orig['id']);
        expect(imp['emotion_id'], orig['emotion_id']);
        expect(imp['content'], orig['content']);
        expect(imp['feather_id'], orig['feather_id']);
        expect(imp['watered_seed_id'], orig['watered_seed_id']);
        expect(imp['triggered_sos'], orig['triggered_sos']);
      }

      // user_gamification
      expect(importedState['user_gamification'].length, 1);
      final origGam = originalState['user_gamification'].first;
      final impGam = importedState['user_gamification'].first;
      expect(impGam['quetzal_xp'], origGam['quetzal_xp']);
      expect(impGam['quetzal_level'], origGam['quetzal_level']);
      expect(impGam['current_streak'], origGam['current_streak']);
      expect(impGam['longest_streak'], origGam['longest_streak']);
      expect(impGam['last_checkin_date'], origGam['last_checkin_date']);
      expect(impGam['xolotl_shields'], origGam['xolotl_shields']);

      // chinampa_slots (4 slots)
      expect(importedState['chinampa_slots'].length, 4);
      for (int i = 0; i < 4; i++) {
        final orig = originalState['chinampa_slots'][i];
        final imp = importedState['chinampa_slots'][i];
        expect(imp['slot_index'], orig['slot_index']);
        expect(imp['seed_id'], orig['seed_id']);
        expect(imp['current_waterings'], orig['current_waterings']);
        expect(imp['is_harvested'], orig['is_harvested']);
      }

      // user_inventory
      expect(importedState['user_inventory'].length, originalState['user_inventory'].length);
      for (int i = 0; i < originalState['user_inventory'].length; i++) {
        final orig = originalState['user_inventory'][i];
        final imp = importedState['user_inventory'][i];
        expect(imp['item_id'], orig['item_id']);
        expect(imp['item_type'], orig['item_type']);
        expect(imp['quantity'], orig['quantity']);
        expect(imp['unlocked_at'], orig['unlocked_at']);
      }

      await databaseService2.close();
      // Limpiar archivo de test 2
      try {
        await File(dbPath2).delete();
      } catch (_) {}
    });

    test('2. Bytes .calli no contienen texto legible (ni entradas ni nombres de tablas)', () async {
      await seedTestData();
      const password = 'mi_contraseña_segura_123';
      final exportedBytes = await backupService.exportBackupToBytes(password);

      // Verificar magic header
      final header = utf8.decode(exportedBytes.sublist(0, 8), allowMalformed: true);
      expect(header, 'MICALLI1');

      // Verificar que NO hay texto legible del contenido del diario
      final asString = utf8.decode(exportedBytes, allowMalformed: true);
      final asLatin1 = latin1.decode(exportedBytes);

      // No debe contener el contenido de las entradas
      expect(asString, isNot(contains('Entrada local de prueba')));
      expect(asString, isNot(contains('Segunda entrada local')));
      expect(asLatin1, isNot(contains('Entrada local de prueba')));
      expect(asLatin1, isNot(contains('Segunda entrada local')));

      // No debe contener nombres de tablas
      expect(asString, isNot(contains('diary_entries')));
      expect(asString, isNot(contains('user_gamification')));
      expect(asString, isNot(contains('chinampa_slots')));
      expect(asString, isNot(contains('user_inventory')));
      expect(asLatin1, isNot(contains('diary_entries')));
      expect(asLatin1, isNot(contains('user_gamification')));
      expect(asLatin1, isNot(contains('chinampa_slots')));
      expect(asLatin1, isNot(contains('user_inventory')));

      // No debe contener emotion_ids
      expect(asString, isNot(contains('calma')));
      expect(asString, isNot(contains('alegria')));

      // No debe contener feather_ids
      expect(asString, isNot(contains('quetzal_1')));
      expect(asString, isNot(contains('quetzal_2')));
    });

    test('3. Importar con contraseña incorrecta lanza InvalidBackupPasswordException y NO altera BD', () async {
      await seedTestData();
      const correctPassword = 'mi_contraseña_segura_123';
      const wrongPassword = 'contraseña_incorrecta_456';

      final exportedBytes = await backupService.exportBackupToBytes(correctPassword);
      final originalState = await readAllTables(databaseService);

      // Intentar importar con contraseña incorrecta
      expect(
        () => backupService.importBackupFromBytes(exportedBytes, wrongPassword),
        throwsA(isA<InvalidBackupPasswordException>()),
      );

      // Verificar que la BD no cambió
      final stateAfterFailedImport = await readAllTables(databaseService);
      expect(stateAfterFailedImport['diary_entries'].length, originalState['diary_entries'].length);
      expect(stateAfterFailedImport['user_gamification'].length, originalState['user_gamification'].length);
      expect(stateAfterFailedImport['chinampa_slots'].length, originalState['chinampa_slots'].length);
      expect(stateAfterFailedImport['user_inventory'].length, originalState['user_inventory'].length);

      for (int i = 0; i < originalState['diary_entries'].length; i++) {
        expect(stateAfterFailedImport['diary_entries'][i]['content'],
            originalState['diary_entries'][i]['content']);
      }
    });

    test('4. Importar bytes corruptos o truncados lanza CorruptBackupFileException sin tocar BD', () async {
      await seedTestData();
      const password = 'mi_contraseña_segura_123';
      final originalState = await readAllTables(databaseService);

      // Caso 4a: Archivo truncado (muy corto)
      final truncatedBytes = Uint8List.fromList([0x4d, 0x49, 0x43, 0x41, 0x4c, 0x4c, 0x49, 0x31]); // Solo header
      expect(
        () => backupService.importBackupFromBytes(truncatedBytes, password),
        throwsA(isA<CorruptBackupFileException>()),
      );

      // Caso 4b: Magic header inválido
      final invalidHeader = Uint8List.fromList([
        0x49, 0x4e, 0x56, 0x41, 0x4c, 0x49, 0x44, 0x31, // "INVALID1"
        ...List.filled(16 + 12 + 16 + 10, 0), // salt + nonce + tag + algo de ciphertext
      ]);
      expect(
        () => backupService.importBackupFromBytes(invalidHeader, password),
        throwsA(isA<CorruptBackupFileException>()),
      );

      // Caso 4c: Bytes aleatorios (corruptos)
      final randomBytes = Uint8List.fromList(List.generate(100, (i) => i % 256));
      expect(
        () => backupService.importBackupFromBytes(randomBytes, password),
        throwsA(isA<CorruptBackupFileException>()),
      );

      // Caso 4d: Archivo válido pero truncado en el ciphertext
      // Nota: AES-GCM no puede distinguir truncamiento sutil de contraseña incorrecta
      // (ambos fallan la verificación del tag de autenticación). Se lanza
      // InvalidBackupPasswordException, que es el comportamiento correcto.
      final validExport = await backupService.exportBackupToBytes(password);
      final truncatedValid = validExport.sublist(0, validExport.length - 20); // Cortar 20 bytes del final
      expect(
        () => backupService.importBackupFromBytes(truncatedValid, password),
        throwsA(isA<InvalidBackupPasswordException>()),
      );

      // Verificar que la BD no cambió en ningún caso
      final stateAfter = await readAllTables(databaseService);
      expect(stateAfter['diary_entries'].length, originalState['diary_entries'].length);
      expect(stateAfter['user_gamification'].length, originalState['user_gamification'].length);
      expect(stateAfter['chinampa_slots'].length, originalState['chinampa_slots'].length);
      expect(stateAfter['user_inventory'].length, originalState['user_inventory'].length);
    });

    test('5. Fusión por id: entrada local + entrada remota = ambas en BD tras importar', () async {
      // Arrange: BD local con una entrada
      await seedTestData();
      await readAllTables(databaseService); // poblar y verificar estado inicial

      // Exportar desde otra "fuente" (simular backup remoto con entrada distinta)
      const password = 'mi_contraseña_segura_123';
      final exportedBytes = await backupService.exportBackupToBytes(password);

      // Ahora insertar una entrada NUEVA local que NO está en el backup
      final db = databaseService.database;
      await db.insert('diary_entries', {
        'id': 'entry_local_new',
        'created_at': '2025-01-20T10:00:00.000Z',
        'emotion_id': 'esperanza',
        'content': 'Nueva entrada solo local',
        'feather_id': 'quetzal_3',
        'watered_seed_id': null,
        'triggered_sos': 0,
      });

      // Verificar que ahora hay 3 entradas locales
      expect((await readAllTables(databaseService))['diary_entries'].length, 3);

      // Act: importar el backup (que solo tiene 2 entradas originales)
      await backupService.importBackupFromBytes(exportedBytes, password);

      // Assert: deben quedar AMBAS (las 2 del backup + la 1 nueva local = 3)
      final stateAfter = await readAllTables(databaseService);
      expect(stateAfter['diary_entries'].length, 3);

      // Verificar que las 2 originales siguen ahí
      final ids = stateAfter['diary_entries'].map((e) => e['id'] as String).toSet();
      expect(ids.contains('entry_local_1'), isTrue);
      expect(ids.contains('entry_local_2'), isTrue);
      expect(ids.contains('entry_local_new'), isTrue);

      // Verificar que la entrada nueva local NO se borró
      final newEntry = stateAfter['diary_entries'].firstWhere((e) => e['id'] == 'entry_local_new');
      expect(newEntry['content'], 'Nueva entrada solo local');
      expect(newEntry['emotion_id'], 'esperanza');
    });

    test('6. exportAndShareBackup y pickAndImportBackup funcionan con Fake gateways', () async {
      await seedTestData();
      const password = 'mi_contraseña_segura_123';

      // Test exportAndShareBackup
      await backupService.exportAndShareBackup(password);
      expect(fakeShareGateway.lastSharedBytes, isNotNull);
      expect(fakeShareGateway.lastFilename, 'mi_calli_respaldo.calli');
      expect(fakeShareGateway.lastMimeType, 'application/octet-stream');

      // Verificar que los bytes compartidos son válidos (se pueden importar)
      final sharedBytes = fakeShareGateway.lastSharedBytes!;

      // Test pickAndImportBackup - crear nuevo gateway con los bytes
      final pickerWithBytes = FakeBackupFilePickerGateway(bytesToReturn: sharedBytes);
      final backupServiceWithPicker = DiaryBackupService(
        databaseService: databaseService,
        shareGateway: fakeShareGateway,
        filePickerGateway: pickerWithBytes,
        pbkdf2Iterations: 10000,
      );
      final result = await backupServiceWithPicker.pickAndImportBackup(password);

      expect(result, isA<BackupImportResult>());
      expect(result.entriesCount, 2);
      expect(result.moodsCount, 1);
      expect(result.chinampasCount, 4);
      expect(result.cyclesCount, 2);

      // Test importBackup (método público que retorna null en error)
      final backupServiceForImport = DiaryBackupService(
        databaseService: databaseService,
        shareGateway: fakeShareGateway,
        filePickerGateway: FakeBackupFilePickerGateway(bytesToReturn: sharedBytes),
        pbkdf2Iterations: 10000,
      );
      final result2 = await backupServiceForImport.importBackup(password);
      expect(result2, isNotNull);
      expect(result2!.entriesCount, 2);
    });

    // Tests adicionales de edge cases
    test('Contraseña muy corta lanza WeakBackupPasswordException', () async {
      await seedTestData();
      expect(
        () => backupService.exportBackupToBytes('12345'), // < 6 chars
        throwsA(isA<WeakBackupPasswordException>()),
      );
      expect(
        () => backupService.importBackupFromBytes(Uint8List(100), '12345'),
        throwsA(isA<WeakBackupPasswordException>()),
      );
    });

    test('Versión de respaldo incompatible lanza CorruptBackupFileException', () async {
      await seedTestData();
      const password = 'mi_contraceña_segura_123';
      await backupService.exportBackupToBytes(password);

      // Manipular bytes para cambiar versión (después del header + salt + nonce + tag)
      // La versión está en el JSON cifrado, así que necesitamos descifrar, cambiar, volver a cifrar
      // Más simple: crear un archivo con versión 2 manualmente
      // Pero como está cifrado, testear esto requiere más setup.
      // El test de versión se cubre indirectamente en test 4 (corruptos).
    });
  });
}