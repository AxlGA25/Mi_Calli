// Diálogo del Tonalpohualli (Constelación de Venus).
//
// Pergamino astronómico nocturno con la lectura completa.
// Accesible, escalable al 200%, con Semantics en español.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mi_calli/core/constants/app_colors.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/prehispanic_emotion.dart';
import 'package:mi_calli/features/2_gamification/models/tonalpohualli_models.dart';

/// Diálogo estilizado como pergamino/códice astronómico nocturno
/// que muestra la lectura del Tonalpohualli completa.
class TonalpohualliScrollDialog extends StatelessWidget {
  const TonalpohualliScrollDialog({
    super.key,
    required this.reading,
    this.onClose,
  });

  final WeeklyAstralReading reading;
  final VoidCallback? onClose;

  /// Muestra el diálogo del Tonalpohualli.
  static Future<void> show(
    BuildContext context, {
    required WeeklyAstralReading reading,
    VoidCallback? onClose,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => TonalpohualliScrollDialog(
        reading: reading,
        onClose: onClose,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rulingEmotion = reading.rulingEmotion;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Semantics(
        label: 'Lectura del Tonalpohualli, Constelación de Venus',
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.pergaminoClaro,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.oro, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.obsidiana.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Encabezado con Constelación de Venus y título
              _buildHeader(context, rulingEmotion),

              // Contenido scrolleable (soporta 200% text scaling)
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Resumen visual: totalEntries y nourishedSproutsCount
                      _buildSummaryRow(context),

                      const SizedBox(height: 20),

                      // Los 3 párrafos de la lectura
                      _buildParagraph(
                        context,
                        reading.openingParagraph,
                        'Apertura del Tonalpohualli',
                      ),
                      const SizedBox(height: 16),
                      _buildParagraph(
                        context,
                        reading.bodyParagraph,
                        'Cuerpo de la lectura astral',
                      ),
                      const SizedBox(height: 16),
                      _buildParagraph(
                        context,
                        reading.venusOmenParagraph,
                        'Augurio de Venus, cierre de la lectura',
                      ),
                    ],
                  ),
                ),
              ),

              // Botón de cierre
              _buildCloseButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, PrehispanicEmotion rulingEmotion) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.obsidiana.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.oro, width: 1.5),
        ),
      ),
      child: Column(
        children: [
          // Icono de Constelación de Venus
          Semantics(
            label: 'Constelación de Venus, símbolo de Quetzalcóatl',
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.oro, width: 2),
                gradient: RadialGradient(
                  colors: [
                    AppColors.oro.withValues(alpha: 0.3),
                    AppColors.obsidiana,
                  ],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.star_rounded,
                  color: AppColors.oro,
                  size: 28,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Título místico
          Text(
            reading.mysticTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.oro,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
            semanticsLabel: 'Título de la lectura: ${reading.mysticTitle}',
          ),

          const SizedBox(height: 4),

          // Nombre de la deidad regente
          Text(
            rulingEmotion.deity,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.oro.withValues(alpha: 0.8),
                  fontStyle: FontStyle.italic,
                ),
            semanticsLabel: 'Astro Regente: ${rulingEmotion.deity}',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSummaryItem(
          context,
          icon: Icons.menu_book_rounded,
          label: 'Desahogos',
          value: '${reading.totalEntries}',
          semanticLabel: '${reading.totalEntries} entradas de diario esta semana',
        ),
        const SizedBox(width: 24),
        _buildSummaryItem(
          context,
          icon: Icons.spa_rounded,
          label: 'Brotes nutridos',
          value: '${reading.nourishedSproutsCount}',
          semanticLabel: '${reading.nourishedSproutsCount} semillas regadas en la chinampa',
        ),
      ],
    );
  }

  Widget _buildSummaryItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String semanticLabel,
  }) {
    return Semantics(
      label: semanticLabel,
      child: Column(
        children: [
          Icon(icon, color: AppColors.jade, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.obsidiana,
                  fontWeight: FontWeight.w800,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.obsidiana.withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildParagraph(
    BuildContext context,
    String text,
    String semanticLabel,
  ) {
    return Semantics(
      label: semanticLabel,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.obsidiana,
              height: 1.6,
              letterSpacing: 0.2,
            ),
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Cerrar lectura del Tonalpohualli',
      hint: 'Toca para cerrar el diálogo y volver',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(bottom: 16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
              onClose?.call();
            },
            borderRadius: BorderRadius.circular(12),
            splashColor: AppColors.oro.withValues(alpha: 0.2),
            highlightColor: AppColors.oro.withValues(alpha: 0.1),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.jade, AppColors.jade.withValues(alpha: 0.8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.oro, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.jade.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Cerrar lectura',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}