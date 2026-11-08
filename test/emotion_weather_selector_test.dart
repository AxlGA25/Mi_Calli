// Tests de widget para EmotionWeatherSelector.
//
// Verifica:
// - Cada clima muestra su texto correcto (deidad + etiqueta emocional).
// - Al tocar uno se llama onChanged con la emoción correcta.
// - El gradiente cambia con la selección.
// - Con reducir movimiento la duración es cero.
// - El widget no se desborda con texto al 200 %.
// - Cada opción tiene su etiqueta de accesibilidad (Semantics).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_calli/core/constants/app_colors.dart';
import 'package:mi_calli/core/settings/app_settings_provider.dart';
import 'package:mi_calli/core/settings/app_settings_service.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/prehispanic_emotion.dart';
import 'package:mi_calli/features/1_sanctuary_journal/presentation/emotion_weather_selector.dart';

// Helper para crear AppSettingsService con reduceMotion configurado
Future<AppSettingsService> createSettingsServiceWithReduceMotion(bool reduceMotion) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final service = AppSettingsService.createForTesting(prefs);
  if (reduceMotion) {
    await service.setReduceMotion(true);
  }
  return service;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Helper para crear el widget de prueba con provider override
  Future<Widget> createTestWidget({
    required PrehispanicEmotion initialEmotion,
    required ValueChanged<PrehispanicEmotion> onChanged,
    bool reduceMotion = false,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settingsService = AppSettingsService.createForTesting(prefs);
    if (reduceMotion) {
      await settingsService.setReduceMotion(true);
    }

    return ProviderScope(
      overrides: [
        appSettingsServiceProvider.overrideWithValue(settingsService),
      ],
      child: MaterialApp(
        theme: ThemeData(
          textTheme: const TextTheme(
            titleMedium: TextStyle(fontSize: 16),
            labelLarge: TextStyle(fontSize: 14),
            bodySmall: TextStyle(fontSize: 12),
          ),
        ),
        home: Scaffold(
          body: EmotionWeatherSelector(
            selectedEmotion: initialEmotion,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  group('EmotionWeatherSelector', () {
    testWidgets('cada clima muestra su deidad y etiqueta emocional correcta', (tester) async {
      await tester.pumpWidget(
        await createTestWidget(
          initialEmotion: PrehispanicEmotion.tlalocLluvia,
          onChanged: (_) {},
        ),
      );

      // Verificar que se muestran los 5 climas con sus textos correctos
      expect(find.text('Lluvia de Tláloc'), findsOneWidget);
      expect(find.text('Tristeza, melancolía'), findsOneWidget);
      expect(find.text('Sol de Tonatiuh'), findsOneWidget);
      expect(find.text('Alegría, calma, gratitud'), findsOneWidget);
      expect(find.text('Viento de Ehécatl'), findsOneWidget);
      expect(find.text('Ansiedad, estrés, abrumo'), findsOneWidget);
      expect(find.text('Tormenta de Mixcóatl'), findsOneWidget);
      expect(find.text('Enojo, frustración'), findsOneWidget);
      expect(find.text('Noche de Metztli'), findsOneWidget);
      expect(find.text('Cansancio, agotamiento'), findsOneWidget);
    });

    testWidgets('al tocar una opción se llama onChanged con la emoción correcta', (tester) async {
      PrehispanicEmotion? capturedEmotion;
      await tester.pumpWidget(
        await createTestWidget(
          initialEmotion: PrehispanicEmotion.tlalocLluvia,
          onChanged: (e) => capturedEmotion = e,
        ),
      );

      // Tocar "Sol de Tonatiuh"
      await tester.tap(find.text('Sol de Tonatiuh').first);
      await tester.pump();

      expect(capturedEmotion, equals(PrehispanicEmotion.tonatiuhSol));

      // Tocar "Viento de Ehécatl"
      await tester.tap(find.text('Viento de Ehécatl').first);
      await tester.pump();

      expect(capturedEmotion, equals(PrehispanicEmotion.ehecatlViento));

      // Tocar "Tormenta de Mixcóatl"
      await tester.tap(find.text('Tormenta de Mixcóatl').first);
      await tester.pump();

      expect(capturedEmotion, equals(PrehispanicEmotion.mixcoatlTormenta));

      // Tocar "Noche de Metztli"
      await tester.tap(find.text('Noche de Metztli').first);
      await tester.pump();

      expect(capturedEmotion, equals(PrehispanicEmotion.metztliNoche));
    });

    testWidgets('el gradiente de fondo cambia al seleccionar otra emoción', (tester) async {
      // Usar un widget stateful que actualice la emoción seleccionada
      PrehispanicEmotion currentEmotion = PrehispanicEmotion.tlalocLluvia;

      // Crear settings service con mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settingsService = AppSettingsService.createForTesting(prefs);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSettingsServiceProvider.overrideWithValue(settingsService),
          ],
          child: MaterialApp(
            theme: ThemeData(
              textTheme: const TextTheme(
                titleMedium: TextStyle(fontSize: 16),
                labelLarge: TextStyle(fontSize: 14),
                bodySmall: TextStyle(fontSize: 12),
              ),
            ),
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return EmotionWeatherSelector(
                    selectedEmotion: currentEmotion,
                    onChanged: (emotion) {
                      setState(() {
                        currentEmotion = emotion;
                      });
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Obtener el AnimatedContainer y verificar su gradiente inicial
      final animatedContainer = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      expect(animatedContainer.decoration, isA<BoxDecoration>());
      final initialDecoration = animatedContainer.decoration as BoxDecoration;
      expect(initialDecoration.gradient, equals(AppColors.gradientTlalocLluvia));

      // Cambiar selección a Sol de Tonatiuh
      await tester.tap(find.text('Sol de Tonatiuh').first);
      await tester.pumpAndSettle(); // Esperar la animación

      final updatedContainer = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      final updatedDecoration = updatedContainer.decoration as BoxDecoration;
      expect(updatedDecoration.gradient, equals(AppColors.gradientTonatiuhSol));
    });

    testWidgets('con reducir movimiento la duración de la animación es cero', (tester) async {
      // Crear widget con reduceMotion = true
      await tester.pumpWidget(
        await createTestWidget(
          initialEmotion: PrehispanicEmotion.tlalocLluvia,
          onChanged: (_) {},
          reduceMotion: true,
        ),
      );

      // El AnimatedContainer debe tener duration = Duration.zero
      final animatedContainer = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      expect(animatedContainer.duration, equals(Duration.zero));
    });

    testWidgets('el widget no se desborda con texto escalado al 200 %', (tester) async {
      // Crear settings service con mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settingsService = AppSettingsService.createForTesting(prefs);

      // Crear widget con texto al 200% desde el inicio
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSettingsServiceProvider.overrideWithValue(settingsService),
          ],
          child: MaterialApp(
            theme: ThemeData(
              textTheme: const TextTheme(
                titleMedium: TextStyle(fontSize: 16),
                labelLarge: TextStyle(fontSize: 14),
                bodySmall: TextStyle(fontSize: 12),
              ),
            ),
            home: MediaQuery(
              data: MediaQueryData(textScaler: const TextScaler.linear(2.0)),
              child: Scaffold(
                body: EmotionWeatherSelector(
                  selectedEmotion: PrehispanicEmotion.tlalocLluvia,
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      // Verificar que no hay overflow - el widget debe renderizarse sin errores
      expect(find.byType(EmotionWeatherSelector), findsOneWidget);
      expect(find.text('Lluvia de Tláloc'), findsOneWidget);
      expect(find.text('Tristeza, melancolía'), findsOneWidget);
    });

    testWidgets('cada opción tiene etiqueta de accesibilidad (Semantics)', (tester) async {
      await tester.pumpWidget(
        await createTestWidget(
          initialEmotion: PrehispanicEmotion.tlalocLluvia,
          onChanged: (_) {},
        ),
      );

      // Obtener el árbol de semántica
      final semantics = tester.getSemantics(find.byType(EmotionWeatherSelector));

      // Verificar que cada opción tiene su etiqueta con la deidad
      expect(semantics.toStringDeep(), contains('Lluvia de Tláloc'));
      expect(semantics.toStringDeep(), contains('Sol de Tonatiuh'));
      expect(semantics.toStringDeep(), contains('Viento de Ehécatl'));
      expect(semantics.toStringDeep(), contains('Tormenta de Mixcóatl'));
      expect(semantics.toStringDeep(), contains('Noche de Metztli'));

      // La opción seleccionada debe tener selected=true
      // Buscar el nodo que tenga 'seleccionado' en su label
      expect(semantics.toStringDeep(), contains('seleccionado'));
    });

    testWidgets('área táctil mínima de 48x48 en cada opción', (tester) async {
      await tester.pumpWidget(
        await createTestWidget(
          initialEmotion: PrehispanicEmotion.tlalocLluvia,
          onChanged: (_) {},
        ),
      );

      // Encontrar los InkWell y verificar sus constraints
      final inkWells = tester.widgetList<InkWell>(find.byType(InkWell));
      expect(inkWells.length, equals(5)); // 5 opciones

      for (final inkWell in inkWells) {
        final child = inkWell.child;
        expect(child, isA<Container>());

        final container = child as Container;
        expect(container.constraints?.minWidth, greaterThanOrEqualTo(48.0));
        expect(container.constraints?.minHeight, greaterThanOrEqualTo(48.0));
      }
    });

    testWidgets('texto visible con nombre de emoción (no solo color ni icono)', (tester) async {
      await tester.pumpWidget(
        await createTestWidget(
          initialEmotion: PrehispanicEmotion.tlalocLluvia,
          onChanged: (_) {},
        ),
      );

      // Cada opción debe tener DOS textos visibles: deidad y etiqueta emocional
      // No solo colores ni iconos
      final textWidgets = tester.widgetList<Text>(find.byType(Text));

      // Debe haber al menos 11 textos: 1 título + 5×2 (deidad + etiqueta)
      expect(textWidgets.length, greaterThanOrEqualTo(11));

      // Verificar que no hay imágenes/iconos como único contenido
      final icons = find.byType(Icon);
      expect(icons, findsNothing);
    });

    testWidgets('no usa palabras clínicas ni de diagnóstico', (tester) async {
      await tester.pumpWidget(
        await createTestWidget(
          initialEmotion: PrehispanicEmotion.tlalocLluvia,
          onChanged: (_) {},
        ),
      );

      // Buscar textos que serían clínicos (no deben aparecer)
      final clinicalTerms = [
        'depresión',
        'ansiedad',
        'trastorno',
        'diagnóstico',
        'síntoma',
        'patología',
        'enfermedad',
        'clínico',
        'médico',
        'psiquiátrico',
      ];

      for (final term in clinicalTerms) {
        expect(find.textContaining(term), findsNothing,
            reason: 'No debe aparecer término clínico: $term');
      }
    });

    testWidgets('animación de escala al seleccionar (sin reduceMotion)', (tester) async {
      await tester.pumpWidget(
        await createTestWidget(
          initialEmotion: PrehispanicEmotion.tlalocLluvia,
          onChanged: (_) {},
        ),
      );

      final animatedScale = tester.widget<AnimatedScale>(find.byType(AnimatedScale).first);
      expect(animatedScale.duration, equals(const Duration(milliseconds: 150)));
    });

    testWidgets('animación de escala al seleccionar (con reduceMotion)', (tester) async {
      // Usar createTestWidget con reduceMotion=true (mismo patrón que test 4)
      await tester.pumpWidget(
        await createTestWidget(
          initialEmotion: PrehispanicEmotion.tlalocLluvia,
          onChanged: (_) {},
          reduceMotion: true,
        ),
      );

      final animatedScale = tester.widget<AnimatedScale>(find.byType(AnimatedScale).first);
      expect(animatedScale.duration, equals(Duration.zero));
    });
  });
}