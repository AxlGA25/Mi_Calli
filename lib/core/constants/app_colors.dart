import 'package:flutter/painting.dart';

/// Paleta de colores prehispánica para Refugio Quetzalcóatl.
///
/// Colores inspirados en la cosmovisión de Teotihuacán:
/// - Jade: piedra sagrada, vida y fertilidad
/// - Turquesa: agua, cielo, Quetzalcóatl
/// - Oro: sol, Tonatiuh, divinidad
/// - Obsidiana: noche, protección, Tezcatlipoca
/// - Rojo Grana/Cempasúchil: sangre, vida, flor de muertos
class AppColors {
  // Colores principales
  static const Color jade = Color(0xFF2A9D8F);
  static const Color turquesa = Color(0xFF48CAE4);
  static const Color oro = Color(0xFFE9C46A);
  static const Color obsidiana = Color(0xFF0F172A);
  static const Color rojoGrana = Color(0xFFE76F51);

  // Gradientes para climas emocionales
  static const LinearGradient gradientTlalocLluvia = LinearGradient(
    colors: [Color(0xFF1E3A5F), Color(0xFF2C5F8A), Color(0xFF3A86C8)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient gradientTonatiuhSol = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFE9C46A), Color(0xFFFEF3C7)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient gradientEhecatlViento = LinearGradient(
    colors: [Color(0xFF64748B), Color(0xFF94A3B8), Color(0xFFE2E8F0)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient gradientMixcoatlTormenta = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF334155), Color(0xFF475569)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient gradientMetztliNoche = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF312E81)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Ciclo Día/Noche para el Valle
  static const LinearGradient gradientDia = LinearGradient(
    colors: [Color(0xFF48CAE4), Color(0xFF90E0EF), Color(0xFFCAF0F8)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient gradientAtardecer = LinearGradient(
    colors: [Color(0xFFF77F00), Color(0xFFFCBF49), Color(0xFFE9C46A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient gradientNoche = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF312E81)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient gradientMadrugada = LinearGradient(
    colors: [Color(0xFF1E3A5F), Color(0xFF2C5F8A), Color(0xFF48CAE4)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Colores para Fuego Sagrado (rachas)
  static const Color fuegoNaranja = Color(0xFFF77F00);
  static const Color fuegoDorado = Color(0xFFE9C46A);
  static const Color fuegoTurquesa = Color(0xFF48CAE4);

  // Colores semánticos
  static const Color success = jade;
  static const Color warning = oro;
  static const Color error = rojoGrana;
  static const Color surface = Color(0xFFFAFAFA);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
}