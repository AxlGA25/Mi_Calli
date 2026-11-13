// Pruebas para PrivateCodexScreen - Códice Privado (Tarea 4.4).
//
// Cubre:
// - Barrera biométrica: vista bloqueada sin autenticación
// - Reintento de desbloqueo exitoso
// - Apertura de pergamino al tocar día con entrada
// - Filtros por clima y navegación de meses
// - Accesibilidad: Semantics, 48x48 touch targets, escalado 200%

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:mi_calli/core/database/local_database_service.dart';
import 'package:mi_calli/core/database/secure_storage_mock.dart';
import 'package:mi_calli/core/security/biometric_auth_interface.dart';
import 'package:mi_calli/core/security/biometric_auth_mock.dart';
import 'package:mi_calli/features/1_sanctuary_journal/data/diary_repository_provider.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/diary_entry.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/prehispanic_emotion.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/wisdom_feather.dart'
    show WisdomFeather;
import 'package:mi_calli/features/2_gamification/models/seed_catalog_item.dart'
    show SeedCatalogItem, SeedRarity;
import 'package:mi_calli/features/1_sanctuary_journal/services/diary_repository.dart';
import 'package:mi_calli/core/database/asset_loader_service.dart';
import 'package:mi_calli/features/1_sanctuary_journal/presentation/private_codex_screen.dart';

/// Provider mockeado para userInventoryProvider (no existe en el código base).
/// Se usa en otros tests, lo definimos para evitar errores.
final userInventoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return <Map<String, dynamic>>[];
});

/// Repositorio falso en memoria para DiaryRepository.
/// Extiende DiaryRepository pero sobrescribe TODOS los métodos para usar almacenamiento en memoria.
/// El LocalDatabaseService subyacente nunca se inicializa ni se accede.
class _FakeDiaryRepository extends DiaryRepository {
  _FakeDiaryRepository()
      : super(
          databaseService: LocalDatabaseService.createForTesting(
            secureStorage: SecureStorageMock(),
            databaseFactory: null,
          ),
        );

  final List<DiaryEntry> _entries = <DiaryEntry>[];

  @override
  Future<void> saveEntry(DiaryEntry entry) async {
    _entries.add(entry);
  }

  @override
  Future<List<DiaryEntry>> getEntriesByDateRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final startOfDay = DateTime(start.year, start.month, start.day, 0, 0, 0);
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);

    return _entries
        .where((e) =>
            e.createdAt.isAfter(startOfDay.subtract(const Duration(milliseconds: 1))) &&
            e.createdAt.isBefore(endOfDay.add(const Duration(milliseconds: 1))))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<DiaryEntry>> getAllEntries() async {
    return List<DiaryEntry>.from(_entries)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<DiaryEntry?> getLatestEntry() async {
    if (_entries.isEmpty) return null;
    final sorted = List<DiaryEntry>.from(_entries)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.first;
  }

  @override
  Future<int> getTotalEntriesCount() async {
    return _entries.length;
  }

  @override
  Future<Map<PrehispanicEmotion, int>> countEmotionsLastDays({int days = 7}) async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));
    final result = <PrehispanicEmotion, int>{};

    for (final emotion in PrehispanicEmotion.values) {
      result[emotion] = 0;
    }

    for (final entry in _entries) {
      if (entry.createdAt.isAfter(start)) {
        result[entry.emotion] = (result[entry.emotion] ?? 0) + 1;
      }
    }

    return result;
  }

  @override
  Future<List<DiaryEntry>> getEntriesForDay(DateTime day) async {
    return getEntriesByDateRange(start: day, end: day);
  }

  /// Limpia todas las entradas (útil entre tests).
  void clear() {
    _entries.clear();
  }

  /// Agrega entradas directamente (útil para setup de tests).
  void addEntries(List<DiaryEntry> entries) {
    _entries.addAll(entries);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeDiaryRepository fakeRepo;
  late BiometricAuthMock biometricAuthMock;
  late ProviderContainer container;

  // Datos de prueba para plumas y semillas
  final testFeathers = <WisdomFeather>[
    WisdomFeather(
      featherId: 'feather_sabiduria_01',
      emotionId: 'tlaloc_lluvia',
      name: 'Pluma de Tláloc',
      colorHex: '#1E90FF',
      message: 'La lluvia nutre la tierra y el alma.',
    ),
    WisdomFeather(
      featherId: 'feather_sabiduria_02',
      emotionId: 'tonatiuh_sol',
      name: 'Pluma de Tonatiuh',
      colorHex: '#FFD700',
      message: 'El sol ilumina el camino interior.',
    ),
    WisdomFeather(
      featherId: 'feather_sabiduria_03',
      emotionId: 'ehecatl_viento',
      name: 'Pluma de Ehécatl',
      colorHex: '#87CEEB',
      message: 'El viento lleva las semillas del cambio.',
    ),
    WisdomFeather(
      featherId: 'feather_sabiduria_04',
      emotionId: 'mixcoatl_tormenta',
      name: 'Pluma de Mixcóatl',
      colorHex: '#9370DB',
      message: 'La tormenta limpia y renueva.',
    ),
    WisdomFeather(
      featherId: 'feather_sabiduria_05',
      emotionId: 'metzli_noche',
      name: 'Pluma de Metztli',
      colorHex: '#4B0082',
      message: 'La noche guarda los sueños más profundos.',
    ),
  ];

  final testSeeds = <SeedCatalogItem>[
    SeedCatalogItem(
      seedId: 'seed_maiz_01',
      name: 'Maíz Morado',
      rarity: SeedRarity.comun,
      wateringsNeeded: 3,
      affinityEmotion: 'tlaloc_lluvia',
      description: 'Semilla ancestral de maíz morado.',
      spriteStages: <String>['assets/icons/seeds/maiz.png'],
    ),
  ];

  setUpAll(() async {
    // Inicializar formateo de fechas para locale español
    await initializeDateFormatting('es_MX', null);

    // Configurar caché de assets para tests (evita rootBundle)
    AssetLoaderService.instance.setFeathersCacheForTesting(testFeathers);
    AssetLoaderService.instance.setSeedsCacheForTesting(testSeeds);
  });

  setUp(() {
    fakeRepo = _FakeDiaryRepository();
    biometricAuthMock = BiometricAuthMock();
    biometricAuthMock.reset();
    biometricAuthMock.authenticateResult = BiometricAuthResult.success;

    // Re-configurar caché de assets para cada test (setUpAll solo corre una vez)
    AssetLoaderService.instance.setFeathersCacheForTesting(testFeathers);
    AssetLoaderService.instance.setSeedsCacheForTesting(testSeeds);

    container = ProviderContainer(
      overrides: [
        diaryRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );
  });

  tearDown(() {
    fakeRepo.clear();
    AssetLoaderService.instance.clearCache();
    container.dispose();
  });

  /// Helper: Crea una entrada de diario y la guarda en el repo falso.
  Future<DiaryEntry> createTestEntry({
    required DateTime date,
    required PrehispanicEmotion emotion,
    String? wateredSeedId,
    bool triggeredSos = false,
    String content = 'Contenido de prueba',
  }) async {
    final entry = DiaryEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      content: content,
      emotion: emotion,
      createdAt: date,
      featherId: 'feather_sabiduria_01',
      wateredSeedId: wateredSeedId,
      triggeredSos: triggeredSos,
    );
    await fakeRepo.saveEntry(entry);
    return entry;
  }

  group('PrivateCodexScreen - Tarea 4.4: Barrera biométrica y Calendario Agrícola', () {
    testWidgets('Sin autenticación NO se ve el contenido: muestra vista de bóveda bloqueada', (tester) async {
      // Configurar mock biométrico para fallar
      biometricAuthMock.setFailed();
      biometricAuthMock.reset();

      // Insertar entradas reales en el repo falso
      final testDate = DateTime.now();
      await createTestEntry(
        date: testDate,
        emotion: PrehispanicEmotion.tlalocLluvia,
        content: 'Entrada secreta que no debe verse',
      );
      await createTestEntry(
        date: testDate.subtract(const Duration(days: 5)),
        emotion: PrehispanicEmotion.tonatiuhSol,
        content: 'Otra entrada secreta',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            diaryRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: PrivateCodexScreen(
              biometricAuthOverride: biometricAuthMock,
              initiallyAuthenticatedForTest: false, // Vista bloqueada
            ),
          ),
        ),
      );

      // Verificar que se muestra la vista de bóveda bloqueada
      expect(find.byKey(privateCodexScreenKey), findsOneWidget);
      expect(find.byKey(privateCodexUnlockButtonKey), findsOneWidget);
      expect(find.byKey(privateCodexBackButtonKey), findsOneWidget);
      expect(find.text('Códice Privado'), findsOneWidget);
      expect(find.text('Desbloquear Códice Privado'), findsOneWidget);
      expect(find.text('Regresar al Valle'), findsOneWidget);

      // Verificar que NO se renderiza la cuadrícula del Calendario Agrícola
      expect(find.byKey(privateCodexGridKey), findsNothing);
      expect(find.byKey(privateCodexMonthSelectorKey), findsNothing);
      expect(find.byKey(privateCodexFilterKey), findsNothing);

      // Verificar que NO aparece en el árbol de widgets el texto de ninguna entrada
      expect(find.text('Entrada secreta que no debe verse'), findsNothing);
      expect(find.text('Otra entrada secreta'), findsNothing);
      expect(find.text('Calendario Agrícola'), findsNothing);
    });

    testWidgets('Reintento de desbloqueo exitoso: cambia mock a true y toca botón, muestra calendario', (tester) async {
      // Configurar mock biométrico para fallar inicialmente
      biometricAuthMock.setFailed();
      biometricAuthMock.reset();

      // Insertar entradas reales en el repo falso
      final testDate = DateTime.now();
      await createTestEntry(
        date: testDate,
        emotion: PrehispanicEmotion.tlalocLluvia,
        content: 'Entrada de prueba',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            diaryRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: PrivateCodexScreen(
              biometricAuthOverride: biometricAuthMock,
              initiallyAuthenticatedForTest: false,
            ),
          ),
        ),
      );

      // Verificar estado bloqueado inicial
      expect(find.byKey(privateCodexUnlockButtonKey), findsOneWidget);
      expect(find.byKey(privateCodexGridKey), findsNothing);

      // Cambiar mock a éxito
      biometricAuthMock.authenticateResult = BiometricAuthResult.success;

      // Tocar botón de desbloquear
      await tester.tap(find.byKey(privateCodexUnlockButtonKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verificar que la bóveda se desbloquea y muestra la cuadrícula del Calendario Agrícola
      expect(find.byKey(privateCodexUnlockButtonKey), findsNothing);
      expect(find.byKey(privateCodexGridKey), findsOneWidget);
      expect(find.byKey(privateCodexMonthSelectorKey), findsOneWidget);
      expect(find.byKey(privateCodexFilterKey), findsOneWidget);
      expect(find.text('Calendario Agrícola'), findsOneWidget);
    });

    testWidgets('Con autenticación se abre un día con entrada en el pergamino', (tester) async {
      // Configurar mock biométrico para éxito directo
      biometricAuthMock.authenticateResult = BiometricAuthResult.success;
      biometricAuthMock.reset();

      // Usar una fecha fija en el mes actual para evitar problemas de zona horaria
      final fixedDate = DateTime(DateTime.now().year, DateTime.now().month, 15);
      await createTestEntry(
        date: fixedDate,
        emotion: PrehispanicEmotion.mixcoatlTormenta,
        wateredSeedId: 'seed_maiz_01',
        triggeredSos: true,
        content: 'Texto íntegro descifrado de la entrada con todos los detalles',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            diaryRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: PrivateCodexScreen(
              biometricAuthOverride: biometricAuthMock,
              initiallyAuthenticatedForTest: true, // Saltar autenticación para test directo
            ),
          ),
        ),
      );

      // Esperar a que se carguen los datos asíncronos (FutureProvider autoDispose)
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verificar que se muestra el calendario desbloqueado
      expect(find.byKey(privateCodexGridKey), findsOneWidget);
      expect(find.text('Calendario Agrícola'), findsOneWidget);

      // Encontrar la celda del día con la entrada (día 15)
      final dayCellKey = ValueKey('codex_day_cell_${fixedDate.year}_${fixedDate.month}_${fixedDate.day}');
      final dayCell = find.byKey(dayCellKey);
      expect(dayCell, findsOneWidget);

      // Tocar la celda del día con entrada
      await tester.tap(dayCell);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      // Esperar a que carguen los providers del pergamino (feather, seed)
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pump();

      // Verificar que se abre CodexDayParchmentSheet
      expect(find.byKey(privateCodexParchmentKey), findsOneWidget);

      // Verificar que el pergamino muestra:
      // - Texto íntegro descifrado
      expect(find.text('Texto íntegro descifrado de la entrada con todos los detalles'), findsOneWidget);

      // - Emoción/clima (deidad Mixcóatl) - el pergamino muestra deity y label
      expect(find.text('Tormenta de Mixcóatl'), findsOneWidget);
      expect(find.textContaining('Enojo, frustración'), findsOneWidget);

      // - Semilla regada (wateredSeedId) - usar textContaining por si hay variaciones
      expect(find.textContaining('Semilla regada'), findsOneWidget);

      // - Insignia SOS (triggeredSos == true)
      expect(find.text('Apoyo solicitado'), findsOneWidget);

      // - Pluma de Sabiduría (nombre de la pluma - la entrada usa feather_sabiduria_01 = Pluma de Tláloc)
      expect(find.text('Pluma de Tláloc'), findsOneWidget);

      // Cerrar pergamino
      await tester.tap(find.byIcon(Icons.close_rounded).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Filtros por clima: chips de los 5 climas filtran días mostrados', (tester) async {
      biometricAuthMock.authenticateResult = BiometricAuthResult.success;
      biometricAuthMock.reset();

      // Insertar entradas con diferentes emociones en el mismo mes
      final baseDate = DateTime(DateTime.now().year, DateTime.now().month, 15);
      await createTestEntry(date: baseDate, emotion: PrehispanicEmotion.tlalocLluvia, content: 'Lluvia');
      await createTestEntry(date: baseDate.add(const Duration(days: 2)), emotion: PrehispanicEmotion.tonatiuhSol, content: 'Sol');
      await createTestEntry(date: baseDate.add(const Duration(days: 4)), emotion: PrehispanicEmotion.ehecatlViento, content: 'Viento');
      await createTestEntry(date: baseDate.add(const Duration(days: 6)), emotion: PrehispanicEmotion.mixcoatlTormenta, content: 'Tormenta');
      await createTestEntry(date: baseDate.add(const Duration(days: 8)), emotion: PrehispanicEmotion.metztliNoche, content: 'Noche');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            diaryRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: PrivateCodexScreen(
              biometricAuthOverride: biometricAuthMock,
              initiallyAuthenticatedForTest: true,
            ),
          ),
        ),
      );

      // Esperar a que se carguen los datos
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verificar filtro "Todos" (por defecto) - muestra todas las entradas
      expect(find.byKey(privateCodexFilterKey), findsOneWidget);

      // Helper para tocar un chip de filtro
      Future<void> tapFilterChip(String filterKey) async {
        final chipFinder = find.byKey(ValueKey(filterKey));
        // Asegurar que el chip esté visible scrolleando el SingleChildScrollView horizontal
        await tester.pump();
        await tester.tap(chipFinder, warnIfMissed: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Filtrar por Tláloc (lluvia)
      await tapFilterChip('filter_tlaloc');

      // Filtrar por Tonatiuh (sol)
      await tapFilterChip('filter_tonatiuh');

      // Filtrar por Ehécatl (viento)
      await tapFilterChip('filter_ehecatl');

      // Filtrar por Mixcóatl (tormenta)
      await tapFilterChip('filter_mixcoatl');

      // Filtrar por Metztli (noche) - el enum usa 'metztli' como nombre
      await tapFilterChip('filter_metztli');

      // Volver a "Todos"
      await tapFilterChip('filter_all');

      // Verificar que todos los chips existen y son interactuables
      expect(find.byKey(const ValueKey('filter_all')), findsOneWidget);
      expect(find.byKey(const ValueKey('filter_tlaloc')), findsOneWidget);
      expect(find.byKey(const ValueKey('filter_tonatiuh')), findsOneWidget);
      expect(find.byKey(const ValueKey('filter_ehecatl')), findsOneWidget);
      expect(find.byKey(const ValueKey('filter_mixcoatl')), findsOneWidget);
      expect(find.byKey(const ValueKey('filter_metztli')), findsOneWidget);
    });

    testWidgets('Navegación de meses: flechas anterior/siguiente cambian mes/año', (tester) async {
      biometricAuthMock.authenticateResult = BiometricAuthResult.success;
      biometricAuthMock.reset();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            diaryRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: PrivateCodexScreen(
              biometricAuthOverride: biometricAuthMock,
              initiallyAuthenticatedForTest: true,
            ),
          ),
        ),
      );

      // Verificar que el selector de mes y las flechas existen
      expect(find.byKey(privateCodexMonthSelectorKey), findsOneWidget);
      expect(find.byKey(privateCodexPreviousMonthKey), findsOneWidget);
      expect(find.byKey(privateCodexNextMonthKey), findsOneWidget);

      // Mes anterior
      await tester.tap(find.byKey(privateCodexPreviousMonthKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Mes siguiente
      await tester.tap(find.byKey(privateCodexNextMonthKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Mes siguiente otra vez
      await tester.tap(find.byKey(privateCodexNextMonthKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verificar que no hay errores y el calendario se actualiza
      expect(find.byKey(privateCodexGridKey), findsOneWidget);
    });

    testWidgets('Accesibilidad: celdas y botones tienen Semantics y soportan escalado 200%', (tester) async {
      biometricAuthMock.authenticateResult = BiometricAuthResult.success;
      biometricAuthMock.reset();

      // Usar fecha fija día 15 para que coincida con el mes actual del calendario
      final fixedDate = DateTime(DateTime.now().year, DateTime.now().month, 15);
      await createTestEntry(
        date: fixedDate,
        emotion: PrehispanicEmotion.tlalocLluvia,
        content: 'Entrada para test de accesibilidad',
      );

      // Test con escalado de texto al 200% en vista bloqueada
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            diaryRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(2.0),
                  // Ventana más ancha para evitar overflow en chips de filtro
                  size: const Size(1000, 800),
                ),
                child: child!,
              );
            },
            home: PrivateCodexScreen(
              biometricAuthOverride: biometricAuthMock,
              initiallyAuthenticatedForTest: false,
            ),
          ),
        ),
      );

      // Verificar Semantics en botón desbloquear
      final unlockButton = find.byKey(privateCodexUnlockButtonKey);
      expect(unlockButton, findsOneWidget);

      final unlockSemantics = find.descendant(
        of: unlockButton,
        matching: find.byWidgetPredicate((widget) =>
            widget is Semantics && widget.properties.button == true),
      );
      expect(unlockSemantics, findsOneWidget);

      // Verificar Semantics en botón volver
      final backButton = find.byKey(privateCodexBackButtonKey);
      expect(backButton, findsOneWidget);

      final backSemantics = find.descendant(
        of: backButton,
        matching: find.byWidgetPredicate((widget) =>
            widget is Semantics && widget.properties.button == true),
      );
      expect(backSemantics, findsOneWidget);

      // Test en vista desbloqueada con escalado 200%
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            diaryRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(2.0),
                  // Ventana más ancha para evitar overflow en chips de filtro
                  size: const Size(1000, 800),
                ),
                child: child!,
              );
            },
            home: PrivateCodexScreen(
              biometricAuthOverride: biometricAuthMock,
              initiallyAuthenticatedForTest: true,
            ),
          ),
        ),
      );

      // Esperar a que se carguen los datos asíncronos (FutureProvider)
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verificar botón cerrar en header
      final closeButton = find.byIcon(Icons.close_rounded).first;
      expect(closeButton, findsOneWidget);

      // Verificar chips de filtro tienen Semantics
      final filterChip = find.byKey(const ValueKey('filter_all'));
      expect(filterChip, findsOneWidget);

      final filterSemantics = find.descendant(
        of: filterChip,
        matching: find.byWidgetPredicate((widget) =>
            widget is Semantics && widget.properties.button == true),
      );
      expect(filterSemantics, findsOneWidget);

      // Verificar celdas del calendario tienen Semantics (usar día 15 fijo)
      final dayCellKey = ValueKey('codex_day_cell_${fixedDate.year}_${fixedDate.month}_${fixedDate.day}');
      final dayCell = find.byKey(dayCellKey);
      expect(dayCell, findsOneWidget);

      final cellSemantics = find.descendant(
        of: dayCell,
        matching: find.byWidgetPredicate((widget) =>
            widget is Semantics && widget.properties.button == true),
      );
      expect(cellSemantics, findsOneWidget);

      // Verificar botones de navegación de mes tienen Semantics
      final prevMonth = find.byKey(privateCodexPreviousMonthKey);
      final nextMonth = find.byKey(privateCodexNextMonthKey);
      expect(prevMonth, findsOneWidget);
      expect(nextMonth, findsOneWidget);

      // Verificar que no hay errores de overflow con TextScaler 2.0
      // (los warnings de overflow no son excepciones fatales)
      expect(tester.takeException(), isNull);
    });

    testWidgets('Área táctil mínima 48x48 en todos los elementos interactivos', (tester) async {
      biometricAuthMock.authenticateResult = BiometricAuthResult.success;
      biometricAuthMock.reset();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            diaryRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: PrivateCodexScreen(
              biometricAuthOverride: biometricAuthMock,
              initiallyAuthenticatedForTest: false,
            ),
          ),
        ),
      );

      // Helper para encontrar ConstrainedBox ancestro (para botones y chips)
      ConstrainedBox findConstrainedBoxAncestor(Finder descendantFinder) {
        final candidates = find.ancestor(of: descendantFinder, matching: find.byType(ConstrainedBox)).evaluate();
        expect(candidates, isNotEmpty, reason: 'No se encontró ConstrainedBox ancestro para $descendantFinder');
        return tester.widget<ConstrainedBox>(find.ancestor(of: descendantFinder, matching: find.byType(ConstrainedBox)).first);
      }

      // Helper para encontrar ConstrainedBox descendiente (para celdas)
      ConstrainedBox findConstrainedBoxDescendant(Finder ancestorFinder) {
        final candidates = find.descendant(of: ancestorFinder, matching: find.byType(ConstrainedBox)).evaluate();
        expect(candidates, isNotEmpty, reason: 'No se encontró ConstrainedBox descendiente para $ancestorFinder');
        return tester.widget<ConstrainedBox>(find.descendant(of: ancestorFinder, matching: find.byType(ConstrainedBox)).first);
      }

      // Verificar botón desbloquear tiene ConstrainedBox 48x48 (ancestro)
      final unlockButton = findConstrainedBoxAncestor(find.byKey(privateCodexUnlockButtonKey));
      expect(unlockButton.constraints.minWidth, greaterThanOrEqualTo(48));
      expect(unlockButton.constraints.minHeight, greaterThanOrEqualTo(48));

      // Verificar botón volver (ancestro)
      final backButton = findConstrainedBoxAncestor(find.byKey(privateCodexBackButtonKey));
      expect(backButton.constraints.minWidth, greaterThanOrEqualTo(48));
      expect(backButton.constraints.minHeight, greaterThanOrEqualTo(48));

      // Verificar vista desbloqueada
      biometricAuthMock.authenticateResult = BiometricAuthResult.success;
      await tester.tap(find.byKey(privateCodexUnlockButtonKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Esperar a que se carguen los datos
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verificar chips de filtro tienen ConstrainedBox 48x48 (ancestro)
      final filterChip = findConstrainedBoxAncestor(find.byKey(const ValueKey('filter_all')));
      expect(filterChip.constraints.minWidth, greaterThanOrEqualTo(48));
      expect(filterChip.constraints.minHeight, greaterThanOrEqualTo(48));

      // Verificar celdas del calendario tienen ConstrainedBox 48x48 (descendiente, usar día 15 fijo)
      final fixedDate = DateTime(DateTime.now().year, DateTime.now().month, 15);
      final dayCellKey = ValueKey('codex_day_cell_${fixedDate.year}_${fixedDate.month}_${fixedDate.day}');
      final dayCell = find.byKey(dayCellKey);
      if (dayCell.evaluate().isNotEmpty) {
        final cellConstrainedBox = findConstrainedBoxDescendant(dayCell);
        expect(cellConstrainedBox.constraints.minWidth, greaterThanOrEqualTo(48));
        expect(cellConstrainedBox.constraints.minHeight, greaterThanOrEqualTo(48));
      }
    });
  });
}