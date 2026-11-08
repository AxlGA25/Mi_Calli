// EmotionWeatherSelector - Selector reutilizable de los 5 climas emocionales.
//
// - Recibe la emoción seleccionada y un callback onChanged (sin navegación ni persistencia).
// - Muestra los 5 climas de CONTEXT.md sección 5D con gradientes de AppColors.
// - Al elegir un clima, el fondo cambia con transición de gradiente usando AnimatedContainer.
// - Si 'reducir movimiento' está activo (AppSettings o sistema), el cambio es inmediato (duración 0).
// - Cada opción: área táctil ≥ 48×48, Semantics en español, texto visible con nombre de emoción,
//   sin desbordes a 200 % de escala de texto.
// - No usa palabras clínicas ni de diagnóstico.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mi_calli/core/constants/app_colors.dart';
import 'package:mi_calli/core/settings/app_settings_provider.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/prehispanic_emotion.dart';

/// Widget reutilizable para seleccionar uno de los 5 climas emocionales prehispánicos.
///
/// - [selectedEmotion]: emoción actualmente seleccionada.
/// - [onChanged]: callback que se invoca cuando el usuario elige otra emoción.
/// - No realiza navegación ni persistencia; solo notifica el cambio.
class EmotionWeatherSelector extends ConsumerWidget {
  const EmotionWeatherSelector({
    super.key,
    required this.selectedEmotion,
    required this.onChanged,
  });

  final PrehispanicEmotion selectedEmotion;
  final ValueChanged<PrehispanicEmotion> onChanged;

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

    // Gradiente actual según la emoción seleccionada
    final currentGradient = _gradientFor(selectedEmotion);

    return AnimatedContainer(
      duration: duration,
      curve: curve,
      decoration: BoxDecoration(gradient: currentGradient),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      // Usar SingleChildScrollView para evitar desbordes a 200% escala de texto
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título del selector
            Semantics(
              label: 'Selecciona tu clima emocional actual',
              child: Text(
                '¿Cómo te sientes hoy?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            const SizedBox(height: 16),
            // Grid 5 columnas (o wrap responsive)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: PrehispanicEmotion.values.map((emotion) {
                final isSelected = emotion == selectedEmotion;
                return _WeatherOption(
                  emotion: emotion,
                  isSelected: isSelected,
                  onTap: () => onChanged(emotion),
                  effectiveReduceMotion: effectiveReduceMotion,
                );
              }).toList(),
            ),
          ],
        ),
      ),
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

/// Opción individual de clima dentro del selector.
class _WeatherOption extends StatelessWidget {
  const _WeatherOption({
    required this.emotion,
    required this.isSelected,
    required this.onTap,
    required this.effectiveReduceMotion,
  });

  final PrehispanicEmotion emotion;
  final bool isSelected;
  final VoidCallback onTap;
  final bool effectiveReduceMotion;

  @override
  Widget build(BuildContext context) {
    // Color del texto: blanco con opacidad según selección
    final textColor = isSelected
        ? Colors.white
        : Colors.white.withValues(alpha: 0.85);

    // Escala visual sutil al seleccionar (sin animación si reduceMotion)
    final scale = isSelected ? 1.05 : 1.0;
    final scaleAnimation = effectiveReduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 150);

    return Semantics(
      label: '${emotion.deity}, ${emotion.label}${isSelected ? ", seleccionado" : ""}',
      selected: isSelected,
      button: true,
      child: AnimatedScale(
        scale: scale,
        duration: scaleAnimation,
        curve: Curves.easeOutCubic,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          // Área táctil mínima 48×48
          child: Container(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nombre de la deidad/clima (visible, no solo icono)
                Text(
                  emotion.deity,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: textColor,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                const SizedBox(height: 2),
                // Etiqueta emocional (legible, no clínica)
                Text(
                  emotion.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: textColor.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w400,
                      ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}