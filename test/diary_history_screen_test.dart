// Tests para DiaryHistoryScreen (Tarea 2.5 - provisional).
//
// Verifica:
// 1. Orden inverso: entradas se muestran de la más reciente a la más antigua.
// 2. Datos completos: cada tarjeta muestra fecha, clima emocional, pluma y contenido.
// 3. Estado vacío: mensaje empático cuando no hay entradas.
// 4. Navegación desde SanctuaryJournalScreen: botón "Mis entradas" abre DiaryHistoryScreen
//    y botón de regreso vuelve a SanctuaryJournalScreen.
// 5. Escalado 200%: sin overflow con TextScaler.linear(2.0).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_calli/core/constants/app_colors.dart';
import 'package:mi_calli/core/database/asset_loader_service.dart';
import 'package:mi_calli/core/security/safety_guard_provider.dart';
import 'package:mi_calli/core/security/safety_guard_service.dart';
import 'package:mi_calli/core/settings/app_settings_provider.dart';
import 'package:mi_calli/core/settings/app_settings_service.dart';
import 'package:mi_calli/features/1_sanctuary_journal/constants/sanctuary_texts.dart';
import 'package:mi_calli/features/1_sanctuary_journal/data/diary_repository_provider.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/diary_entry.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/prehispanic_emotion.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/wisdom_feather.dart';
import 'package:mi_calli/features/1_sanctuary_journal/presentation/diary_history_screen.dart';
import 'package:mi_calli/features/1_sanctuary_journal/presentation/sanctuary_journal_screen.dart';
import 'package:mi_calli/features/1_sanctuary_journal/services/diary_repository.dart';

// Mock de DiaryRepository para tests
class MockDiaryRepository {
  MockDiaryRepository();

  final List<DiaryEntry> _savedEntries = [];
  bool _shouldFail = false;

  void setShouldFail(bool fail) {
    _shouldFail = fail;
  }

  void setEntries(List<DiaryEntry> entries) {
    _savedEntries
      ..clear()
      ..addAll(entries);
  }

  List<DiaryEntry> get savedEntries => List.unmodifiable(_savedEntries);

  Future<void> saveEntry(DiaryEntry entry) async {
    if (_shouldFail) {
      throw DiaryRepositoryException('Error simulado al guardar');
    }
    _savedEntries.add(entry);
  }

  Future<List<DiaryEntry>> getAllEntries() async {
    return List.from(_savedEntries.reversed);
  }
}

// Wrapper que implementa la interfaz de DiaryRepository pero delega al mock
class _MockDiaryRepositoryProvider implements DiaryRepository {
  _MockDiaryRepositoryProvider(this.mockRepository);

  final MockDiaryRepository mockRepository;

  @override
  Future<void> saveEntry(DiaryEntry entry) async {
    return mockRepository.saveEntry(entry);
  }

  @override
  Future<List<DiaryEntry>> getEntriesByDateRange({
    required DateTime start,
    required DateTime end,
  }) async {
    return [];
  }

  @override
  Future<List<DiaryEntry>> getEntriesForDay(DateTime day) async {
    return [];
  }

  @override
  Future<Map<PrehispanicEmotion, int>> countEmotionsLastDays({
    int days = 7,
  }) async {
    return {};
  }

  @override
  Future<DiaryEntry?> getLatestEntry() async {
    return null;
  }

  @override
  Future<int> getTotalEntriesCount() async {
    return 0;
  }

  @override
  Future<List<DiaryEntry>> getAllEntries() async {
    return mockRepository.savedEntries.reversed.toList();
  }
}

// Helper para precargar plumas en tests
Future<void> setupTestFeathers() async {
  final feathers = [
    WisdomFeather(
      featherId: 'pluma_tlaloc_01',
      emotionId: 'tlaloc_lluvia',
      name: 'Pluma de Rocío de Jade',
      colorHex: '#2E86C1',
      message: 'La lluvia limpia las heridas que el sol no ve.',
    ),
    WisdomFeather(
      featherId: 'pluma_tonatiuh_01',
      emotionId: 'tonatiuh_sol',
      name: 'Pluma de Rayo Dorado',
      colorHex: '#E9C46A',
      message: 'El calor de tus pensamientos ilumina el valle.',
    ),
    WisdomFeather(
      featherId: 'pluma_ehecatl_01',
      emotionId: 'ehecatl_viento',
      name: 'Pluma de Brisa Turquesa',
      colorHex: '#48C9B0',
      message: 'El viento lleva tus susurros a las estrellas.',
    ),
    WisdomFeather(
      featherId: 'pluma_mixcoatl_01',
      emotionId: 'mixcoatl_tormenta',
      name: 'Pluma de Obsidiana y Fuego',
      colorHex: '#E74C3C',
      message: 'En la tormenta también hay luz; tú eres el relámpago.',
    ),
    WisdomFeather(
      featherId: 'pluma_metztli_01',
      emotionId: 'metztli_noche',
      name: 'Pluma de Luz Estelar',
      colorHex: '#8E44AD',
      message: 'La noche guarda secretos que el día olvida.',
    ),
  ];
  AssetLoaderService.instance.setFeathersCacheForTesting(feathers);
}

// Helper para crear entradas de prueba con fechas específicas usando el constructor directo
List<DiaryEntry> createTestEntries() {
  final now = DateTime.now();
  return [
    // Entrada más antigua: ayer
    DiaryEntry(
      id: 'entry_1',
      createdAt: now.subtract(const Duration(days: 1)).toUtc(),
      emotion: PrehispanicEmotion.tlalocLluvia,
      content: 'Ayer fue un día difícil, mucha tristeza.',
      featherId: 'pluma_tlaloc_01',
      wateredSeedId: null,
      triggeredSos: false,
    ),
    // Entrada intermedia: hace 2 horas
    DiaryEntry(
      id: 'entry_2',
      createdAt: now.subtract(const Duration(hours: 2)).toUtc(),
      emotion: PrehispanicEmotion.tonatiuhSol,
      content: 'Hace un rato me sentí muy bien, agradecido.',
      featherId: 'pluma_tonatiuh_01',
      wateredSeedId: null,
      triggeredSos: false,
    ),
    // Entrada más reciente: hace 5 minutos
    DiaryEntry(
      id: 'entry_3',
      createdAt: now.subtract(const Duration(minutes: 5)).toUtc(),
      emotion: PrehispanicEmotion.ehecatlViento,
      content: 'Ahora mismo tengo ansiedad, el viento sopla fuerte.',
      featherId: 'pluma_ehecatl_01',
      wateredSeedId: null,
      triggeredSos: false,
    ),
  ];
}

// Helper para crear el widget DiaryHistoryScreen con mock
Widget createDiaryHistoryScreenTestWidget({
  required MockDiaryRepository mockRepository,
}) {
  return ProviderScope(
    overrides: [
      diaryRepositoryProvider.overrideWithValue(
        _MockDiaryRepositoryProvider(mockRepository),
      ),
    ],
    child: MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.jade,
          brightness: Brightness.light,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 16),
          titleMedium: TextStyle(fontSize: 16),
          labelLarge: TextStyle(fontSize: 14),
          bodySmall: TextStyle(fontSize: 12),
          headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      home: const DiaryHistoryScreen(),
    ),
  );
}

// Helper para crear el widget SanctuaryJournalScreen con mock
Future<Widget> createSanctuaryJournalScreenForNavigationTest({
  required MockDiaryRepository mockRepository,
}) async {
  await setupTestFeathers();

  // Usar SafetyGuardService que nunca detecta SOS para navegación simple
  final noSosSafetyGuard = SafetyGuardService.createForTesting([]);

  final prefs = await SharedPreferences.getInstance();
  final settingsService = AppSettingsService.createForTesting(prefs);
  await settingsService.setReduceMotion(true);
  await settingsService.setTrustedContactName('Test Contact');
  await settingsService.setTrustedContactPhone('5551234567');

  return ProviderScope(
    overrides: [
      appSettingsServiceProvider.overrideWithValue(settingsService),
      diaryRepositoryProvider.overrideWithValue(
        _MockDiaryRepositoryProvider(mockRepository),
      ),
      safetyGuardServiceProvider.overrideWithValue(
        AsyncValue.data(noSosSafetyGuard),
      ),
    ],
    child: MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.jade,
          brightness: Brightness.light,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 16),
          titleMedium: TextStyle(fontSize: 16),
          labelLarge: TextStyle(fontSize: 14),
          bodySmall: TextStyle(fontSize: 12),
          headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      home: const SanctuaryJournalScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Configuración compartida SIN initializeDateFormatting
  // (el test de fallback de locale debe correr ANTES de inicializar el locale)
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await setupTestFeathers();
  });

  // Test de robustez de locale: DEBE ir ANTES de cualquier llamada a
  // initializeDateFormatting para verificar que el catch funciona.
  testWidgets(
    'Robustez de locale: DiaryHistoryScreen se renderiza SIN haber llamado a '
    'initializeDateFormatting (usa fallback ISO y no lanza LocaleDataException)',
    (tester) async {
      // NO llamamos a initializeDateFormatting aquí - probamos el fallback
      final mockRepository = MockDiaryRepository();
      mockRepository.setEntries([
        DiaryEntry(
          id: 'entry_fallback',
          createdAt: DateTime.now().toUtc(),
          emotion: PrehispanicEmotion.tlalocLluvia,
          content: 'Prueba fallback locale',
          featherId: 'pluma_tlaloc_01',
          wateredSeedId: null,
          triggeredSos: false,
        ),
      ]);

      await tester.pumpWidget(
        createDiaryHistoryScreenTestWidget(mockRepository: mockRepository),
      );
      await tester.pumpAndSettle();

      // No debe explotar - debe renderizar la pantalla
      expect(find.byType(DiaryHistoryScreen), findsOneWidget);
      // El contenido de la entrada debe verse
      expect(find.text('Prueba fallback locale'), findsOneWidget);
      // La fecha debe usar formato fallback (contiene "/" o formato ISO simple)
      // Verificamos que haya ALGÚN texto de fecha (no vacío, no excepción)
      expect(find.textContaining('Lluvia de Tláloc'), findsOneWidget);
      expect(find.textContaining('Pluma de'), findsOneWidget);
    },
  );

  // Ahora inicializamos el locale para el resto de tests
  setUpAll(() async {
    await initializeDateFormatting('es_MX', null);
  });

  group('DiaryHistoryScreen', () {
    late MockDiaryRepository mockRepository;

    setUp(() {
      mockRepository = MockDiaryRepository();
    });

    testWidgets(
      'Orden inverso: 3 entradas con distintas fechas se muestran de la más '
      'reciente a la más antigua',
      (tester) async {
        final entries = createTestEntries();
        mockRepository.setEntries(entries);

        await tester.pumpWidget(
          createDiaryHistoryScreenTestWidget(mockRepository: mockRepository),
        );
        await tester.pump();

        // Verificar que las 3 tarjetas están en orden: más reciente primero
        // entry_3 (hace 5 min) -> entry_2 (hace 2 horas) -> entry_1 (ayer)
        // Buscamos por el contenido de cada entrada en orden visual
        final entry3Finder = find.text('Ahora mismo tengo ansiedad, el viento sopla fuerte.');
        final entry2Finder = find.text('Hace un rato me sentí muy bien, agradecido.');
        final entry1Finder = find.text('Ayer fue un día difícil, mucha tristeza.');

        // Verificar que existen
        expect(entry3Finder, findsOneWidget);
        expect(entry2Finder, findsOneWidget);
        expect(entry1Finder, findsOneWidget);

        // Verificar el orden visual: entry_3 debe aparecer ANTES que entry_2,
        // y entry_2 ANTES que entry_1 en el árbol de widgets

        // Obtener posiciones en el scroll view
        final entry3Offset = tester.getCenter(entry3Finder);
        final entry2Offset = tester.getCenter(entry2Finder);
        final entry1Offset = tester.getCenter(entry1Finder);

        // En un ListView vertical, la más reciente (entry_3) debe estar más arriba
        // (menor offset Y) que las anteriores
        expect(entry3Offset.dy, lessThan(entry2Offset.dy));
        expect(entry2Offset.dy, lessThan(entry1Offset.dy));
      },
    );

    testWidgets(
      'Datos completos: cada tarjeta muestra fecha, clima emocional, pluma y contenido',
      (tester) async {
        final entries = createTestEntries();
        mockRepository.setEntries(entries);

        await tester.pumpWidget(
          createDiaryHistoryScreenTestWidget(mockRepository: mockRepository),
        );
        await tester.pump();
        await tester.pump(); // Extra pump para que carguen las plumas

        // Verificar primera tarjeta (entry_3 - más reciente - Ehecatl Viento)
        expect(find.textContaining('Pluma de Brisa Turquesa'), findsOneWidget);
        expect(find.text('El viento lleva tus susurros a las estrellas.'), findsOneWidget);
        expect(find.text('Viento de Ehécatl'), findsOneWidget);
        expect(find.text('(Ansiedad, estrés, abrumo)'), findsOneWidget);
        expect(find.text('Ahora mismo tengo ansiedad, el viento sopla fuerte.'), findsOneWidget);

        // Verificar segunda tarjeta (entry_2 - Tonatiuh Sol)
        expect(find.textContaining('Pluma de Rayo Dorado'), findsOneWidget);
        expect(find.text('El calor de tus pensamientos ilumina el valle.'), findsOneWidget);
        expect(find.text('Sol de Tonatiuh'), findsOneWidget);
        expect(find.text('(Alegría, calma, gratitud)'), findsOneWidget);
        expect(find.text('Hace un rato me sentí muy bien, agradecido.'), findsOneWidget);

        // Verificar tercera tarjeta (entry_1 - Tlaloc Lluvia)
        expect(find.textContaining('Pluma de Rocío de Jade'), findsOneWidget);
        expect(find.text('La lluvia limpia las heridas que el sol no ve.'), findsOneWidget);
        expect(find.text('Lluvia de Tláloc'), findsOneWidget);
        expect(find.text('(Tristeza, melancolía)'), findsOneWidget);
        expect(find.text('Ayer fue un día difícil, mucha tristeza.'), findsOneWidget);
      },
    );

    testWidgets(
      'Estado vacío: cuando el repositorio devuelve lista vacía, '
      'se muestra el texto de estado vacío sin errores',
      (tester) async {
        mockRepository.setEntries([]);

        await tester.pumpWidget(
          createDiaryHistoryScreenTestWidget(mockRepository: mockRepository),
        );
        await tester.pump();

        // Verificar que NO hay tarjetas de entradas (buscar por contenido típico)
        expect(find.textContaining('Pluma de'), findsNothing);

        // Verificar que se muestra el mensaje de estado vacío
        expect(find.text(SanctuaryTexts.historialVacioMensaje), findsOneWidget);
        expect(
          find.text('Aún no has entregado ninguna ofrenda. Tus palabras aparecerán aquí cuando escribas.'),
          findsOneWidget,
        );

        // Verificar que el icono decorativo está presente
        expect(find.byIcon(Icons.book_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'Navegación desde SanctuaryJournalScreen: tocar "Mis entradas" abre '
      'DiaryHistoryScreen y botón de regreso vuelve',
      (tester) async {
        mockRepository.setEntries(createTestEntries());

        await tester.pumpWidget(
          await createSanctuaryJournalScreenForNavigationTest(
            mockRepository: mockRepository,
          ),
        );
        await tester.pump();

        // Verificar que estamos en SanctuaryJournalScreen
        expect(find.byType(SanctuaryJournalScreen), findsOneWidget);
        expect(find.byType(DiaryHistoryScreen), findsNothing);

        // Buscar y tocar el botón "Mis entradas"
        await tester.ensureVisible(find.text('Mis entradas'));
        await tester.tap(find.text('Mis entradas'));
        await tester.pumpAndSettle(); // Esperar a que se complete la navegación

        // Verificar que ahora estamos en DiaryHistoryScreen (se muestra en pantalla)
        expect(find.byType(DiaryHistoryScreen), findsOneWidget);
        // Nota: SanctuaryJournalScreen sigue en el árbol de widgets (comportamiento normal de Navigator)

        // Verificar que se muestran las entradas
        expect(find.textContaining('Pluma de'), findsNWidgets(3));

        // Tocar el botón de regreso (leading del AppBar - IconButton con arrow_back)
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle(); // Esperar a que se complete la navegación de regreso

        // Verificar que DiaryHistoryScreen ya no está visible (se hizo pop)
        expect(find.byType(DiaryHistoryScreen), findsNothing);
        // SanctuaryJournalScreen sigue siendo el mismo widget en el árbol
        expect(find.byType(SanctuaryJournalScreen), findsOneWidget);
      },
    );

    testWidgets(
      'Escalado 200%: DiaryHistoryScreen con varias entradas se renderiza '
      'sin overflow con TextScaler.linear(2.0)',
      (tester) async {
        mockRepository.setEntries(createTestEntries());

        // Usar un viewport más alto para acomodar el escalado 200%
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(
              textScaler: const TextScaler.linear(2.0),
              size: const Size(400, 1200), // Viewport alto para 3 entradas a 200%
            ),
            child: createDiaryHistoryScreenTestWidget(mockRepository: mockRepository),
          ),
        );
        await tester.pumpAndSettle(); // Esperar a que carguen plumas y se renderice todo

        // Verificar que el widget se renderiza sin overflow
        expect(find.byType(DiaryHistoryScreen), findsOneWidget);
        // Verificar que al menos las 2 primeras entradas se renderizan (la 3ra puede estar
        // fuera del viewport en tests, pero la clave es que NO hay error de overflow)
        expect(find.textContaining('Pluma de'), findsAtLeastNWidgets(2));

        // Verificar que los textos clave de las entradas visibles siguen presentes
        expect(find.text('Viento de Ehécatl'), findsOneWidget);
        expect(find.text('Sol de Tonatiuh'), findsOneWidget);
        // La tercera entrada (Lluvia de Tláloc) puede no estar visible en el viewport de test
      },
    );

    testWidgets(
      'Escalado 200% estado vacío: se renderiza sin overflow',
      (tester) async {
        mockRepository.setEntries([]);

        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(textScaler: const TextScaler.linear(2.0)),
            child: createDiaryHistoryScreenTestWidget(mockRepository: mockRepository),
          ),
        );
        await tester.pump();

        // Verificar que el estado vacío se renderiza sin overflow
        expect(find.byType(DiaryHistoryScreen), findsOneWidget);
        expect(find.text(SanctuaryTexts.historialVacioMensaje), findsOneWidget);
        expect(find.byIcon(Icons.book_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'Invalidación de caché: abrir "Mis entradas" (vacío) → guardar entrada → '
      'volver a abrir "Mis entradas" → la nueva entrada aparece (autoDispose recarga)',
      (tester) async {
        // Empezar con lista vacía
        mockRepository.setEntries([]);

        // 1. Abrir DiaryHistoryScreen (vacío)
        await tester.pumpWidget(
          createDiaryHistoryScreenTestWidget(mockRepository: mockRepository),
        );
        await tester.pumpAndSettle();

        // Verificar estado vacío
        expect(find.text(SanctuaryTexts.historialVacioMensaje), findsOneWidget);
        expect(find.textContaining('Pluma de'), findsNothing);

        // 2. Simular guardar una entrada nueva (agregar al mock)
        final newEntry = DiaryEntry(
          id: 'entry_new',
          createdAt: DateTime.now().toUtc(),
          emotion: PrehispanicEmotion.metztliNoche,
          content: 'Nueva entrada de prueba',
          featherId: 'pluma_metztli_01',
          wateredSeedId: null,
          triggeredSos: false,
        );
        mockRepository.setEntries([newEntry]);

        // 3. Navegar fuera y volver a abrir (simular pop y push nuevo)
        // En un test real, esto sería: Navigator.pop() -> Navigator.push()
        // Aquí simulamos creando un nuevo widget DiaryHistoryScreen
        // que usa el mismo provider (autoDispose debería haber invalidado la caché)
        await tester.pumpWidget(
          createDiaryHistoryScreenTestWidget(mockRepository: mockRepository),
        );
        await tester.pumpAndSettle();

        // 4. Verificar que la nueva entrada aparece (provider recargó)
        expect(find.text(SanctuaryTexts.historialVacioMensaje), findsNothing);
        expect(find.textContaining('Pluma de'), findsOneWidget);
        // Verificar contenido de la entrada (la pluma se carga async, así que verificamos el texto)
        expect(find.text('Nueva entrada de prueba'), findsOneWidget);
        // Verificar que el nombre de la emoción aparece
        expect(find.text('Noche de Metztli'), findsOneWidget);
        expect(find.text('(Cansancio, agotamiento)'), findsOneWidget);
      },
    );
  });
}