// Modelos para el servicio de audio ambiental de Mi Calli.
//
// Define las fases horarias del Valle de Teotihuacán y la configuración
// de la pista de audio que debe reproducirse según el clima emocional
// o la hora del día.

import 'package:mi_calli/features/1_sanctuary_journal/models/prehispanic_emotion.dart';

/// Fases del día en el Valle de Teotihuacán según la cosmovisión prehispánica.
///
/// Cada fase tiene un nombre en náhuatl, un nombre en español y un rango horario.
/// Fuente: docs/etapa_3_pantallas_ui_ux.md sección 3.
enum ValleyTimePhase {
  /// Amanecer Tlahuizcalpan (06:00–08:59)
  dawn,

  /// Día Solar Tonatiuh (09:00–17:59)
  day,

  /// Atardecer Nepantla (18:00–19:59)
  dusk,

  /// Noche Estrellada Metztli (20:00–05:59)
  night;

  /// Obtiene la fase horaria correspondiente a una hora del día (0-23).
  ///
  /// Rangos exactos según docs/etapa_3_pantallas_ui_ux.md:
  /// - dawn: 6-8
  /// - day: 9-17
  /// - dusk: 18-19
  /// - night: 20-23, 0-5
  static ValleyTimePhase fromHour(int hour) {
    if (hour >= 6 && hour <= 8) {
      return ValleyTimePhase.dawn;
    } else if (hour >= 9 && hour <= 17) {
      return ValleyTimePhase.day;
    } else if (hour >= 18 && hour <= 19) {
      return ValleyTimePhase.dusk;
    } else {
      // 20-23 y 0-5
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

  /// Nombre en español de la fase.
  String get spanishName => switch (this) {
        ValleyTimePhase.dawn => 'Amanecer',
        ValleyTimePhase.day => 'Día Solar',
        ValleyTimePhase.dusk => 'Atardecer',
        ValleyTimePhase.night => 'Noche Estrellada',
      };

  /// Ruta esperada del asset de audio ambiental para esta fase.
  ///
  /// Los archivos deben colocarse en assets/audio/ (actualmente solo .gitkeep).
  /// El servicio degrada limpiamente si el archivo no existe.
  String get defaultAudioAssetPath => switch (this) {
        ValleyTimePhase.dawn => 'assets/audio/ambient_dawn.mp3',
        ValleyTimePhase.day => 'assets/audio/ambient_day.mp3',
        ValleyTimePhase.dusk => 'assets/audio/ambient_dusk.mp3',
        ValleyTimePhase.night => 'assets/audio/ambient_night.mp3',
      };
}

/// Configuración inmutable de la pista de audio ambiental que debe sonar.
///
/// Prioriza el clima emocional activo (si hay override) sobre la fase horaria.
/// Inmutable para uso seguro con Riverpod y comparación por igualdad.
class AmbientAudioTrackConfig {
  /// Crea una configuración de pista ambiental.
  ///
  /// Si [activeEmotionOverride] no es null, se usa la pista del clima emocional:
  /// 'assets/audio/weather_${emotion.id}.mp3'.
  /// Si es null, se usa [timePhase.defaultAudioAssetPath].
  const AmbientAudioTrackConfig({
    this.activeEmotionOverride,
    required this.timePhase,
  });

  /// Emoción que sobrescribe la pista horaria (ej. al escribir en el diario).
  final PrehispanicEmotion? activeEmotionOverride;

  /// Fase horaria actual del Valle.
  final ValleyTimePhase timePhase;

  /// Ruta del asset de audio que debe reproducirse.
  String get assetPath {
    if (activeEmotionOverride != null) {
      return 'assets/audio/weather_${activeEmotionOverride!.id}.mp3';
    }
    return timePhase.defaultAudioAssetPath;
  }

  /// Indica si la pista actual es una pista de clima emocional.
  bool get isEmotionTrack => activeEmotionOverride != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AmbientAudioTrackConfig &&
        other.activeEmotionOverride == activeEmotionOverride &&
        other.timePhase == timePhase;
  }

  @override
  int get hashCode => Object.hash(activeEmotionOverride, timePhase);

  @override
  String toString() {
    return 'AmbientAudioTrackConfig('
        'emotionOverride: ${activeEmotionOverride?.id ?? 'none'}, '
        'timePhase: $timePhase, '
        'assetPath: $assetPath)';
  }
}