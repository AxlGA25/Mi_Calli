// DiaryHistoryScreen - Pantalla provisional de historial de entradas (Tarea 2.5).
//
// IMPORTANTE: Esta pantalla es PROVISIONAL y se eliminará al construir
// PrivateCodexScreen en la Tarea 4.4 (Fase 4).
//
// - AppBar con título "Mis entradas" y botón de regreso (Navigator.pop)
// - Lista de entradas en orden cronológico inverso (más recientes primero)
// - Cada tarjeta muestra: fecha/hora local, clima emocional (nombre + deidad + color),
//   Pluma de Sabiduría (nombre + mensaje) y contenido de la entrada
// - Estado vacío empático si no hay entradas
// - Accesibilidad: Semantics, área táctil 48x48, soporte escalado 200% sin overflow
// - Contraste WCAG >= 4.5:1 en todos los textos

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:mi_calli/core/constants/app_colors.dart';
import 'package:mi_calli/core/database/asset_loader_service.dart';
import 'package:mi_calli/features/1_sanctuary_journal/constants/sanctuary_texts.dart';
import 'package:mi_calli/features/1_sanctuary_journal/data/diary_repository_provider.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/diary_entry.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/prehispanic_emotion.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/wisdom_feather.dart';

/// Constantes de contraste para DiaryHistoryScreen (Tarea 2.5).
///
/// Centraliza todos los colores usados en la pantalla para permitir
/// verificación de contraste WCAG 4.5:1 en test/contrast_test.dart.
class DiaryHistoryContrastConstants {
  // AppBar
  static const Color appBarBgColor = AppColors.pergaminoClaro;
  static const Color appBarTitleColor = AppColors.obsidiana;
  static const Color appBarIconColor = AppColors.obsidiana;

  // Tarjeta de entrada (_EntryCard)
  static const Color entryCardBgColor = Colors.white;
  static const Color entryCardBorderColor = AppColors.obsidiana;
  static const double entryCardBorderAlpha = 0.1;
  static const Color entryCardShadowColor = AppColors.obsidiana;
  static const double entryCardShadowAlpha = 0.05;

  // Textos dentro de la tarjeta
  static const Color entryDateTimeColor = AppColors.obsidiana;
  static const Color entryEmotionDeityColor = AppColors.obsidiana;
  static const Color entryEmotionLabelColor = AppColors.obsidiana;
  static const double entryEmotionLabelAlpha = 0.6;
  static const Color entryFeatherNameColor = AppColors.obsidiana;
  static const Color entryFeatherMessageColor = AppColors.obsidiana;
  static const double entryFeatherMessageAlpha = 0.7;
  static const Color entryDividerColor = AppColors.obsidiana;
  static const double entryDividerAlpha = 0.5; // Aumentado para WCAG 3:1 decorativo en blanco
  static const Color entryContentColor = AppColors.obsidiana;
  static const double entryContentAlpha = 0.85;

  // Indicador de color de emoción (círculo)
  static const Color emotionIndicatorColor = AppColors.obsidiana; // placeholder, se sobrescribe por emoción

  // Estados vacío/error
  static const Color emptyStateIconColor = AppColors.obsidiana;
  static const double emptyStateIconAlpha = 0.7; // Para WCAG 3:1 decorativo en pergaminoClaro
  static const Color emptyStateTextColor = AppColors.obsidiana;
  static const double emptyStateTextAlpha = 0.8;
  // Error icon: rojo más oscuro para WCAG 3:1 en pergaminoClaro
  static const Color errorIconColor = Color(0xFFB71C1C); // Darker red (Material Red 900)
  static const Color errorTitleColor = AppColors.obsidiana;
  static const Color errorMessageColor = AppColors.obsidiana;
  static const double errorMessageAlpha = 0.6;

  // Loading
  static const Color loadingColor = AppColors.obsidiana;

  // Feather error
  static const Color featherErrorColor = AppColors.obsidiana;
  static const double featherErrorAlpha = 0.8; // Aumentado para WCAG 4.5:1 texto en blanco

  DiaryHistoryContrastConstants._();
}

/// Pantalla PROVISIONAL de historial de entradas del diario (Tarea 2.5).
///
/// Se eliminará al implementar PrivateCodexScreen en la Tarea 4.4.
/// Muestra todas las entradas guardadas ordenadas de la más reciente a la más antigua.
class DiaryHistoryScreen extends ConsumerWidget {
  const DiaryHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Provider que carga todas las entradas de forma reactiva
    final entriesAsync = ref.watch(_diaryHistoryEntriesProvider);

    return Scaffold(
      backgroundColor: DiaryHistoryContrastConstants.appBarBgColor,
      appBar: AppBar(
        title: Text(
          'Mis entradas',
          style: TextStyle(
            color: DiaryHistoryContrastConstants.appBarTitleColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: DiaryHistoryContrastConstants.appBarBgColor,
        elevation: 0,
        leading: Semantics(
          label: 'Regresar al diario',
          button: true,
          child: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: DiaryHistoryContrastConstants.appBarIconColor,
              size: 28,
            ),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Regresar',
          ),
        ),
        iconTheme: IconThemeData(color: DiaryHistoryContrastConstants.appBarIconColor),
      ),
      body: entriesAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return _buildEmptyState();
          }
          return _buildEntriesList(entries);
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: DiaryHistoryContrastConstants.loadingColor),
        ),
        error: (error, stackTrace) => _buildErrorState(error.toString()),
      ),
    );
  }

  /// Estado vacío: mensaje cálido y empático cuando no hay entradas.
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: 400,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono decorativo
              Icon(
                Icons.book_outlined,
                size: 80,
                color: DiaryHistoryContrastConstants.emptyStateIconColor
                    .withValues(alpha: DiaryHistoryContrastConstants.emptyStateIconAlpha),
              ),
              const SizedBox(height: 24),
              // Mensaje empático
              Text(
                SanctuaryTexts.historialVacioMensaje,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.5,
                  color: DiaryHistoryContrastConstants.emptyStateTextColor
                      .withValues(alpha: DiaryHistoryContrastConstants.emptyStateTextAlpha),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Estado de error (poco probable, pero por si acaso).
  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: DiaryHistoryContrastConstants.errorIconColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No pudimos cargar tus entradas',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: DiaryHistoryContrastConstants.errorTitleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: DiaryHistoryContrastConstants.errorMessageColor
                  .withValues(alpha: DiaryHistoryContrastConstants.errorMessageAlpha),
            ),
          ),
        ],
      ),
    );
  }

  /// Lista de entradas con tarjetas.
  Widget _buildEntriesList(List<DiaryEntry> entries) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _EntryCard(entry: entry);
      },
    );
  }
}

/// Provider para cargar todas las entradas de forma reactiva.
///
/// Usa diaryRepositoryProvider y expone un Future con lista de DiaryEntry.
/// Con autoDispose, se recarga siempre al abrir DiaryHistoryScreen (evita caché
/// al navegar ida y vuelta desde SanctuaryJournalScreen).
final _diaryHistoryEntriesProvider =
    FutureProvider.autoDispose<List<DiaryEntry>>((ref) async {
  final repository = ref.watch(diaryRepositoryProvider);
  return repository.getAllEntries();
});

/// Tarjeta individual de una entrada en el historial.
class _EntryCard extends ConsumerWidget {
  const _EntryCard({required this.entry});

  final DiaryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtener información de la emoción
    final emotion = entry.emotion;
    final emotionColor = _getEmotionColor(emotion);

    // Obtener la pluma asociada (usando featherId de la entrada)
    final featherAsync = ref.watch(_featherByIdProvider(entry.featherId));

    return Semantics(
      label: 'Entrada del ${_formatDateTime(entry.createdAt.toLocal())}, '
          'clima ${emotion.deity}, pluma ${entry.featherId}',
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DiaryHistoryContrastConstants.entryCardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: DiaryHistoryContrastConstants.entryCardBorderColor
                .withValues(alpha: DiaryHistoryContrastConstants.entryCardBorderAlpha),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: DiaryHistoryContrastConstants.entryCardShadowColor
                  .withValues(alpha: DiaryHistoryContrastConstants.entryCardShadowAlpha),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado: fecha + indicador de clima
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Indicador visual de color del clima (círculo)
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: emotionColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                // Fecha y hora local formateada
                Expanded(
                  child: Text(
                    _formatDateTime(entry.createdAt.toLocal()),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: DiaryHistoryContrastConstants.entryDateTimeColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Clima emocional: nombre + deidad
            Row(
              children: [
                Flexible(
                  child: Text(
                    emotion.deity,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: DiaryHistoryContrastConstants.entryEmotionDeityColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '(${emotion.label})',
                    style: TextStyle(
                      fontSize: 13,
                      color: DiaryHistoryContrastConstants.entryEmotionLabelColor
                          .withValues(alpha: DiaryHistoryContrastConstants.entryEmotionLabelAlpha),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Pluma de Sabiduría: nombre y mensaje
            featherAsync.when(
              data: (feather) => _buildFeatherInfo(feather),
              loading: () => SizedBox(
                height: 20,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: DiaryHistoryContrastConstants.loadingColor,
                    ),
                  ),
                ),
              ),
              error: (_, __) => _buildFeatherError(),
            ),
            const SizedBox(height: 12),
            // Separador sutil
            Divider(
              color: DiaryHistoryContrastConstants.entryDividerColor
                  .withValues(alpha: DiaryHistoryContrastConstants.entryDividerAlpha),
              height: 1,
            ),
            const SizedBox(height: 12),
            // Contenido de la entrada
            Text(
              entry.content,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: DiaryHistoryContrastConstants.entryContentColor
                    .withValues(alpha: DiaryHistoryContrastConstants.entryContentAlpha),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatherInfo(WisdomFeather feather) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          feather.name,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: DiaryHistoryContrastConstants.entryFeatherNameColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          feather.message,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: DiaryHistoryContrastConstants.entryFeatherMessageColor
                .withValues(alpha: DiaryHistoryContrastConstants.entryFeatherMessageAlpha),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatherError() {
    return Text(
      'Pluma de Sabiduría no disponible',
      style: TextStyle(
        fontSize: 13,
        color: DiaryHistoryContrastConstants.featherErrorColor
            .withValues(alpha: DiaryHistoryContrastConstants.featherErrorAlpha),
        fontStyle: FontStyle.italic,
      ),
    );
  }

  /// Formatea la fecha y hora local de forma legible.
  ///
  /// Si los datos de locale no están inicializados (p. ej., widget montado
  /// aisladamente en test sin llamar a initializeDateFormatting), cae a un
  /// formato ISO simple para evitar LocaleDataException.
  String _formatDateTime(DateTime dateTime) {
    // Convertir a hora local UNA SOLA VEZ al inicio
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDate = DateTime(local.year, local.month, local.day);
    // CONTEXT.md prohíbe Duration(days: 1) para límites de día local
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    // Formatear hora (siempre 24h) usando 'local'
    String timeStr;
    try {
      final timeFormat = DateFormat('HH:mm', 'es_MX');
      timeStr = timeFormat.format(local);
    } catch (_) {
      // Fallback si locale no inicializado
      timeStr = local.toString().substring(11, 16); // "HH:mm"
    }

    if (entryDate == today) {
      return 'Hoy, $timeStr';
    } else if (entryDate == yesterday) {
      return 'Ayer, $timeStr';
    } else {
      String dateStr;
      try {
        final dateFormat = DateFormat('d \'de\' MMMM', 'es_MX');
        dateStr = dateFormat.format(local);
      } catch (_) {
        // Fallback: dd/MM/yyyy
        final d = local.day.toString().padLeft(2, '0');
        final m = local.month.toString().padLeft(2, '0');
        final y = local.year;
        dateStr = '$d/$m/$y';
      }
      return '$dateStr, $timeStr';
    }
  }

  /// Obtiene el color asociado a la emoción (usando AppColors).
  Color _getEmotionColor(PrehispanicEmotion emotion) {
    return switch (emotion) {
      PrehispanicEmotion.tlalocLluvia => AppColors.jade,
      PrehispanicEmotion.tonatiuhSol => AppColors.oro,
      PrehispanicEmotion.ehecatlViento => AppColors.turquesa,
      PrehispanicEmotion.mixcoatlTormenta => AppColors.rojoGrana,
      PrehispanicEmotion.metztliNoche => const Color(0xFF9D4EDD), // Violeta Metztli
    };
  }
}

/// Provider para obtener una pluma por su featherId.
final _featherByIdProvider = FutureProvider.family<WisdomFeather, String>((ref, featherId) async {
  final feathers = await AssetLoaderService.instance.loadFeathers();
  try {
    return feathers.firstWhere((f) => f.featherId == featherId);
  } on StateError {
    // Fallback: buscar por emotionId si no se encuentra por featherId
    // (para compatibilidad con entradas antiguas)
    // Como no tenemos el emotionId aquí, lanzamos error
    throw AssetLoadException('Pluma no encontrada: $featherId');
  }
});