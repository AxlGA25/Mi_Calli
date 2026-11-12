// Modelos para la Lectura del Tonalpohualli (Constelación de Venus).
//
// Generados según CONTEXT.md punto 11 y docs/etapa_2_gamificacion_teotihuacan.md sección 6.
// Algoritmo 100% local, sin IA externa.

import 'package:mi_calli/features/1_sanctuary_journal/models/prehispanic_emotion.dart';

/// Lectura astral semanal completa e inmutable.
///
/// Contiene el vector de frecuencias emocionales, el Astro Regente,
/// los 3 bloques de texto (Apertura, Cuerpo, Augurio de Venus) y metadatos.
class WeeklyAstralReading {
  const WeeklyAstralReading({
    required this.rulingEmotion,
    required this.mysticTitle,
    required this.emotionFrequencies,
    required this.totalEntries,
    required this.nourishedSproutsCount,
    required this.openingParagraph,
    required this.bodyParagraph,
    required this.venusOmenParagraph,
    required this.generatedAt,
  });

  /// Emoción predominante de la semana (Astro Regente / max(V)).
  final PrehispanicEmotion rulingEmotion;

  /// Título prehispánico según el Astro Regente (ej. 'Bajo el Manto de Tláloc').
  final String mysticTitle;

  /// Vector V de frecuencias de las 5 emociones en los últimos 7 días.
  /// Claves: 'tlaloc_lluvia', 'tonatiuh_sol', 'ehecatl_viento', 'mixcoatl_tormenta', 'metztli_noche'.
  final Map<String, int> emotionFrequencies;

  /// Total de entradas de diario en los últimos 7 días.
  final int totalEntries;

  /// Conteo de brotes nutridos / riegos en la semana (C_total).
  /// Entradas con watered_seed_id != null o total de ofrendas/riegos.
  final int nourishedSproutsCount;

  /// Párrafo de Apertura según el Astro Regente (emoción predominante).
  final String openingParagraph;

  /// Párrafo de Cuerpo según C_total y total de entradas.
  final String bodyParagraph;

  /// Párrafo de Augurio de Venus (cierre motivacional según Astro Regente).
  final String venusOmenParagraph;

  /// Momento de generación de la lectura (UTC).
  final DateTime generatedAt;

  /// Texto completo de la lectura con separadores de párrafo.
  String get fullReadingText =>
      '$openingParagraph\n\n$bodyParagraph\n\n$venusOmenParagraph';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeeklyAstralReading &&
          runtimeType == other.runtimeType &&
          rulingEmotion == other.rulingEmotion &&
          mysticTitle == other.mysticTitle &&
          _mapEquals(emotionFrequencies, other.emotionFrequencies) &&
          totalEntries == other.totalEntries &&
          nourishedSproutsCount == other.nourishedSproutsCount &&
          openingParagraph == other.openingParagraph &&
          bodyParagraph == other.bodyParagraph &&
          venusOmenParagraph == other.venusOmenParagraph &&
          generatedAt == other.generatedAt;

  @override
  int get hashCode => Object.hash(
    rulingEmotion,
    mysticTitle,
    Object.hashAll(emotionFrequencies.entries),
    totalEntries,
    nourishedSproutsCount,
    openingParagraph,
    bodyParagraph,
    venusOmenParagraph,
    generatedAt,
  );

  @override
  String toString() =>
      'WeeklyAstralReading(rulingEmotion: $rulingEmotion, '
      'mysticTitle: $mysticTitle, totalEntries: $totalEntries, '
      'nourishedSproutsCount: $nourishedSproutsCount, generatedAt: $generatedAt)';

  static bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}