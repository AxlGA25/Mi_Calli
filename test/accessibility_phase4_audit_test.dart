// Test de accesibilidad para la Fase 4 (Tarea 4.9).
//
// Verifica que ninguna pantalla ni modal sufra RenderFlex overflow a
// TextScaler.linear(2.0) en tamaño de pantalla móvil estándar (412x915).
// También verifica Semantics, área táctil ≥ 48×48 px y reduceMotion.
//
// Pantallas/modales cubiertos:
// 1. TeotihuacanValleyScreen (5 zonas táctiles + 3 botones HUD, Semantics, ≥ 48×48, sin overflow)
// 2. SanctuaryJournalScreen (sin overflow 200%, controles con Semantics)
// 3. PrivateCodexScreen bloqueado y desbloqueado (sin overflow 200%)
// 4. AltarOfCalmModal (sin overflow 200%, reduceMotion: true)
// 5. SettingsScreen y PrivacyAndLegalScreen (scroll completo sin overflow 200%)
// 6. TonalpohualliScrollDialog (sin overflow 200%)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;
import 'package:intl/date_symbol_data_local.dart';

import 'package:mi_calli/core/security/biometric_auth_interface.dart';
import 'package:mi_calli/core/security/biometric_auth_mock.dart';
import 'package:mi_calli/core/audio/ambient_audio_models.dart';
import 'package:mi_calli/core/audio/ambient_audio_service.dart';
import 'package:mi_calli/core/audio/ambient_audio_player_interface.dart';
import 'package:mi_calli/core/settings/app_settings_provider.dart';
import 'package:mi_calli/core/settings/app_settings_service.dart';
import 'package:mi_calli/core/database/asset_loader_service.dart';
import 'package:mi_calli/core/database/local_database_service.dart';
import 'package:mi_calli/core/database/secure_storage_mock.dart';
import 'package:mi_calli/core/security/support_contact_service.dart';
import 'package:mi_calli/features/1_sanctuary_journal/data/diary_repository_provider.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/diary_entry.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/prehispanic_emotion.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/wisdom_feather.dart';
import 'package:mi_calli/features/1_sanctuary_journal/presentation/private_codex_screen.dart';
import 'package:mi_calli/features/1_sanctuary_journal/presentation/sanctuary_journal_screen.dart';
import 'package:mi_calli/features/1_sanctuary_journal/presentation/emotion_weather_selector.dart';
import 'package:mi_calli/features/1_sanctuary_journal/services/diary_repository.dart';
import 'package:mi_calli/features/2_gamification/models/deity_relic_models.dart';
import 'package:mi_calli/features/2_gamification/models/gamification_models.dart';
import 'package:mi_calli/features/2_gamification/models/seed_catalog_item.dart';
import 'package:mi_calli/features/2_gamification/models/tonalpohualli_models.dart';
import 'package:mi_calli/features/2_gamification/models/chinampa_models.dart';
import 'package:mi_calli/features/2_gamification/providers/relics_provider.dart';
import 'package:mi_calli/features/2_gamification/services/tonalpohualli_generator.dart';
import 'package:mi_calli/features/2_gamification/controllers/chinampa_controller.dart';
import 'package:mi_calli/features/2_gamification/presentation/tonalpohualli_scroll_dialog.dart';
import 'package:mi_calli/features/2_gamification/services/sacred_fire_and_evolution_service.dart';
import 'package:mi_calli/features/3_teotihuacan_valley/presentation/settings_screen.dart';
import 'package:mi_calli/features/3_teotihuacan_valley/presentation/privacy_and_legal_screen.dart';
import 'package:mi_calli/features/3_teotihuacan_valley/presentation/teotihuacan_valley_screen.dart';
import 'package:mi_calli/features/3_teotihuacan_valley/presentation/widgets/altar_of_calm_modal.dart';
import 'package:mi_calli/features/3_teotihuacan_valley/presentation/widgets/chinampa_bottom_sheet.dart';
import 'package:mi_calli/features/3_teotihuacan_valley/presentation/widgets/sacred_fire_status_dialog.dart';

/// Provider mockeado para supportContactServiceProvider (usado por SupportNetworkModal).
final supportContactServiceProvider = Provider<SupportContactService>((ref) {
  throw UnimplementedError('supportContactServiceProvider debe ser sobrescrito en tests');
});

/// Mock del reproductor de audio para tests.
class MockAmbientAudioPlayer implements AmbientAudioPlayerInterface {
  bool _isPlaying = false;
  String? _currentAssetPath;

  @override
  Future<void> playLoop(String assetPath, {double volume = 1.0}) async {
    _isPlaying = true;
    _currentAssetPath = assetPath;
  }

  @override
  Future<void> pause() async {
    _isPlaying = false;
  }

  @override
  Future<void> resume() async {
    if (_currentAssetPath != null) {
      _isPlaying = true;
    }
  }

  @override
  Future<void> stop() async {
    _isPlaying = false;
    _currentAssetPath = null;
  }

  @override
  Future<void> dispose() async {
    _isPlaying = false;
    _currentAssetPath = null;
  }

  @override
  bool get isPlaying => _isPlaying;

  @override
  String? get currentAssetPath => _currentAssetPath;
}

/// Tamaño de pantalla móvil estándar para tests de accesibilidad.
const Size kMobileSize = Size(412, 915);

/// Escalado de texto al 200% para tests de accesibilidad.
const TextScaler kTextScaler200 = TextScaler.linear(2.0);

/// Helper para envolver widgets en MaterialApp con configuración de accesibilidad.
/// Si se proporciona [container], envuelve todo el MaterialApp en UncontrolledProviderScope
/// para que los modales (showModalBottomSheet, showDialog) tengan acceso a los providers.
Widget _wrapWithAccessibility({
  required Widget child,
  TextScaler textScaler = kTextScaler200,
  bool reduceMotion = true,
  Size size = kMobileSize,
  ProviderContainer? container,
}) {
  final materialApp = MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: textScaler,
        disableAnimations: reduceMotion,
        platformBrightness: Brightness.light,
      ),
      child: ProviderScope(child: child),
    ),
  );

  if (container != null) {
    return UncontrolledProviderScope(container: container, child: materialApp);
  }
  return materialApp;
}

/// Repositorio falso en memoria para DiaryRepository (implementa la interfaz sin DB real).
class _FakeDiaryRepository implements DiaryRepository {
  _FakeDiaryRepository();

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

  void clear() {
    _entries.clear();
  }

  void addEntries(List<DiaryEntry> entries) {
    _entries.addAll(entries);
  }
}

/// Datos de prueba para plumas y semillas.
final List<WisdomFeather> _testFeathers = <WisdomFeather>[
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

final List<SeedCatalogItem> _testSeeds = <SeedCatalogItem>[
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

/// Helper para crear una entrada de prueba.
Future<DiaryEntry> _createTestEntry({
  required DateTime date,
  required PrehispanicEmotion emotion,
  String? wateredSeedId,
  bool triggeredSos = false,
  String content = 'Contenido de prueba',
}) async {
  return DiaryEntry(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    content: content,
    emotion: emotion,
    createdAt: date,
    featherId: 'feather_sabiduria_01',
    wateredSeedId: wateredSeedId,
    triggeredSos: triggeredSos,
  );
}

/// Helper para crear una lectura de prueba para TonalpohualliScrollDialog.
WeeklyAstralReading _createTestReading() {
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tarea 4.9 - Pasada de Accesibilidad Fase 4', () {
    late _FakeDiaryRepository fakeRepo;
    late BiometricAuthMock biometricAuthMock;
    late ProviderContainer container;
    late AppSettingsService settingsService;
    late MockAmbientAudioPlayer mockPlayer;
    late LocalDatabaseService databaseService;
    late SecureStorageMock secureStorageMock;

    setUpAll(() async {
      // Inicializar formato de fechas para locale español
      await initializeDateFormatting('es_MX', null);

      // Configurar caché de assets para tests
      AssetLoaderService.instance.setFeathersCacheForTesting(_testFeathers);
      AssetLoaderService.instance.setSeedsCacheForTesting(_testSeeds);

      // Inicializar SQLite FFI para tests
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      SharedPreferences.setMockInitialValues({});
      settingsService = await AppSettingsService.create();
      mockPlayer = MockAmbientAudioPlayer();

      // Crear mock de almacenamiento seguro para tests
      secureStorageMock = SecureStorageMock();

      // Crear base de datos real en memoria para tests
      databaseService = LocalDatabaseService.createForTesting(
        secureStorage: secureStorageMock,
        databaseFactory: databaseFactoryFfi,
      );
      await databaseService.initialize();
    });

    setUp(() {
      fakeRepo = _FakeDiaryRepository();
      biometricAuthMock = BiometricAuthMock();
      biometricAuthMock.reset();
      biometricAuthMock.authenticateResult = BiometricAuthResult.success;

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

    tearDownAll(() async {
      await databaseService.close();
    });

    // =========================================================================
    // 1. TeotihuacanValleyScreen
    // =========================================================================
    testWidgets(
        'TeotihuacanValleyScreen: 5 zonas táctiles + 3 botones HUD con Semantics, '
        'área ≥ 48×48, sin overflow a 200%', (tester) async {
      // Arrange: Configurar providers mock para el valle
      final valleyContainer = ProviderContainer(
        overrides: [
          appSettingsServiceProvider.overrideWithValue(settingsService),
          ambientAudioPlayerProvider.overrideWithValue(mockPlayer),
          localDatabaseServiceProvider.overrideWithValue(databaseService),
          // Mock userRelicsProvider - FutureProvider<List<UnlockedRelic>> - retorna lista vacía
          userRelicsProvider.overrideWith((ref) => Future.value(const <UnlockedRelic>[])),
          // Mock isTonalpohualliAvailableProvider - FutureProvider<bool> - retorna false
          isTonalpohualliAvailableProvider.overrideWith((ref) => Future.value(false)),
          // Mock ambientAudioCurrentTimePhaseProvider - Provider<ValleyTimePhase> - retorna day
          ambientAudioCurrentTimePhaseProvider.overrideWithValue(ValleyTimePhase.day),
          // Mock ambientAudioCurrentEmotionOverrideProvider - Provider<PrehispanicEmotion?> - retorna null
          ambientAudioCurrentEmotionOverrideProvider.overrideWithValue(null),
          // Override missing providers (not defined in codebase but used by widgets)
          userInventoryProvider.overrideWith((ref) => Future.value(const <String, int>{})),
          supportContactServiceProvider.overrideWithValue(SupportContactService.createForTesting(settingsService)),
        ],
      );

      final valleyWidget = _wrapWithAccessibility(
        child: UncontrolledProviderScope(
          container: valleyContainer,
          child: TeotihuacanValleyScreen(
            currentTimeOverride: DateTime(2026, 1, 15, 12, 0, 0), // Día
            emotionOverride: PrehispanicEmotion.tonatiuhSol,
            forceVenusAvailable: true,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(valleyWidget);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Assert: Verificar que no hay overflow
      expect(tester.takeException(), isNull,
          reason: 'No debe haber RenderFlex overflow a 200% texto');

      // Verificar 5 zonas táctiles en Layer 3 (ValleyScenicElementsLayer)
      // Estas se encuentran mediante Semantics en el layer (usando labels exactos del código)
      final touchZoneLabels = [
        'Escribir en el Santuario del Diario con Quetzalcóatl',
        'Abrir la Chinampa Sagrada y tus cultivos',
        'Ver racha del Fuego Sagrado y evolución de Quetzalcóatl',
        'Abrir el Códice Privado de entradas pasadas',
        'Abrir lectura semanal del Tonalpohualli',
      ];

      for (final label in touchZoneLabels) {
        final zone = find.bySemanticsLabel(label);
        expect(zone, findsOneWidget, reason: 'Zona táctil con label "$label" debe existir');
      }

      // Verificar 3 botones del HUD (Layer 4 - ValleyTopHudLayer)
      // Audio button label depende del estado mute, verificar que existe con alguno de los dos labels
      final audioButtonMuted = find.bySemanticsLabel('Activar sonido ambiental');
      final audioButtonUnmuted = find.bySemanticsLabel('Silenciar sonido ambiental');
      expect(audioButtonMuted.evaluate().isNotEmpty || audioButtonUnmuted.evaluate().isNotEmpty, isTrue,
          reason: 'Botón de audio debe existir con label de mute o unmute');

      final settingsButton = find.bySemanticsLabel('Abrir ajustes y accesibilidad');
      final sosButton = find.bySemanticsLabel('Altar de Calma: respiración y red de apoyo');

      expect(settingsButton, findsOneWidget);
      expect(sosButton, findsOneWidget);

      // Verificar área táctil ≥ 48×48 para zonas táctiles (usando keys correctas)
      final zoneKeys = [
        'touch_zone_quetzalcoatl',
        'touch_zone_chinampa',
        'touch_zone_sacred_fire',
        'touch_zone_codex_temple',
        'touch_zone_venus_constellation',
      ];

      for (final key in zoneKeys) {
        final zone = find.byKey(ValueKey(key));
        if (zone.evaluate().isNotEmpty) {
          final constrainedBox = tester.widget<ConstrainedBox>(
            find.descendant(of: zone, matching: find.byType(ConstrainedBox)).first,
          );
          expect(constrainedBox.constraints.minWidth, greaterThanOrEqualTo(48),
              reason: 'Zona $key debe tener minWidth ≥ 48');
          expect(constrainedBox.constraints.minHeight, greaterThanOrEqualTo(48),
              reason: 'Zona $key debe tener minHeight ≥ 48');
        }
      }

      // Verificar área táctil ≥ 48×48 para botones HUD
      final hudKeys = [
        'valley_hud_audio_button',
        'valley_hud_settings_button',
        'valley_hud_sos_button',
      ];

      for (final key in hudKeys) {
        final button = find.byKey(ValueKey(key));
        if (button.evaluate().isNotEmpty) {
          final constrainedBox = tester.widget<ConstrainedBox>(
            find.descendant(of: button, matching: find.byType(ConstrainedBox)).first,
          );
          expect(constrainedBox.constraints.minWidth, greaterThanOrEqualTo(48),
              reason: 'Botón HUD $key debe tener minWidth ≥ 48');
          expect(constrainedBox.constraints.minHeight, greaterThanOrEqualTo(48),
              reason: 'Botón HUD $key debe tener minHeight ≥ 48');
        }
      }

      valleyContainer.dispose();
    });

    // =========================================================================
    // 2. SanctuaryJournalScreen
    // =========================================================================
    testWidgets('SanctuaryJournalScreen: sin overflow a 200%, controles con Semantics',
        (tester) async {
      final journalContainer = ProviderContainer(
        overrides: [
          appSettingsServiceProvider.overrideWithValue(settingsService),
          ambientAudioPlayerProvider.overrideWithValue(mockPlayer),
          localDatabaseServiceProvider.overrideWithValue(databaseService),
        ],
      );

      final journalWidget = _wrapWithAccessibility(
        child: UncontrolledProviderScope(
          container: journalContainer,
          child: const SanctuaryJournalScreen(),
        ),
      );

      await tester.pumpWidget(journalWidget);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Verificar que no hay overflow
      expect(tester.takeException(), isNull,
          reason: 'No debe haber RenderFlex overflow a 200% texto');

      // Asegurar que todo se renderice completamente
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Verificar botón "Mis entradas" tiene Semantics
      final misEntradasButton = find.byKey(const ValueKey('sanctuary_mis_entradas_button'));
      expect(misEntradasButton, findsOneWidget);
      // El key está EN el Semantics widget, verificar sus propiedades
      final misEntradasSemantics = tester.widget<Semantics>(misEntradasButton);
      expect(misEntradasSemantics.properties.label, equals('Abrir historial de entradas del diario'));
      expect(misEntradasSemantics.properties.button, isTrue);

      // Verificar texto de invitación tiene Semantics
      // Buscar el Semantics directamente por su label usando widgetPredicate
      final invitationSemantics = find.byWidgetPredicate((widget) {
        if (widget is Semantics) {
          return widget.properties.label == 'Tu refugio te escucha. Elige cómo te sientes hoy y deja que Quetzalcóatl cuide lo que escribes.';
        }
        return false;
      });
      expect(invitationSemantics, findsOneWidget);

      // Verificar EmotionWeatherSelector tiene Semantics (5 botones de emoción)
      // Los botones de emoción usan el formato: "Deidad, Etiqueta" o "Deidad, Etiqueta, seleccionado" para el seleccionado
      // Primero encontrar el EmotionWeatherSelector, luego buscar sus Semantics descendientes
      final emotionSelector = find.byType(EmotionWeatherSelector);
      expect(emotionSelector, findsOneWidget);

      // Encontrar todos los Semantics con button=true dentro del EmotionWeatherSelector
      final allEmotionSemantics = find.descendant(
        of: emotionSelector,
        matching: find.byWidgetPredicate((widget) => widget is Semantics && widget.properties.button == true),
      );
      // Debe haber 5 botones de emoción
      expect(allEmotionSemantics, findsNWidgets(5), reason: 'Debe haber 5 botones de emoción con Semantics');

      // Verificar que cada emoción tiene al menos un label que coincide (uno tendrá ", seleccionado")
      for (final emotion in PrehispanicEmotion.values) {
        final expectedLabelPrefix = '${emotion.deity}, ${emotion.label}';
        final hasMatchingLabel = allEmotionSemantics.evaluate().any((element) {
          final semantics = element.widget as Semantics;
          final label = semantics.properties.label;
          return label != null && label.startsWith(expectedLabelPrefix);
        });
        expect(hasMatchingLabel, isTrue, reason: 'Botón de emoción ${emotion.deity} no encontrado');
      }

      // Verificar pergamino tiene Semantics - usar tester.allWidgets porque Semantics en Container no interactivo
      await tester.pump(const Duration(milliseconds: 100));
      final allSemantics = tester.allWidgets.whereType<Semantics>().toList();
      final pergaminoSemantics = allSemantics.firstWhere(
        (s) => s.properties.label == 'Pergamino para escribir tu entrada del diario',
        orElse: () => throw StateError('Semantics de Pergamino no encontrado'),
      );
      expect(pergaminoSemantics, isNotNull);

      // Verificar botón "Entregar ofrenda" tiene Semantics
      expect(find.bySemanticsLabel('Guardar tu entrada del diario y recibir tu Pluma de Sabiduría'), findsOneWidget);

      // Verificar botón "Necesito apoyo" tiene Semantics
      expect(find.bySemanticsLabel('Abrir red de apoyo: contactar a persona de confianza o llamar a Línea de la Vida'), findsOneWidget);

      journalContainer.dispose();
    });

    // =========================================================================
    // 3. PrivateCodexScreen - Vista bloqueada
    // =========================================================================
    testWidgets('PrivateCodexScreen (bloqueado): sin overflow a 200%', (tester) async {
      biometricAuthMock.setFailed();
      biometricAuthMock.reset();

      final codexWidget = _wrapWithAccessibility(
        child: UncontrolledProviderScope(
          container: container,
          child: PrivateCodexScreen(
            biometricAuthOverride: biometricAuthMock,
            initiallyAuthenticatedForTest: false,
          ),
        ),
      );

      await tester.pumpWidget(codexWidget);
      await tester.pumpAndSettle();

      // Verificar que no hay overflow
      expect(tester.takeException(), isNull,
          reason: 'No debe haber RenderFlex overflow a 200% texto en vista bloqueada');

      // Verificar elementos principales están presentes
      expect(find.byKey(privateCodexScreenKey), findsOneWidget);
      expect(find.byKey(privateCodexUnlockButtonKey), findsOneWidget);
      expect(find.byKey(privateCodexBackButtonKey), findsOneWidget);
      expect(find.text('Códice Privado'), findsOneWidget);
      expect(find.text('Desbloquear Códice Privado'), findsOneWidget);

      // Verificar Semantics en botones
      final unlockButton = find.byKey(privateCodexUnlockButtonKey);
      final unlockSemantics = find.descendant(
        of: unlockButton,
        matching: find.byWidgetPredicate((widget) =>
            widget is Semantics && widget.properties.button == true),
      );
      expect(unlockSemantics, findsOneWidget);

      final backButton = find.byKey(privateCodexBackButtonKey);
      final backSemantics = find.descendant(
        of: backButton,
        matching: find.byWidgetPredicate((widget) =>
            widget is Semantics && widget.properties.button == true),
      );
      expect(backSemantics, findsOneWidget);
    });

    // =========================================================================
    // 4. PrivateCodexScreen - Vista desbloqueada
    // =========================================================================
    testWidgets('PrivateCodexScreen (desbloqueado): sin overflow a 200%', (tester) async {
      // Insertar entrada de prueba
      final testDate = DateTime(DateTime.now().year, DateTime.now().month, 15);
      await fakeRepo.saveEntry(await _createTestEntry(
        date: testDate,
        emotion: PrehispanicEmotion.tlalocLluvia,
        content: 'Entrada para test de accesibilidad',
      ));

      final codexWidget = _wrapWithAccessibility(
        child: UncontrolledProviderScope(
          container: container,
          child: PrivateCodexScreen(
            biometricAuthOverride: biometricAuthMock,
            initiallyAuthenticatedForTest: true,
          ),
        ),
      );

      await tester.pumpWidget(codexWidget);
      // Esperar a que se carguen los datos asíncronos
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Verificar que no hay overflow
      expect(tester.takeException(), isNull,
          reason: 'No debe haber RenderFlex overflow a 200% texto en vista desbloqueada');

      // Verificar elementos del calendario
      expect(find.byKey(privateCodexGridKey), findsOneWidget);
      expect(find.byKey(privateCodexMonthSelectorKey), findsOneWidget);
      expect(find.byKey(privateCodexFilterKey), findsOneWidget);
      expect(find.byKey(privateCodexPreviousMonthKey), findsOneWidget);
      expect(find.byKey(privateCodexNextMonthKey), findsOneWidget);
      expect(find.text('Calendario Agrícola'), findsOneWidget);

      // Verificar botón cerrar en header tiene Semantics
      // El key 'codex_parchment_close_button' solo existe en CodexDayParchmentSheet (modal al tocar día)
      // El header usa Semantics con label 'Cerrar Códice Privado y volver al Valle'
      final headerCloseSemantics = find.byWidgetPredicate((widget) =>
          widget is Semantics &&
          widget.properties.button == true &&
          widget.properties.label == 'Cerrar Códice Privado y volver al Valle');
      expect(headerCloseSemantics, findsOneWidget);

      // Verificar chips de filtro tienen Semantics
      for (final filterName in ['filter_all', 'filter_tlaloc', 'filter_tonatiuh',
                                'filter_ehecatl', 'filter_mixcoatl', 'filter_metztli']) {
        final chip = find.byKey(ValueKey(filterName));
        if (chip.evaluate().isNotEmpty) {
          final chipSemantics = find.descendant(
            of: chip,
            matching: find.byWidgetPredicate((widget) =>
                widget is Semantics && widget.properties.button == true),
          );
          expect(chipSemantics, findsOneWidget, reason: 'Chip $filterName debe tener Semantics');
        }
      }

      // Verificar celdas del calendario tienen Semantics
      final dayCellKey = ValueKey('codex_day_cell_${testDate.year}_${testDate.month}_${testDate.day}');
      final dayCell = find.byKey(dayCellKey);
      if (dayCell.evaluate().isNotEmpty) {
        final cellSemantics = find.descendant(
          of: dayCell,
          matching: find.byWidgetPredicate((widget) =>
              widget is Semantics && widget.properties.button == true),
        );
        expect(cellSemantics, findsOneWidget, reason: 'Célula del día debe tener Semantics');
      }
    });

    // =========================================================================
    // 5. AltarOfCalmModal - con reduceMotion: true
    // =========================================================================
    testWidgets('AltarOfCalmModal: sin overflow a 200%, reduceMotion: true', (tester) async {
      final altarContainer = ProviderContainer(
        overrides: [
          appSettingsServiceProvider.overrideWithValue(settingsService),
          supportContactServiceProvider.overrideWithValue(SupportContactService.createForTesting(settingsService)),
        ],
      );

      // Bombear el modal directamente dentro del ProviderScope para evitar problemas
      // con el Overlay que no hereda el ProviderScope del test
      await tester.pumpWidget(
        _wrapWithAccessibility(
          child: UncontrolledProviderScope(
            container: altarContainer,
            child: const AltarOfCalmModal(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verificar que no hay overflow
      expect(tester.takeException(), isNull,
          reason: 'No debe haber RenderFlex overflow a 200% texto en AltarOfCalmModal');

      // Verificar elementos principales
      expect(find.text('Aquí hay manos que te sostienen'), findsOneWidget);
      expect(find.text('Altar de Calma · Viento de Ehécatl'), findsOneWidget);
      expect(find.text('Respiración de Ehécatl (4-4-6)'), findsOneWidget);
      expect(find.text('Inhala 4s · Sostén 4s · Exhala 6s · Repite 3 ciclos'), findsOneWidget);
      expect(find.text('Red de Apoyo Dual'), findsOneWidget);
      expect(find.text('En un toque: contacto de confianza o línea profesional 24/7'), findsOneWidget);

      // Verificar botones tienen Semantics
      expect(find.bySemanticsLabel('Iniciar ejercicio de respiración 4-4-6'), findsOneWidget);
      expect(find.bySemanticsLabel('Llamar a Línea de la Vida 800 911 2000'), findsOneWidget);
      expect(find.byKey(const ValueKey('altar_trusted_contact_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('altar_lifeline_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('altar_configure_contact_button')), findsOneWidget);

      // Verificar área táctil ≥ 48×48 para botones
      final buttonKeys = [
        'altar_breathing_toggle_button',
        'altar_trusted_contact_button',
        'altar_lifeline_button',
        'altar_configure_contact_button',
      ];

      for (final key in buttonKeys) {
        final button = find.byKey(ValueKey(key));
        if (button.evaluate().isNotEmpty) {
          // El ConstrainedBox con minHeight 56 es ANCESTRO del FilledButton (key en FilledButton)
          final constrainedBox = tester.widget<ConstrainedBox>(
            find.ancestor(of: button, matching: find.byType(ConstrainedBox)).first,
          );
          expect(constrainedBox.constraints.minWidth, greaterThanOrEqualTo(48),
              reason: 'Botón $key debe tener minWidth ≥ 48');
          expect(constrainedBox.constraints.minHeight, greaterThanOrEqualTo(48),
              reason: 'Botón $key debe tener minHeight ≥ 48');
        }
      }

      // Cerrar modal no necesario - el modal se bombea directamente
      altarContainer.dispose();
    });

    // =========================================================================
    // 6. SettingsScreen - scroll completo sin overflow a 200%
    // =========================================================================
    testWidgets('SettingsScreen: scroll completo sin overflow a 200%', (tester) async {
      final settingsContainer = ProviderContainer(
        overrides: [
          appSettingsServiceProvider.overrideWithValue(settingsService),
        ],
      );

      final settingsWidget = _wrapWithAccessibility(
        child: UncontrolledProviderScope(
          container: settingsContainer,
          child: const SettingsScreen(),
        ),
      );

      await tester.pumpWidget(settingsWidget);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      settingsContainer.dispose();

      // Verificar que no hay overflow
      expect(tester.takeException(), isNull,
          reason: 'No debe haber RenderFlex overflow a 200% texto en SettingsScreen');

      // Verificar secciones principales
      expect(find.text('Ajustes'), findsOneWidget);
      expect(find.text('General'), findsOneWidget);
      expect(find.text('Apariencia / Accesibilidad'), findsOneWidget);
      expect(find.text('Notificaciones'), findsOneWidget);
      expect(find.text('Red de Apoyo'), findsOneWidget);
      expect(find.text('Privacidad y Legal'), findsOneWidget);

      // Verificar tiles tienen Semantics
      final settingsKeys = [
        'settings_tile_audio',
        'settings_tile_app_lock',
        'settings_tile_version',
        'settings_tile_recordatorio',
      ];

      for (final key in settingsKeys) {
        final tile = find.byKey(ValueKey(key));
        if (tile.evaluate().isNotEmpty) {
          // El key está EN el Semantics widget
          final semanticsWidget = tester.widget<Semantics>(tile);
          expect(semanticsWidget.properties.button, isTrue, reason: 'Tile $key debe tener Semantics con button=true');
        }
      }

      // Verificar scroll funciona (buscar elemento al final)
      await tester.dragUntilVisible(
        find.text('Importar mi Diario'),
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      expect(find.text('Importar mi Diario'), findsOneWidget);
    });

    // =========================================================================
    // 7. PrivacyAndLegalScreen - scroll completo sin overflow a 200%
    // =========================================================================
    testWidgets('PrivacyAndLegalScreen: scroll completo sin overflow a 200%', (tester) async {
      final privacyWidget = _wrapWithAccessibility(
        child: const PrivacyAndLegalScreen(),
      );

      await tester.pumpWidget(privacyWidget);
      await tester.pumpAndSettle();

      // Verificar que no hay overflow
      expect(tester.takeException(), isNull,
          reason: 'No debe haber RenderFlex overflow a 200% texto en PrivacyAndLegalScreen');

      // Verificar secciones legales
      expect(find.text('Aviso y Privacidad'), findsOneWidget);
      expect(find.text('Descargo Médico'), findsOneWidget);
      expect(find.text('Solo Mayores de 18 Años'), findsOneWidget);
      expect(find.text('Privacidad Absoluta'), findsOneWidget);
      expect(find.text('Exportación Cifrada'), findsOneWidget);
      expect(find.text('Consentimiento de Datos Sensibles'), findsOneWidget);
      expect(find.text('Red de Apoyo Dual'), findsOneWidget);
      expect(find.text('Recordatorio Diario'), findsOneWidget);
      expect(find.text('Política de Privacidad Completa (Web)'), findsOneWidget);

      // Verificar scroll funciona
      await tester.dragUntilVisible(
        find.text('Política de Privacidad Completa (Web)'),
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      expect(find.text('Política de Privacidad Completa (Web)'), findsOneWidget);
    });

    // =========================================================================
    // 8. TonalpohualliScrollDialog - sin overflow a 200%
    // =========================================================================
    testWidgets('TonalpohualliScrollDialog: sin overflow a 200%', (tester) async {
      final testReading = _createTestReading();

      // Bombear botón que abre el dialog, con container en _wrapWithAccessibility
      await tester.pumpWidget(
        _wrapWithAccessibility(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => TonalpohualliScrollDialog.show(
                context,
                reading: testReading,
                onClose: () {},
              ),
              child: const Text('Abrir Tonalpohualli'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Tonalpohualli'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Verificar que no hay overflow
      expect(tester.takeException(), isNull,
          reason: 'No debe haber RenderFlex overflow a 200% texto en TonalpohualliScrollDialog');

      // Verificar contenido principal
      expect(find.text('Bajo el Manto de Tláloc'), findsOneWidget);
      expect(find.text('Lluvia de Tláloc'), findsOneWidget);
      // "Constelación de Venus, símbolo de Quetzalcóatl" es Semantics en Container no interactivo
      // Buscar en todos los widgets (incluyendo overlay) el Semantics con ese label
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      final allSemantics = tester.allWidgets.whereType<Semantics>().toList();
      final venusSemantics = allSemantics.firstWhere(
        (s) => s.properties.label == 'Constelación de Venus, símbolo de Quetzalcóatl',
        orElse: () => throw StateError('Semantics de Constelación de Venus no encontrado'),
      );
      expect(venusSemantics, isNotNull);

      // Verificar los 3 párrafos
      expect(find.textContaining('Los sabios observadores del cielo vieron que las aguas de Tláloc'),
          findsOneWidget);
      expect(find.textContaining('Tu chinampa guardó memoria de 4 brotes nutridos'), findsOneWidget);
      expect(find.textContaining('Venus, lucero de la mañana, asoma sobre el horizonte'), findsOneWidget);

      // Verificar resumen visual
      expect(find.text('5'), findsWidgets); // Desahogos
      expect(find.text('4'), findsWidgets); // Brotes nutridos

      // Verificar botón cerrar con Semantics - usar tester.allWidgets porque Semantics en overlay
      final allSemanticsDialog = tester.allWidgets.whereType<Semantics>().toList();
      final closeSemantics = allSemanticsDialog.firstWhere(
        (s) => s.properties.label == 'Cerrar lectura del Tonalpohualli',
        orElse: () => throw StateError('Semantics de botón cerrar no encontrado'),
      );
      expect(closeSemantics, isNotNull);

      // Verificar Semantics en textos
      final textWidgets = tester.allWidgets.whereType<Text>().toList();
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
    });

    // =========================================================================
    // Test adicional: ChinampaBottomSheet - sin overflow a 200%
    // =========================================================================
    testWidgets('ChinampaBottomSheet: sin overflow a 200%', (tester) async {
      final chinampaContainer = ProviderContainer(
        overrides: [
          appSettingsServiceProvider.overrideWithValue(settingsService),
          ambientAudioPlayerProvider.overrideWithValue(mockPlayer),
          localDatabaseServiceProvider.overrideWithValue(databaseService),
          chinampaSlotsProvider.overrideWith((ref) => Future.value(const <ChinampaSlotState>[])),
          seedCatalogProvider.overrideWith((ref) => Future.value(const <String, SeedCatalogItem>{})),
          userInventoryProvider.overrideWith((ref) => Future.value(const <String, int>{})),
        ],
      );

      // Pasar el container a _wrapWithAccessibility para que TODO el MaterialApp
      // (incluyendo Navigator y routes/overlays) quede envuelto en UncontrolledProviderScope.
      // Así el bottom sheet mostrado vía showModalBottomSheet hereda los providers.
      await tester.pumpWidget(
        _wrapWithAccessibility(
          container: chinampaContainer,
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ChinampaBottomSheet.show(context),
              child: const Text('Abrir Chinampa'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Chinampa'));
      // Pump multiple frames to let async providers resolve and animations settle
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Verificar que no hay overflow
      expect(tester.takeException(), isNull,
          reason: 'No debe haber RenderFlex overflow a 200% texto en ChinampaBottomSheet');

      // Verificar contenido
      final chinampaSagradaFinder = find.byWidgetPredicate((widget) =>
          widget is Text && widget.data?.contains('Chinampa Sagrada') == true);
      expect(chinampaSagradaFinder, findsOneWidget);

      final cultivosFinder = find.byWidgetPredicate((widget) =>
          widget is Text && widget.data?.contains('Tus cultivos emocionales') == true);
      expect(cultivosFinder, findsOneWidget);

      final inventarioFinder = find.byWidgetPredicate((widget) =>
          widget is Text && widget.data?.contains('Inventario de Semillas') == true);
      expect(inventarioFinder, findsOneWidget);

      // Cerrar bottom sheet
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      chinampaContainer.dispose();
    });

    // =========================================================================
    // Test adicional: SacredFireStatusDialog - sin overflow a 200%
    // =========================================================================
    testWidgets('SacredFireStatusDialog: sin overflow a 200%', (tester) async {
      final sacredFireContainer = ProviderContainer(
        overrides: [
          appSettingsServiceProvider.overrideWithValue(settingsService),
          ambientAudioPlayerProvider.overrideWithValue(mockPlayer),
          localDatabaseServiceProvider.overrideWithValue(databaseService),
          userRelicsProvider.overrideWith((ref) => Future.value(const <UnlockedRelic>[])),
          gamificationStateProvider.overrideWith((ref) => Future.value(const GamificationState(
            quetzalXp: 0,
            quetzalLevel: 1,
            currentStreak: 0,
            longestStreak: 0,
            lastCheckinDate: null,
            xolotlShields: 1,
          ))),
        ],
      );

      // Mostrar el dialog vía showDialog (como TonalpohualliScrollDialog)
      // para que tenga los constraints correctos del Dialog (insetPadding, etc.)
      // y herede el ProviderScope del Navigator envuelto en UncontrolledProviderScope.
      await tester.pumpWidget(
        _wrapWithAccessibility(
          container: sacredFireContainer,
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => SacredFireStatusDialog.show(context),
              child: const Text('Abrir Fuego Sagrado'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Fuego Sagrado'));
      // Pump multiple frames para que resuelvan los providers async y el dialog se muestre.
      // NO usar pumpAndSettle porque _AnimatedFlame tiene animación infinita
      // (AnimationController con repeat(reverse: true)) que impediría que se asiente.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Verificar que no hay overflow
      expect(tester.takeException(), isNull,
          reason: 'No debe haber RenderFlex overflow a 200% texto en SacredFireStatusDialog');

      // Verificar contenido real renderizado:
      // - Tier display name (con currentStreak=0 es "Brasas en espera")
      // - Sección "Fuego Sagrado"
      // - Sección "Quetzalcóatl"
      // - Botón cerrar con Semantics
      final tierDisplayFinder = find.byWidgetPredicate((widget) =>
          widget is Text && widget.data == 'Brasas en espera');
      expect(tierDisplayFinder, findsOneWidget);

      final fuegoSagradoFinder = find.byWidgetPredicate((widget) =>
          widget is Text && widget.data == 'Fuego Sagrado');
      expect(fuegoSagradoFinder, findsOneWidget);

      final quetzalFinder = find.byWidgetPredicate((widget) =>
          widget is Text && widget.data?.contains('Quetzalcóatl') == true);
      expect(quetzalFinder, findsOneWidget);

      // Verificar botón cerrar tiene Semantics
      final closeButtonSemantics = find.byWidgetPredicate((widget) =>
          widget is Semantics &&
          widget.properties.button == true &&
          widget.properties.label == 'Cerrar estado del Fuego Sagrado');
      expect(closeButtonSemantics, findsOneWidget);

      sacredFireContainer.dispose();
    });
  });
}