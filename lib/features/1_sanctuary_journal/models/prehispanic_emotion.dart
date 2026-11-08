/// Enum que representa los 5 climas emocionales prehispánicos.
///
/// Fuente de verdad: `CONTEXT.md` sección 5D.
/// Cada emoción está asociada a una deidad/clima de la cosmovisión teotihuacana.
enum PrehispanicEmotion {
  /// Tristeza, melancolía — Lluvia de Tláloc
  tlalocLluvia,

  /// Alegría, calma, gratitud — Sol de Tonatiuh
  tonatiuhSol,

  /// Ansiedad, estrés, abrumo — Viento de Ehécatl
  ehecatlViento,

  /// Enojo, frustración — Tormenta de Mixcóatl
  mixcoatlTormenta,

  /// Cansancio, agotamiento — Noche de Metztli
  metztliNoche;

  /// Obtiene el `PrehispanicEmotion` desde su `emotion_id` (string usado en BD y JSON).
  ///
  /// Lanza [ArgumentError] si el id no corresponde a ninguna emoción válida.
  static PrehispanicEmotion fromId(String emotionId) {
    return PrehispanicEmotion.values.firstWhere(
      (e) => e.id == emotionId,
      orElse: () => throw ArgumentError('Emoción inválida: $emotionId'),
    );
  }

  /// Identificador único usado en base de datos, JSON y APIs.
  /// Coincide con la columna `emotion_id` de `diary_entries` (CONTEXT.md sección 5D).
  String get id => switch (this) {
        PrehispanicEmotion.tlalocLluvia => 'tlaloc_lluvia',
        PrehispanicEmotion.tonatiuhSol => 'tonatiuh_sol',
        PrehispanicEmotion.ehecatlViento => 'ehecatl_viento',
        PrehispanicEmotion.mixcoatlTormenta => 'mixcoatl_tormenta',
        PrehispanicEmotion.metztliNoche => 'metztli_noche',
      };

  /// Nombre legible en español de México para mostrar en UI.
  String get label => switch (this) {
        PrehispanicEmotion.tlalocLluvia => 'Tristeza, melancolía',
        PrehispanicEmotion.tonatiuhSol => 'Alegría, calma, gratitud',
        PrehispanicEmotion.ehecatlViento => 'Ansiedad, estrés, abrumo',
        PrehispanicEmotion.mixcoatlTormenta => 'Enojo, frustración',
        PrehispanicEmotion.metztliNoche => 'Cansancio, agotamiento',
      };

  /// Deidad/clima asociado en la cosmovisión prehispánica.
  String get deity => switch (this) {
        PrehispanicEmotion.tlalocLluvia => 'Lluvia de Tláloc',
        PrehispanicEmotion.tonatiuhSol => 'Sol de Tonatiuh',
        PrehispanicEmotion.ehecatlViento => 'Viento de Ehécatl',
        PrehispanicEmotion.mixcoatlTormenta => 'Tormenta de Mixcóatl',
        PrehispanicEmotion.metztliNoche => 'Noche de Metztli',
      };

  /// Descripción breve para accesibilidad y tooltips.
  String get description => 'Clima emocional: $deity — $label';

  /// Color hex asociado a esta emoción (paleta prehispánica).
  String get colorHex => switch (this) {
        PrehispanicEmotion.tlalocLluvia => '#2A9D8F', // Jade Quetzalcóatl
        PrehispanicEmotion.tonatiuhSol => '#E9C46A', // Oro Tonatiuh
        PrehispanicEmotion.ehecatlViento => '#48CAE4', // Turquesa Ehécatl
        PrehispanicEmotion.mixcoatlTormenta => '#E76F51', // Rojo Grana / Cempasúchil
        PrehispanicEmotion.metztliNoche => '#9D4EDD', // Violeta Metztli
      };

  /// Gradiente de fondo para el selector de clima (usado en `EmotionWeatherSelector`).
  /// Los gradientes están definidos en `AppColors` pero aquí damos los stops para consistencia.
  List<int> get gradientColors => switch (this) {
        PrehispanicEmotion.tlalocLluvia => [0xFF2A9D8F, 0xFF1B7A6D], // Jade → Jade oscuro
        PrehispanicEmotion.tonatiuhSol => [0xFFE9C46A, 0xFFD4A843], // Oro → Oro oscuro
        PrehispanicEmotion.ehecatlViento => [0xFF48CAE4, 0xFF2AA8C8], // Turquesa → Turquesa oscuro
        PrehispanicEmotion.mixcoatlTormenta => [0xFFE76F51, 0xFFC8553A], // Cempasúchil → Rojo oscuro
        PrehispanicEmotion.metztliNoche => [0xFF9D4EDD, 0xFF7B3BC4], // Violeta → Violeta oscuro
      };

  /// Valida si un string es un `emotion_id` válido.
  static bool isValidId(String emotionId) {
    return PrehispanicEmotion.values.any((e) => e.id == emotionId);
  }

  /// Lista de todos los `emotion_id` válidos.
  static List<String> get allIds => PrehispanicEmotion.values.map((e) => e.id).toList();
}