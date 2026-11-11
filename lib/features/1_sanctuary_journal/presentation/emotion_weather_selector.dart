// EmotionWeatherSelector - Selector reutilizable de los 5 climas emocionales.
//
// - Recibe la emoción seleccionada y un callback onChanged (sin navegación ni persistencia).
// - Muestra los 5 climas de CONTEXT.md sección 5D (sin fondo propio, transparente).
// - Si 'reducir movimiento' está activo (AppSettings o sistema), la animación de escala es inmediata (duración 0).
// - Cada opción: área táctil ≥ 48×48, Semantics en español, texto visible con nombre de emoción,
//   sin desbordes a 200 % de escala de texto (el widget padre debe ser desplazable).
// - No usa palabras clínicas ni de diagnóstico.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mi_calli/core/constants/app_colors.dart';
import 'package:mi_calli/core/settings/app_settings_provider.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/prehispanic_emotion.dart';

// Constantes de color/superficie para tests de contraste (WCAG 4.5:1).
// Deben coincidir exactamente con los valores usados en la implementación.
class EmotionWeatherSelectorContrastConstants {
  static const Color selectorTitleBgColor = Color.fromRGBO(255, 255, 255, 0.85);
  static const Color selectorTitleTextColor = AppColors.obsidiana;
  static const Color optionSelectedBgColor = Color.fromRGBO(255, 255, 255, 0.95);
  static const Color optionUnselectedBgColor = Color.fromRGBO(255, 255, 255, 0.85);
  static const Color optionTextColor = AppColors.obsidiana;
  static const double optionTextSecondaryAlpha = 0.85;
  static const Color optionSelectedBorderColor = AppColors.obsidiana;
  static const Color optionUnselectedBorderColor = Color.fromRGBO(15, 23, 42, 0.3); // obsidiana alpha 0.3

  EmotionWeatherSelectorContrastConstants._();
}

/// Widget reutilizable para seleccionar uno de los 5 climas emocionales prehispánicos.
///
/// - [selectedEmotion]: emoción actualmente seleccionada.
/// - [onChanged]: callback que se invoca cuando el usuario elige otra emoción.
/// - No realiza navegación ni persistencia; solo notifica el cambio.
/// - **Sin fondo propio** (transparente); el fondo lo provee [EmotionGradientBackground].
/// - **Sin SingleChildScrollView propio**; debe usarse dentro de un contenedor desplazable.
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Título del selector
        // Usa texto oscuro (obsidiana) sobre capa translúcida clara para contraste 4.5:1
        Semantics(
          label: 'Selecciona tu clima emocional actual',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: EmotionWeatherSelectorContrastConstants.selectorTitleBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '¿Cómo te sientes hoy?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: EmotionWeatherSelectorContrastConstants.selectorTitleTextColor,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
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
    );
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
    // Usa texto oscuro (obsidiana) sobre capa translúcida clara para garantizar
    // contraste 4.5:1 mínimo en todos los 5 gradientes (incluyendo Tonatiuh Sol
    // y Ehecatl Viento que son claros).
    final backgroundColor = isSelected
        ? EmotionWeatherSelectorContrastConstants.optionSelectedBgColor
        : EmotionWeatherSelectorContrastConstants.optionUnselectedBgColor;
    final borderColor = isSelected
        ? EmotionWeatherSelectorContrastConstants.optionSelectedBorderColor
        : EmotionWeatherSelectorContrastConstants.optionUnselectedBorderColor;
    final borderWidth = isSelected ? 2.0 : 1.0;

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
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: borderWidth,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nombre de la deidad/clima (visible, no solo icono)
                Text(
                  emotion.deity,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: EmotionWeatherSelectorContrastConstants.optionTextColor,
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
                        color: EmotionWeatherSelectorContrastConstants.optionTextColor.withValues(
                          alpha: EmotionWeatherSelectorContrastConstants.optionTextSecondaryAlpha,
                        ),
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