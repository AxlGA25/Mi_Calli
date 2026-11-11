// Tests para SacredFireAndEvolutionService usando SQLite FFI real.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mi_calli/core/database/local_database_service.dart';
import 'package:mi_calli/core/database/secure_storage_mock.dart';
import 'package:mi_calli/features/2_gamification/models/gamification_models.dart';
import 'package:mi_calli/features/2_gamification/services/sacred_fire_and_evolution_service.dart';

void main() {
  // Inicializar sqflite FFI para tests de escritorio
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempDir;
  late SecureStorageMock mockStorage;
  late LocalDatabaseService databaseService;
  late SacredFireAndEvolutionService service;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mi_calli_test_');
    mockStorage = SecureStorageMock();
    databaseService = LocalDatabaseService.createForTesting(
      secureStorage: mockStorage,
      databasePath: path.join(tempDir.path, 'test.db'),
      databaseFactory: databaseFactoryFfi,
    );
    // Inicializar la base de datos real
    await databaseService.initialize();
    service = SacredFireAndEvolutionService(databaseService);
  });

  tearDown(() async {
    await databaseService.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Estado inicial en DB', () {
    test('valores por defecto correctos', () async {
      final state = await service.getState();

      expect(state.quetzalXp, equals(0));
      expect(state.quetzalLevel, equals(1));
      expect(state.currentStreak, equals(0));
      expect(state.longestStreak, equals(0));
      expect(state.lastCheckinDate, isNull);
      expect(state.xolotlShields, equals(1));
      expect(state.evolutionStage, equals(QuetzalEvolutionStage.level1CoatlJade));
      expect(state.sacredFireTier, equals(SacredFireTier.embers));
      expect(state.feathersCount, equals(0));
    });
  });

  group('QuetzalEvolutionStage.fromXp umbrales exactos', () {
    test('0 XP -> level1CoatlJade (Nivel 1)', () {
      expect(QuetzalEvolutionStage.fromXp(0), equals(QuetzalEvolutionStage.level1CoatlJade));
      expect(QuetzalEvolutionStage.fromXp(0).levelNumber, equals(1));
    });

    test('40 XP -> level1CoatlJade (Nivel 1)', () {
      expect(QuetzalEvolutionStage.fromXp(40), equals(QuetzalEvolutionStage.level1CoatlJade));
      expect(QuetzalEvolutionStage.fromXp(40).levelNumber, equals(1));
    });

    test('50 XP -> level2AprendizViento (Nivel 2)', () {
      expect(QuetzalEvolutionStage.fromXp(50), equals(QuetzalEvolutionStage.level2AprendizViento));
      expect(QuetzalEvolutionStage.fromXp(50).levelNumber, equals(2));
    });

    test('140 XP -> level2AprendizViento (Nivel 2)', () {
      expect(QuetzalEvolutionStage.fromXp(140), equals(QuetzalEvolutionStage.level2AprendizViento));
      expect(QuetzalEvolutionStage.fromXp(140).levelNumber, equals(2));
    });

    test('150 XP -> level3GuardianEmplumado (Nivel 3)', () {
      expect(QuetzalEvolutionStage.fromXp(150), equals(QuetzalEvolutionStage.level3GuardianEmplumado));
      expect(QuetzalEvolutionStage.fromXp(150).levelNumber, equals(3));
    });

    test('290 XP -> level3GuardianEmplumado (Nivel 3)', () {
      expect(QuetzalEvolutionStage.fromXp(290), equals(QuetzalEvolutionStage.level3GuardianEmplumado));
      expect(QuetzalEvolutionStage.fromXp(290).levelNumber, equals(3));
    });

    test('300 XP -> level4SenorAurora (Nivel 4)', () {
      expect(QuetzalEvolutionStage.fromXp(300), equals(QuetzalEvolutionStage.level4SenorAurora));
      expect(QuetzalEvolutionStage.fromXp(300).levelNumber, equals(4));
    });

    test('490 XP -> level4SenorAurora (Nivel 4)', () {
      expect(QuetzalEvolutionStage.fromXp(490), equals(QuetzalEvolutionStage.level4SenorAurora));
      expect(QuetzalEvolutionStage.fromXp(490).levelNumber, equals(4));
    });

    test('500 XP -> level5QuetzalcoatlSupremo (Nivel 5)', () {
      expect(QuetzalEvolutionStage.fromXp(500), equals(QuetzalEvolutionStage.level5QuetzalcoatlSupremo));
      expect(QuetzalEvolutionStage.fromXp(500).levelNumber, equals(5));
    });

    test('leveledUp se activa solo al cruzar de nivel', () async {
      // Primer check-in: 0 -> 10 XP (nivel 1)
      final r1 = await service.registerDailyCheckin(now: DateTime(2026, 11, 1, 12, 0, 0));
      expect(r1.leveledUp, isFalse);
      expect(r1.state.quetzalLevel, equals(1));

      // 3 check-ins más: 10 -> 40 XP (todavía nivel 1)
      for (int i = 0; i < 3; i++) {
        final r = await service.registerDailyCheckin(now: DateTime(2026, 11, 2 + i, 12, 0, 0));
        expect(r.leveledUp, isFalse);
        expect(r.state.quetzalLevel, equals(1));
      }

      // 4º check-in adicional: 40 -> 50 XP (cruza a nivel 2)
      final r5 = await service.registerDailyCheckin(now: DateTime(2026, 11, 5, 12, 0, 0));
      expect(r5.leveledUp, isTrue);
      expect(r5.state.quetzalLevel, equals(2));

      // Siguiente check-in: 50 -> 60 XP (mismo nivel 2)
      final r6 = await service.registerDailyCheckin(now: DateTime(2026, 11, 6, 12, 0, 0));
      expect(r6.leveledUp, isFalse);
      expect(r6.state.quetzalLevel, equals(2));
    });
  });

  group('SacredFireTier.fromStreak etapas y colores', () {
    test('0 días -> embers', () {
      expect(SacredFireTier.fromStreak(0), equals(SacredFireTier.embers));
    });

    test('1 día -> warmOrange', () {
      expect(SacredFireTier.fromStreak(1), equals(SacredFireTier.warmOrange));
    });

    test('2 días -> warmOrange', () {
      expect(SacredFireTier.fromStreak(2), equals(SacredFireTier.warmOrange));
    });

    test('3 días -> warmOrange', () {
      expect(SacredFireTier.fromStreak(3), equals(SacredFireTier.warmOrange));
    });

    test('4 días -> solarGold', () {
      expect(SacredFireTier.fromStreak(4), equals(SacredFireTier.solarGold));
    });

    test('5 días -> solarGold', () {
      expect(SacredFireTier.fromStreak(5), equals(SacredFireTier.solarGold));
    });

    test('6 días -> solarGold', () {
      expect(SacredFireTier.fromStreak(6), equals(SacredFireTier.solarGold));
    });

    test('7 días -> mysticTurquoise', () {
      expect(SacredFireTier.fromStreak(7), equals(SacredFireTier.mysticTurquoise));
    });

    test('10 días -> mysticTurquoise', () {
      expect(SacredFireTier.fromStreak(10), equals(SacredFireTier.mysticTurquoise));
    });
  });

  group('Primer check-in y días consecutivos', () {
    test('primer check-in: firstCheckin, streak=1, formato YYYY-MM-DD', () async {
      final result = await service.registerDailyCheckin(now: DateTime(2026, 11, 1, 12, 0, 0));

      expect(result.status, equals(StreakStatus.firstCheckin));
      expect(result.state.currentStreak, equals(1));
      expect(result.state.longestStreak, equals(1));
      expect(result.state.lastCheckinDate, equals('2026-11-01'));
      expect(result.state.quetzalXp, equals(10));
      expect(result.state.feathersCount, equals(1));
    });

    test('días consecutivos (diffDays == 1): incremented, streak++, longestStreak', () async {
      await service.registerDailyCheckin(now: DateTime(2026, 11, 1, 12, 0, 0)); // día 1
      await service.registerDailyCheckin(now: DateTime(2026, 11, 2, 12, 0, 0)); // día 2
      final result = await service.registerDailyCheckin(now: DateTime(2026, 11, 3, 12, 0, 0)); // día 3

      expect(result.status, equals(StreakStatus.incremented));
      expect(result.state.currentStreak, equals(3));
      expect(result.state.longestStreak, equals(3));
      expect(result.state.lastCheckinDate, equals('2026-11-03'));
      expect(result.state.quetzalXp, equals(30));
    });
  });

  group('Mismo día (diffDays == 0) y grantJournalXp', () {
    test('segundo check-in mismo día con grantJournalXp=true: alreadyCheckedInToday, mantiene streak, suma XP', () async {
      await service.registerDailyCheckin(now: DateTime(2026, 11, 1, 10, 0, 0)); // primer check-in
      final result = await service.registerDailyCheckin(now: DateTime(2026, 11, 1, 20, 0, 0)); // mismo día

      expect(result.status, equals(StreakStatus.alreadyCheckedInToday));
      expect(result.state.currentStreak, equals(1));
      expect(result.state.quetzalXp, equals(20)); // 10 + 10
      expect(result.state.lastCheckinDate, equals('2026-11-01'));
    });

    test('check-in con grantJournalXp=false: aviva racha sin sumar XP de pluma', () async {
      await service.registerDailyCheckin(now: DateTime(2026, 11, 1, 10, 0, 0), grantJournalXp: true);
      final result = await service.registerDailyCheckin(now: DateTime(2026, 11, 1, 20, 0, 0), grantJournalXp: false);

      expect(result.status, equals(StreakStatus.alreadyCheckedInToday));
      expect(result.state.currentStreak, equals(1));
      expect(result.state.quetzalXp, equals(10)); // solo el primero
      expect(result.state.lastCheckinDate, equals('2026-11-01'));
    });
  });

  group('Protección empática del Manto de Xólotl (diffDays == 2 con escudos)', () {
    test('saltar 1 día calendario consume 1 escudo, incrementa streak, savedByXolotl', () async {
      // Día 1
      await service.registerDailyCheckin(now: DateTime(2026, 11, 1, 12, 0, 0));
      // Día 3 (salta día 2) - tiene 1 escudo inicial
      final result = await service.registerDailyCheckin(now: DateTime(2026, 11, 3, 12, 0, 0));

      expect(result.status, equals(StreakStatus.savedByXolotl));
      expect(result.state.currentStreak, equals(2));
      expect(result.state.xolotlShields, equals(0)); // consumió 1
      expect(result.state.lastCheckinDate, equals('2026-11-03'));
    });
  });

  group('Reinicio compasivo (diffDays == 2 sin escudos, diffDays >= 3)', () {
    test('diffDays == 2 con 0 escudos: resetCompassionate, streak=1, conserva longestStreak, mantiene escudos', () async {
      // Día 1
      await service.registerDailyCheckin(now: DateTime(2026, 11, 1, 12, 0, 0));
      // Usar el escudo saltando un día
      await service.registerDailyCheckin(now: DateTime(2026, 11, 3, 12, 0, 0)); // consume escudo, shields=0, streak=2
      // Ahora saltar otro día (día 5) sin escudos
      final result = await service.registerDailyCheckin(now: DateTime(2026, 11, 5, 12, 0, 0));

      expect(result.status, equals(StreakStatus.resetCompassionate));
      expect(result.state.currentStreak, equals(1));
      expect(result.state.longestStreak, equals(2)); // conserva el máximo histórico
      expect(result.state.xolotlShields, equals(0)); // mantiene escudos actuales
      expect(result.compassionateMessage, isNotEmpty);
    });

    test('diffDays >= 3 con escudos: resetCompassionate, streak=1, conserva longestStreak, mantiene escudos', () async {
      // Día 1
      await service.registerDailyCheckin(now: DateTime(2026, 11, 1, 12, 0, 0));
      // Día 5 (diffDays = 4)
      final result = await service.registerDailyCheckin(now: DateTime(2026, 11, 5, 12, 0, 0));

      expect(result.status, equals(StreakStatus.resetCompassionate));
      expect(result.state.currentStreak, equals(1));
      expect(result.state.longestStreak, equals(1));
      expect(result.state.xolotlShields, equals(1)); // mantiene el escudo inicial
      expect(result.compassionateMessage, isNotEmpty);
    });
  });

  group('Recarga y tope máximo del Amuleto de Obsidiana (cada 7 días, máx 2)', () {
    test('0 escudos -> día 7: sube a 1, shieldEarned=true', () async {
      // Consumir el escudo inicial saltando un día
      await service.registerDailyCheckin(now: DateTime(2026, 11, 1, 12, 0, 0)); // día 1, shields=1
      await service.registerDailyCheckin(now: DateTime(2026, 11, 3, 12, 0, 0)); // día 3, savedByXolotl, shields=0, streak=2
      // Continuar días consecutivos hasta día 7
      await service.registerDailyCheckin(now: DateTime(2026, 11, 4, 12, 0, 0)); // día 4, streak=3
      await service.registerDailyCheckin(now: DateTime(2026, 11, 5, 12, 0, 0)); // día 5, streak=4
      await service.registerDailyCheckin(now: DateTime(2026, 11, 6, 12, 0, 0)); // día 6, streak=5
      await service.registerDailyCheckin(now: DateTime(2026, 11, 7, 12, 0, 0)); // día 7, streak=6
      final result = await service.registerDailyCheckin(now: DateTime(2026, 11, 8, 12, 0, 0)); // día 8, streak=7

      expect(result.state.currentStreak, equals(7));
      expect(result.state.xolotlShields, equals(1));
      expect(result.shieldEarned, isTrue);
    });

    test('1 escudo -> día 7: sube a 2, shieldEarned=true', () async {
      // Día 1 a 7 consecutivos (sin perder escudos)
      for (int day = 1; day <= 7; day++) {
        await service.registerDailyCheckin(now: DateTime(2026, 11, day, 12, 0, 0));
      }
      // En día 7, streak=7, shields debería ser 2 (inicial 1 + 1 ganado)
      final state = await service.getState();
      expect(state.currentStreak, equals(7));
      expect(state.xolotlShields, equals(2));
    });

    test('2 escudos -> día 14: se queda en 2, shieldEarned=false', () async {
      // Día 1 a 14 consecutivos
      for (int day = 1; day <= 14; day++) {
        final result = await service.registerDailyCheckin(now: DateTime(2026, 11, day, 12, 0, 0));
        if (day == 14) {
          expect(result.state.currentStreak, equals(14));
          expect(result.state.xolotlShields, equals(2));
          expect(result.shieldEarned, isFalse); // ya estaba en tope
        }
      }
    });
  });

  group('Frontera de medianoche local', () {
    test('23:55 y 00:05 día siguiente = diffDays == 1 (incremented)', () async {
      // Check-in a las 23:55 del día 1
      await service.registerDailyCheckin(now: DateTime(2026, 11, 1, 23, 55, 0));
      // Check-in a las 00:05 del día 2 (solo 10 min después)
      final result = await service.registerDailyCheckin(now: DateTime(2026, 11, 2, 0, 5, 0));

      expect(result.status, equals(StreakStatus.incremented));
      expect(result.state.currentStreak, equals(2));
      expect(result.state.lastCheckinDate, equals('2026-11-02'));
    });
  });
}