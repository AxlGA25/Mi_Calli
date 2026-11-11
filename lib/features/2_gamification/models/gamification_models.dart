import 'package:flutter/material.dart';
import 'package:mi_calli/core/constants/app_colors.dart';

/// Etapas de evolución del Quetzalcóatl basadas en XP.
enum QuetzalEvolutionStage {
  /// Nivel 1: Cóatl de Jade (0–4 plumas, 0–49 XP)
  level1CoatlJade(1, 'Cóatl de Jade', 0, 0),

  /// Nivel 2: Aprendiz del Viento (5–14 plumas, 50–149 XP)
  level2AprendizViento(2, 'Aprendiz del Viento', 5, 50),

  /// Nivel 3: Guardián Emplumado (15–29 plumas, 150–299 XP)
  level3GuardianEmplumado(3, 'Guardián Emplumado', 15, 150),

  /// Nivel 4: Señor de la Aurora / Tlahuizcalpantecuhtli (30–49 plumas, 300–499 XP)
  level4SenorAurora(4, 'Señor de la Aurora (Tlahuizcalpantecuhtli)', 30, 300),

  /// Nivel 5: Quetzalcóatl Supremo (>= 50 plumas, >= 500 XP)
  level5QuetzalcoatlSupremo(5, 'Quetzalcóatl Supremo', 50, 500);

  const QuetzalEvolutionStage(
    this.levelNumber,
    this.displayName,
    this.minFeathers,
    this.minXp,
  );

  final int levelNumber;
  final String displayName;
  final int minFeathers;
  final int minXp;

  /// Obtiene la etapa correspondiente según el XP actual.
  /// 1 pluma = 10 XP.
  static QuetzalEvolutionStage fromXp(int xp) {
    if (xp >= 500) return QuetzalEvolutionStage.level5QuetzalcoatlSupremo;
    if (xp >= 300) return QuetzalEvolutionStage.level4SenorAurora;
    if (xp >= 150) return QuetzalEvolutionStage.level3GuardianEmplumado;
    if (xp >= 50) return QuetzalEvolutionStage.level2AprendizViento;
    return QuetzalEvolutionStage.level1CoatlJade;
  }
}

/// Niveles del Fuego Sagrado basados en la racha diaria.
enum SacredFireTier {
  /// 0 días: Brasas en espera (intensidad 0.15)
  embers(0, 0.15, 'Brasas en espera'),

  /// 1–3 días: Fuego Cálido (intensidad 0.5)
  warmOrange(1, 0.5, 'Fuego Cálido'),

  /// 4–6 días: Fuego Solar (intensidad 0.8)
  solarGold(4, 0.8, 'Fuego Solar'),

  /// >= 7 días: Fuego Místico de Quetzalcóatl (intensidad 1.0)
  mysticTurquoise(7, 1.0, 'Fuego Místico de Quetzalcóatl');

  const SacredFireTier(this.minStreakDays, this.intensity, this.displayName);

  final int minStreakDays;
  final double intensity;
  final String displayName;

  /// Obtiene el tier correspondiente según los días de racha.
  static SacredFireTier fromStreak(int streak) {
    if (streak >= 7) return SacredFireTier.mysticTurquoise;
    if (streak >= 4) return SacredFireTier.solarGold;
    if (streak >= 1) return SacredFireTier.warmOrange;
    return SacredFireTier.embers;
  }

  /// Color principal del tier (usa exclusivamente colores de AppColors).
  Color get primaryColor {
    switch (this) {
      case SacredFireTier.embers:
        return AppColors.obsidiana.withValues(alpha: 0.4);
      case SacredFireTier.warmOrange:
        return AppColors.fuegoNaranja;
      case SacredFireTier.solarGold:
        return AppColors.fuegoDorado;
      case SacredFireTier.mysticTurquoise:
        return AppColors.fuegoTurquesa;
    }
  }

  /// Colores del gradiente para el tier (usa exclusivamente colores de AppColors).
  List<Color> get gradientColors {
    switch (this) {
      case SacredFireTier.embers:
        return [
          AppColors.obsidiana.withValues(alpha: 0.2),
          AppColors.obsidiana.withValues(alpha: 0.4),
        ];
      case SacredFireTier.warmOrange:
        return [AppColors.fuegoNaranja, AppColors.oro];
      case SacredFireTier.solarGold:
        return [AppColors.fuegoDorado, AppColors.oro, AppColors.turquesa];
      case SacredFireTier.mysticTurquoise:
        return [AppColors.fuegoTurquesa, AppColors.turquesa, AppColors.jade];
    }
  }
}

/// Estado del resultado del check-in diario.
enum StreakStatus {
  /// Primer check-in de la historia.
  firstCheckin,

  /// Ya se hizo check-in hoy.
  alreadyCheckedInToday,

  /// La racha se incrementó en 1.
  incremented,

  /// La racha se salvó usando un escudo de Xólotl (día perdido).
  savedByXolotl,

  /// La racha se reinició con compasión (sin escudos o >= 3 días perdidos).
  resetCompassionate,
}

/// Estado inmutable de la gamificación.
class GamificationState {
  const GamificationState({
    required this.quetzalXp,
    required this.quetzalLevel,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastCheckinDate,
    required this.xolotlShields,
  });

  final int quetzalXp;
  final int quetzalLevel;
  final int currentStreak;
  final int longestStreak;
  final String? lastCheckinDate; // Formato YYYY-MM-DD
  final int xolotlShields;

  /// Etapa de evolución actual basada en XP.
  QuetzalEvolutionStage get evolutionStage => QuetzalEvolutionStage.fromXp(quetzalXp);

  /// Tier del Fuego Sagrado basado en la racha actual.
  SacredFireTier get sacredFireTier => SacredFireTier.fromStreak(currentStreak);

  /// Número de plumas (1 pluma = 10 XP).
  int get feathersCount => quetzalXp ~/ 10;

  /// Crea un GamificationState desde el mapa de la base de datos.
  factory GamificationState.fromMap(Map<String, dynamic> map) {
    return GamificationState(
      quetzalXp: map['quetzal_xp'] as int? ?? 0,
      quetzalLevel: map['quetzal_level'] as int? ?? 1,
      currentStreak: map['current_streak'] as int? ?? 0,
      longestStreak: map['longest_streak'] as int? ?? 0,
      lastCheckinDate: map['last_checkin_date'] as String?,
      xolotlShields: map['xolotl_shields'] as int? ?? 1,
    );
  }

  /// Convierte a mapa para guardar en la base de datos.
  Map<String, dynamic> toMap() {
    return {
      'quetzal_xp': quetzalXp,
      'quetzal_level': quetzalLevel,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_checkin_date': lastCheckinDate,
      'xolotl_shields': xolotlShields,
    };
  }

  /// Crea una copia con campos modificados.
  GamificationState copyWith({
    int? quetzalXp,
    int? quetzalLevel,
    int? currentStreak,
    int? longestStreak,
    String? lastCheckinDate,
    int? xolotlShields,
  }) {
    return GamificationState(
      quetzalXp: quetzalXp ?? this.quetzalXp,
      quetzalLevel: quetzalLevel ?? this.quetzalLevel,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastCheckinDate: lastCheckinDate ?? this.lastCheckinDate,
      xolotlShields: xolotlShields ?? this.xolotlShields,
    );
  }
}

/// Resultado de un check-in diario.
class CheckinResult {
  const CheckinResult({
    required this.state,
    required this.status,
    required this.leveledUp,
    required this.shieldEarned,
    required this.compassionateMessage,
  });

  final GamificationState state;
  final StreakStatus status;
  final bool leveledUp;
  final bool shieldEarned;
  final String compassionateMessage;
}