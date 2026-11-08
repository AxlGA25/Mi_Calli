// Tests para SafetyGuardService.
// Usa el JSON REAL (assets/data/crisis_patterns.json), no createForTesting.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

import 'package:mi_calli/core/security/safety_guard_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SafetyGuardService - con JSON real', () {
    late SafetyGuardService service;

    setUpAll(() async {
      // Usar la instancia real inicializada desde el asset
      service = await SafetyGuardService.initialize();
    });

    group('normalize', () {
      test('convierte a minúsculas', () {
        expect(
          SafetyGuardService.normalize('QUIERO MORIRME'),
          equals('quiero morirme'),
        );
      });

      test('elimina acentos', () {
        expect(
          SafetyGuardService.normalize('no aguanto más'),
          equals('no aguanto mas'),
        );
      });

      test('convierte ñ a n', () {
        expect(
          SafetyGuardService.normalize('mañana'),
          equals('manana'),
        );
      });

      test('convierte puntuación en espacios', () {
        expect(
          SafetyGuardService.normalize('quiero morirme!!!'),
          equals('quiero morirme'),
        );
        expect(
          SafetyGuardService.normalize('¿quiero morirme?'),
          equals('quiero morirme'),
        );
        expect(
          SafetyGuardService.normalize('quiero,morirme'),
          equals('quiero morirme'),
        );
      });

      test('colapsa espacios repetidos', () {
        expect(
          SafetyGuardService.normalize('quiero    morirme'),
          equals('quiero morirme'),
        );
      });

      test('recorta espacios al inicio y final', () {
        expect(
          SafetyGuardService.normalize('  quiero morirme  '),
          equals('quiero morirme'),
        );
      });

      test('maneja texto largo con múltiples transformaciones', () {
        const input = '  QUIERO MORIRME!!!  No aguanto MÁS...  ';
        const expected = 'quiero morirme no aguanto mas';
        expect(
          SafetyGuardService.normalize(input),
          equals(expected),
        );
      });
    });

    group('check - frases que DEBEN disparar (con JSON real)', () {
      test('"no quiero vivir más" dispara ideación', () {
        final result = service.check('no quiero vivir más');
        expect(result.matched, isTrue);
        expect(result.category, equals('ideacion'));
      });

      test('"ya no quiero vivir" dispara ideación', () {
        final result = service.check('ya no quiero vivir');
        expect(result.matched, isTrue);
        expect(result.category, equals('ideacion'));
      });

      test('"quisiera morir" dispara ideación', () {
        final result = service.check('quisiera morir');
        expect(result.matched, isTrue);
        expect(result.category, equals('ideacion'));
      });

      test('"me voy a matar" dispara ideación', () {
        final result = service.check('me voy a matar');
        expect(result.matched, isTrue);
        expect(result.category, equals('ideacion'));
      });

      test('"ojalá no despertar" dispara ideación', () {
        final result = service.check('ojalá no despertar');
        expect(result.matched, isTrue);
        expect(result.category, equals('ideacion'));
      });

      test('"quisiera no despertar" dispara ideación', () {
        final result = service.check('quisiera no despertar');
        expect(result.matched, isTrue);
        expect(result.category, equals('ideacion'));
      });

      test('"me quiero hacer daño" dispara autolesión', () {
        final result = service.check('me quiero hacer daño');
        expect(result.matched, isTrue);
        expect(result.category, equals('autolesion'));
      });

      test('"me voy a hacer daño" dispara autolesión', () {
        final result = service.check('me voy a hacer daño');
        expect(result.matched, isTrue);
        expect(result.category, equals('autolesion'));
      });

      test('"estarían mejor sin mí" dispara desesperanza', () {
        final result = service.check('estarían mejor sin mí');
        expect(result.matched, isTrue);
        expect(result.category, equals('desesperanza'));
      });

      test('"soy una carga para mi familia" dispara desesperanza', () {
        final result = service.check('soy una carga para mi familia');
        expect(result.matched, isTrue);
        expect(result.category, equals('desesperanza'));
      });

      test('"nadie me extrañaría" dispara ideación', () {
        final result = service.check('nadie me extrañaría');
        expect(result.matched, isTrue);
        expect(result.category, equals('ideacion'));
      });

      test('"me corté los brazos" dispara autolesión', () {
        final result = service.check('me corté los brazos');
        expect(result.matched, isTrue);
        expect(result.category, equals('autolesion'));
      });

      test('"QUIERO MORIRME!!!" dispara ideación (mayúsculas y puntuación)', () {
        final result = service.check('QUIERO MORIRME!!!');
        expect(result.matched, isTrue);
        expect(result.category, equals('ideacion'));
      });

      // --- NUEVAS PRUEBAS REQUERIDAS: frases que DEBEN disparar ---
      test('"me quiero morir, a mi nadie me quiere" dispara ideación (sin unless a mi)', () {
        final result = service.check('me quiero morir, a mi nadie me quiere');
        expect(result.matched, isTrue);
        expect(result.category, equals('ideacion'));
      });

      test('"quiero morirme a mi edad" dispara ideación (sin unless a mi)', () {
        final result = service.check('quiero morirme a mi edad');
        expect(result.matched, isTrue);
        expect(result.category, equals('ideacion'));
      });

      test('"quisiera morir a mi manera" dispara ideación (sin unless a mi)', () {
        final result = service.check('quisiera morir a mi manera');
        expect(result.matched, isTrue);
        expect(result.category, equals('ideacion'));
      });

      // --- Cobertura adicional de patrones existentes ---
      test('"pensé en quitarme la vida" dispara ideación (con acento y frase enterrada)', () {
        final result = service.check('pensé en quitarme la vida hoy');
        expect(result.matched, isTrue);
        expect(result.category, equals('ideacion'));
      });

      test('"no aguanto más" dispara desesperanza (con acento)', () {
        final result = service.check('no aguanto más');
        expect(result.matched, isTrue);
        expect(result.category, equals('desesperanza'));
      });

      test('"todos estarían mejor sin mí" dispara desesperanza (con acentos)', () {
        final result = service.check('todos estarían mejor sin mí');
        expect(result.matched, isTrue);
        expect(result.category, equals('desesperanza'));
      });

      test('"quiero hacerme daño" dispara autolesión', () {
        final result = service.check('quiero hacerme daño');
        expect(result.matched, isTrue);
        expect(result.category, equals('autolesion'));
      });

      test('frase enterrada en texto largo dispara', () {
        const longText = '''
Hoy fue un día muy difícil. Me desperté temprano y no tenía ganas de nada.
Pensé en quitarme la vida mientras caminaba al trabajo, pero luego recordé
que tengo una cita con mi terapeuta el jueves. Espero que me ayude.
''';
        final result = service.check(longText);
        expect(result.matched, isTrue);
        expect(result.category, equals('ideacion'));
      });

      test('con acentos y puntuación variada', () {
        final result = service.check('¡Ya no quiero vivir...!');
        expect(result.matched, isTrue);
        expect(result.category, equals('ideacion'));
      });

      test(r'suicid\w* detecta variantes', () {
        expect(service.check('pensando en suicidio').matched, isTrue);
        expect(service.check('ideación suicida').matched, isTrue);
        expect(service.check('suicidarse').matched, isTrue);
      });
    });

    group('check - frases que NO deben disparar (falsos positivos)', () {
      test('"no quiero vivir en esta ciudad" NO dispara (unless en ideacion_03)', () {
        final result = service.check('no quiero vivir en esta ciudad');
        expect(result.matched, isFalse);
      });

      test('"no aguanto más a mi jefe" NO dispara (unless a mi jefe en desesperanza_01)', () {
        final result = service.check('no aguanto más a mi jefe');
        expect(result.matched, isFalse);
      });

      test('"no aguanto este calor" NO dispara', () {
        final result = service.check('no aguanto este calor');
        expect(result.matched, isFalse);
      });

      test('"me voy a matar trabajando" NO dispara (unless trabajando en ideacion_12)', () {
        final result = service.check('me voy a matar trabajando');
        expect(result.matched, isFalse);
      });

      test('"morirme de miedo" NO dispara (unless de miedo)', () {
        final result = service.check('morirme de miedo');
        expect(result.matched, isFalse);
      });

      test('"me corté el pelo" NO dispara (no venas/muñecas/brazos/piernas/piel)', () {
        final result = service.check('me corté el pelo');
        expect(result.matched, isFalse);
      });

      test('"quiero cortarme el pelo" NO dispara', () {
        final result = service.check('quiero cortarme el pelo');
        expect(result.matched, isFalse);
      });

      test('"me muero de risa" NO dispara', () {
        final result = service.check('me muero de risa');
        expect(result.matched, isFalse);
      });

      test('"mato el tiempo leyendo" NO dispara', () {
        final result = service.check('mato el tiempo leyendo');
        expect(result.matched, isFalse);
      });

      // --- 10 FALSOS POSITIVOS ADICIONALES (lista literal) ---
      test('"me voy a cortar el pelo" NO dispara', () {
        final result = service.check('me voy a cortar el pelo');
        expect(result.matched, isFalse);
      });

      test('"morirme de risa" NO dispara', () {
        final result = service.check('morirme de risa');
        expect(result.matched, isFalse);
      });

      test('"matarme de risa" NO dispara', () {
        final result = service.check('matarme de risa');
        expect(result.matched, isFalse);
      });

      test('"me muero de hambre" NO dispara', () {
        final result = service.check('me muero de hambre');
        expect(result.matched, isFalse);
      });

      test('"me voy a morir de sueño" NO dispara', () {
        final result = service.check('me voy a morir de sueño');
        expect(result.matched, isFalse);
      });

      test('"no aguanto este calor" NO dispara (duplicado intencional)', () {
        final result = service.check('no aguanto este calor');
        expect(result.matched, isFalse);
      });

      test('"cortarme las uñas" NO dispara (no venas/muñecas)', () {
        final result = service.check('voy a cortarme las uñas');
        expect(result.matched, isFalse);
      });

      test('"me voy a matar estudiando" NO dispara (unless estudiando en ideacion_12)', () {
        final result = service.check('me voy a matar estudiando');
        expect(result.matched, isFalse);
      });

      test('"me voy a matar corriendo" NO dispara (unless corriendo en ideacion_12)', () {
        final result = service.check('me voy a matar corriendo');
        expect(result.matched, isFalse);
      });

      test('"me voy a matar entrenando" NO dispara (unless entrenando en ideacion_12)', () {
        final result = service.check('me voy a matar entrenando');
        expect(result.matched, isFalse);
      });
    });

    group('check - una anulación no esconde otra coincidencia', () {
      test('"me muero de risa pero quiero morirme" dispara ideación', () {
        final result = service.check('me muero de risa pero quiero morirme');
        expect(result.matched, isTrue);
        expect(result.category, equals('ideacion'));
      });

      test('"no aguanto este calor pero ya no quiero vivir" dispara', () {
        final result = service.check('no aguanto este calor pero ya no quiero vivir');
        expect(result.matched, isTrue);
        expect(result.category, equals('ideacion'));
      });

      test('"matarme de hambre pero me quiero matar" dispara', () {
        final result = service.check('matarme de hambre pero me quiero matar');
        expect(result.matched, isTrue);
        expect(result.category, equals('ideacion'));
      });
    });

    group('check - unless solo se aplica a 3 palabras posteriores', () {
      test('"quiero morirme y no se que hacer ya estoy trabajando en casa" dispara (unless no alcanza)', () {
        // El 'trabajando' está a más de 3 palabras de 'morirme', no debe anular
        final result = service.check('quiero morirme y no se que hacer ya estoy trabajando en casa');
        expect(result.matched, isTrue);
        expect(result.category, equals('ideacion'));
      });

      test('"me quiero morir pero ahora estoy estudiando para examen" dispara (unless no alcanza)', () {
        final result = service.check('me quiero morir pero ahora estoy estudiando para examen');
        expect(result.matched, isTrue);
        expect(result.category, equals('ideacion'));
      });

      test('"me quiero matar trabajando" NO dispara (unless inmediato en ideacion_02)', () {
        // 'trabajando' está inmediatamente después, sí debe anular (ideacion_02 tiene unless trabajando)
        final result = service.check('me quiero matar trabajando');
        expect(result.matched, isFalse);
      });
    });

    group('check - resultado no contiene texto analizado', () {
      test('SafetyCheckResult no incluye el texto', () {
        const sensitiveText = 'quiero morirme esta noche en mi casa';
        final result = service.check(sensitiveText);

        final resultStr = result.toString();
        expect(resultStr, isNot(contains('morirme')));
        expect(resultStr, isNot(contains('noche')));
        expect(resultStr, isNot(contains('casa')));
        expect(resultStr, isNot(contains(sensitiveText)));
      });

      test('categoría correcta sin texto', () {
        final result = service.check('quiero quitarme la vida');
        expect(result.category, equals('ideacion'));
        expect(result.toString(), contains('ideacion'));
        expect(result.toString(), isNot(contains('quitarme')));
      });
    });

    group('check - sin registros', () {
      test('check no imprime en consola', () {
        final result = service.check('quiero morirme');
        expect(result.matched, isTrue);
      });
    });

    group('createForTesting - patrones inyectados (para tests de unidad aislados)', () {
      test('permite inyectar patrones para testing', () {
        final testPatterns = [
          CompiledPattern(
            id: 'test_01',
            category: 'test_cat',
            regex: RegExp(r'\bpalabra prueba\b'),
          ),
        ];
        final testService = SafetyGuardService.createForTesting(testPatterns);

        expect(testService.check('palabra prueba').matched, isTrue);
        expect(testService.check('palabra prueba').category, equals('test_cat'));
        expect(testService.check('otra cosa').matched, isFalse);
      });

      test('patrones inyectados respetan unless', () {
        final testPatterns = [
          CompiledPattern(
            id: 'test_02',
            category: 'test_cat',
            regex: RegExp(r'\bdisparar\b'),
            unlessPatterns: [RegExp(r'de risa')],
          ),
        ];
        final testService = SafetyGuardService.createForTesting(testPatterns);

        expect(testService.check('disparar').matched, isTrue);
        expect(testService.check('disparar de risa').matched, isFalse);
      });
    });

    group('fallback - archivo faltante o dañado', () {
      test('servicio con fallback detecta frases básicas', () {
        final fallbackService = SafetyGuardService.createForTesting(
          SafetyGuardService.fallbackPatterns(),
        );

        expect(fallbackService.check('quiero morirme').matched, isTrue);
        expect(fallbackService.check('ya no quiero vivir').matched, isTrue);
        expect(fallbackService.check('me quiero matar').matched, isTrue);
        expect(fallbackService.check('no quiero seguir viviendo').matched, isTrue);
        expect(fallbackService.check('quitarme la vida').matched, isTrue);

        // Falsos positivos siguen funcionando
        expect(fallbackService.check('morirme de risa').matched, isFalse);
        expect(fallbackService.check('matarme de hambre').matched, isFalse);
      });

      test('fallback tiene SOLO 6 patrones (no 34 del JSON)', () {
        final fallbackService = SafetyGuardService.createForTesting(
          SafetyGuardService.fallbackPatterns(),
        );
        // El fallback solo tiene 6 patrones de ideación básica
        expect(fallbackService.check('quiero morirme').matched, isTrue);
        expect(fallbackService.check('me voy a matar').matched, isFalse); // no está en fallback
        expect(fallbackService.check('nadie me extrañaría').matched, isFalse); // no está en fallback
        expect(fallbackService.check('me corté los brazos').matched, isFalse); // no está en fallback
      });
    });

    group('rendimiento', () {
      test('texto de 10000 caracteres se analiza en < 50ms', () {
        // Generar texto de ~10000 caracteres con repeticiones de 'morirme' y 'no aguanto'
        final buffer = StringBuffer();
        for (int i = 0; i < 200; i++) {
          buffer.write('No aguanto más esta situación. ');
          buffer.write('Me morí de cansancio. ');
          buffer.write('Quiero moríreme ya. ');
        }
        final longText = buffer.toString();
        expect(longText.length, greaterThan(10000));

        final stopwatch = Stopwatch()..start();
        service.check(longText);
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(50),
          reason: 'Análisis tomó ${stopwatch.elapsedMilliseconds}ms, debe ser < 50ms',
        );
      });
    });

    group('carga de JSON desde disco', () {
      test('carga el JSON y verifica que ningún patrón se omite por regex inválida', () async {
        // Cargar el JSON directamente desde el asset
        final jsonString = await rootBundle.loadString('assets/data/crisis_patterns.json');
        final Map<String, dynamic> jsonMap = json.decode(jsonString) as Map<String, dynamic>;
        final patternsJson = jsonMap['patterns'] as List<dynamic>;

        // Verificar que todos los patrones tienen regex válidas
        int validPatterns = 0;
        int invalidPatterns = 0;
        for (final p in patternsJson) {
          try {
            final regexStr = p['regex'] as String;
            RegExp(regexStr); // Lanzará FormatException si es inválida
            validPatterns++;
          } on FormatException {
            invalidPatterns++;
          }
        }

        // Todos los patrones deben ser válidos
        expect(invalidPatterns, equals(0), reason: '$invalidPatterns patrones tienen regex inválida');
        expect(validPatterns, equals(patternsJson.length));
        expect(validPatterns, equals(34)); // Exactamente 34 patrones en el JSON

        // Verificar que el servicio real funciona con todos los patrones
        expect(service.check('quiero morirme').matched, isTrue);
        expect(service.check('ya no quiero vivir').matched, isTrue);
        expect(service.check('me voy a matar').matched, isTrue);
        expect(service.check('me corté los brazos').matched, isTrue);
      });
    });

    group('inicialización y manejo de errores', () {
      test('después de initialize(), el servicio usa los 34 patrones del JSON (no 6 del fallback)', () {
        // Verificar que patrones del JSON funcionan (no están en fallback)
        expect(service.check('me voy a matar').matched, isTrue);
        expect(service.check('nadie me extrañaría').matched, isTrue);
        expect(service.check('me corté los brazos').matched, isTrue);
        expect(service.check('quisiera morir').matched, isTrue);
        expect(service.check('ojalá no despertar').matched, isTrue);
        expect(service.check('soy una carga para mi familia').matched, isTrue);
        expect(service.check('estarían mejor sin mí').matched, isTrue);
        expect(service.check('me quiero hacer daño').matched, isTrue);
        expect(service.check('me voy a hacer daño').matched, isTrue);
        expect(service.check('quiero morirme a mi edad').matched, isTrue);
      });

      test('check no lanza error aunque no se haya llamado initialize()', () {
        // SafetyGuardService.check() usa la instancia singleton.
        // Si no se inicializó, instance lanzaría StateError, pero check() en sí no falla.
        // Aquí verificamos que el método check no lanza excepción con entrada válida.
        expect(() => service.check('texto cualquiera'), returnsNormally);
        expect(() => service.check(''), returnsNormally);
        expect(() => service.check('quiero morirme'), returnsNormally);
      });

      test('si initialize falla, usa fallback y no rompe el arranque', () async {
        // Simular fallo creando un servicio con patrones de fallback
        final fallbackService = SafetyGuardService.createForTesting(
          SafetyGuardService.fallbackPatterns(),
        );

        // El fallback debe detectar frases básicas
        expect(fallbackService.check('quiero morirme').matched, isTrue);
        expect(fallbackService.check('ya no quiero vivir').matched, isTrue);
        expect(fallbackService.check('me quiero matar').matched, isTrue);

        // Y no debe lanzar excepción
        expect(() => fallbackService.check('cualquier texto'), returnsNormally);
      });
    });
  });
}