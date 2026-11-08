// This is a basic Flutter widget test.
//
// Tests for constants accessibility and correctness.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_calli/core/constants/app_colors.dart';
import 'package:mi_calli/core/constants/sos_texts.dart';
import 'package:mi_calli/core/constants/legal_texts.dart';

void main() {
  group('AppColors constants', () {
    test('have correct values', () {
      // Test all main colors
      expect(AppColors.jade, equals(const Color(0xFF2A9D8F)));
      expect(AppColors.turquesa, equals(const Color(0xFF48CAE4)));
      expect(AppColors.oro, equals(const Color(0xFFE9C46A)));
      expect(AppColors.obsidiana, equals(const Color(0xFF0F172A)));
      expect(AppColors.rojoGrana, equals(const Color(0xFFE76F51)));

      // Test semantic colors
      expect(AppColors.success, equals(AppColors.jade));
      expect(AppColors.warning, equals(AppColors.oro));
      expect(AppColors.error, equals(AppColors.rojoGrana));

      // Test Fuego Sagrado colors
      expect(AppColors.fuegoNaranja, equals(const Color(0xFFF77F00)));
      expect(AppColors.fuegoDorado, equals(const Color(0xFFE9C46A)));
      expect(AppColors.fuegoTurquesa, equals(const Color(0xFF48CAE4)));

      // Test onboarding colors
      expect(AppColors.pergaminoClaro, equals(const Color(0xFFFDFBF7)));
      expect(AppColors.rosaSuave, equals(const Color(0xFFF8C8DC)));
    });
  });

  group('SosTexts constants', () {
    test('have correct values', () {
      // mensajePersonaConfianza es ahora una función
      expect(SosTexts.mensajePersonaConfianza('María'),
          'Hola María, te escribo desde mi refugio porque en este momento '
          'no me siento muy bien emocionalmente y me ayudaría mucho platicar '
          'o sentir tu compañía. ¿Tienes un momento?');
      expect(SosTexts.mensajePersonaConfianza(null),
          'Hola, te escribo desde mi refugio porque en este momento '
          'no me siento muy bien emocionalmente y me ayudaría mucho platicar '
          'o sentir tu compañía. ¿Tienes un momento?');
      expect(SosTexts.lineaDeLaVida, '800 911 2000');
      expect(SosTexts.emergencias911, '911');
      expect(SosTexts.botonLineaDeLaVida, 'Llamar a Línea de la Vida (800 911 2000)');
      expect(SosTexts.botonEmergencias, 'Llamar al 911');
    });
  });

  group('LegalTexts constants - Parte A (A1-A12)', () {
    test('all Parte A constants are non-empty and correct', () {
      // A1 - Bienvenida
      expect(LegalTexts.welcomeTitle, equals('Bienvenido a tu refugio'));
      expect(LegalTexts.welcomeBody, isNotEmpty);

      // A2 - Mayoría de edad
      expect(LegalTexts.ageGateTitle, equals('Antes de entrar'));
      expect(LegalTexts.ageGateBody, isNotEmpty);
      expect(LegalTexts.ageGateConfirm, equals('Tengo 18 años o más'));
      expect(LegalTexts.ageGateDecline, equals('Soy menor de 18'));

      // A3 - Pantalla para menores
      expect(LegalTexts.underageTitle, equals('Gracias por decirnos'));
      expect(LegalTexts.underageBody, isNotEmpty);
      expect(LegalTexts.underageButtonLineaDeLaVida, equals('Llamar a la Línea de la Vida'));
      expect(LegalTexts.underageButtonEmergencias, equals('Llamar al 911'));

      // A4 - Aviso importante
      expect(LegalTexts.disclaimerTitle, equals('Un aviso importante'));
      expect(LegalTexts.disclaimerBody, isNotEmpty);
      expect(LegalTexts.disclaimerPrivacyLink, equals('Leer aviso de privacidad'));

      // A5 - Resumen de privacidad
      expect(LegalTexts.privacySummaryTitle, equals('Tu diario es solo tuyo'));
      expect(LegalTexts.privacySummaryBody, isNotEmpty);
      expect(LegalTexts.privacySummaryButton, equals('Ver aviso de privacidad completo'));

      // A6 - Respaldo en la nube
      expect(LegalTexts.cloudConsentTitle, equals('Respaldar mi progreso'));
      expect(LegalTexts.cloudConsentBody, isNotEmpty);
      expect(LegalTexts.cloudConsentContinue, equals('Continuar con Google'));
      expect(LegalTexts.cloudConsentLater, equals('Ahora no'));

      // A7 - Contacto de confianza
      expect(LegalTexts.contactExplain, isNotEmpty);

      // A8 - Exportar diario
      expect(LegalTexts.exportWarningTitle, equals('Exportar mi diario'));
      expect(LegalTexts.exportWarningBody, isNotEmpty);

      // A9 - Importar diario
      expect(LegalTexts.importConfirm, isNotEmpty);

      // A10 - Recordatorio
      expect(LegalTexts.reminderExplain, isNotEmpty);
      expect(LegalTexts.reminderNotificationText, isNotEmpty);

      // A11 - Eliminar mi respaldo
      expect(LegalTexts.deleteBackupTitle, equals('Eliminar mi respaldo'));
      expect(LegalTexts.deleteBackupBody, isNotEmpty);
      expect(LegalTexts.deleteBackupConfirm, equals('Eliminar respaldo'));
      expect(LegalTexts.deleteBackupCancel, equals('Cancelar'));

      // A12 - Consentimiento
      expect(LegalTexts.consentTitle, equals('Tu consentimiento'));
      expect(LegalTexts.consentBody, isNotEmpty);
      expect(LegalTexts.consentCheck, isNotEmpty);
      expect(LegalTexts.consentContinue, equals('Continuar'));
      expect(LegalTexts.consentDecline, equals('Ahora no'));
      expect(LegalTexts.consentDeclineBody, isNotEmpty);

      // URL política de privacidad (para Play Store)
      expect(LegalTexts.urlPoliticaPrivacidad, startsWith('https://'));
    });
  });
}