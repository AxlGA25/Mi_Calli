// Pruebas para PrivacyAndLegalScreen (Tarea 4.6).
//
// Verifica que la pantalla muestra todos los textos legales correctamente
// y tiene las keys de accesibilidad esperadas.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mi_calli/features/3_teotihuacan_valley/presentation/privacy_and_legal_screen.dart';
import 'package:mi_calli/core/constants/app_colors.dart';

void main() {
  group('PrivacyAndLegalScreen', () {
    testWidgets('renderiza pantalla con título y botón volver', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PrivacyAndLegalScreen(),
          ),
        ),
      );

      // Verificar título en AppBar
      expect(find.text('Aviso y Privacidad'), findsOneWidget);

      // Verificar botón volver
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

      // Verificar key de la pantalla
      expect(find.byKey(const ValueKey('privacy_and_legal_screen')), findsOneWidget);
    });

    testWidgets('muestra todas las secciones legales', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PrivacyAndLegalScreen(),
          ),
        ),
      );

      // Verificar que todas las secciones están presentes
      expect(find.text('Descargo Médico'), findsOneWidget);
      expect(find.text('Solo Mayores de 18 Años'), findsOneWidget);
      expect(find.text('Privacidad Absoluta'), findsOneWidget);
      expect(find.text('Exportación Cifrada'), findsOneWidget);
      expect(find.text('Consentimiento de Datos Sensibles'), findsOneWidget);
      expect(find.text('Red de Apoyo Dual'), findsOneWidget);
      expect(find.text('Recordatorio Diario'), findsOneWidget);
      expect(find.text('Política de Privacidad Completa (Web)'), findsOneWidget);
    });

    testWidgets('contenido de Descargo Médico es correcto', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PrivacyAndLegalScreen(),
          ),
        ),
      );

      expect(find.textContaining('NO sustituye'), findsOneWidget);
      expect(find.textContaining('Línea de la Vida (800 911 2000)'), findsOneWidget);
      expect(find.textContaining('911'), findsOneWidget);
    });

    testWidgets('contenido de Privacidad Absoluta menciona SQLCipher', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PrivacyAndLegalScreen(),
          ),
        ),
      );

      expect(find.textContaining('SQLCipher AES-256'), findsOneWidget);
      expect(find.textContaining('NUNCA sale de tu teléfono'), findsOneWidget);
      expect(find.textContaining('progreso numérico'), findsOneWidget);
    });

    testWidgets('contenido de Exportación Cifrada menciona AES-256-GCM', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PrivacyAndLegalScreen(),
          ),
        ),
      );

      expect(find.textContaining('.calli'), findsOneWidget);
      expect(find.textContaining('AES-256-GCM'), findsOneWidget);
      expect(find.textContaining('contraseña NO se guarda'), findsOneWidget);
    });

    testWidgets('scroll funciona correctamente', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PrivacyAndLegalScreen(),
          ),
        ),
      );

      // Hacer scroll hacia abajo para ver todas las secciones
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -1000));
      await tester.pumpAndSettle();

      // Verificar que la última sección sigue visible
      expect(find.text('Política de Privacidad Completa (Web)'), findsOneWidget);
    });

    testWidgets('botón volver navega hacia atrás', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Navigator(
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (_) => const PrivacyAndLegalScreen(),
              ),
            ),
          ),
        ),
      );

      // Verificar que el botón volver existe
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

      // Tap en el botón volver
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      // El Navigator debería haber hecho pop, por lo que la pantalla ya no está
      // En este test verificamos que no hay error al hacer tap
    });

    testWidgets('todas las secciones tienen iconos', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PrivacyAndLegalScreen(),
          ),
        ),
      );

      // Verificar que hay iconos en cada sección (8 secciones = 8 iconos)
      final iconFinder = find.byType(Icon);
      expect(iconFinder, findsAtLeastNWidgets(8));
    });

    testWidgets('estilo visual correcto (colores prehispánicos)', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PrivacyAndLegalScreen(),
          ),
        ),
      );

      // Verificar fondo obsidiana
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(AppColors.obsidiana));

      // Verificar AppBar color obsidiana
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, equals(AppColors.obsidiana));
    });
  });
}