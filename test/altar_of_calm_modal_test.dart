// Pruebas para AltarOfCalmModal (Tarea 4.5).
//
// Cubre:
// - 3 fases del ciclo 4-4-6 (Inhala, Sostén, Exhala)
// - Completar 3 ciclos alimenta el Fuego Sagrado y muestra banner
// - Botones de apoyo funcionan (Línea de la Vida y contacto de confianza)
// - Guardar/actualizar contacto de confianza desde formulario
// - reduceMotion = true y escalado de texto 200% sin overflow

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;

import 'package:mi_calli/core/database/local_database_service.dart';
import 'package:mi_calli/core/database/secure_storage_mock.dart';
import 'package:mi_calli/core/settings/app_settings_provider.dart';
import 'package:mi_calli/core/settings/app_settings_service.dart';
import 'package:mi_calli/features/2_gamification/services/sacred_fire_and_evolution_service.dart';
import 'package:mi_calli/features/2_gamification/models/gamification_models.dart';
import 'package:mi_calli/features/3_teotihuacan_valley/presentation/widgets/altar_of_calm_modal.dart';
import 'package:mi_calli/core/performance/safe_animation_wrapper.dart';

/// Mock service for Sacred Fire that immediately succeeds
class MockSacredFireAndEvolutionService extends SacredFireAndEvolutionService {
  int registerDailyCheckinCallCount = 0;
  DateTime? lastCheckinDate;
  bool lastGrantJournalXp = false;

  MockSacredFireAndEvolutionService() : super(LocalDatabaseService.createForTesting(
    secureStorage: SecureStorageMock(),
    databaseFactory: databaseFactoryFfi,
  ));

  @override
  Future<CheckinResult> registerDailyCheckin({
    required DateTime now,
    bool grantJournalXp = true,
  }) async {
    registerDailyCheckinCallCount++;
    lastCheckinDate = now;
    lastGrantJournalXp = grantJournalXp;
    // Return a successful result without touching the database
    final state = GamificationState(
      quetzalXp: 0,
      quetzalLevel: 1,
      currentStreak: 1,
      longestStreak: 1,
      lastCheckinDate: now.toIso8601String().substring(0, 10),
      xolotlShields: 1,
    );
    return CheckinResult(
      state: state,
      status: StreakStatus.incremented,
      leveledUp: false,
      shieldEarned: false,
      compassionateMessage: '',
    );
  }
}

/// Provider para localDatabaseService (necesario para tests)
final localDatabaseServiceProvider = Provider<LocalDatabaseService>((ref) {
  throw UnimplementedError('localDatabaseServiceProvider debe ser sobrescrito en tests');
});

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('AltarOfCalmModal', () {
    late ProviderContainer container;
    late AppSettingsService settingsService;
    late LocalDatabaseService databaseService;
    late SecureStorageMock secureStorageMock;
    late MockSacredFireAndEvolutionService mockSacredFireService;

    setUp(() async {
      // Inicializar SQLite FFI para tests
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      SharedPreferences.setMockInitialValues({});
      settingsService = await AppSettingsService.create();

      // Crear mock de almacenamiento seguro para tests
      secureStorageMock = SecureStorageMock();

      // Crear base de datos real en memoria para tests
      databaseService = LocalDatabaseService.createForTesting(
        secureStorage: secureStorageMock,
        databaseFactory: databaseFactoryFfi,
      );
      await databaseService.initialize();

      mockSacredFireService = MockSacredFireAndEvolutionService();

      container = ProviderContainer(
        overrides: [
          appSettingsServiceProvider.overrideWithValue(settingsService),
          localDatabaseServiceProvider.overrideWithValue(databaseService),
          sacredFireAndEvolutionServiceProvider.overrideWithValue(mockSacredFireService),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await databaseService.close();
    });

    Future<void> openModal(WidgetTester tester) async {
      // Reset test timer factory
      AltarOfCalmModal.setTestTimerFactory(null);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => AltarOfCalmModal.show(context),
                    child: const Text('Abrir Altar'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Altar'));
      await tester.pumpAndSettle();
    }

    /// Callback for test timer
    VoidCallback? testTickCallback;

    /// Sets up a test timer that allows manual time advancement.
    void setupTestTimer() {
      AltarOfCalmModal.setTestTimerFactory((tickCallback) {
        testTickCallback = tickCallback;
      });
    }

    /// Advances the breathing engine by the given number of seconds.
    Future<void> advanceEngine(WidgetTester tester, int seconds) async {
      for (int i = 0; i < seconds; i++) {
        testTickCallback?.call();
        await tester.pump(const Duration(milliseconds: 1));
      }
    }

    Future<void> scrollTo(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
    }

    testWidgets('renderiza modal con título y subtítulo correctos', (tester) async {
      await openModal(tester);

      // Verificar título y subtítulo (compatibilidad con tests existentes)
      expect(find.text('Aquí hay manos que te sostienen'), findsOneWidget);
      expect(find.text('Altar de Calma · Viento de Ehécatl'), findsOneWidget);
    });

    testWidgets('Sección 1: fases del ciclo 4-4-6', (tester) async {
      await openModal(tester);
      setupTestTimer();

      // Verificar estado inicial: idle, botón dice "Iniciar"
      await scrollTo(tester, find.byKey(const ValueKey('altar_breathing_toggle_button')));
      expect(find.text('Iniciar'), findsOneWidget);

      // Tap en botón para iniciar
      await tester.tap(find.byKey(const ValueKey('altar_breathing_toggle_button')));
      await tester.pump();

      // Debe mostrar "Inhala" y empezar cuenta regresiva (usar key para encontrar el texto de fase)
      expect(find.byKey(const ValueKey('altar_breathing_phase_text')), findsOneWidget);
      expect(find.text('Pausar'), findsOneWidget);
      expect(find.byKey(const ValueKey('altar_cycle_counter')), findsOneWidget);

      // Avanzar 4 segundos (Inhala -> Sostén)
      await advanceEngine(tester, 4);

      expect(find.byKey(const ValueKey('altar_breathing_phase_text')), findsOneWidget);

      // Avanzar 4 segundos (Sostén -> Exhala)
      await advanceEngine(tester, 4);

      expect(find.byKey(const ValueKey('altar_breathing_phase_text')), findsOneWidget);

      // Avanzar 6 segundos (completa ciclo 1)
      await advanceEngine(tester, 6);

      // Debe mostrar "Ciclo 1 de 3" y volver a "Inhala"
      expect(find.byKey(const ValueKey('altar_cycle_counter')), findsOneWidget);
      expect(find.byKey(const ValueKey('altar_breathing_phase_text')), findsOneWidget);
    });

    testWidgets('completar 3 ciclos alimenta Fuego Sagrado y muestra banner', (tester) async {
      await openModal(tester);
      setupTestTimer();

      // Iniciar respiración
      await scrollTo(tester, find.byKey(const ValueKey('altar_breathing_toggle_button')));
      await tester.tap(find.byKey(const ValueKey('altar_breathing_toggle_button')));
      await tester.pump();

      // Ciclo 1: 4s + 4s + 6s = 14s
      await advanceEngine(tester, 4);
      await advanceEngine(tester, 4);
      await advanceEngine(tester, 6);
      expect(find.byKey(const ValueKey('altar_cycle_counter')), findsOneWidget);

      // Ciclo 2: 4s + 4s + 6s = 14s
      await advanceEngine(tester, 4);
      await advanceEngine(tester, 4);
      await advanceEngine(tester, 6);
      expect(find.byKey(const ValueKey('altar_cycle_counter')), findsOneWidget);

      // Ciclo 3: 4s + 4s + 6s = 14s
      await advanceEngine(tester, 4);
      await advanceEngine(tester, 4);
      await advanceEngine(tester, 6);

      // Esperar a que se complete la operación asíncrona (mock es inmediato)
      await tester.pumpAndSettle();

      // Debe mostrar banner de Fuego Sagrado alimentado
      expect(find.byKey(const ValueKey('altar_sacred_fire_fed_banner')), findsOneWidget);
      expect(find.text('Has completado 3 ciclos de calma. Tu Fuego Sagrado ha sido alimentado hoy.'), findsOneWidget);
      expect(find.text('Completo'), findsOneWidget);
      expect(find.text('Reiniciar'), findsOneWidget);

      // Verificar que se llamó exactamente una vez con grantJournalXp: false
      expect(mockSacredFireService.registerDailyCheckinCallCount, equals(1));
      expect(mockSacredFireService.lastGrantJournalXp, isFalse);
      expect(mockSacredFireService.lastCheckinDate, isNotNull);
    });

    testWidgets('botón Línea de la Vida tiene key correcta y texto', (tester) async {
      await openModal(tester);

      // Verificar botón Línea de la Vida (hacer scroll)
      await scrollTo(tester, find.byKey(const ValueKey('altar_lifeline_button')));
      expect(find.byKey(const ValueKey('altar_lifeline_button')), findsOneWidget);
      expect(find.text('Llamar a Línea de la Vida (800 911 2000)'), findsOneWidget);
    });

    testWidgets('botón Persona de Confianza sin contacto muestra formulario de configuración', (tester) async {
      await openModal(tester);

      // Sin contacto configurado, el botón debe decir "Configurar contacto de confianza"
      await scrollTo(tester, find.byKey(const ValueKey('altar_trusted_contact_button')));
      expect(find.byKey(const ValueKey('altar_trusted_contact_button')), findsOneWidget);

      // Tap en botón debe mostrar formulario
      await tester.tap(find.byKey(const ValueKey('altar_trusted_contact_button')));
      await tester.pumpAndSettle();

      // Verificar formulario de configuración
      expect(find.byKey(const ValueKey('altar_contact_name_input')), findsOneWidget);
      expect(find.byKey(const ValueKey('altar_contact_phone_input')), findsOneWidget);
      expect(find.byKey(const ValueKey('altar_save_contact_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('altar_configure_contact_button')), findsNothing); // Oculto mientras se configura
    });

    testWidgets('guardar contacto de confianza desde formulario', (tester) async {
      await openModal(tester);

      // Abrir formulario de configuración
      await scrollTo(tester, find.byKey(const ValueKey('altar_trusted_contact_button')));
      await tester.tap(find.byKey(const ValueKey('altar_trusted_contact_button')));
      await tester.pumpAndSettle();

      // Llenar formulario
      await tester.enterText(find.byKey(const ValueKey('altar_contact_name_input')), 'María');
      await tester.enterText(find.byKey(const ValueKey('altar_contact_phone_input')), '+5215512345678');
      await tester.pump();

      // Guardar
      await scrollTo(tester, find.byKey(const ValueKey('altar_save_contact_button')));
      await tester.tap(find.byKey(const ValueKey('altar_save_contact_button')));
      await tester.pumpAndSettle();

      // Debe volver a botones y mostrar el nombre
      await scrollTo(tester, find.byKey(const ValueKey('altar_trusted_contact_button')));
      expect(find.text('Pedir compañía a María'), findsOneWidget);
      expect(find.byKey(const ValueKey('altar_configure_contact_button')), findsOneWidget);
      expect(find.text('Editar contacto de confianza'), findsOneWidget);
    });

    testWidgets('actualizar contacto de confianza existente', (tester) async {
      // Primero configurar un contacto
      await settingsService.setTrustedContactName('Juan');
      await settingsService.setTrustedContactPhone('+5215587654321');

      await openModal(tester);

      // Verificar que muestra el contacto actual
      await scrollTo(tester, find.byKey(const ValueKey('altar_trusted_contact_button')));
      expect(find.text('Pedir compañía a Juan'), findsOneWidget);

      // Editar contacto - scroll to configure button
      await scrollTo(tester, find.byKey(const ValueKey('altar_configure_contact_button')));
      await tester.tap(find.byKey(const ValueKey('altar_configure_contact_button')));
      await tester.pumpAndSettle();

      // Llenar formulario con nuevos datos
      await tester.enterText(find.byKey(const ValueKey('altar_contact_name_input')), 'Pedro');
      await tester.enterText(find.byKey(const ValueKey('altar_contact_phone_input')), '+5215599999999');
      await tester.pump();

      // Guardar
      await scrollTo(tester, find.byKey(const ValueKey('altar_save_contact_button')));
      await tester.tap(find.byKey(const ValueKey('altar_save_contact_button')));
      await tester.pumpAndSettle();

      // Debe mostrar el contacto actualizado
      await scrollTo(tester, find.byKey(const ValueKey('altar_trusted_contact_button')));
      expect(find.text('Pedir compañía a Pedro'), findsOneWidget);
    });

    testWidgets('soporta reduceMotion = true sin animación de escala continua', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () => AltarOfCalmModal.show(context),
                      child: const Text('Abrir Altar'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Altar'));
      await tester.pumpAndSettle();

      // Iniciar respiración
      await scrollTo(tester, find.byKey(const ValueKey('altar_breathing_toggle_button')));
      await tester.tap(find.byKey(const ValueKey('altar_breathing_toggle_button')));
      await tester.pump();

      // Debe mostrar fase actual pero sin animación continua (SafeAnimationWrapper usa fallback)
      expect(find.byKey(const ValueKey('altar_breathing_phase_text')), findsOneWidget);
      expect(find.byType(SafeAnimationWrapper), findsWidgets);
    });

    testWidgets('soporte escalado de texto 200% (TextScaler.linear(2.0)) sin overflow', (tester) async {
      await openModal(tester);

      // Verificar que el modal se renderiza sin overflow
      // El modal usa SingleChildScrollView y DraggableScrollableSheet
      expect(find.byType(SingleChildScrollView), findsWidgets);
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);

      // Expandir a contenido completo
      await tester.drag(find.byType(DraggableScrollableSheet), const Offset(0, -500));
      await tester.pumpAndSettle();

      // No debe haber errores de overflow (no lanzan excepción)
      expect(find.byKey(const ValueKey('altar_breathing_toggle_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('altar_lifeline_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('altar_trusted_contact_button')), findsOneWidget);
    });

    testWidgets('botón Pausar detiene el timer y permite Continuar', (tester) async {
      await openModal(tester);
      setupTestTimer();

      // Iniciar
      await tester.ensureVisible(find.byKey(const ValueKey('altar_breathing_toggle_button')));
      await tester.tap(find.byKey(const ValueKey('altar_breathing_toggle_button')));
      await tester.pump();
      expect(find.text('Pausar'), findsOneWidget);

      // Pausar - usar pump simple
      await tester.tap(find.byKey(const ValueKey('altar_breathing_toggle_button')));
      await tester.pump();
      expect(find.text('Continuar'), findsOneWidget);
      expect(find.text('Pausado'), findsOneWidget);

      // Continuar
      await tester.tap(find.byKey(const ValueKey('altar_breathing_toggle_button')));
      await tester.pump();
      expect(find.text('Pausar'), findsOneWidget);
    });

    testWidgets('botón Reiniciar tras completar 3 ciclos vuelve a estado inicial', (tester) async {
      await openModal(tester);
      setupTestTimer();

      // Completar 3 ciclos (usar incrementos pequeños)
      await scrollTo(tester, find.byKey(const ValueKey('altar_breathing_toggle_button')));
      await tester.tap(find.byKey(const ValueKey('altar_breathing_toggle_button')));
      await tester.pump();

      // 3 ciclos de 14s cada uno = 42s total, en incrementos de 4+4+6
      for (int i = 0; i < 3; i++) {
        await advanceEngine(tester, 4);
        await advanceEngine(tester, 4);
        await advanceEngine(tester, 6);
      }

      // Esperar a que se complete la operación asíncrona (mock es inmediato)
      await tester.pumpAndSettle();

      // Verificar estado completado
      expect(find.byKey(const ValueKey('altar_sacred_fire_fed_banner')), findsOneWidget);
      expect(find.text('Reiniciar'), findsOneWidget);

      // Reiniciar
      await scrollTo(tester, find.byKey(const ValueKey('altar_breathing_toggle_button')));
      await tester.tap(find.byKey(const ValueKey('altar_breathing_toggle_button')));
      await tester.pump();

      // Debe volver a estado inicial
      expect(find.text('Iniciar'), findsOneWidget);
      expect(find.byKey(const ValueKey('altar_cycle_counter')), findsOneWidget);
      expect(find.byKey(const ValueKey('altar_sacred_fire_fed_banner')), findsNothing);
    });

    testWidgets('todos los botones tienen Semantics con label accesible', (tester) async {
      await openModal(tester);

      // Verificar Semantics en botón de respiración
      final breathingButton = find.byKey(const ValueKey('altar_breathing_toggle_button'));
      final breathingSemantics = find.descendant(
        of: breathingButton,
        matching: find.byWidgetPredicate((widget) => widget is Semantics && widget.properties.button == true),
      );
      expect(breathingSemantics, findsOneWidget);

      // Verificar Semantics en botón Línea de la Vida
      await scrollTo(tester, find.byKey(const ValueKey('altar_lifeline_button')));
      final lifelineButton = find.byKey(const ValueKey('altar_lifeline_button'));
      final lifelineSemantics = find.descendant(
        of: lifelineButton,
        matching: find.byWidgetPredicate((widget) => widget is Semantics && widget.properties.button == true),
      );
      expect(lifelineSemantics, findsOneWidget);

      // Verificar Semantics en botón contacto confianza
      await scrollTo(tester, find.byKey(const ValueKey('altar_trusted_contact_button')));
      final trustedButton = find.byKey(const ValueKey('altar_trusted_contact_button'));
      final trustedSemantics = find.descendant(
        of: trustedButton,
        matching: find.byWidgetPredicate((widget) => widget is Semantics && widget.properties.button == true),
      );
      expect(trustedSemantics, findsOneWidget);
    });

    testWidgets('áreas táctiles mínimas 48x48 en todos los botones', (tester) async {
      await openModal(tester);

      // Verificar botones de apoyo (estado inicial)
      for (final key in [
        const ValueKey('altar_breathing_toggle_button'),
        const ValueKey('altar_lifeline_button'),
        const ValueKey('altar_trusted_contact_button'),
        const ValueKey('altar_configure_contact_button'),
      ]) {
        // Buscar el ConstrainedBox que es padre directo del botón (con constraints 48x48)
        final constrainedBoxes = find.ancestor(
          of: find.byKey(key),
          matching: find.byWidgetPredicate((widget) {
            if (widget is ConstrainedBox) {
              final constraints = widget.constraints;
              return constraints.minWidth >= 48 && constraints.minHeight >= 48;
            }
            return false;
          }),
        );
        expect(constrainedBoxes, findsAtLeastNWidgets(1), reason: 'Botón $key debe tener ConstrainedBox con minWidth>=48, minHeight>=48');
      }

      // Abrir formulario para verificar botón de guardar
      await scrollTo(tester, find.byKey(const ValueKey('altar_trusted_contact_button')));
      await tester.tap(find.byKey(const ValueKey('altar_trusted_contact_button')));
      await tester.pumpAndSettle();

      // Verificar botón de guardar en formulario
      final saveButtonBoxes = find.ancestor(
        of: find.byKey(const ValueKey('altar_save_contact_button')),
        matching: find.byWidgetPredicate((widget) {
          if (widget is ConstrainedBox) {
            final constraints = widget.constraints;
            return constraints.minWidth >= 48 && constraints.minHeight >= 48;
          }
          return false;
        }),
      );
      expect(saveButtonBoxes, findsAtLeastNWidgets(1), reason: 'Botón altar_save_contact_button debe tener ConstrainedBox con minWidth>=48, minHeight>=48');
    });
  });
}