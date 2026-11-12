// Modelos para el servicio de audio ambiental del Valle de Teotihuacán.
//
// Define las fases horarias del día y la configuración de pistas de audio
// que mezcla el ciclo horario con el clima emocional seleccionado.

import 'package:mi_calli/features/1_sanctuary_journal/models/prehispanic_emotion.dart';

/// Fases del día en el Valle de Teotihuacán según la cosmovisión prehispánica.
///
/// Rangos exactos de `docs/etapa_3_pantallas_ui_ux.md` sección 3:
/// - Amanecer (Tlahuizcalpan): 06:00–08:59
/// - Día Solar (Tonatiuh): 09:00–17:59
/// - Atardecer (Nepantla): 18:00–19:59
/// - Noche Estrellada (Metztli): 20:00–05:59
enum ValleyTimePhase {
  /// Amanecer — Tlahuizcalpan (06:00–08:59)
  dawn,

  /// Día Solar — Tonatiuh (09:00–17:59)
  day,

  /// Atardecer — Nepantla (18:00–19:59)
  dusk,

  /// Noche Estrellada — Metztli (20:00–05:59)
  night;

  /// Convierte la hora del día (0–23) a la fase horaria correspondiente.
  ///
  /// Rangos según `docs/etapa_3_pantallas_ui_ux.md` sección 3:
  /// - 6–8   → dawn  (Amanecer Tlahuizcalpan)
  /// - 9–17  → day   (Día Solar Tonatiuh)
  /// - 18–19 → dusk  (Atardecer Nepantla)
  /// - 20–23, 0–5 → night (Noche Estrellada Metztli)
  static ValleyTimePhase fromHour(int hour) {
    if (hour >= 6 && hour <= 8) {
      return ValleyTimePhase.dawn;
    } else if (hour >= 9 && hour <= 17) {
      return ValleyTimePhase.day;
    } else if (hour >= 18 && hour <= 19) {
      return ValleyTimePhase.dusk;
    } else {
      // 20–23 y 0–5
      return ValleyTimePhase.night;
    }
  }

  /// Nombre en náhuatl de la fase.
  String get nahuatlName => switch (this) {
        ValleyTimePhase.dawn => 'Tlahuizcalpan',
        ValleyTimePhase.day => 'Tonatiuh',
        ValleyTimePhase.dusk => 'Nepantla',
        ValleyTimePhase.night => 'Metztli',
      };

  /// Nombre en español de México para mostrar en UI.
  String get spanishName => switch (this) {
        ValleyTimePhase.dawn => 'Amanecer',
        ValleyTimePhase.day => 'Día Solar',
        ValleyTimePhase.dusk => 'Atardecer',
        ValleyTimePhase.night => 'Noche Estrellada',
      };

  /// Ruta del asset de audio base para esta fase horaria.
  ///
  /// Se espera en `assets/audio/` (ej. `assets/audio/ambient_dawn.mp3`).
  /// Si el archivo no existe físicamente, el servicio debe degradarse
  /// limpiamente sin lanzar excepciones.
  String get defaultAudioAssetPath => switch (this) {
        ValleyTimePhase.dawn => 'assets/audio/ambient_dawn.mp3',
        ValleyTimePhase.day => 'assets/audio/ambient_day.mp3',
        ValleyTimePhase.dusk => 'assets/audio/ambient_dusk.mp3',
        ValleyTimePhase.night => 'assets/audio/ambient_night.mp3',
      };

  /// Rango horario legible para tooltips y accesibilidad.
  String get timeRangeLabel => switch (this) {
        ValleyTimePhase.dawn => '06:00–08:59',
        ValleyTimePhase.day => '09:00–17:59',
        ValleyTimePhase.dusk => '18:00–19:59',
        ValleyTimePhase.night => '20:00–05:59',
      };
}

/// Configuración inmutable de la pista de audio ambiental que debe sonar.
///
/// Prioriza el clima emocional activo (si hay `activeEmotionOverride`)
/// sobre la fase horaria base.
class AmbientAudioTrackConfig {
  /// Crea una configuración de pista.
  ///
  /// - [timePhase]: fase horaria actual (base).
  /// - [activeEmotionOverride]: emoción seleccionada en el diario/valle (opcional).
  ///   Si no es null, usa `'assets/audio/weather_${emotion.id}.mp3'`.
  const AmbientAudioTrackConfig({
    required this.timePhase,
    this.activeEmotionOverride,
  });

  /// Fase horaria base del Valle.
  final ValleyTimePhase timePhase;

  /// Clima emocional que sobrescribe la pista horaria (ej. al escribir en el diario).
  final PrehispanicEmotion? activeEmotionOverride;

  /// Ruta del asset que debe reproducirse según la prioridad.
  ///
  /// 1. Si hay `activeEmotionOverride`: `'assets/audio/weather_${emotion.id}.mp3'`
  /// 2. Si no: `timePhase.defaultAudioAssetPath`
  String get assetPath => activeEmotionOverride != null
      ? 'assets/audio/weather_${activeEmotionOverride!.id}.mp3'
      : timePhase.defaultAudioAssetPath;

  /// Indica si la pista actual es una sobrescritura por emoción.
  bool get isEmotionOverride => activeEmotionOverride != null;

  /// Descripción legible para logs y depuración.
  String get description => isEmotionOverride
      ? 'Clima emocional: ${activeEmotionOverride!.deity} (${activeEmotionOverride!.id})'
      : 'Fase horaria: ${timePhase.spanishName} (${timePhase.nahuatlName})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AmbientAudioTrackConfig &&
        other.timePhase == timePhase &&
        other.activeEmotionOverride == activeEmotionOverride;
  }

  @override
  int get hashCode => Object.hash(timePhase, activeEmotionOverride);

  @override
  String toString() =>
      'AmbientAudioTrackConfig(assetPath: $assetPath, $description)';
}