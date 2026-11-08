// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_calli/main.dart';
import 'package:mi_calli/core/constants/app_colors.dart';
import 'package:mi_calli/core/constants/sos_texts.dart';
import 'package:mi_calli/core/constants/legal_texts.dart';

void main() {
  testWidgets('App builds and shows constants demo screen',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MiCalliApp()));

    // Verify that the app title is shown.
    expect(find.text('Mi Calli - Prueba de Constantes'), findsOneWidget);

    // Verify color constant is accessible (Jade color used in app bar)
    expect(AppColors.jade, equals(const Color(0xFF2A9D8F)));

    // Verify SOS text constant is accessible
    expect(SosTexts.mensajePersonaConfianza,
        contains('Hola [Nombre], te escribo desde mi refugio'));
    expect(SosTexts.lineaDeLaVida, equals('800 911 2000'));
    expect(SosTexts.emergencias911, equals('911'));

    // Verify Legal text constants are accessible
    expect(LegalTexts.avisoPrincipal, contains('NO es un servicio médico'));
    expect(LegalTexts.confirmacionMayoriaEdad, contains('18 años'));
    expect(LegalTexts.confirmacionBorradoRespaldo, contains('Eliminar tu respaldo'));
    expect(LegalTexts.urlPoliticaPrivacidad, contains('https://'));
  });

  test('AppColors constants have correct values', () {
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
  });

  test('SosTexts constants have correct values', () {
    expect(SosTexts.mensajePersonaConfianza,
        'Hola [Nombre], te escribo desde mi refugio porque en este momento '
        'no me siento muy bien emocionalmente y me ayudaría mucho platicar '
        'o sentir tu compañía. ¿Tienes un momento?');
    expect(SosTexts.lineaDeLaVida, '800 911 2000');
    expect(SosTexts.emergencias911, '911');
    expect(SosTexts.botonLineaDeLaVida, 'Llamar a Línea de la Vida (800 911 2000)');
    expect(SosTexts.botonEmergencias, 'Llamar al 911');
  });

  test('LegalTexts constants are non-empty placeholders', () {
    // All legal texts should be non-empty and contain placeholder markers
    expect(LegalTexts.avisoPrincipal, isNotEmpty);
    expect(LegalTexts.avisoPrincipal, contains('PENDIENTE DE APROBACIÓN'));

    expect(LegalTexts.confirmacionMayoriaEdad, isNotEmpty);
    expect(LegalTexts.confirmacionMayoriaEdad, contains('PENDIENTE DE APROBACIÓN'));

    expect(LegalTexts.pantallaSoloAdultos, isNotEmpty);
    expect(LegalTexts.pantallaSoloAdultos, contains('PENDIENTE DE APROBACIÓN'));

    expect(LegalTexts.confirmacionBorradoRespaldo, isNotEmpty);
    expect(LegalTexts.confirmacionBorradoRespaldo, contains('PENDIENTE DE APROBACIÓN'));

    expect(LegalTexts.urlPoliticaPrivacidad, startsWith('https://'));

    expect(LegalTexts.datosRecolectados, isNotEmpty);
    expect(LegalTexts.datosRecolectados, contains('PENDIENTE DE APROBACIÓN'));

    expect(LegalTexts.avisoExportacion, isNotEmpty);
    expect(LegalTexts.avisoExportacion, contains('PENDIENTE DE APROBACIÓN'));

    expect(LegalTexts.avisoImportacion, isNotEmpty);
    expect(LegalTexts.avisoImportacion, contains('PENDIENTE DE APROBACIÓN'));
  });
}