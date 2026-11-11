// EmotionGradientBackground - Fondo de gradiente animado para los 5 climas emocionales.
//
// - Recibe la emoción y dibuja el gradiente a pantalla completa.
// - Usa SafeAnimationWrapper para aislamiento (RepaintBoundary) y pausa por ciclo de vida.
// - Transición suave con AnimatedContainer (duración 0 si "reducir movimiento" activo).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mi_calli/core/constants/app_colors.dart';
import 'package:mi_calli/core/performance/safe_animation_wrapper.dart';
import 'package:mi_calli/core/settings/app_settings_provider.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/prehispanic_emotion.dart';

/// Fondo de gradiente animado según la emoción seleccionada.
///
/// - [emotion]: emoción que determina el gradiente.
/// - Cubre toda la pantalla disponible.
/// - Respeta "reducir movimiento" (AppSettings + MediaQuery).
class EmotionGradientBackground extends ConsumerWidget {
  const EmotionGradientBackground({
    super.key,
    required this.emotion,
  });

  final PrehispanicEmotion emotion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Leer reduceMotion de AppSettings + MediaQuery del sistema
    final appReduceMotion = ref.watch(
      appSettingsProvider.select((s) => s.reduceMotion),
    );
    final systemReduceMotion = MediaQuery.disableAnimationsOf(context);
    final effectiveReduceMotion = appReduceMotion || systemReduceMotion;

    // Duración de la animación: 0 si reduceMotion, 500ms si no
    final duration = effectiveReduceMotion ? Duration.zero : const Duration(milliseconds: 500);
    final curve = Curves.easeInOutCubic;

    // Gradiente actual según la emoción
    final currentGradient = _gradientFor(emotion);

    // Child: AnimatedContainer con el gradiente
    final animatedContainer = AnimatedContainer(
      duration: duration,
      curve: curve,
      decoration: BoxDecoration(gradient: currentGradient),
      child: const SizedBox.expand(), // Ocupa todo el espacio disponible
    );

    // Fallback: Container estático con el mismo gradiente (para reduceMotion o ciclo de vida)
    final fallbackContainer = Container(
      decoration: BoxDecoration(gradient: currentGradient),
      child: const SizedBox.expand(),
    );

    return SafeAnimationWrapper(
      fallbackWidget: fallbackContainer,
      // Usar 'never' para que AnimatedContainer maneje reduceMotion internamente
      // (duration = 0) y SafeAnimationWrapper solo aporte RepaintBoundary + pausa por ciclo de vida
      fallbackBehavior: SafeAnimationFallbackBehavior.never,
      child: animatedContainer,
    );
  }

  /// Devuelve el gradiente correspondiente a la emoción (usando AppColors).
  LinearGradient _gradientFor(PrehispanicEmotion emotion) {
    return switch (emotion) {
      PrehispanicEmotion.tlalocLluvia => AppColors.gradientTlalocLluvia,
      PrehispanicEmotion.tonatiuhSol => AppColors.gradientTonatiuhSol,
      PrehispanicEmotion.ehecatlViento => AppColors.gradientEhecatlViento,
      PrehispanicEmotion.mixcoatlTormenta => AppColors.gradientMixcoatlTormenta,
      PrehispanicEmotion.metztliNoche => AppColors.gradientMetztliNoche,
    };
  }
}