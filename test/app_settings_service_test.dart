// Pruebas unitarias para AppSettingsService.
//
// Verifica que los valores por defecto son los indicados (audio, reducir movimiento
// y recordatorio apagados) y que guardar y leer cada uno de los 9 ajustes funciona.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_calli/core/settings/app_settings_service.dart';

void main() {
  group('AppSettingsService', () {
    late SharedPreferences prefs;
    late AppSettingsService service;

    setUp(() async {
      // Configurar SharedPreferences con valores vacíos para cada test
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      service = AppSettingsService.createForTesting(prefs);
    });

    group('Valores por defecto', () {
      test('onboarding_done es false por defecto', () {
        expect(service.onboardingDone, isFalse);
      });

      test('adult_confirmed es false por defecto', () {
        expect(service.adultConfirmed, isFalse);
      });

      test('audio_enabled es false por defecto (apagado)', () {
        expect(service.audioEnabled, isFalse);
      });

      test('reduce_motion es false por defecto (apagado)', () {
        expect(service.reduceMotion, isFalse);
      });

      test('reminder_enabled es false por defecto (apagado)', () {
        expect(service.reminderEnabled, isFalse);
      });

      test('reminder_time es null por defecto', () {
        expect(service.reminderTime, isNull);
      });

      test('last_astral_reading_date es null por defecto', () {
        expect(service.lastAstralReadingDate, isNull);
      });

      test('trusted_contact_name es null por defecto', () {
        expect(service.trustedContactName, isNull);
      });

      test('trustedContactPhone es null por defecto', () {
        expect(service.trustedContactPhone, isNull);
      });

      test('app_lock_enabled es true por defecto (candado activado)', () {
        expect(service.appLockEnabled, isTrue);
      });

      test('privacy_consent_accepted es false por defecto', () {
        expect(service.privacyConsentAccepted, isFalse);
      });

      test('currentState devuelve AppSettingsState con todos los defaults', () {
        final state = service.currentState;

        expect(state.onboardingDone, isFalse);
        expect(state.adultConfirmed, isFalse);
        expect(state.audioEnabled, isFalse);
        expect(state.reduceMotion, isFalse);
        expect(state.reminderEnabled, isFalse);
        expect(state.appLockEnabled, isTrue);
        expect(state.privacyConsentAccepted, isFalse);
        expect(state.reminderTime, isNull);
        expect(state.lastAstralReadingDate, isNull);
        expect(state.trustedContactName, isNull);
        expect(state.trustedContactPhone, isNull);
      });
    });

    group('Guardar y leer cada ajuste', () {
      test('setOnboardingDone y getter onboardingDone', () async {
        await service.setOnboardingDone(true);
        expect(service.onboardingDone, isTrue);

        await service.setOnboardingDone(false);
        expect(service.onboardingDone, isFalse);
      });

      test('setAdultConfirmed y getter adultConfirmed', () async {
        await service.setAdultConfirmed(true);
        expect(service.adultConfirmed, isTrue);

        await service.setAdultConfirmed(false);
        expect(service.adultConfirmed, isFalse);
      });

      test('setAudioEnabled y getter audioEnabled', () async {
        await service.setAudioEnabled(true);
        expect(service.audioEnabled, isTrue);

        await service.setAudioEnabled(false);
        expect(service.audioEnabled, isFalse);
      });

      test('setReduceMotion y getter reduceMotion', () async {
        await service.setReduceMotion(true);
        expect(service.reduceMotion, isTrue);

        await service.setReduceMotion(false);
        expect(service.reduceMotion, isFalse);
      });

      test('setReminderEnabled y getter reminderEnabled', () async {
        await service.setReminderEnabled(true);
        expect(service.reminderEnabled, isTrue);

        await service.setReminderEnabled(false);
        expect(service.reminderEnabled, isFalse);
      });

      test('setReminderTime y getter reminderTime', () async {
        await service.setReminderTime('20:00');
        expect(service.reminderTime, equals('20:00'));

        await service.setReminderTime('07:30');
        expect(service.reminderTime, equals('07:30'));

        // Limpiar (pasar null)
        await service.setReminderTime(null);
        expect(service.reminderTime, isNull);
      });

      test('setLastAstralReadingDate y getter lastAstralReadingDate', () async {
        await service.setLastAstralReadingDate('2024-12-25');
        expect(service.lastAstralReadingDate, equals('2024-12-25'));

        await service.setLastAstralReadingDate('2025-01-01');
        expect(service.lastAstralReadingDate, equals('2025-01-01'));

        // Limpiar (pasar null)
        await service.setLastAstralReadingDate(null);
        expect(service.lastAstralReadingDate, isNull);
      });

      test('setTrustedContactName y getter trustedContactName', () async {
        await service.setTrustedContactName('María');
        expect(service.trustedContactName, equals('María'));

        await service.setTrustedContactName('Juan');
        expect(service.trustedContactName, equals('Juan'));

        // Limpiar (pasar null)
        await service.setTrustedContactName(null);
        expect(service.trustedContactName, isNull);
      });

      test('setTrustedContactPhone y getter trustedContactPhone', () async {
        await service.setTrustedContactPhone('5551234567');
        expect(service.trustedContactPhone, equals('5551234567'));

        await service.setTrustedContactPhone('5559876543');
        expect(service.trustedContactPhone, equals('5559876543'));

        // Limpiar (pasar null)
        await service.setTrustedContactPhone(null);
        expect(service.trustedContactPhone, isNull);
      });

      test('setAppLockEnabled y getter appLockEnabled', () async {
        await service.setAppLockEnabled(false);
        expect(service.appLockEnabled, isFalse);

        await service.setAppLockEnabled(true);
        expect(service.appLockEnabled, isTrue);
      });

      test('setPrivacyConsentAccepted y getter privacyConsentAccepted', () async {
        await service.setPrivacyConsentAccepted(true);
        expect(service.privacyConsentAccepted, isTrue);

        await service.setPrivacyConsentAccepted(false);
        expect(service.privacyConsentAccepted, isFalse);
      });
    });

    group('AppSettingsState copyWith', () {
      test('copyWith actualiza solo los campos proporcionados', () {
        const original = AppSettingsState(
          onboardingDone: true,
          adultConfirmed: true,
          audioEnabled: true,
          reduceMotion: true,
          reminderEnabled: true,
          appLockEnabled: true,
          privacyConsentAccepted: false,
          reminderTime: '20:00',
          lastAstralReadingDate: '2024-12-25',
          trustedContactName: 'Test',
          trustedContactPhone: '5551234567',
        );

        final updated = original.copyWith(audioEnabled: false, reminderTime: '08:00');

        expect(updated.onboardingDone, isTrue);
        expect(updated.adultConfirmed, isTrue);
        expect(updated.audioEnabled, isFalse);
        expect(updated.reduceMotion, isTrue);
        expect(updated.reminderEnabled, isTrue);
        expect(updated.reminderTime, equals('08:00'));
        expect(updated.lastAstralReadingDate, equals('2024-12-25'));
        expect(updated.trustedContactName, equals('Test'));
        expect(updated.trustedContactPhone, equals('5551234567'));
      });

      test('copyWith con clearReminderTime limpia el valor', () {
        const original = AppSettingsState(
          onboardingDone: false,
          adultConfirmed: false,
          audioEnabled: false,
          reduceMotion: false,
          reminderEnabled: false,
          appLockEnabled: true,
          privacyConsentAccepted: false,
          reminderTime: '20:00',
        );

        final updated = original.copyWith(clearReminderTime: true);

        expect(updated.reminderTime, isNull);
      });

      test('copyWith con clearLastAstralReadingDate limpia el valor', () {
        const original = AppSettingsState(
          onboardingDone: false,
          adultConfirmed: false,
          audioEnabled: false,
          reduceMotion: false,
          reminderEnabled: false,
          appLockEnabled: true,
          privacyConsentAccepted: false,
          lastAstralReadingDate: '2024-12-25',
        );

        final updated = original.copyWith(clearLastAstralReadingDate: true);

        expect(updated.lastAstralReadingDate, isNull);
      });

      test('copyWith con clearTrustedContactName limpia el valor', () {
        const original = AppSettingsState(
          onboardingDone: false,
          adultConfirmed: false,
          audioEnabled: false,
          reduceMotion: false,
          reminderEnabled: false,
          appLockEnabled: true,
          privacyConsentAccepted: false,
          trustedContactName: 'Test',
        );

        final updated = original.copyWith(clearTrustedContactName: true);

        expect(updated.trustedContactName, isNull);
      });

      test('copyWith con clearTrustedContactPhone limpia el valor', () {
        const original = AppSettingsState(
          onboardingDone: false,
          adultConfirmed: false,
          audioEnabled: false,
          reduceMotion: false,
          reminderEnabled: false,
          appLockEnabled: true,
          privacyConsentAccepted: false,
          trustedContactPhone: '5551234567',
        );

        final updated = original.copyWith(clearTrustedContactPhone: true);

        expect(updated.trustedContactPhone, isNull);
      });

      test('copyWith sin argumentos devuelve instancia igual', () {
        const original = AppSettingsState.defaults();
        final copied = original.copyWith();

        expect(copied, equals(original));
      });
    });

    group('saveState', () {
      test('saveState persiste todos los valores', () async {
        const state = AppSettingsState(
          onboardingDone: true,
          adultConfirmed: true,
          audioEnabled: true,
          reduceMotion: true,
          reminderEnabled: true,
          appLockEnabled: true,
          privacyConsentAccepted: false,
          reminderTime: '07:30',
          lastAstralReadingDate: '2024-06-15',
          trustedContactName: 'Ana',
          trustedContactPhone: '5551112222',
        );

        await service.saveState(state);

        // Verificar lectura directa de SharedPreferences
        expect(prefs.getBool(_SettingsKeys.onboardingDone), isTrue);
        expect(prefs.getBool(_SettingsKeys.adultConfirmed), isTrue);
        expect(prefs.getBool(_SettingsKeys.audioEnabled), isTrue);
        expect(prefs.getBool(_SettingsKeys.reduceMotion), isTrue);
        expect(prefs.getBool(_SettingsKeys.reminderEnabled), isTrue);
        expect(prefs.getString(_SettingsKeys.reminderTime), equals('07:30'));
        expect(prefs.getString(_SettingsKeys.lastAstralReadingDate), equals('2024-06-15'));
        expect(prefs.getString(_SettingsKeys.trustedContactName), equals('Ana'));
        expect(prefs.getString(_SettingsKeys.trustedContactPhone), equals('5551112222'));

        // Verificar a través del servicio
        expect(service.onboardingDone, isTrue);
        expect(service.adultConfirmed, isTrue);
        expect(service.audioEnabled, isTrue);
        expect(service.reduceMotion, isTrue);
        expect(service.reminderEnabled, isTrue);
        expect(service.reminderTime, equals('07:30'));
        expect(service.lastAstralReadingDate, equals('2024-06-15'));
        expect(service.trustedContactName, equals('Ana'));
        expect(service.trustedContactPhone, equals('5551112222'));
      });

      test('saveState con valores null los elimina de SharedPreferences', () async {
        // Primero guardar valores
        const stateWithValues = AppSettingsState(
          onboardingDone: false,
          adultConfirmed: false,
          audioEnabled: false,
          reduceMotion: false,
          reminderEnabled: false,
          appLockEnabled: true,
          privacyConsentAccepted: false,
          reminderTime: '20:00',
          lastAstralReadingDate: '2024-12-25',
          trustedContactName: 'Test',
          trustedContactPhone: '5551234567',
        );
        await service.saveState(stateWithValues);

        // Ahora guardar con nulls
        const stateWithNulls = AppSettingsState(
          onboardingDone: false,
          adultConfirmed: false,
          audioEnabled: false,
          reduceMotion: false,
          reminderEnabled: false,
          appLockEnabled: true,
          privacyConsentAccepted: false,
          reminderTime: null,
          lastAstralReadingDate: null,
          trustedContactName: null,
          trustedContactPhone: null,
        );
        await service.saveState(stateWithNulls);

        // Verificar que se eliminaron
        expect(prefs.getString(_SettingsKeys.reminderTime), isNull);
        expect(prefs.getString(_SettingsKeys.lastAstralReadingDate), isNull);
        expect(prefs.getString(_SettingsKeys.trustedContactName), isNull);
        expect(prefs.getString(_SettingsKeys.trustedContactPhone), isNull);
      });
    });

    group('Persistencia entre instancias', () {
      test('Los valores persisten al crear nueva instancia del servicio', () async {
        await service.setAudioEnabled(true);
        await service.setReduceMotion(true);
        await service.setReminderEnabled(true);
        await service.setReminderTime('08:00');
        await service.setLastAstralReadingDate('2024-01-01');
        await service.setTrustedContactName('Pedro');
        await service.setTrustedContactPhone('5553334444');

        // Crear nueva instancia con las mismas SharedPreferences
        final newService = AppSettingsService.createForTesting(prefs);

        expect(newService.audioEnabled, isTrue);
        expect(newService.reduceMotion, isTrue);
        expect(newService.reminderEnabled, isTrue);
        expect(newService.reminderTime, equals('08:00'));
        expect(newService.lastAstralReadingDate, equals('2024-01-01'));
        expect(newService.trustedContactName, equals('Pedro'));
        expect(newService.trustedContactPhone, equals('5553334444'));
      });
    });
  });
}

// Importar las keys privadas para las pruebas de persistencia directa
// (usamos la misma clase _SettingsKeys que en el service)
class _SettingsKeys {
  static const String onboardingDone = 'onboarding_done';
  static const String adultConfirmed = 'adult_confirmed';
  static const String audioEnabled = 'audio_enabled';
  static const String reduceMotion = 'reduce_motion';
  static const String reminderEnabled = 'reminder_enabled';
  static const String reminderTime = 'reminder_time';
  static const String lastAstralReadingDate = 'last_astral_reading_date';
  static const String trustedContactName = 'trusted_contact_name';
  static const String trustedContactPhone = 'trusted_contact_phone';
}