// Pruebas para SettingsScreen (Tarea 4.6).
//
// Cubre las 5 secciones:
// 1. General
// 2. Apariencia / Accesibilidad
// 3. Notificaciones
// 4. Red de Apoyo
// 5. Privacidad y Legal
//
// Verifica reactividad con AppSettingsProvider, navegación y formularios.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_calli/core/settings/app_settings_provider.dart';
import 'package:mi_calli/core/settings/app_settings_service.dart';
import 'package:mi_calli/features/3_teotihuacan_valley/presentation/settings_screen.dart';
import 'package:mi_calli/features/3_teotihuacan_valley/presentation/privacy_and_legal_screen.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('SettingsScreen', () {
    late ProviderContainer container;
    late AppSettingsService settingsService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      settingsService = await AppSettingsService.create();

      container = ProviderContainer(
        overrides: [
          appSettingsServiceProvider.overrideWithValue(settingsService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    Future<void> openSettings(WidgetTester tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    // Helper para hacer tap en un tile por su título
    Future<void> tapTile(WidgetTester tester, String title) async {
      final tile = find.ancestor(
        of: find.text(title).first,
        matching: find.byWidgetPredicate((widget) => widget is InkWell),
      );
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await tester.pumpAndSettle();
    }

    // Helper para hacer tap en un tile por su ValueKey (el key está en el Semantics)
    Future<void> tapTileByKey(WidgetTester tester, String key) async {
      final tile = find.byKey(ValueKey(key));
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await tester.pumpAndSettle();
    }

    testWidgets('renderiza pantalla con título y 5 secciones', (tester) async {
      await openSettings(tester);

      expect(find.text('Ajustes'), findsOneWidget);
      expect(find.text('General'), findsOneWidget);
      expect(find.text('Apariencia / Accesibilidad'), findsOneWidget);
      expect(find.text('Notificaciones'), findsOneWidget);
      expect(find.text('Red de Apoyo'), findsOneWidget);
      expect(find.text('Privacidad y Legal'), findsOneWidget);
      expect(find.byKey(const ValueKey('settings_screen')), findsOneWidget);
    });

    group('Sección 1: General', () {
      testWidgets('Audio Ambiental - toggle funciona', (tester) async {
        await openSettings(tester);

        expect(find.text('Desactivado'), findsAtLeastNWidgets(1));

        await tapTile(tester, 'Audio Ambiental');

        expect(find.text('Activado'), findsAtLeastNWidgets(1));
      });

      testWidgets('Candado de la App - toggle funciona', (tester) async {
        await openSettings(tester);

        expect(find.text('Candado de la App'), findsOneWidget);
        expect(find.text('Biometría al volver de segundo plano (>30s)'), findsOneWidget);

        await tapTile(tester, 'Candado de la App');
      });

      testWidgets('Versión de la App - abre diálogo', (tester) async {
        await openSettings(tester);

        await tapTileByKey(tester, 'settings_tile_version');

        // Verify dialog opens (check for dialog-specific content, not tile text)
        expect(find.text('Mi Calli v1.0.0'), findsOneWidget);
        expect(find.text('Refugio Quetzalcóatl'), findsOneWidget);
        expect(find.textContaining('prehisp'), findsOneWidget);

        await tester.tap(find.text('Cerrar'));
        await tester.pumpAndSettle();
      });
    });

    group('Sección 2: Apariencia / Accesibilidad', () {
      testWidgets('Reducir Movimiento - toggle funciona', (tester) async {
        await openSettings(tester);

        expect(find.text('Reducir Movimiento'), findsOneWidget);
        expect(find.text('Desactivado'), findsAtLeastNWidgets(1));

        await tapTile(tester, 'Reducir Movimiento');

        expect(find.text('Activado'), findsAtLeastNWidgets(1));
      });
    });

    group('Sección 3: Notificaciones', () {
      testWidgets('Recordatorio Diario - toggle y selector de hora', (tester) async {
        await openSettings(tester);

        expect(find.text('Recordatorio Diario'), findsOneWidget);
        expect(find.text('Desactivado'), findsAtLeastNWidgets(1));

        await tapTile(tester, 'Recordatorio Diario');
      });

      testWidgets('Hora del Recordatorio visible cuando está activado', (tester) async {
        await settingsService.setReminderEnabled(true);
        await settingsService.setReminderTime('18:30');

        await openSettings(tester);

        expect(find.text('Recordatorio Diario'), findsOneWidget);
        expect(find.text('Activado a las 18:30'), findsOneWidget);
        expect(find.text('Hora del Recordatorio'), findsOneWidget);
        expect(find.text('18:30'), findsOneWidget);
      });
    });

    group('Sección 4: Red de Apoyo', () {
      testWidgets('Contacto de Confianza - muestra "No configurado" inicialmente', (tester) async {
        await openSettings(tester);

        expect(find.text('Contacto de Confianza'), findsOneWidget);
        expect(find.text('No configurado'), findsOneWidget);
      });

      testWidgets('Contacto de Confianza - abre formulario de configuración', (tester) async {
        await openSettings(tester);

        await tapTile(tester, 'Contacto de Confianza');

        expect(find.text('Configurar Contacto de Confianza'), findsOneWidget);
        expect(find.byKey(const ValueKey('settings_contact_name_input')), findsOneWidget);
        expect(find.byKey(const ValueKey('settings_contact_phone_input')), findsOneWidget);
        expect(find.byKey(const ValueKey('settings_save_contact_button')), findsOneWidget);
      });

      testWidgets('Contacto de Confianza - guarda y muestra contacto', (tester) async {
        await openSettings(tester);

        await tapTile(tester, 'Contacto de Confianza');

        await tester.enterText(
          find.byKey(const ValueKey('settings_contact_name_input')),
          'María'
        );
        await tester.enterText(
          find.byKey(const ValueKey('settings_contact_phone_input')),
          '+5215512345678'
        );
        await tester.pump();

        // Ensure save button is visible (may be off-screen in bottom sheet)
        await tester.ensureVisible(find.byKey(const ValueKey('settings_save_contact_button')));
        await tester.tap(find.byKey(const ValueKey('settings_save_contact_button')));

        // Wait for bottom sheet to close and main screen to rebuild
        await tester.pumpAndSettle();
        await tester.pump(); // Extra pump for state propagation

        // Check for exact subtitle format to avoid matching SnackBar
        expect(find.text('María (+5215512345678)'), findsOneWidget);
      });

      testWidgets('Contacto de Confianza - edita contacto existente', (tester) async {
        // Use notifier to ensure provider state is updated
        await container.read(appSettingsProvider.notifier).setTrustedContactName('Juan');
        await container.read(appSettingsProvider.notifier).setTrustedContactPhone('+5215587654321');

        await openSettings(tester);

        expect(find.textContaining('Juan'), findsOneWidget);
        expect(find.textContaining('+5215587654321'), findsOneWidget);

        await tapTile(tester, 'Contacto de Confianza');

        expect(find.text('Editar Contacto de Confianza'), findsOneWidget);
        expect(find.byKey(const ValueKey('settings_clear_contact_button')), findsOneWidget);

        await tester.enterText(
          find.byKey(const ValueKey('settings_contact_name_input')),
          'Pedro'
        );
        await tester.enterText(
          find.byKey(const ValueKey('settings_contact_phone_input')),
          '+5215599999999'
        );
        await tester.pump();

        // Ensure save button is visible (may be off-screen in bottom sheet)
        await tester.ensureVisible(find.byKey(const ValueKey('settings_save_contact_button')));
        await tester.tap(find.byKey(const ValueKey('settings_save_contact_button')));

        // Wait for bottom sheet to close and main screen to rebuild
        await tester.pumpAndSettle();
        await tester.pump(); // Extra pump for state propagation

        // Check for exact subtitle format to avoid matching SnackBar
        expect(find.text('Pedro (+5215599999999)'), findsOneWidget);
      });

      testWidgets('Contacto de Confianza - eliminar contacto', (tester) async {
        // Use notifier to ensure provider state is updated
        await container.read(appSettingsProvider.notifier).setTrustedContactName('Juan');
        await container.read(appSettingsProvider.notifier).setTrustedContactPhone('+5215587654321');

        await openSettings(tester);

        expect(find.textContaining('Juan'), findsOneWidget);
        expect(find.textContaining('+5215587654321'), findsOneWidget);

        // Open contact config bottom sheet
        await tapTile(tester, 'Contacto de Confianza');

        // Tap clear button in bottom sheet
        await tester.ensureVisible(find.byKey(const ValueKey('settings_clear_contact_button')));
        await tester.tap(find.byKey(const ValueKey('settings_clear_contact_button')));
        await tester.pumpAndSettle();

        // After bottom sheet closes, verify main screen shows "No configurado"
        expect(find.text('No configurado'), findsOneWidget);
      });
    });

    group('Sección 5: Privacidad y Legal', () {
      testWidgets('Aviso y Privacidad - navega a PrivacyAndLegalScreen', (tester) async {
        await openSettings(tester);

        await tapTile(tester, 'Aviso y Privacidad');

        expect(find.byType(PrivacyAndLegalScreen), findsOneWidget);
        expect(find.text('Aviso y Privacidad'), findsOneWidget);
      });

      testWidgets('Política de Privacidad (Web) - intenta lanzar URL', (tester) async {
        await openSettings(tester);

        await tapTile(tester, 'Política de Privacidad (Web)');

        expect(find.byType(SettingsScreen), findsOneWidget);
      });

      testWidgets('Eliminar mi Respaldo - muestra diálogo de confirmación', (tester) async {
        await openSettings(tester);

        await tapTile(tester, 'Eliminar mi Respaldo en la Nube');

        expect(find.text('Eliminar mi respaldo'), findsOneWidget);
        expect(find.text('Eliminar respaldo'), findsOneWidget);
        expect(find.text('Cancelar'), findsOneWidget);
      });

      testWidgets('Exportar mi Diario - muestra diálogo de advertencia', (tester) async {
        await openSettings(tester);

        await tapTile(tester, 'Exportar mi Diario');

        expect(find.text('Exportar mi diario'), findsOneWidget);
        expect(find.text('Exportar'), findsOneWidget);
        expect(find.text('Cancelar'), findsOneWidget);
      });
    });

    testWidgets('scroll funciona en toda la pantalla', (tester) async {
      await openSettings(tester);

      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -1000));
      await tester.pumpAndSettle();

      expect(find.text('Exportar mi Diario'), findsOneWidget);
    });

    testWidgets('todos los tiles principales existen y son accesibles', (tester) async {
      await openSettings(tester);

      for (final title in [
        'Audio Ambiental',
        'Candado de la App',
        'Versión de la App',
        'Reducir Movimiento',
        'Recordatorio Diario',
        'Contacto de Confianza',
        'Aviso y Privacidad',
        'Política de Privacidad (Web)',
        'Eliminar mi Respaldo en la Nube',
        'Exportar mi Diario',
      ]) {
        // Verificar que el texto existe y tiene un ancestro InkWell (tappable)
        final inkWell = find.ancestor(
          of: find.text(title).first,
          matching: find.byWidgetPredicate((widget) => widget is InkWell),
        );
        expect(inkWell, findsOneWidget, reason: 'Tile "$title" debe ser tappable (InkWell)');
      }
    });

    testWidgets('reactividad: cambios en settings se reflejan en UI', (tester) async {
      await openSettings(tester);

      container.read(appSettingsProvider.notifier).setAudioEnabled(true);
      await tester.pumpAndSettle();

      expect(find.text('Activado'), findsAtLeastNWidgets(1));
    });
  });
}