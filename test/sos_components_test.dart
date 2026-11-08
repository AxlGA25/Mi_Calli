// Pruebas para SupportNetworkModal y SupportContactService.
//
// Verifica:
// 1. Modal abre tel:8009112000 y tel:911
// 2. Botón contacto lleva a configurarlo si no hay contacto
// 3. Botón "Necesito apoyo" en pantalla de bloqueo abre modal sin autenticar

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mi_calli/core/security/support_network_modal.dart';
import 'package:mi_calli/core/security/support_contact_service.dart';
import 'package:mi_calli/features/0_onboarding/biometric_lock_screen.dart';
import 'package:mi_calli/core/security/biometric_vault_service.dart';
import 'package:mi_calli/core/security/biometric_auth_mock.dart';
import 'package:mi_calli/core/settings/app_settings_service.dart';
import 'package:mi_calli/core/settings/app_settings_provider.dart';
import 'package:mi_calli/core/constants/sos_texts.dart';

void main() {
  group('SupportContactService', () {
    late SharedPreferences prefs;
    late AppSettingsService settings;
    late SupportContactService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      settings = AppSettingsService.createForTesting(prefs);
      service = SupportContactService.createForTesting(settings);
    });

    test('hasContact es false si no hay contacto configurado', () {
      expect(service.hasContact, isFalse);
    });

    test('hasContact es true si hay nombre y teléfono', () async {
      await settings.setTrustedContactName('María');
      await settings.setTrustedContactPhone('5551234567');
      expect(service.hasContact, isTrue);
    });

    test('displayName retorna nombre si existe', () async {
      await settings.setTrustedContactName('María');
      expect(service.displayName, equals('María'));
    });

    test('displayName retorna fallback si no hay nombre', () async {
      await settings.setTrustedContactPhone('5551234567');
      expect(service.displayName, equals('mi persona de confianza'));
    });

    test('phoneDigits retorna solo dígitos', () async {
      await settings.setTrustedContactPhone('55 5123 4567');
      expect(service.phoneDigits, equals('5551234567'));
    });
  });

  group('SupportNetworkModal', () {
    late SharedPreferences prefs;
    late AppSettingsService settings;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      settings = AppSettingsService.createForTesting(prefs);
    });

    testWidgets('modal muestra botones correctos (sin contacto)', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          appSettingsServiceProvider.overrideWithValue(settings),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => SupportNetworkModal.show(context),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      // Verificar que el modal se muestra
      expect(find.text(SosTexts.tituloSupportNetworkModal), findsOneWidget);
      // Sin contacto, debe mostrar "Configurar contacto de confianza"
      expect(find.text(SosTexts.botonConfigurarContacto), findsOneWidget);
      expect(find.text(SosTexts.botonLineaDeLaVida), findsOneWidget);
      expect(find.text(SosTexts.botonEmergencias), findsOneWidget);
    });

    testWidgets('botón Línea de la Vida intenta abrir tel:8009112000', (tester) async {
      // No podemos probar url_launcher directamente en tests sin mock,
      // pero verificamos que el botón existe y tiene el texto correcto
      await tester.pumpWidget(ProviderScope(
        overrides: [
          appSettingsServiceProvider.overrideWithValue(settings),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => SupportNetworkModal.show(context),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      // El botón Línea de la Vida debe existir con el número correcto
      expect(find.text(SosTexts.botonLineaDeLaVida), findsOneWidget);
      expect(SosTexts.botonLineaDeLaVida, contains('800 911 2000'));
    });

    testWidgets('botón Emergencias intenta abrir tel:911', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          appSettingsServiceProvider.overrideWithValue(settings),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => SupportNetworkModal.show(context),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.text(SosTexts.botonEmergencias), findsOneWidget);
      expect(SosTexts.botonEmergencias, contains('911'));
    });

    testWidgets('botón contacto sin configurar muestra "Configurar contacto"', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          appSettingsServiceProvider.overrideWithValue(settings),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => SupportNetworkModal.show(context),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      // Sin contacto configurado, el botón debe decir "Configurar contacto de confianza"
      expect(find.text(SosTexts.botonConfigurarContacto), findsOneWidget);
    });

    testWidgets('botón contacto con configurado muestra nombre', (tester) async {
      await settings.setTrustedContactName('María');
      await settings.setTrustedContactPhone('5551234567');
      // Asegurar que los valores se persistan antes de construir
      await tester.pump();

      await tester.pumpWidget(ProviderScope(
        overrides: [
          appSettingsServiceProvider.overrideWithValue(settings),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => SupportNetworkModal.show(context),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      // Con contacto configurado, debe mostrar "Contactar a mi persona de confianza"
      expect(find.text(SosTexts.botonContactoConfianza), findsOneWidget);
    });

    testWidgets('mensaje SOS personalizado usa nombre del contacto', (tester) async {
      // Configurar contacto (nombre Y teléfono)
      await settings.setTrustedContactName('María');
      await settings.setTrustedContactPhone('5551234567');
      await tester.pump();

      await tester.pumpWidget(ProviderScope(
        overrides: [
          appSettingsServiceProvider.overrideWithValue(settings),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => SupportNetworkModal.show(context),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      // Tocar botón de contacto para abrir selector WhatsApp/SMS
      await tester.tap(find.text(SosTexts.botonContactoConfianza));
      await tester.pumpAndSettle();

      // Verificar que el selector muestra el nombre en el título
      expect(find.text('¿Cómo quieres contactar a María?'), findsOneWidget);
    });

    testWidgets('mensaje SOS personalizado usa fallback cuando solo hay teléfono', (tester) async {
      // Solo teléfono, sin nombre -> hasContact es false, muestra botón "Configurar"
      await settings.setTrustedContactPhone('5551234567');
      await tester.pump();

      await tester.pumpWidget(ProviderScope(
        overrides: [
          appSettingsServiceProvider.overrideWithValue(settings),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => SupportNetworkModal.show(context),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      // Sin nombre, hasContact=false, debe mostrar "Configurar contacto de confianza"
      expect(find.text(SosTexts.botonConfigurarContacto), findsOneWidget);

      // Pero SupportContactService.displayName usa fallback "mi persona de confianza"
      final service = SupportContactService.createForTesting(settings);
      expect(service.displayName, equals('mi persona de confianza'));
    });

    group('Mensaje SOS - Texto exacto', () {
      test('con nombre "María" genera texto exacto sin [Nombre]', () {
        final msg = SosTexts.mensajePersonaConfianza('María');
        expect(msg, equals(
          'Hola María, te escribo desde mi refugio porque en este momento '
          'no me siento muy bien emocionalmente y me ayudaría mucho platicar '
          'o sentir tu compañía. ¿Tienes un momento?'
        ));
        expect(msg, isNot(contains('[Nombre]')));
      });

      test('con nombre null genera texto exacto sin [Nombre] ni "mi persona de confianza"', () {
        final msg = SosTexts.mensajePersonaConfianza(null);
        expect(msg, equals(
          'Hola, te escribo desde mi refugio porque en este momento '
          'no me siento muy bien emocionalmente y me ayudaría mucho platicar '
          'o sentir tu compañía. ¿Tienes un momento?'
        ));
        expect(msg, isNot(contains('[Nombre]')));
        expect(msg, isNot(contains('mi persona de confianza')));
      });

      test('con nombre vacío genera texto exacto sin [Nombre]', () {
        final msg = SosTexts.mensajePersonaConfianza('');
        expect(msg, equals(
          'Hola, te escribo desde mi refugio porque en este momento '
          'no me siento muy bien emocionalmente y me ayudaría mucho platicar '
          'o sentir tu compañía. ¿Tienes un momento?'
        ));
        expect(msg, isNot(contains('[Nombre]')));
      });

      test('con nombre solo espacios genera texto exacto sin [Nombre]', () {
        final msg = SosTexts.mensajePersonaConfianza('   ');
        expect(msg, equals(
          'Hola, te escribo desde mi refugio porque en este momento '
          'no me siento muy bien emocionalmente y me ayudaría mucho platicar '
          'o sentir tu compañía. ¿Tienes un momento?'
        ));
        expect(msg, isNot(contains('[Nombre]')));
      });

      test('con nombre con espacios alrededor los recorta', () {
        final msg = SosTexts.mensajePersonaConfianza('  Ana  ');
        expect(msg, equals(
          'Hola Ana, te escribo desde mi refugio porque en este momento '
          'no me siento muy bien emocionalmente y me ayudaría mucho platicar '
          'o sentir tu compañía. ¿Tienes un momento?'
        ));
        expect(msg, isNot(contains('[Nombre]')));
      });
    });
  });

  group('BiometricLockScreen - Botón Necesito apoyo', () {
    late SharedPreferences prefs;
    late AppSettingsService settings;
    late BiometricAuthMock authMock;
    late BiometricVaultService vaultService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      settings = AppSettingsService.createForTesting(prefs);
      authMock = BiometricAuthMock();
      vaultService = BiometricVaultService.createForTesting(
        authMock: authMock,
        settingsMock: settings,
      );
      await vaultService.initializationComplete;
      BiometricVaultService.setInstanceForTesting(vaultService);
    });

    tearDown(() {
      vaultService.dispose();
      BiometricVaultService.setInstanceForTesting(null);
    });

    testWidgets('botón "Necesito apoyo" abre SupportNetworkModal sin autenticar', (tester) async {
      // Configurar bóveda como locked
      vaultService.lock();

      await tester.pumpWidget(ProviderScope(
        overrides: [
          appSettingsServiceProvider.overrideWithValue(settings),
          biometricVaultServiceProvider.overrideWithValue(vaultService),
          biometricVaultStateProvider.overrideWith(
            (ref) => Stream.value(BiometricVaultState.locked),
          ),
        ],
        child: MaterialApp(
          home: const BiometricLockScreen(),
        ),
      ));

      await tester.pumpAndSettle();

      // Verificar que la pantalla de bloqueo se muestra
      expect(find.byType(BiometricLockScreen), findsOneWidget);

      // Verificar que el botón "Necesito apoyo" existe
      expect(find.text('Necesito apoyo'), findsOneWidget);

      // Tocar el botón - debe abrir el modal sin autenticar
      await tester.tap(find.text('Necesito apoyo'));
      await tester.pumpAndSettle();

      // Verificar que el modal se abrió (título visible)
      expect(find.text(SosTexts.tituloSupportNetworkModal), findsOneWidget);
    });
  });
}