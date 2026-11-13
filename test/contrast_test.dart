// Test de contraste WCAG para SanctuaryJournalScreen y EmotionWeatherSelector.
//
// Verifica que todos los textos críticos de la pantalla cumplen con la
// relación de contraste mínima de 4.5:1 (WCAG AA para texto normal).
//
// La pantalla usa capas translúcidas detrás de los textos para garantizar
// legibilidad sobre los gradientes:
// - Frase superior y etiquetas de clima: fondo blanco con alpha 0.85/0.95
// - Botón "Entregar ofrenda": fondo obsidiana
// - Botón "Necesito apoyo": fondo blanco con alpha 0.9
//
// El test verifica el contraste REAL percibido: texto vs su fondo inmediato.
// Esto es lo que exige WCAG para "texto normal" (4.5:1).
//
// Colores fuentes: AppColors (gradientes, obsidiana, jade, etc.) y
// PrehispanicEmotion (ningún color hardcodeado en la prueba).

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_calli/core/constants/app_colors.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/prehispanic_emotion.dart';
import 'package:mi_calli/features/1_sanctuary_journal/presentation/emotion_weather_selector.dart';
import 'package:mi_calli/features/1_sanctuary_journal/presentation/private_codex_screen.dart';
import 'package:mi_calli/features/1_sanctuary_journal/presentation/sanctuary_journal_screen.dart';

/// Calcula la luminancia relativa de un color (sRGB -> lineal -> luminancia).
///
/// Fórmula WCAG 2.1:
/// - Color.r, .g, .b devuelven double 0.0-1.0 en Flutter (ya normalizados)
/// - Si <= 0.03928: c_lineal = c / 12.92
/// - Si > 0.03928: c_lineal = ((c + 0.055) / 1.055) ^ 2.4
/// - L = 0.2126 * R + 0.7152 * G + 0.0722 * B
double _relativeLuminance(Color color) {
  double channel(double c) {
    return c <= 0.03928
        ? c / 12.92
        : pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = channel(color.r);
  final g = channel(color.g);
  final b = channel(color.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// Calcula la relación de contraste entre dos colores.
///
/// Fórmula WCAG: (L1 + 0.05) / (L2 + 0.05) donde L1 es la luminancia del
/// color más claro y L2 del más oscuro. Resultado >= 1.0.
double _contrastRatio(Color color1, Color color2) {
  final l1 = _relativeLuminance(color1);
  final l2 = _relativeLuminance(color2);
  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}

/// Obtiene el gradiente correspondiente a una emoción.
LinearGradient _gradientForEmotion(PrehispanicEmotion emotion) {
  return switch (emotion) {
    PrehispanicEmotion.tlalocLluvia => AppColors.gradientTlalocLluvia,
    PrehispanicEmotion.tonatiuhSol => AppColors.gradientTonatiuhSol,
    PrehispanicEmotion.ehecatlViento => AppColors.gradientEhecatlViento,
    PrehispanicEmotion.mixcoatlTormenta => AppColors.gradientMixcoatlTormenta,
    PrehispanicEmotion.metztliNoche => AppColors.gradientMetztliNoche,
  };
}

/// Calcula el color de fondo efectivo componiendo un overlay translúcido
/// sobre cada parada del gradiente y tomando el peor caso (mínimo contraste).
///
/// Para textos sobre capas translúcidas, el contraste debe verificarse
/// contra cada parada del gradiente porque el usuario puede ver cualquier
/// parte del gradiente a través de la translucidez.
///
/// Usa `Color.alphaBlend(foreground, background)` nativo de Flutter.
double _minContrastOnGradient({
  required Color textColor,
  required Color overlayColor, // Color translúcido (ej. blanco alpha 0.85)
  required LinearGradient gradient,
}) {
  final stops = gradient.colors;
  double minRatio = double.infinity;

  for (final stopColor in stops) {
    // Componer overlay translúcido sobre la parada del gradiente
    // Color.alphaBlend(foreground, background) = foreground over background
    final effectiveBg = Color.alphaBlend(overlayColor, stopColor);
    // Calcular contraste del texto contra este fondo efectivo
    final ratio = _contrastRatio(textColor, effectiveBg);
    if (ratio < minRatio) {
      minRatio = ratio;
    }
  }
  return minRatio;
}

/// Calcula el contraste mínimo cuando tanto el texto como el fondo pueden tener alpha.
/// Compone el texto sobre el fondo efectivo y calcula el contraste percibido.
///
/// Usa `Color.alphaBlend(foreground, background)` nativo de Flutter.
double _minContrastWithTextAlpha({
  required Color textColor, // Puede tener alpha
  required Color overlayColor, // Capa translúcida (ej. blanco alpha 0.85)
  required LinearGradient gradient,
}) {
  final stops = gradient.colors;
  double minRatio = double.infinity;

  for (final stopColor in stops) {
    // Fondo efectivo: overlay sobre parada del gradiente
    final effectiveBg = Color.alphaBlend(overlayColor, stopColor);
    // Texto efectivo: texto (con su alpha) sobre fondo efectivo
    final effectiveText = Color.alphaBlend(textColor, effectiveBg);
    // Contraste del texto efectivo vs fondo efectivo
    final ratio = _contrastRatio(effectiveText, effectiveBg);
    if (ratio < minRatio) {
      minRatio = ratio;
    }
  }
  return minRatio;
}

void main() {
  group('Contraste WCAG 4.5:1 - SanctuaryJournalScreen', () {
    // Constantes desde la implementación real
    const phraseBgColor =
        SanctuaryJournalContrastConstants.phraseBgColor;
    // climateSelectedBgColor y climateUnselectedBgColor ahora están en
    // EmotionWeatherSelectorContrastConstants para evitar duplicidad
    const climateSelectedBgColor =
        EmotionWeatherSelectorContrastConstants.optionSelectedBgColor;
    const climateUnselectedBgColor =
        EmotionWeatherSelectorContrastConstants.optionUnselectedBgColor;
    const entregarOfrendaBgColor =
        SanctuaryJournalContrastConstants.entregarOfrendaBgColor;
    const necesitoApoyoBgColor =
        SanctuaryJournalContrastConstants.necesitoApoyoBgColor;
    const darkTextColor =
        SanctuaryJournalContrastConstants.darkTextColor;
    const lightTextColor =
        SanctuaryJournalContrastConstants.lightTextColor;

    // Tests para elementos con fondo sólido (no dependen del gradiente)
    test('entregar_ofrenda_habilitado: texto blanco vs obsidiana >= 4.5:1', () {
      final ratio = _contrastRatio(lightTextColor, entregarOfrendaBgColor);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason:
            'entregar_ofrenda_habilitado: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 4.5:1',
      );
    });

    test('necesito_apoyo: texto obsidiana vs blanco alpha 0.9 >= 4.5:1', () {
      final ratio = _contrastRatio(darkTextColor, necesitoApoyoBgColor);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason:
            'necesito_apoyo: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 4.5:1',
      );
    });

    // Tests para elementos con fondo translúcido sobre gradiente:
    // Deben pasar en TODOS los 5 climas (peor caso entre paradas del gradiente)
    for (final emotion in PrehispanicEmotion.values) {
      final gradient = _gradientForEmotion(emotion);
      final emotionName = emotion.id;

      test(
        'frase_superior ($emotionName): obsidiana vs blanco alpha 0.85 sobre gradiente >= 4.5:1',
        () {
          final ratio = _minContrastOnGradient(
            textColor: darkTextColor,
            overlayColor: phraseBgColor,
            gradient: gradient,
          );
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason:
                'frase_superior ($emotionName): contraste mínimo ${ratio.toStringAsFixed(2)}:1, mínimo 4.5:1',
          );
        },
      );

      test(
        'etiqueta_clima_seleccionada ($emotionName): obsidiana vs blanco alpha 0.95 sobre gradiente >= 4.5:1',
        () {
          final ratio = _minContrastOnGradient(
            textColor: darkTextColor,
            overlayColor: climateSelectedBgColor,
            gradient: gradient,
          );
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason:
                'etiqueta_clima_seleccionada ($emotionName): contraste mínimo ${ratio.toStringAsFixed(2)}:1, mínimo 4.5:1',
          );
        },
      );

      test(
        'etiqueta_clima_no_seleccionada ($emotionName): obsidiana alpha 0.85 vs blanco alpha 0.85 sobre gradiente >= 4.5:1',
        () {
          final textWithAlpha =
              darkTextColor.withValues(alpha: EmotionWeatherSelectorContrastConstants.optionTextSecondaryAlpha);
          final ratio = _minContrastWithTextAlpha(
            textColor: textWithAlpha,
            overlayColor: climateUnselectedBgColor,
            gradient: gradient,
          );
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason:
                'etiqueta_clima_no_seleccionada ($emotionName): contraste mínimo ${ratio.toStringAsFixed(2)}:1, mínimo 4.5:1',
          );
        },
      );

      test(
        'selector_titulo ($emotionName): obsidiana vs blanco alpha 0.85 sobre gradiente >= 4.5:1',
        () {
          final ratio = _minContrastOnGradient(
            textColor: EmotionWeatherSelectorContrastConstants.selectorTitleTextColor,
            overlayColor: EmotionWeatherSelectorContrastConstants.selectorTitleBgColor,
            gradient: gradient,
          );
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason:
                'selector_titulo ($emotionName): contraste mínimo ${ratio.toStringAsFixed(2)}:1, mínimo 4.5:1',
          );
        },
      );
    }
  });

  group('Contraste WCAG 4.5:1 - Feather Dialog (Pluma de Sabiduría)', () {
    const dialogBgColor =
        SanctuaryJournalContrastConstants.featherDialogBgColor;
    const dialogTextColor =
        SanctuaryJournalContrastConstants.featherDialogTextColor;
    const dialogButtonBgColor =
        SanctuaryJournalContrastConstants.featherDialogButtonBgColor;
    const dialogButtonTextColor =
        SanctuaryJournalContrastConstants.featherDialogButtonTextColor;

    // El diálogo usa fondo sólido (pergaminoClaro), no gradiente.
    // Verificar textos y botón directamente contra este fondo.

    test('feather_dialog_nombre: obsidiana vs pergaminoClaro >= 4.5:1', () {
      final ratio = _contrastRatio(dialogTextColor, dialogBgColor);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason:
            'feather_dialog_nombre: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 4.5:1',
      );
    });

    test('feather_dialog_mensaje: obsidiana alpha 0.8 vs pergaminoClaro >= 4.5:1', () {
      final textWithAlpha = dialogTextColor.withValues(alpha: 0.8);
      // Texto con alpha sobre fondo sólido: componer y medir con Color.alphaBlend nativo
      final effectiveText = Color.alphaBlend(textWithAlpha, dialogBgColor);
      final ratio = _contrastRatio(effectiveText, dialogBgColor);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason:
            'feather_dialog_mensaje: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 4.5:1',
      );
    });

    test('feather_dialog_boton_cerrar: blanco vs obsidiana >= 4.5:1', () {
      final ratio = _contrastRatio(dialogButtonTextColor, dialogButtonBgColor);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason:
            'feather_dialog_boton_cerrar: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 4.5:1',
      );
    });

    // Verificar también que el icono decorativo (feather.color) NO se use como texto.
    // El test de arriba usa obsidiana para el botón, no feather.color.
  });

  group('Contraste WCAG 4.5:1 - PrivateCodexScreen (Códice Privado)', () {
    // Constantes desde PrivateCodexContrastConstants
    const vaultBgColor = PrivateCodexContrastConstants.vaultBgColor;
    const vaultTitleColor = PrivateCodexContrastConstants.vaultTitleColor;
    const vaultSubtitleColor = PrivateCodexContrastConstants.vaultSubtitleColor;
    const vaultSubtitleAlpha = PrivateCodexContrastConstants.vaultSubtitleAlpha;
    const unlockButtonBgColor = PrivateCodexContrastConstants.unlockButtonBgColor;
    const unlockButtonTextColor = PrivateCodexContrastConstants.unlockButtonTextColor;
    const backButtonColor = PrivateCodexContrastConstants.backButtonColor;
    const backButtonAlpha = PrivateCodexContrastConstants.backButtonAlpha;

    const headerBgColor = PrivateCodexContrastConstants.headerBgColor;
    const headerTitleColor = PrivateCodexContrastConstants.headerTitleColor;
    const headerIconColor = PrivateCodexContrastConstants.headerIconColor;
    const headerIconAlpha = PrivateCodexContrastConstants.headerIconAlpha;

    const monthSelectorBgColor = PrivateCodexContrastConstants.monthSelectorBgColor;
    const monthSelectorTextColor = PrivateCodexContrastConstants.monthSelectorTextColor;
    const monthSelectorBorderColor = PrivateCodexContrastConstants.monthSelectorBorderColor;
    const monthSelectorBorderAlpha = PrivateCodexContrastConstants.monthSelectorBorderAlpha;

    const filterChipSelectedBgColor = PrivateCodexContrastConstants.filterChipSelectedBgColor;
    const filterChipSelectedTextColor = PrivateCodexContrastConstants.filterChipSelectedTextColor;
    const filterChipUnselectedBgColor = PrivateCodexContrastConstants.filterChipUnselectedBgColor;
    const filterChipUnselectedTextColor = PrivateCodexContrastConstants.filterChipUnselectedTextColor;
    const filterChipUnselectedTextAlpha = PrivateCodexContrastConstants.filterChipUnselectedTextAlpha;

    const gridBgColor = PrivateCodexContrastConstants.gridBgColor;
    const dayCellEmptyBgColor = PrivateCodexContrastConstants.dayCellEmptyBgColor;
    const dayCellEmptyBgAlpha = PrivateCodexContrastConstants.dayCellEmptyBgAlpha;
    const dayCellEmptyTextColor = PrivateCodexContrastConstants.dayCellEmptyTextColor;
    const dayCellEmptyTextAlpha = PrivateCodexContrastConstants.dayCellEmptyTextAlpha;

    const parchmentBgColor = PrivateCodexContrastConstants.parchmentBgColor;
    const parchmentTitleColor = PrivateCodexContrastConstants.parchmentTitleColor;
    const parchmentTextColor = PrivateCodexContrastConstants.parchmentTextColor;
    const parchmentTextAlpha = PrivateCodexContrastConstants.parchmentTextAlpha;
    const parchmentDividerColor = PrivateCodexContrastConstants.parchmentDividerColor;
    const parchmentDividerAlpha = PrivateCodexContrastConstants.parchmentDividerAlpha;
    const closeButtonBgColor = PrivateCodexContrastConstants.closeButtonBgColor;
    const closeButtonTextColor = PrivateCodexContrastConstants.closeButtonTextColor;

    const errorIconColor = PrivateCodexContrastConstants.errorIconColor;
    const errorTextColor = PrivateCodexContrastConstants.errorTextColor;

    // Vista bloqueada - fondo sólido (obsidiana)
    test('privatecodex_vault_titulo: oro vs obsidiana >= 4.5:1', () {
      final ratio = _contrastRatio(vaultTitleColor, vaultBgColor);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason:
            'privatecodex_vault_titulo: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 4.5:1',
      );
    });

    test('privatecodex_vault_subtitulo: pergaminoClaro alpha 0.8 vs obsidiana >= 4.5:1', () {
      final textWithAlpha = vaultSubtitleColor.withValues(alpha: vaultSubtitleAlpha);
      final effectiveText = Color.alphaBlend(textWithAlpha, vaultBgColor);
      final ratio = _contrastRatio(effectiveText, vaultBgColor);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason:
            'privatecodex_vault_subtitulo: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 4.5:1',
      );
    });

    test('privatecodex_vault_boton_desbloquear: obsidiana vs oro >= 4.5:1', () {
      final ratio = _contrastRatio(unlockButtonTextColor, unlockButtonBgColor);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason:
            'privatecodex_vault_boton_desbloquear: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 4.5:1',
      );
    });

    test('privatecodex_vault_boton_volver: pergaminoClaro alpha 0.9 vs obsidiana >= 4.5:1', () {
      final textWithAlpha = backButtonColor.withValues(alpha: backButtonAlpha);
      final effectiveText = Color.alphaBlend(textWithAlpha, vaultBgColor);
      final ratio = _contrastRatio(effectiveText, vaultBgColor);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason:
            'privatecodex_vault_boton_volver: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 4.5:1',
      );
    });

    // Vista desbloqueada - Header
    test('privatecodex_header_titulo: oro vs obsidiana >= 4.5:1', () {
      final ratio = _contrastRatio(headerTitleColor, headerBgColor);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason:
            'privatecodex_header_titulo: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 4.5:1',
      );
    });

    test('privatecodex_header_icono_cerrar: pergaminoClaro alpha 0.9 vs obsidiana >= 3:1 (decorativo)', () {
      final iconWithAlpha = headerIconColor.withValues(alpha: headerIconAlpha);
      final effectiveIcon = Color.alphaBlend(iconWithAlpha, headerBgColor);
      final ratio = _contrastRatio(effectiveIcon, headerBgColor);
      expect(
        ratio,
        greaterThanOrEqualTo(3.0),
        reason:
            'privatecodex_header_icono_cerrar: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 3:1 (decorativo)',
      );
    });

    // Selector de mes/año
    test('privatecodex_month_selector_texto: obsidiana vs pergaminoClaro >= 4.5:1', () {
      final ratio = _contrastRatio(monthSelectorTextColor, monthSelectorBgColor);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason:
            'privatecodex_month_selector_texto: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 4.5:1',
      );
    });

    test('privatecodex_month_selector_borde: obsidiana alpha 0.2 vs pergaminoClaro >= 3:1 (decorativo)', () {
      final borderWithAlpha = monthSelectorBorderColor.withValues(alpha: monthSelectorBorderAlpha);
      final effectiveBorder = Color.alphaBlend(borderWithAlpha, monthSelectorBgColor);
      final ratio = _contrastRatio(effectiveBorder, monthSelectorBgColor);
      expect(
        ratio,
        greaterThanOrEqualTo(3.0),
        reason:
            'privatecodex_month_selector_borde: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 3:1 (decorativo)',
      );
    });

    // Filtro de climas (chips)
    test('privatecodex_filter_chip_selected: blanco vs jade >= 4.5:1', () {
      final ratio = _contrastRatio(filterChipSelectedTextColor, filterChipSelectedBgColor);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason:
            'privatecodex_filter_chip_selected: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 4.5:1',
      );
    });

    test('privatecodex_filter_chip_unselected: obsidiana alpha 0.8 vs pergaminoClaro >= 4.5:1', () {
      final textWithAlpha = filterChipUnselectedTextColor.withValues(alpha: filterChipUnselectedTextAlpha);
      final effectiveText = Color.alphaBlend(textWithAlpha, filterChipUnselectedBgColor);
      final ratio = _contrastRatio(effectiveText, filterChipUnselectedBgColor);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason:
            'privatecodex_filter_chip_unselected: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 4.5:1',
      );
    });

    // Cuadrícula del calendario - día vacío
    test('privatecodex_day_cell_empty: obsidiana alpha 0.5 vs piedra volcánica alpha 0.3 sobre pergamino >= 4.5:1', () {
      // Fondo: piedra volcánica alpha 0.3 sobre pergamino
      final bgWithAlpha = dayCellEmptyBgColor.withValues(alpha: dayCellEmptyBgAlpha);
      final effectiveBg = Color.alphaBlend(bgWithAlpha, gridBgColor);
      // Texto: obsidiana alpha 0.5
      final textWithAlpha = dayCellEmptyTextColor.withValues(alpha: dayCellEmptyTextAlpha);
      final effectiveText = Color.alphaBlend(textWithAlpha, effectiveBg);
      final ratio = _contrastRatio(effectiveText, effectiveBg);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason:
            'privatecodex_day_cell_empty: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 4.5:1',
      );
    });

    // Pergamino de detalle (CodexDayParchmentSheet)
    test('privatecodex_parchment_titulo: obsidiana vs pergaminoClaro >= 4.5:1', () {
      final ratio = _contrastRatio(parchmentTitleColor, parchmentBgColor);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason:
            'privatecodex_parchment_titulo: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 4.5:1',
      );
    });

    test('privatecodex_parchment_texto: obsidiana alpha 0.9 vs pergaminoClaro >= 4.5:1', () {
      final textWithAlpha = parchmentTextColor.withValues(alpha: parchmentTextAlpha);
      final effectiveText = Color.alphaBlend(textWithAlpha, parchmentBgColor);
      final ratio = _contrastRatio(effectiveText, parchmentBgColor);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason:
            'privatecodex_parchment_texto: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 4.5:1',
      );
    });

    test('privatecodex_parchment_divisor: obsidiana alpha 0.3 vs pergaminoClaro >= 3:1 (decorativo)', () {
      final dividerWithAlpha = parchmentDividerColor.withValues(alpha: parchmentDividerAlpha);
      final effectiveDivider = Color.alphaBlend(dividerWithAlpha, parchmentBgColor);
      final ratio = _contrastRatio(effectiveDivider, parchmentBgColor);
      expect(
        ratio,
        greaterThanOrEqualTo(3.0),
        reason:
            'privatecodex_parchment_divisor: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 3:1 (decorativo)',
      );
    });

    test('privatecodex_parchment_boton_cerrar: oro vs obsidiana >= 4.5:1', () {
      final ratio = _contrastRatio(closeButtonTextColor, closeButtonBgColor);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason:
            'privatecodex_parchment_boton_cerrar: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 4.5:1',
      );
    });

    // Estados error/carga
    test('privatecodex_error_icono: rojoGrana vs pergaminoClaro >= 3:1 (decorativo)', () {
      final ratio = _contrastRatio(errorIconColor, parchmentBgColor);
      expect(
        ratio,
        greaterThanOrEqualTo(3.0),
        reason:
            'privatecodex_error_icono: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 3:1 (decorativo)',
      );
    });

    test('privatecodex_error_texto: obsidiana vs pergaminoClaro >= 4.5:1', () {
      final ratio = _contrastRatio(errorTextColor, parchmentBgColor);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason:
            'privatecodex_error_texto: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 4.5:1',
      );
    });
  });
}