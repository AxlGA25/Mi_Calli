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
import 'package:mi_calli/features/1_sanctuary_journal/presentation/diary_history_screen.dart';
import 'package:mi_calli/features/1_sanctuary_journal/presentation/emotion_weather_selector.dart';
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

  group('Contraste WCAG 4.5:1 - Botón "Mis entradas" (SanctuaryJournalScreen)', () {
    const misEntradasBgColor =
        SanctuaryJournalContrastConstants.misEntradasBgColor;
    const misEntradasTextColor =
        SanctuaryJournalContrastConstants.misEntradasTextColor;

    // El botón "Mis entradas" está en la esquina superior derecha, sobre el gradiente
    // de emoción. Tiene fondo blanco alpha 0.9 y texto obsidiana.
    for (final emotion in PrehispanicEmotion.values) {
      final gradient = _gradientForEmotion(emotion);
      final emotionName = emotion.id;

      test(
        'boton_mis_entradas ($emotionName): obsidiana vs blanco alpha 0.9 sobre gradiente >= 4.5:1',
        () {
          final ratio = _minContrastOnGradient(
            textColor: misEntradasTextColor,
            overlayColor: misEntradasBgColor,
            gradient: gradient,
          );
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason:
                'boton_mis_entradas ($emotionName): contraste mínimo ${ratio.toStringAsFixed(2)}:1, mínimo 4.5:1',
          );
        },
      );
    }
  });

  group('Contraste WCAG 4.5:1 - DiaryHistoryScreen', () {
    // Constantes desde DiaryHistoryContrastConstants
    const appBarBgColor = DiaryHistoryContrastConstants.appBarBgColor;
    const appBarTitleColor = DiaryHistoryContrastConstants.appBarTitleColor;
    const appBarIconColor = DiaryHistoryContrastConstants.appBarIconColor;
    const entryCardBgColor = DiaryHistoryContrastConstants.entryCardBgColor;
    const entryDateTimeColor = DiaryHistoryContrastConstants.entryDateTimeColor;
    const entryEmotionDeityColor = DiaryHistoryContrastConstants.entryEmotionDeityColor;
    const entryEmotionLabelColor = DiaryHistoryContrastConstants.entryEmotionLabelColor;
    const entryEmotionLabelAlpha = DiaryHistoryContrastConstants.entryEmotionLabelAlpha;
    const entryFeatherNameColor = DiaryHistoryContrastConstants.entryFeatherNameColor;
    const entryFeatherMessageColor = DiaryHistoryContrastConstants.entryFeatherMessageColor;
    const entryFeatherMessageAlpha = DiaryHistoryContrastConstants.entryFeatherMessageAlpha;
    const entryDividerColor = DiaryHistoryContrastConstants.entryDividerColor;
    const entryDividerAlpha = DiaryHistoryContrastConstants.entryDividerAlpha;
    const entryContentColor = DiaryHistoryContrastConstants.entryContentColor;
    const entryContentAlpha = DiaryHistoryContrastConstants.entryContentAlpha;
    const emptyStateIconColor = DiaryHistoryContrastConstants.emptyStateIconColor;
    const emptyStateIconAlpha = DiaryHistoryContrastConstants.emptyStateIconAlpha;
    const emptyStateTextColor = DiaryHistoryContrastConstants.emptyStateTextColor;
    const emptyStateTextAlpha = DiaryHistoryContrastConstants.emptyStateTextAlpha;
    const errorIconColor = DiaryHistoryContrastConstants.errorIconColor;
    const errorTitleColor = DiaryHistoryContrastConstants.errorTitleColor;
    const errorMessageColor = DiaryHistoryContrastConstants.errorMessageColor;
    const errorMessageAlpha = DiaryHistoryContrastConstants.errorMessageAlpha;
    const loadingColor = DiaryHistoryContrastConstants.loadingColor;
    const featherErrorColor = DiaryHistoryContrastConstants.featherErrorColor;
    const featherErrorAlpha = DiaryHistoryContrastConstants.featherErrorAlpha;

    // AppBar - fondo sólido (pergaminoClaro)
    test('diaryhistory_appbar_titulo: obsidiana vs pergaminoClaro >= 4.5:1', () {
      final ratio = _contrastRatio(appBarTitleColor, appBarBgColor);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason:
            'diaryhistory_appbar_titulo: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 4.5:1',
      );
    });

    test('diaryhistory_appbar_icono: obsidiana vs pergaminoClaro >= 4.5:1', () {
      final ratio = _contrastRatio(appBarIconColor, appBarBgColor);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason:
            'diaryhistory_appbar_icono: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 4.5:1',
      );
    });

    // Tarjeta de entrada - fondo blanco sólido
    test('diaryhistory_tarjeta_fecha: obsidiana vs blanco >= 4.5:1', () {
      final ratio = _contrastRatio(entryDateTimeColor, entryCardBgColor);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason:
            'diaryhistory_tarjeta_fecha: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 4.5:1',
      );
    });

    test('diaryhistory_tarjeta_emocion_deidad: obsidiana vs blanco >= 4.5:1', () {
      final ratio = _contrastRatio(entryEmotionDeityColor, entryCardBgColor);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason:
            'diaryhistory_tarjeta_emocion_deidad: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 4.5:1',
      );
    });

    test('diaryhistory_tarjeta_emocion_label: obsidiana alpha 0.6 vs blanco >= 4.5:1', () {
      final textWithAlpha = entryEmotionLabelColor.withValues(alpha: entryEmotionLabelAlpha);
      final effectiveText = Color.alphaBlend(textWithAlpha, entryCardBgColor);
      final ratio = _contrastRatio(effectiveText, entryCardBgColor);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason:
            'diaryhistory_tarjeta_emocion_label: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 4.5:1',
      );
    });

    test('diaryhistory_tarjeta_pluma_nombre: obsidiana vs blanco >= 4.5:1', () {
      final ratio = _contrastRatio(entryFeatherNameColor, entryCardBgColor);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason:
            'diaryhistory_tarjeta_pluma_nombre: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 4.5:1',
      );
    });

    test('diaryhistory_tarjeta_pluma_mensaje: obsidiana alpha 0.7 vs blanco >= 4.5:1', () {
      final textWithAlpha = entryFeatherMessageColor.withValues(alpha: entryFeatherMessageAlpha);
      final effectiveText = Color.alphaBlend(textWithAlpha, entryCardBgColor);
      final ratio = _contrastRatio(effectiveText, entryCardBgColor);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason:
            'diaryhistory_tarjeta_pluma_mensaje: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 4.5:1',
      );
    });

    test('diaryhistory_tarjeta_divisor: obsidiana alpha 0.1 vs blanco >= 4.5:1 (decorativo)', () {
      // El divisor es decorativo, pero verificamos que no sea invisible
      final dividerWithAlpha = entryDividerColor.withValues(alpha: entryDividerAlpha);
      final effectiveDivider = Color.alphaBlend(dividerWithAlpha, entryCardBgColor);
      final ratio = _contrastRatio(effectiveDivider, entryCardBgColor);
      // Divisor decorativo - mínimo 3:1 para elementos UI no textuales
      expect(
        ratio,
        greaterThanOrEqualTo(3.0),
        reason:
            'diaryhistory_tarjeta_divisor: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 3:1 (decorativo)',
      );
    });

    test('diaryhistory_tarjeta_contenido: obsidiana alpha 0.85 vs blanco >= 4.5:1', () {
      final textWithAlpha = entryContentColor.withValues(alpha: entryContentAlpha);
      final effectiveText = Color.alphaBlend(textWithAlpha, entryCardBgColor);
      final ratio = _contrastRatio(effectiveText, entryCardBgColor);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason:
            'diaryhistory_tarjeta_contenido: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 4.5:1',
      );
    });

    // Estado vacío - fondo pergaminoClaro (appBarBgColor)
    test('diaryhistory_vacio_icono: obsidiana alpha 0.4 vs pergaminoClaro >= 4.5:1 (decorativo)', () {
      final iconWithAlpha = emptyStateIconColor.withValues(alpha: emptyStateIconAlpha);
      final effectiveIcon = Color.alphaBlend(iconWithAlpha, appBarBgColor);
      final ratio = _contrastRatio(effectiveIcon, appBarBgColor);
      // Icono decorativo - mínimo 3:1
      expect(
        ratio,
        greaterThanOrEqualTo(3.0),
        reason:
            'diaryhistory_vacio_icono: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 3:1 (decorativo)',
      );
    });

    test('diaryhistory_vacio_texto: obsidiana alpha 0.8 vs pergaminoClaro >= 4.5:1', () {
      final textWithAlpha = emptyStateTextColor.withValues(alpha: emptyStateTextAlpha);
      final effectiveText = Color.alphaBlend(textWithAlpha, appBarBgColor);
      final ratio = _contrastRatio(effectiveText, appBarBgColor);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason:
            'diaryhistory_vacio_texto: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 4.5:1',
      );
    });

    // Estado error
    test('diaryhistory_error_icono: rojoGrana vs pergaminoClaro >= 4.5:1 (decorativo)', () {
      final ratio = _contrastRatio(errorIconColor, appBarBgColor);
      expect(
        ratio,
        greaterThanOrEqualTo(3.0),
        reason:
            'diaryhistory_error_icono: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 3:1 (decorativo)',
      );
    });

    test('diaryhistory_error_titulo: obsidiana vs pergaminoClaro >= 4.5:1', () {
      final ratio = _contrastRatio(errorTitleColor, appBarBgColor);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason:
            'diaryhistory_error_titulo: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 4.5:1',
      );
    });

    test('diaryhistory_error_mensaje: obsidiana alpha 0.6 vs pergaminoClaro >= 4.5:1', () {
      final textWithAlpha = errorMessageColor.withValues(alpha: errorMessageAlpha);
      final effectiveText = Color.alphaBlend(textWithAlpha, appBarBgColor);
      final ratio = _contrastRatio(effectiveText, appBarBgColor);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason:
            'diaryhistory_error_mensaje: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 4.5:1',
      );
    });

    // Loading
    test('diaryhistory_loading: obsidiana vs pergaminoClaro >= 4.5:1 (decorativo)', () {
      final ratio = _contrastRatio(loadingColor, appBarBgColor);
      expect(
        ratio,
        greaterThanOrEqualTo(3.0),
        reason:
            'diaryhistory_loading: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 3:1 (decorativo)',
      );
    });

    // Feather error
    test('diaryhistory_feather_error: obsidiana alpha 0.5 vs blanco >= 4.5:1', () {
      final textWithAlpha = featherErrorColor.withValues(alpha: featherErrorAlpha);
      final effectiveText = Color.alphaBlend(textWithAlpha, entryCardBgColor);
      final ratio = _contrastRatio(effectiveText, entryCardBgColor);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason:
            'diaryhistory_feather_error: contraste ${ratio.toStringAsFixed(2)}:1, mínimo 4.5:1',
      );
    });
  });
}