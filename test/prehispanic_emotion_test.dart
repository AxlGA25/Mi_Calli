// Tests para PrehispanicEmotion enum.
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_calli/features/1_sanctuary_journal/models/prehispanic_emotion.dart';

void main() {
  group('PrehispanicEmotion', () {
    test('tiene exactamente 5 valores', () {
      expect(PrehispanicEmotion.values.length, equals(5));
    });

    test('valores coinciden con CONTEXT.md sección 5D', () {
      final ids = PrehispanicEmotion.values.map((e) => e.id).toList();
      expect(ids, containsAllInOrder([
        'tlaloc_lluvia',
        'tonatiuh_sol',
        'ehecatl_viento',
        'mixcoatl_tormenta',
        'metztli_noche',
      ]));
    });

    group('fromId', () {
      test('convierte todos los IDs válidos correctamente', () {
        expect(PrehispanicEmotion.fromId('tlaloc_lluvia'), equals(PrehispanicEmotion.tlalocLluvia));
        expect(PrehispanicEmotion.fromId('tonatiuh_sol'), equals(PrehispanicEmotion.tonatiuhSol));
        expect(PrehispanicEmotion.fromId('ehecatl_viento'), equals(PrehispanicEmotion.ehecatlViento));
        expect(PrehispanicEmotion.fromId('mixcoatl_tormenta'), equals(PrehispanicEmotion.mixcoatlTormenta));
        expect(PrehispanicEmotion.fromId('metztli_noche'), equals(PrehispanicEmotion.metztliNoche));
      });

      test('lanza ArgumentError para ID inválido', () {
        expect(() => PrehispanicEmotion.fromId('invalido'), throwsArgumentError);
        expect(() => PrehispanicEmotion.fromId(''), throwsArgumentError);
        expect(() => PrehispanicEmotion.fromId('Tlaloc_Lluvia'), throwsArgumentError); // case sensitive
      });
    });

    group('id', () {
      test('devuelve el ID de base de datos (con underscore)', () {
        expect(PrehispanicEmotion.tlalocLluvia.id, equals('tlaloc_lluvia'));
        expect(PrehispanicEmotion.tonatiuhSol.id, equals('tonatiuh_sol'));
        expect(PrehispanicEmotion.ehecatlViento.id, equals('ehecatl_viento'));
        expect(PrehispanicEmotion.mixcoatlTormenta.id, equals('mixcoatl_tormenta'));
        expect(PrehispanicEmotion.metztliNoche.id, equals('metztli_noche'));
      });
    });

    group('label', () {
      test('devuelve etiqueta legible en español de México', () {
        expect(PrehispanicEmotion.tlalocLluvia.label, equals('Tristeza, melancolía'));
        expect(PrehispanicEmotion.tonatiuhSol.label, equals('Alegría, calma, gratitud'));
        expect(PrehispanicEmotion.ehecatlViento.label, equals('Ansiedad, estrés, abrumo'));
        expect(PrehispanicEmotion.mixcoatlTormenta.label, equals('Enojo, frustración'));
        expect(PrehispanicEmotion.metztliNoche.label, equals('Cansancio, agotamiento'));
      });
    });

    group('deity', () {
      test('devuelve la deidad/clima asociado', () {
        expect(PrehispanicEmotion.tlalocLluvia.deity, equals('Lluvia de Tláloc'));
        expect(PrehispanicEmotion.tonatiuhSol.deity, equals('Sol de Tonatiuh'));
        expect(PrehispanicEmotion.ehecatlViento.deity, equals('Viento de Ehécatl'));
        expect(PrehispanicEmotion.mixcoatlTormenta.deity, equals('Tormenta de Mixcóatl'));
        expect(PrehispanicEmotion.metztliNoche.deity, equals('Noche de Metztli'));
      });
    });

    group('description', () {
      test('combina deidad y label', () {
        expect(
          PrehispanicEmotion.tlalocLluvia.description,
          equals('Clima emocional: Lluvia de Tláloc — Tristeza, melancolía'),
        );
      });
    });

    group('colorHex', () {
      test('devuelve colores de la paleta prehispánica', () {
        expect(PrehispanicEmotion.tlalocLluvia.colorHex, equals('#2A9D8F')); // Jade
        expect(PrehispanicEmotion.tonatiuhSol.colorHex, equals('#E9C46A')); // Oro
        expect(PrehispanicEmotion.ehecatlViento.colorHex, equals('#48CAE4')); // Turquesa
        expect(PrehispanicEmotion.mixcoatlTormenta.colorHex, equals('#E76F51')); // Cempasúchil
        expect(PrehispanicEmotion.metztliNoche.colorHex, equals('#9D4EDD')); // Violeta
      });
    });

    group('gradientColors', () {
      test('devuelve lista de 2 colores para gradiente', () {
        for (final emotion in PrehispanicEmotion.values) {
          final colors = emotion.gradientColors;
          expect(colors.length, equals(2));
          expect(colors[0], isA<int>());
          expect(colors[1], isA<int>());
        }
      });
    });

    group('isValidId', () {
      test('true para IDs válidos', () {
        expect(PrehispanicEmotion.isValidId('tlaloc_lluvia'), isTrue);
        expect(PrehispanicEmotion.isValidId('tonatiuh_sol'), isTrue);
        expect(PrehispanicEmotion.isValidId('ehecatl_viento'), isTrue);
        expect(PrehispanicEmotion.isValidId('mixcoatl_tormenta'), isTrue);
        expect(PrehispanicEmotion.isValidId('metztli_noche'), isTrue);
      });

      test('false para IDs inválidos', () {
        expect(PrehispanicEmotion.isValidId('invalido'), isFalse);
        expect(PrehispanicEmotion.isValidId(''), isFalse);
        expect(PrehispanicEmotion.isValidId('Tlaloc_Lluvia'), isFalse);
      });
    });

    group('allIds', () {
      test('contiene los 5 IDs válidos', () {
        expect(PrehispanicEmotion.allIds, equals([
          'tlaloc_lluvia',
          'tonatiuh_sol',
          'ehecatl_viento',
          'mixcoatl_tormenta',
          'metztli_noche',
        ]));
      });
    });

    group('equality y hashCode', () {
      test('valores iguales son iguales', () {
        expect(PrehispanicEmotion.tlalocLluvia, equals(PrehispanicEmotion.tlalocLluvia));
        expect(PrehispanicEmotion.tlalocLluvia.hashCode, equals(PrehispanicEmotion.tlalocLluvia.hashCode));
      });

      test('valores distintos no son iguales', () {
        expect(PrehispanicEmotion.tlalocLluvia, isNot(equals(PrehispanicEmotion.tonatiuhSol)));
      });
    });
  });
}