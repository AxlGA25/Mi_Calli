// Tests for TonalpohualliGenerator using real SQLite FFI.
// Pruebas de disponibilidad (isReadingAvailable) y generación (generateWeeklyReading).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mi_calli/core/database/local_database_service.dart';
import 'package:mi_calli/core/database/secure_storage_mock.dart';
import 'package:mi_calli/core/settings/app_settings_service.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/prehispanic_emotion.dart';
import 'package:mi_calli/features/2_gamification/models/tonalpohualli_models.dart';
import 'package:mi_calli/features/2_gamification/services/tonalpohualli_generator.dart';
import 'package:mi_calli/features/2_gamification/presentation/tonalpohualli_scroll_dialog.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Inicializar SQLite FFI
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  late Directory tempDir;
  late LocalDatabaseService db;
  late AppSettingsService settings;
  late TonalpohualliGenerator generator;

  setUp(() async {
    // Directorio temporal para BD
    tempDir = await Directory.systemTemp.createTemp('tonalpohualli_test_');

    // BD de prueba con SQLite FFI (sin cifrado)
    final dbPath = '${tempDir.path}/test.db';
    final secureStorageMock = SecureStorageMock();
    db = LocalDatabaseService.createForTesting(
      secureStorage: secureStorageMock,
      databasePath: dbPath,
      databaseFactory: databaseFactory,
    );
    await db.initialize();

    // SharedPreferences mock
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    settings = AppSettingsService.createForTesting(prefs);

    generator = TonalpohualliGenerator(db, settings);
  });

  tearDown(() async {
    await db.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  // Helper: insertar entrada de diario usando insertDiaryEntry
  Future<void> insertEntry({
    required DateTime date,
    required String emotionId,
    String? wateredSeedId,
  }) async {
    await db.insertDiaryEntry(
      id: 'test_${date.millisecondsSinceEpoch}',
      createdAt: date,
      emotionId: emotionId,
      content: 'Nota de prueba',
      featherId: 'feather_${date.millisecondsSinceEpoch}',
      wateredSeedId: wateredSeedId,
      triggeredSos: false,
    );
  }

  // Helper: configurar fecha "now" fija para tests deterministas
  DateTime fixedNow(int year, int month, int day, {int hour = 12}) =>
      DateTime(year, month, day, hour);

  group('TonalpohualliGenerator - isReadingAvailable', () {
    test('Sin entradas en la semana → false (aunque sea domingo o hayan pasado 10 días)', () async {
      final now = fixedNow(2026, 11, 8); // Domingo
      final available = await generator.isReadingAvailable(now: now);
      expect(available, isFalse);
    });

    test('Se habilita en domingo: con 1 entrada en últimos 7 días y hoy domingo → true', () async {
      await insertEntry(
        date: fixedNow(2026, 11, 3), // Martes
        emotionId: 'tlaloc_lluvia',
        wateredSeedId: null,
      );
      final now = fixedNow(2026, 11, 8); // Domingo
      final available = await generator.isReadingAvailable(now: now);
      expect(available, isTrue);
    });

    test('Sigue disponible hasta abrirse (no desaparece el lunes): '
        'última lectura hace 4 días (jueves), pasa domingo sin abrir, entra lunes → true', () async {
      // Simular última lectura el jueves 2026-11-05
      await settings.setLastAstralReadingDate('2026-11-05');

      // Entrada el sábado 2026-11-07 (dentro de los 7 días)
      await insertEntry(
        date: fixedNow(2026, 11, 7),
        emotionId: 'tlaloc_lluvia',
        wateredSeedId: null,
      );

      // Usuario entra el lunes 2026-11-09 (cruzó domingo sin abrir)
      final now = fixedNow(2026, 11, 9);
      final available = await generator.isReadingAvailable(now: now);
      expect(available, isTrue);
    });

    test('Sigue disponible hasta abrirse (primera vez): entrada en sábado, pasa domingo sin abrir, entra martes → true', () async {
      // Sin lastAstralReadingDate (primera vez)
      // Entrada el sábado 2026-11-07
      await insertEntry(
        date: fixedNow(2026, 11, 7),
        emotionId: 'tlaloc_lluvia',
        wateredSeedId: null,
      );

      // Usuario entra el martes 2026-11-10 (cruzó domingo sin abrir)
      final now = fixedNow(2026, 11, 10);
      final available = await generator.isReadingAvailable(now: now);
      expect(available, isTrue);
    });

    test('Se habilita a los 7 días de la última lectura: '
        'última lectura miércoles 2026-11-04, hoy miércoles 2026-11-11 (diffDays == 7) → true', () async {
      await settings.setLastAstralReadingDate('2026-11-04');

      // Entrada en la semana actual (ej. lunes 2026-11-09)
      await insertEntry(
        date: fixedNow(2026, 11, 9),
        emotionId: 'tonatiuh_sol',
        wateredSeedId: null,
      );

      final now = fixedNow(2026, 11, 11); // Miércoles siguiente
      final available = await generator.isReadingAvailable(now: now);
      expect(available, isTrue);
    });

    test('Una vez abierta hoy, se deshabilita hasta el siguiente ciclo: '
        'markReadingAsOpened guarda YYYY-MM-DD y isReadingAvailable mismo día → false', () async {
      await insertEntry(
        date: fixedNow(2026, 11, 3),
        emotionId: 'tlaloc_lluvia',
        wateredSeedId: null,
      );

      final now = fixedNow(2026, 11, 8); // Domingo
      // Generar y marcar como abierta
      await generator.generateWeeklyReading(now: now, markAsOpened: true);

      // Verificar que ya no está disponible el mismo día
      final availableSameDay = await generator.isReadingAvailable(now: now);
      expect(availableSameDay, isFalse);

      // Tampoco al día siguiente (lunes) si no es domingo ni han pasado 7 días
      final nextDay = fixedNow(2026, 11, 9);
      final availableNextDay = await generator.isReadingAvailable(now: nextDay);
      expect(availableNextDay, isFalse);
    });

    test('Ventana de 7 días empieza a medianoche: '
        'entrada temprano hace 6 días (06:00) sigue contando dentro de la ventana', () async {
      // Entrada hace 6 días a las 06:00 (temprano en la mañana)
      final sixDaysAgoEarly = fixedNow(2026, 11, 6, hour: 6); // Viernes 06:00
      await insertEntry(
        date: sixDaysAgoEarly,
        emotionId: 'tlaloc_lluvia',
        wateredSeedId: null,
      );

      // Hoy miércoles 2026-11-12 a mediodía (6 días después)
      final now = fixedNow(2026, 11, 12, hour: 12);
      final available = await generator.isReadingAvailable(now: now);
      expect(available, isTrue);
    });
  });

  group('TonalpohualliGenerator - generateWeeklyReading', () {
    test('Sin entradas en los últimos 7 días → null', () async {
      final now = fixedNow(2026, 11, 8);
      final reading = await generator.generateWeeklyReading(now: now);
      expect(reading, isNull);
    });

    test('Semana de datos de ejemplo: 3 tlaloc_lluvia, 1 tonatiuh_sol, 1 ehecatl_viento, '
        '4 con watered_seed_id → rulingEmotion = tlalocLluvia, frecuencias correctas, párrafos coherentes', () async {
      final now = fixedNow(2026, 11, 8); // Domingo

      // 3 entradas tlaloc_lluvia (2 con watered_seed_id)
      await insertEntry(date: fixedNow(2026, 11, 2), emotionId: 'tlaloc_lluvia', wateredSeedId: 'seed_1');
      await insertEntry(date: fixedNow(2026, 11, 4), emotionId: 'tlaloc_lluvia', wateredSeedId: 'seed_2');
      await insertEntry(date: fixedNow(2026, 11, 6), emotionId: 'tlaloc_lluvia', wateredSeedId: null);

      // 1 entrada tonatiuh_sol (con watered_seed_id)
      await insertEntry(date: fixedNow(2026, 11, 3), emotionId: 'tonatiuh_sol', wateredSeedId: 'seed_3');

      // 1 entrada ehecatl_viento (con watered_seed_id)
      await insertEntry(date: fixedNow(2026, 11, 5), emotionId: 'ehecatl_viento', wateredSeedId: 'seed_4');

      final reading = await generator.generateWeeklyReading(now: now);

      expect(reading, isNotNull);
      expect(reading!.rulingEmotion, equals(PrehispanicEmotion.tlalocLluvia));
      expect(reading.mysticTitle, equals('Bajo el Manto de Tláloc'));

      // Verificar vector de frecuencias
      expect(reading.emotionFrequencies['tlaloc_lluvia'], equals(3));
      expect(reading.emotionFrequencies['tonatiuh_sol'], equals(1));
      expect(reading.emotionFrequencies['ehecatl_viento'], equals(1));
      expect(reading.emotionFrequencies['mixcoatl_tormenta'], equals(0));
      expect(reading.emotionFrequencies['metztli_noche'], equals(0));

      // Verificar totales
      expect(reading.totalEntries, equals(5));
      expect(reading.nourishedSproutsCount, equals(4));

      // Verificar párrafos
      expect(reading.openingParagraph, contains('Los sabios observadores del cielo vieron que las aguas de Tláloc'));
      expect(reading.bodyParagraph, contains('4 brotes nutridos'));
      expect(reading.bodyParagraph, contains('5 ofrendas'));
      expect(reading.venusOmenParagraph, isNotEmpty);
      expect(reading.venusOmenParagraph, contains('Venus'));
    });

    test('Desempate determinista: dos emociones empatan en máximo, gana la más reciente', () async {
      final now = fixedNow(2026, 11, 8);

      // tlaloc_lluvia: 2 entradas (más antigua el 2, más reciente el 5)
      await insertEntry(date: fixedNow(2026, 11, 2), emotionId: 'tlaloc_lluvia', wateredSeedId: null);
      await insertEntry(date: fixedNow(2026, 11, 5), emotionId: 'tlaloc_lluvia', wateredSeedId: null);

      // tonatiuh_sol: 2 entradas (más antigua el 3, más reciente el 7 - MÁS RECIENTE)
      await insertEntry(date: fixedNow(2026, 11, 3), emotionId: 'tonatiuh_sol', wateredSeedId: null);
      await insertEntry(date: fixedNow(2026, 11, 7), emotionId: 'tonatiuh_sol', wateredSeedId: null);

      final reading = await generator.generateWeeklyReading(now: now);

      expect(reading, isNotNull);
      // tonatiuh_sol gana porque su entrada más reciente (7) es posterior a la de tlaloc_lluvia (5)
      expect(reading!.rulingEmotion, equals(PrehispanicEmotion.tonatiuhSol));
      expect(reading.mysticTitle, equals('El Resplandor de Tonatiuh'));
    });

    test('Todas las 5 emociones producen lecturas coherentes con su mysticTitle', () async {
      final emotionTestCases = [
        ('tlaloc_lluvia', PrehispanicEmotion.tlalocLluvia, 'Bajo el Manto de Tláloc', 'aguas de Tláloc'),
        ('tonatiuh_sol', PrehispanicEmotion.tonatiuhSol, 'El Resplandor de Tonatiuh', 'Sol de Tonatiuh'),
        ('ehecatl_viento', PrehispanicEmotion.ehecatlViento, 'El Aliento de Ehécatl', 'Viento de Ehécatl'),
        ('mixcoatl_tormenta', PrehispanicEmotion.mixcoatlTormenta, 'El Fuego de Mixcóatl', 'Tormenta de Mixcóatl'),
        ('metztli_noche', PrehispanicEmotion.metztliNoche, 'La Calma Estelar de Metztli', 'Noche de Metztli'),
      ];

      for (final (emotionId, expectedEmotion, expectedTitle, expectedKeyword) in emotionTestCases) {
        // Limpiar BD para cada test
        await db.database.delete('diary_entries');

        final now = fixedNow(2026, 11, 8);
        // 3 entradas de la emoción bajo test, 1 de otra
        await insertEntry(date: fixedNow(2026, 11, 2), emotionId: emotionId, wateredSeedId: null);
        await insertEntry(date: fixedNow(2026, 11, 4), emotionId: emotionId, wateredSeedId: null);
        await insertEntry(date: fixedNow(2026, 11, 6), emotionId: emotionId, wateredSeedId: null);
        await insertEntry(date: fixedNow(2026, 11, 3), emotionId: 'tonatiuh_sol', wateredSeedId: null);

        final reading = await generator.generateWeeklyReading(now: now);

        expect(reading, isNotNull, reason: 'Lectura no generada para $emotionId');
        expect(reading!.rulingEmotion, equals(expectedEmotion), reason: 'Ruling emotion incorrecta para $emotionId');
        expect(reading.mysticTitle, equals(expectedTitle), reason: 'MysticTitle incorrecto para $emotionId');
        expect(reading.openingParagraph, contains(expectedKeyword), reason: 'OpeningParagraph no menciona keyword para $emotionId');
        expect(reading.venusOmenParagraph, isNotEmpty, reason: 'VenusOmenParagraph vacío para $emotionId');
      }
    });
  });

  group('TonalpohualliScrollDialog - Widget Tests', () {
    // Helper para crear una WeeklyAstralReading de prueba
    WeeklyAstralReading createTestReading() {
      return WeeklyAstralReading(
        rulingEmotion: PrehispanicEmotion.tlalocLluvia,
        mysticTitle: 'Bajo el Manto de Tláloc',
        emotionFrequencies: {
          'tlaloc_lluvia': 3,
          'tonatiuh_sol': 1,
          'ehecatl_viento': 1,
          'mixcoatl_tormenta': 0,
          'metztli_noche': 0,
        },
        totalEntries: 5,
        nourishedSproutsCount: 4,
        openingParagraph:
            'Los sabios observadores del cielo vieron que las aguas de Tláloc '
            'bañaron tu valle esta semana. Cada gota que cayó sobre tu sembradío '
            'fue un susurro de la montaña, recordándote que la tristeza también riega '
            'y que de lo hondo brota lo más verde.',
        bodyParagraph:
            'Tu chinampa guardó memoria de 4 brotes nutridos '
            'entre las 5 ofrendas que dejaste en el altar. Cada riego fue '
            'una promesa cumplida, cada semilla bebida un pacto con la tierra. '
            'Quetzalcóatl sonríe al ver que tus manos no olvidaron el surco.',
        venusOmenParagraph:
            'Venus, lucero de la mañana, asoma sobre el horizonte y susurra: '
            '"Las aguas que hoy caen son los ríos del mañana. Confía en tu valle."',
        generatedAt: DateTime.now().toUtc(),
      );
    }

    testWidgets('Renderiza TonalpohualliScrollDialog con WeeklyAstralReading de prueba, '
        'muestra mysticTitle, 3 párrafos, soporta TextScaler 200% sin overflow, '
        'botón de cierre ejecuta callback / cierra el diálogo', (WidgetTester tester) async {
      final testReading = createTestReading();
      bool closeCallbackCalled = false;

      // Construir el widget envuelto en MaterialApp para tema y navegación
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TonalpohualliScrollDialog(
              reading: testReading,
              onClose: () => closeCallbackCalled = true,
            ),
          ),
        ),
      );

      // 1. Verificar que muestra el mysticTitle
      expect(find.text('Bajo el Manto de Tláloc'), findsOneWidget);

      // 2. Verificar que muestra los 3 párrafos
      expect(find.textContaining('Los sabios observadores del cielo vieron que las aguas de Tláloc'), findsOneWidget);
      expect(find.textContaining('Tu chinampa guardó memoria de 4 brotes nutridos'), findsOneWidget);
      expect(find.textContaining('Venus, lucero de la mañana, asoma sobre el horizonte'), findsOneWidget);

      // 3. Verificar resumen visual (totalEntries y nourishedSproutsCount)
      expect(find.text('5'), findsWidgets); // Desahogos
      expect(find.text('4'), findsWidgets); // Brotes nutridos

      // 4. Probar TextScaler 200% (2.0) - simular escalado de texto grande
      // Flutter usa MediaQuery para textScaler, así que envolvemos con un MediaQuery modificado
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(2.0), // 200% de texto
              ),
              child: TonalpohualliScrollDialog(
                reading: testReading,
                onClose: () => closeCallbackCalled = true,
              ),
            ),
          ),
        ),
      );

      // Verificar que no hay errores de overflow (el diálogo debe renderizarse sin excepciones)
      // Si hay overflow, Flutter lo reporta como error en la consola de tests
      expect(tester.takeException(), isNull);

      // Los textos siguen estando presentes tras el escalado
      expect(find.text('Bajo el Manto de Tláloc'), findsOneWidget);
      expect(find.textContaining('Los sabios observadores del cielo vieron que las aguas de Tláloc'), findsOneWidget);
      expect(find.textContaining('Tu chinampa guardó memoria de 4 brotes nutridos'), findsOneWidget);
      expect(find.textContaining('Venus, lucero de la mañana, asoma sobre el horizonte'), findsOneWidget);

      // 5. Probar botón de cierre - debe ejecutar callback y cerrar el diálogo
      // Volver a escala normal para test de interacción
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TonalpohualliScrollDialog(
              reading: testReading,
              onClose: () => closeCallbackCalled = true,
            ),
          ),
        ),
      );

      // Encontrar y tocar el botón "Cerrar lectura"
      final closeButtonFinder = find.text('Cerrar lectura');
      expect(closeButtonFinder, findsOneWidget);

      await tester.tap(closeButtonFinder);
      await tester.pumpAndSettle();

      // Verificar que se ejecutó el callback
      expect(closeCallbackCalled, isTrue);

      // Verificar que el diálogo se cerró (ya no está en el árbol)
      expect(find.text('Bajo el Manto de Tláloc'), findsNothing);
    });

    testWidgets('show() static method abre el diálogo correctamente', (WidgetTester tester) async {
      final testReading = createTestReading();
      bool closeCallbackCalled = false;

      // Usar Navigator para probar show()
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => TonalpohualliScrollDialog.show(
                context,
                reading: testReading,
                onClose: () => closeCallbackCalled = true,
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      );

      // Tocar botón para abrir diálogo
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      // Verificar que el diálogo está visible
      expect(find.text('Bajo el Manto de Tláloc'), findsOneWidget);
      expect(find.textContaining('Los sabios observadores del cielo vieron que las aguas de Tláloc'), findsOneWidget);

      // Cerrar con el botón
      await tester.tap(find.text('Cerrar lectura'));
      await tester.pumpAndSettle();

      // Verificar callback y cierre
      expect(closeCallbackCalled, isTrue);
      expect(find.text('Bajo el Manto de Tláloc'), findsNothing);
    });

    testWidgets('Diálogo es accesible: Semantics labels presentes en widget tree', (WidgetTester tester) async {
      final testReading = createTestReading();

      // Usar show() para abrir el diálogo correctamente (como en el test que pasa)
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => TonalpohualliScrollDialog.show(
                context,
                reading: testReading,
                onClose: () {},
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      );

      // Abrir el diálogo
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      // Encontrar todos los widgets Text en el árbol y verificar sus semanticsLabel
      final textWidgets = tester.allWidgets.whereType<Text>().toList();

      // Verificar Semantics en el encabezado (Text con semanticsLabel)
      final titleText = textWidgets.firstWhere(
        (t) => t.data == 'Bajo el Manto de Tláloc',
        orElse: () => throw StateError('Title text not found'),
      );
      expect(titleText.semanticsLabel, equals('Título de la lectura: Bajo el Manto de Tláloc'));

      final deityText = textWidgets.firstWhere(
        (t) => t.data == 'Lluvia de Tláloc',
        orElse: () => throw StateError('Deity text not found'),
      );
      expect(deityText.semanticsLabel, equals('Astro Regente: Lluvia de Tláloc'));

      // Verificar que los párrafos existen (usan Semantics widget envolvente)
      expect(textWidgets.any((t) => t.data!.contains('Los sabios observadores del cielo vieron que las aguas de Tláloc')), isTrue);
      expect(textWidgets.any((t) => t.data!.contains('Tu chinampa guardó memoria de 4 brotes nutridos')), isTrue);
      expect(textWidgets.any((t) => t.data!.contains('Venus, lucero de la mañana, asoma sobre el horizonte')), isTrue);

      // Verificar resumen visual
      expect(textWidgets.any((t) => t.data == '5'), isTrue); // Desahogos
      expect(textWidgets.any((t) => t.data == '4'), isTrue); // Brotes nutridos

      // Verificar botón de cierre
      expect(textWidgets.any((t) => t.data == 'Cerrar lectura'), isTrue);
    });
  });
}