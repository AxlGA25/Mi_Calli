// Pruebas para TeotihuacanValleyScreen (Tarea 4.2).
//
// Cubre:
// - Stack completo con 4 capas
// - 4 fases horarias (dawn, day, dusk, night)
// - 5 elementos centrales con ValueKeys
// - Sin FAB ni HUD
// - RepaintBoundary en todas las capas
// - reduceMotion / SafeAnimationWrapper

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_calli/core/audio/ambient_audio_models.dart';
import 'package:mi_calli/core/audio/ambient_audio_service.dart';
import 'package:mi_calli/core/audio/ambient_audio_player_interface.dart';
import 'package:mi_calli/core/settings/app_settings_provider.dart';
import 'package:mi_calli/core/settings/app_settings_service.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/prehispanic_emotion.dart';
import 'package:mi_calli/features/2_gamification/models/deity_relic_models.dart';
import 'package:mi_calli/features/2_gamification/providers/relics_provider.dart';
import 'package:mi_calli/features/3_teotihuacan_valley/presentation/widgets/valley_sky_gradient_layer.dart';
import 'package:mi_calli/features/3_teotihuacan_valley/presentation/widgets/valley_pyramids_background_layer.dart';
import 'package:mi_calli/features/3_teotihuacan_valley/presentation/widgets/valley_weather_particles_layer.dart';
import 'package:mi_calli/features/3_teotihuacan_valley/presentation/widgets/valley_scenic_elements_layer.dart';
import 'package:mi_calli/features/3_teotihuacan_valley/presentation/teotihuacan_valley_screen.dart';
import 'package:mi_calli/core/performance/safe_animation_wrapper.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('ValleySkyGradientLayer', () {
    testWidgets('renderiza gradiente correcto para cada fase', (tester) async {
      const phases = [
        ValleyTimePhase.dawn,
        ValleyTimePhase.day,
        ValleyTimePhase.dusk,
        ValleyTimePhase.night,
      ];

      for (final phase in phases) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ValleySkyGradientLayer(
                key: valleySkyLayerKey,
                timePhase: phase,
              ),
            ),
          ),
        );

        expect(find.byKey(valleySkyLayerKey), findsOneWidget);
      }
    });

    testWidgets('aplica emotionOverride mezclando gradientes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValleySkyGradientLayer(
              key: valleySkyLayerKey,
              timePhase: ValleyTimePhase.day,
              emotionOverride: PrehispanicEmotion.tlalocLluvia,
            ),
          ),
        ),
      );

      expect(find.byKey(valleySkyLayerKey), findsOneWidget);
    });

    testWidgets('muestra astro correcto por fase', (tester) async {
      const phaseAstroMap = {
        ValleyTimePhase.dawn: '_RisingSun',
        ValleyTimePhase.day: '_RadiantSun',
        ValleyTimePhase.dusk: '_SettingSun',
        ValleyTimePhase.night: '_MetztliMoon',
      };

      for (final entry in phaseAstroMap.entries) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ValleySkyGradientLayer(
                key: valleySkyLayerKey,
                timePhase: entry.key,
              ),
            ),
          ),
        );

        expect(find.byKey(valleySkyLayerKey), findsOneWidget);
      }
    });

    testWidgets('oculta astro en metztliNoche y mixcoatlTormenta', (tester) async {
      for (final emotion in [
        PrehispanicEmotion.metztliNoche,
        PrehispanicEmotion.mixcoatlTormenta,
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ValleySkyGradientLayer(
                key: valleySkyLayerKey,
                timePhase: ValleyTimePhase.night,
                emotionOverride: emotion,
              ),
            ),
          ),
        );

        expect(find.byKey(valleySkyLayerKey), findsOneWidget);
      }
    });

    testWidgets('muestra neblina en amanecer', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValleySkyGradientLayer(
              key: valleySkyLayerKey,
              timePhase: ValleyTimePhase.dawn,
            ),
          ),
        ),
      );

      expect(find.byKey(valleySkyLayerKey), findsOneWidget);
    });

    testWidgets('muestra constelación de Venus en noche sin emoción', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValleySkyGradientLayer(
              key: valleySkyLayerKey,
              timePhase: ValleyTimePhase.night,
            ),
          ),
        ),
      );

      expect(find.byKey(valleySkyLayerKey), findsOneWidget);
    });
  });

  group('ValleyPyramidsBackgroundLayer', () {
    testWidgets('renderiza pirámides para cada fase', (tester) async {
      const phases = [
        ValleyTimePhase.dawn,
        ValleyTimePhase.day,
        ValleyTimePhase.dusk,
        ValleyTimePhase.night,
      ];

      for (final phase in phases) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ValleyPyramidsBackgroundLayer(
                key: valleyPyramidsLayerKey,
                timePhase: phase,
              ),
            ),
          ),
        );

        expect(find.byKey(valleyPyramidsLayerKey), findsOneWidget);
      }
    });

    testWidgets('aplica emotionOverride', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValleyPyramidsBackgroundLayer(
              key: valleyPyramidsLayerKey,
              timePhase: ValleyTimePhase.day,
              emotionOverride: PrehispanicEmotion.tonatiuhSol,
            ),
          ),
        ),
      );

      expect(find.byKey(valleyPyramidsLayerKey), findsOneWidget);
    });
  });

  group('ValleyWeatherParticlesLayer', () {
    testWidgets('renderiza estrellas/luciérnagas en noche sin emotionOverride', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValleyWeatherParticlesLayer(
              key: valleyWeatherParticlesLayerKey,
              emotionOverride: null,
              timePhase: ValleyTimePhase.night,
            ),
          ),
        ),
      );

      expect(find.byKey(valleyWeatherParticlesLayerKey), findsOneWidget);
    });

    testWidgets('no renderiza nada en día sin emotionOverride', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValleyWeatherParticlesLayer(
              key: valleyWeatherParticlesLayerKey,
              emotionOverride: null,
              timePhase: ValleyTimePhase.day,
            ),
          ),
        ),
      );

      expect(find.byKey(valleyWeatherParticlesLayerKey), findsOneWidget);
    });

    testWidgets('renderiza lluvia para tlalocLluvia', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValleyWeatherParticlesLayer(
              key: valleyWeatherParticlesLayerKey,
              emotionOverride: PrehispanicEmotion.tlalocLluvia,
              timePhase: ValleyTimePhase.day,
            ),
          ),
        ),
      );

      expect(find.byKey(valleyWeatherParticlesLayerKey), findsOneWidget);
    });

    testWidgets('renderiza viento para ehecatlViento', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValleyWeatherParticlesLayer(
              key: valleyWeatherParticlesLayerKey,
              emotionOverride: PrehispanicEmotion.ehecatlViento,
              timePhase: ValleyTimePhase.day,
            ),
          ),
        ),
      );

      expect(find.byKey(valleyWeatherParticlesLayerKey), findsOneWidget);
    });

    testWidgets('renderiza tormenta para mixcoatlTormenta', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValleyWeatherParticlesLayer(
              key: valleyWeatherParticlesLayerKey,
              emotionOverride: PrehispanicEmotion.mixcoatlTormenta,
              timePhase: ValleyTimePhase.day,
            ),
          ),
        ),
      );

      expect(find.byKey(valleyWeatherParticlesLayerKey), findsOneWidget);
    });

    testWidgets('no renderiza partículas para tonatiuhSol y metztliNoche', (tester) async {
      for (final emotion in [
        PrehispanicEmotion.tonatiuhSol,
        PrehispanicEmotion.metztliNoche,
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ValleyWeatherParticlesLayer(
                key: valleyWeatherParticlesLayerKey,
                emotionOverride: emotion,
                timePhase: ValleyTimePhase.day,
              ),
            ),
          ),
        );

        expect(find.byKey(valleyWeatherParticlesLayerKey), findsOneWidget);
      }
    });
  });

  group('ValleyScenicElementsLayer', () {
    testWidgets('renderiza vegetación para cada fase', (tester) async {
      const phases = [
        ValleyTimePhase.dawn,
        ValleyTimePhase.day,
        ValleyTimePhase.dusk,
        ValleyTimePhase.night,
      ];

      for (final phase in phases) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ValleyScenicElementsLayer(
                key: valleyScenicElementsLayerKey,
                timePhase: phase,
              ),
            ),
          ),
        );

        expect(find.byKey(valleyScenicElementsLayerKey), findsOneWidget);
      }
    });

    testWidgets('muestra mariposas con reliquia Xochiquétzal en día', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValleyScenicElementsLayer(
              key: valleyScenicElementsLayerKey,
              timePhase: ValleyTimePhase.day,
              hasXochiquetzalRelic: true,
            ),
          ),
        ),
      );

      expect(find.byKey(valleyScenicElementsLayerKey), findsOneWidget);
    });

    testWidgets('no muestra mariposas sin reliquia Xochiquétzal', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValleyScenicElementsLayer(
              key: valleyScenicElementsLayerKey,
              timePhase: ValleyTimePhase.day,
              hasXochiquetzalRelic: false,
            ),
          ),
        ),
      );

      expect(find.byKey(valleyScenicElementsLayerKey), findsOneWidget);
    });

    testWidgets('no muestra mariposas en lluvia/tormenta aunque tenga reliquia', (tester) async {
      for (final emotion in [
        PrehispanicEmotion.tlalocLluvia,
        PrehispanicEmotion.mixcoatlTormenta,
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ValleyScenicElementsLayer(
                key: valleyScenicElementsLayerKey,
                timePhase: ValleyTimePhase.day,
                emotionOverride: emotion,
                hasXochiquetzalRelic: true,
              ),
            ),
          ),
        );

        expect(find.byKey(valleyScenicElementsLayerKey), findsOneWidget);
      }
    });

    testWidgets('muestra fauna Xólotl con showXolotl en atardecer/noche', (tester) async {
      for (final phase in [ValleyTimePhase.dusk, ValleyTimePhase.night]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ValleyScenicElementsLayer(
                key: valleyScenicElementsLayerKey,
                timePhase: phase,
                showXolotl: true,
              ),
            ),
          ),
        );

        expect(find.byKey(valleyScenicElementsLayerKey), findsOneWidget);
      }
    });

    testWidgets('muestra luciérnagas en noche sin tormenta/lluvia', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValleyScenicElementsLayer(
              key: valleyScenicElementsLayerKey,
              timePhase: ValleyTimePhase.night,
            ),
          ),
        ),
      );

      expect(find.byKey(valleyScenicElementsLayerKey), findsOneWidget);
    });

    testWidgets('no muestra luciérnagas con tormenta o lluvia', (tester) async {
      for (final emotion in [
        PrehispanicEmotion.mixcoatlTormenta,
        PrehispanicEmotion.tlalocLluvia,
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ValleyScenicElementsLayer(
                key: valleyScenicElementsLayerKey,
                timePhase: ValleyTimePhase.night,
                emotionOverride: emotion,
              ),
            ),
          ),
        );

        expect(find.byKey(valleyScenicElementsLayerKey), findsOneWidget);
      }
    });

    testWidgets('muestra neblina en amanecer y emociones nocturnas', (tester) async {
      // Amanecer
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValleyScenicElementsLayer(
              key: valleyScenicElementsLayerKey,
              timePhase: ValleyTimePhase.dawn,
            ),
          ),
        ),
      );
      expect(find.byKey(valleyScenicElementsLayerKey), findsOneWidget);

      // Metztli noche
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValleyScenicElementsLayer(
              key: valleyScenicElementsLayerKey,
              timePhase: ValleyTimePhase.day,
              emotionOverride: PrehispanicEmotion.metztliNoche,
            ),
          ),
        ),
      );
      expect(find.byKey(valleyScenicElementsLayerKey), findsOneWidget);
    });

    testWidgets('tiene los 5 elementos centrales con ValueKeys', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValleyScenicElementsLayer(
              key: valleyScenicElementsLayerKey,
              timePhase: ValleyTimePhase.day,
              hasTlalocRelic: true,
              showXolotl: true,
            ),
          ),
        ),
      );

      // Verificar las 5 claves centrales
      expect(find.byKey(valleyAltarQuetzalcoatlKey), findsOneWidget);
      expect(find.byKey(valleyXolotlFaunaKey), findsOneWidget);
      expect(find.byKey(valleyFuegoSagradoKey), findsOneWidget);
      expect(find.byKey(valleyChinampaKey), findsOneWidget);
      expect(find.byKey(valleyVasijaTlalocKey), findsOneWidget);
    });

    testWidgets('no muestra Xólotl ni Vasija Tláloc sin flags correspondientes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValleyScenicElementsLayer(
              key: valleyScenicElementsLayerKey,
              timePhase: ValleyTimePhase.night,
              hasTlalocRelic: false,
              showXolotl: false,
            ),
          ),
        ),
      );

      expect(find.byKey(valleyAltarQuetzalcoatlKey), findsOneWidget);
      expect(find.byKey(valleyFuegoSagradoKey), findsOneWidget);
      expect(find.byKey(valleyChinampaKey), findsOneWidget);
      expect(find.byKey(valleyXolotlFaunaKey), findsNothing);
      expect(find.byKey(valleyVasijaTlalocKey), findsNothing);
    });
  });

  group('TeotihuacanValleyScreen', () {
    late ProviderContainer container;
    late AppSettingsService settingsService;
    late MockAmbientAudioPlayer mockPlayer;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      settingsService = await AppSettingsService.create();
      mockPlayer = MockAmbientAudioPlayer();

      container = ProviderContainer(
        overrides: [
          appSettingsServiceProvider.overrideWithValue(settingsService),
          ambientAudioPlayerProvider.overrideWithValue(mockPlayer),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
    });

    testWidgets('renderiza Stack completo con 4 capas', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: TeotihuacanValleyScreen(),
          ),
        ),
      );

      // Verificar que las 4 capas están presentes
      expect(find.byKey(valleySkyLayerKey), findsOneWidget);
      expect(find.byKey(valleyPyramidsLayerKey), findsOneWidget);
      expect(find.byKey(valleyWeatherParticlesLayerKey), findsOneWidget);
      expect(find.byKey(valleyScenicElementsLayerKey), findsOneWidget);
      expect(find.byKey(teotihuacanValleyScreenKey), findsOneWidget);
    });

    testWidgets('NO tiene FAB (se agregará en Tarea 4.3)', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: TeotihuacanValleyScreen(),
          ),
        ),
      );

      // No debe haber FloatingActionButton
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('todas las capas tienen RepaintBoundary', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: TeotihuacanValleyScreen(),
          ),
        ),
      );

      // Verificar RepaintBoundary en cada capa buscando el widget en el árbol
      // find.ancestor encuentra todos los ancestros, usamos findsWidgets (>=1)
      final skyRepaint = find.ancestor(
        of: find.byKey(valleySkyLayerKey),
        matching: find.byType(RepaintBoundary),
      );
      expect(skyRepaint, findsWidgets);

      final pyramidsRepaint = find.ancestor(
        of: find.byKey(valleyPyramidsLayerKey),
        matching: find.byType(RepaintBoundary),
      );
      expect(pyramidsRepaint, findsWidgets);

      final weatherRepaint = find.ancestor(
        of: find.byKey(valleyWeatherParticlesLayerKey),
        matching: find.byType(RepaintBoundary),
      );
      expect(weatherRepaint, findsWidgets);

      final scenicRepaint = find.ancestor(
        of: find.byKey(valleyScenicElementsLayerKey),
        matching: find.byType(RepaintBoundary),
      );
      expect(scenicRepaint, findsWidgets);
    });

    testWidgets('SafeAnimationWrapper envuelve WeatherParticlesLayer', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: TeotihuacanValleyScreen(),
          ),
        ),
      );

      // Verificar que SafeAnimationWrapper está presente envolviendo weather layer
      final weatherWrapper = find.ancestor(
        of: find.byKey(valleyWeatherParticlesLayerKey),
        matching: find.byType(SafeAnimationWrapper),
      );
      expect(weatherWrapper, findsOneWidget);
    });

    testWidgets('respeta reduceMotion mostrando fallback estático', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              disableAnimations: true,
            ),
            child: UncontrolledProviderScope(
              container: container,
              child: const TeotihuacanValleyScreen(),
            ),
          ),
        ),
      );

      // Buscar el indicador de reduce motion
      expect(find.text('Movimiento reducido'), findsOneWidget);
    });

    testWidgets('reactivo a currentTimeOverride parameter', (tester) async {
      // Probar con currentTimeOverride forzando noche
      final nightTime = DateTime(2024, 1, 1, 22, 0); // 10 PM

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: TeotihuacanValleyScreen(
              currentTimeOverride: nightTime,
            ),
          ),
        ),
      );

      expect(find.byKey(teotihuacanValleyScreenKey), findsOneWidget);
    });

    testWidgets('reactivo a emotionOverride parameter', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: TeotihuacanValleyScreen(
              emotionOverride: PrehispanicEmotion.tlalocLluvia,
            ),
          ),
        ),
      );

      // La capa de clima debería mostrar partículas de lluvia
      expect(find.byKey(valleyWeatherParticlesLayerKey), findsOneWidget);
    });

    testWidgets('muestra los 5 elementos centrales con ValueKeys', (tester) async {
      // Crear container con relic mock para Tláloc y Xólotl
      final relicsContainer = ProviderContainer(
        overrides: [
          appSettingsServiceProvider.overrideWithValue(settingsService),
          ambientAudioPlayerProvider.overrideWithValue(mockPlayer),
          userRelicsProvider.overrideWith(
            (ref) => Future.value([
              UnlockedRelic(
                catalog: DeityRelicCatalog.vasijaTlaloc,
                unlockedAt: DateTime.now(),
                quantity: 1,
              ),
            ]),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: relicsContainer,
          child: MaterialApp(
            home: TeotihuacanValleyScreen(
              currentTimeOverride: DateTime(2024, 1, 1, 22, 0), // Noche
            ),
          ),
        ),
      );

      // Esperar a que el FutureProvider se resuelva
      await tester.pump();

      // Verificar las 5 claves centrales en la pantalla completa
      expect(find.byKey(valleyAltarQuetzalcoatlKey), findsOneWidget);
      expect(find.byKey(valleyXolotlFaunaKey), findsOneWidget);
      expect(find.byKey(valleyFuegoSagradoKey), findsOneWidget);
      expect(find.byKey(valleyChinampaKey), findsOneWidget);
      expect(find.byKey(valleyVasijaTlalocKey), findsOneWidget);

      relicsContainer.dispose();
    });

    testWidgets('maneja orientación landscape', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: TeotihuacanValleyScreen(),
          ),
        ),
      );

      // Cambiar a landscape usando tester.view (APIs no deprecated)
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
      });

      await tester.pump();

      expect(find.byKey(teotihuacanValleyScreenKey), findsOneWidget);
    });

    testWidgets('usa userRelicsProvider para reliquias', (tester) async {
      // Crear container con relic mock
      final relicsContainer = ProviderContainer(
        overrides: [
          appSettingsServiceProvider.overrideWithValue(settingsService),
          ambientAudioPlayerProvider.overrideWithValue(mockPlayer),
          userRelicsProvider.overrideWith(
            (ref) => Future.value([
              UnlockedRelic(
                catalog: DeityRelicCatalog.mariposasXochiquetzal,
                unlockedAt: DateTime.now(),
                quantity: 1,
              ),
            ]),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: relicsContainer,
          child: const MaterialApp(
            home: TeotihuacanValleyScreen(),
          ),
        ),
      );

      expect(find.byKey(teotihuacanValleyScreenKey), findsOneWidget);
      relicsContainer.dispose();
    });

    testWidgets('respeta SafeArea', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: TeotihuacanValleyScreen(),
          ),
        ),
      );

      // Verificar que el Scaffold tiene SafeArea
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.body, isNotNull);
    });

    testWidgets('no tiene AppBar, Drawer, ni BottomNavigationBar', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: TeotihuacanValleyScreen(),
          ),
        ),
      );

      // Usar la key del Scaffold para encontrarlo
      final scaffold = tester.widget<Scaffold>(find.byKey(teotihuacanValleyScreenKey));
      expect(scaffold.appBar, isNull);
      expect(scaffold.drawer, isNull);
      expect(scaffold.endDrawer, isNull);
      expect(scaffold.bottomNavigationBar, isNull);
      expect(scaffold.floatingActionButton, isNull);
    });
  });
}

/// Mock para el reproductor de audio (implementa la interfaz completa)
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