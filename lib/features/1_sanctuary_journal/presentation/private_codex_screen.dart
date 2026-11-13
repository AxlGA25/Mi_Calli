// PrivateCodexScreen - Códice Privado con autenticación biométrica y Calendario Agrícola (Tarea 4.4).
//
// Reemplaza a DiaryHistoryScreen (provisional) con una interfaz diegética:
// - Barrera biométrica/PIN mediante BiometricAuthInterface (inyectable para tests)
// - Vista bloqueada: bóveda de obsidiana y oro con botón "Desbloquear Códice Privado"
// - Vista desbloqueada: Calendario Agrícola mensual (GridView) con filtro por 5 climas
// - Cada día muestra insignia climática/agrícola o parcela en descanso
// - Al tocar día con entradas: CodexDayParchmentSheet con detalle completo
//
// Respeta: Semantics, área táctil 48x48, escalado 200% sin overflow, contraste WCAG.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';

import 'package:mi_calli/core/constants/app_colors.dart';
import 'package:mi_calli/core/database/asset_loader_service.dart';
import 'package:mi_calli/core/security/biometric_auth_interface.dart';
import 'package:mi_calli/core/security/biometric_vault_service.dart';
import 'package:mi_calli/features/1_sanctuary_journal/data/diary_repository_provider.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/diary_entry.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/prehispanic_emotion.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/wisdom_feather.dart';
import 'package:mi_calli/features/2_gamification/models/seed_catalog_item.dart';

/// Constantes de contraste para PrivateCodexScreen (Tarea 4.4).
///
/// Centraliza todos los colores usados en la pantalla para permitir
/// verificación de contraste WCAG 4.5:1 en tests.
class PrivateCodexContrastConstants {
  // Vista bloqueada (bóveda)
  static const Color vaultBgColor = AppColors.obsidiana;
  static const Color vaultTitleColor = AppColors.oro;
  static const Color vaultSubtitleColor = AppColors.pergaminoClaro;
  static const double vaultSubtitleAlpha = 0.8;
  static const Color unlockButtonBgColor = AppColors.oro;
  static const Color unlockButtonTextColor = AppColors.obsidiana;
  static const Color backButtonColor = AppColors.pergaminoClaro;
  static const double backButtonAlpha = 0.9;

  // Vista desbloqueada - Header
  static const Color headerBgColor = AppColors.obsidiana;
  static const Color headerTitleColor = AppColors.oro;
  static const Color headerIconColor = AppColors.pergaminoClaro;
  static const double headerIconAlpha = 0.9;

  // Selector de mes/año
  static const Color monthSelectorBgColor = AppColors.pergaminoClaro;
  static const Color monthSelectorTextColor = AppColors.obsidiana;
  static const Color monthSelectorBorderColor = AppColors.obsidiana;
  static const double monthSelectorBorderAlpha = 0.5;

  // Filtro de climas
  static const Color filterChipSelectedBgColor = AppColors.jade;
  static const Color filterChipSelectedTextColor = AppColors.obsidiana; // Negro sobre jade para contraste WCAG 4.5:1
  static const Color filterChipUnselectedBgColor = AppColors.pergaminoClaro;
  static const Color filterChipUnselectedTextColor = AppColors.obsidiana;
  static const double filterChipUnselectedTextAlpha = 0.8;
  static const Color filterChipBorderColor = AppColors.obsidiana;
  static const double filterChipBorderAlpha = 0.2;

  // Cuadrícula del calendario
  static const Color gridBgColor = Color(0xFFFDFBF7); // Pergamino muy claro
  static const Color dayCellEmptyBgColor = Color(0xFF8B7D6B); // Piedra volcánica tenue
  static const double dayCellEmptyBgAlpha = 0.3;
  static const Color dayCellEmptyTextColor = AppColors.obsidiana;
  static const double dayCellEmptyTextAlpha = 0.8; // Aumentado para WCAG 4.5:1
  static const Color dayCellBorderColor = AppColors.obsidiana;
  static const double dayCellBorderAlpha = 0.15;

  // Badge de emoción en celda
  static const double badgeBackgroundAlpha = 0.25;

  // Pergamino de detalle (CodexDayParchmentSheet)
  static const Color parchmentBgColor = AppColors.pergaminoClaro;
  static const Color parchmentTitleColor = AppColors.obsidiana;
  static const Color parchmentTextColor = AppColors.obsidiana;
  static const double parchmentTextAlpha = 0.9;
  static const Color parchmentDividerColor = AppColors.obsidiana;
  static const double parchmentDividerAlpha = 0.5; // Aumentado para WCAG 3:1 decorativo
  static const double parchmentBadgeBgAlpha = 0.2;
  static const Color closeButtonBgColor = AppColors.obsidiana;
  static const Color closeButtonTextColor = AppColors.oro;

  // Estados vacío/error/carga
  static const Color loadingColor = AppColors.oro;
  static const Color errorIconColor = Color(0xFFB71C1C);
  static const Color errorTextColor = AppColors.obsidiana;

  PrivateCodexContrastConstants._();
}

/// Claves globales para testing (Tarea 4.4).
final GlobalKey privateCodexScreenKey = GlobalKey(debugLabel: 'privateCodexScreen');
final ValueKey<String> privateCodexUnlockButtonKey = const ValueKey<String>('private_codex_unlock_button');
final ValueKey<String> privateCodexBackButtonKey = const ValueKey<String>('private_codex_back_button');
final ValueKey<String> privateCodexMonthSelectorKey = const ValueKey<String>('private_codex_month_selector');
final ValueKey<String> privateCodexPreviousMonthKey = const ValueKey<String>('private_codex_previous_month');
final ValueKey<String> privateCodexNextMonthKey = const ValueKey<String>('private_codex_next_month');
final ValueKey<String> privateCodexFilterKey = const ValueKey<String>('private_codex_filter');
final ValueKey<String> privateCodexGridKey = const ValueKey<String>('private_codex_grid');
final ValueKey<String> privateCodexParchmentKey = const ValueKey<String>('private_codex_parchment');

/// Filtro de emociones para el Calendario Agrícola.
enum CodexEmotionFilter {
  all('Todos'),
  tlaloc('Tláloc'),
  tonatiuh('Tonatiuh'),
  ehecatl('Ehécatl'),
  mixcoatl('Mixcóatl'),
  metztli('Metztli');

  const CodexEmotionFilter(this.label);
  final String label;

  PrehispanicEmotion? get emotion => switch (this) {
    CodexEmotionFilter.tlaloc => PrehispanicEmotion.tlalocLluvia,
    CodexEmotionFilter.tonatiuh => PrehispanicEmotion.tonatiuhSol,
    CodexEmotionFilter.ehecatl => PrehispanicEmotion.ehecatlViento,
    CodexEmotionFilter.mixcoatl => PrehispanicEmotion.mixcoatlTormenta,
    CodexEmotionFilter.metztli => PrehispanicEmotion.metztliNoche,
    CodexEmotionFilter.all => null,
  };
}

/// Estado de autenticación local para PrivateCodexScreen.
class _PrivateCodexAuthState {
  final bool isAuthenticated;
  final bool isAuthenticating;
  final String? authError;

  const _PrivateCodexAuthState({
    required this.isAuthenticated,
    required this.isAuthenticating,
    this.authError,
  });

  _PrivateCodexAuthState copyWith({
    bool? isAuthenticated,
    bool? isAuthenticating,
    String? authError,
  }) {
    return _PrivateCodexAuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
      authError: authError ?? this.authError,
    );
  }
}

// ============================================================================
// PROVIDERS DE NIVEL SUPERIOR (Top-level providers)
// ============================================================================

/// Provider para el estado de autenticación local de PrivateCodexScreen.
/// Se inicializa con [initiallyAuthenticatedForTest] para tests.
final privateCodexAuthStateProvider = StateProvider.family<_PrivateCodexAuthState, bool>((ref, initiallyAuthenticatedForTest) {
  return _PrivateCodexAuthState(
    isAuthenticated: initiallyAuthenticatedForTest,
    isAuthenticating: false,
    authError: null,
  );
});

/// Provider para mes/año actual del calendario.
final privateCodexCurrentMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

/// Provider para filtro de emoción seleccionado.
final privateCodexEmotionFilterProvider = StateProvider<CodexEmotionFilter>((ref) {
  return CodexEmotionFilter.all;
});

/// Provider para las entradas del mes actual (reactivo a mes y filtro).
final privateCodexMonthEntriesProvider = FutureProvider.autoDispose<Map<int, List<DiaryEntry>>>((ref) async {
  final currentMonth = ref.watch(privateCodexCurrentMonthProvider);
  final filter = ref.watch(privateCodexEmotionFilterProvider);
  final repository = ref.watch(diaryRepositoryProvider);

  final startOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
  final endOfMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0, 23, 59, 59, 999);

  final entries = await repository.getEntriesByDateRange(start: startOfMonth, end: endOfMonth);

  // Agrupar por día del mes
  final Map<int, List<DiaryEntry>> entriesByDay = {};
  for (final entry in entries) {
    final localDay = entry.createdAt.toLocal().day;

    // Aplicar filtro de emoción si no es "Todos"
    if (filter.emotion != null && entry.emotion != filter.emotion) {
      continue;
    }

    entriesByDay.putIfAbsent(localDay, () => []).add(entry);
  }

  return entriesByDay;
});

/// Provider para obtener una pluma por su featherId (para el pergamino).
final _featherByIdProvider = FutureProvider.family<WisdomFeather, String>((ref, featherId) async {
  final feathers = await AssetLoaderService.instance.loadFeathers();
  try {
    return feathers.firstWhere((f) => f.featherId == featherId);
  } on StateError {
    throw AssetLoadException('Pluma no encontrada: $featherId');
  }
});

/// Provider para obtener una semilla por su seedId (para el pergamino).
final _seedByIdProvider = FutureProvider.family<SeedCatalogItem, String>((ref, seedId) async {
  final seeds = await AssetLoaderService.instance.loadSeedsCatalog();
  try {
    return seeds.firstWhere((s) => s.seedId == seedId);
  } on StateError {
    throw AssetLoadException('Semilla no encontrada: $seedId');
  }
});

/// Pantalla principal del Códice Privado (Tarea 4.4).
///
/// Implementa:
/// 1. Barrera biométrica/PIN con BiometricAuthInterface (inyectable para tests)
/// 2. Vista bloqueada: bóveda de obsidiana/oro + botón desbloquear + botón volver
/// 3. Vista desbloqueada: Calendario Agrícola con selector mes/año, filtro 5 climas,
///    GridView de días con insignias climáticas/agrícolas
/// 4. CodexDayParchmentSheet al tocar día con entradas
///
/// Parámetros para testing:
/// - [biometricAuthOverride]: Inyecta implementación mock de BiometricAuthInterface.
/// - [initiallyAuthenticatedForTest]: Si true, salta autenticación y muestra contenido directamente.
class PrivateCodexScreen extends ConsumerWidget {
  const PrivateCodexScreen({
    super.key,
    this.biometricAuthOverride,
    this.initiallyAuthenticatedForTest = false,
  });

  /// Implementación de autenticación biométrica para testing (inyectable).
  /// Si es null, usa BiometricVaultService.instance (producción).
  final BiometricAuthInterface? biometricAuthOverride;

  /// Si true, omite la autenticación biométrica y muestra directamente el contenido desbloqueado.
  /// Solo para tests de integración que verifican la UI desbloqueada.
  final bool initiallyAuthenticatedForTest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      key: privateCodexScreenKey,
      backgroundColor: PrivateCodexContrastConstants.vaultBgColor,
      body: Consumer(
        builder: (context, ref, child) {
          final authState = ref.watch(privateCodexAuthStateProvider(initiallyAuthenticatedForTest));

          if (!authState.isAuthenticated) {
            return _buildLockedVaultView(context, ref);
          }

          return _buildUnlockedCalendarView(context, ref);
        },
      ),
    );
  }

  /// Inicia el flujo de autenticación biométrica/PIN.
  Future<void> _authenticate(WidgetRef ref, BuildContext context) async {
    final authStateNotifier = ref.read(privateCodexAuthStateProvider(initiallyAuthenticatedForTest).notifier);
    authStateNotifier.state = authStateNotifier.state.copyWith(isAuthenticating: true);

    try {
      String localizedReason = 'Desbloquea tu Códice Privado para leer tus ofrendas pasadas';

      if (biometricAuthOverride != null) {
        final result = await biometricAuthOverride!.authenticate(
          localizedReason: localizedReason,
          stickyAuth: true,
          biometricOnly: false,
        );

        if (result == BiometricAuthResult.success || result == BiometricAuthResult.notAvailable) {
          authStateNotifier.state = authStateNotifier.state.copyWith(
            isAuthenticated: true,
            isAuthenticating: false,
          );
        } else {
          authStateNotifier.state = authStateNotifier.state.copyWith(
            isAuthenticated: false,
            isAuthenticating: false,
            authError: _getAuthErrorMessage(result),
          );
        }
        return;
      }

      // Usar el servicio de bóveda para autenticación manual (producción)
      final vaultService = ref.read(biometricVaultServiceProvider);
      final result = await vaultService.requestUnlock(localizedReason: localizedReason);

      if (result == BiometricAuthResult.success || result == BiometricAuthResult.notAvailable) {
        authStateNotifier.state = authStateNotifier.state.copyWith(
          isAuthenticated: true,
          isAuthenticating: false,
        );
      } else {
        authStateNotifier.state = authStateNotifier.state.copyWith(
          isAuthenticated: false,
          isAuthenticating: false,
          authError: 'Autenticación fallida o cancelada',
        );
      }
    } catch (e) {
      authStateNotifier.state = authStateNotifier.state.copyWith(
        isAuthenticated: false,
        isAuthenticating: false,
        authError: 'Error inesperado: $e',
      );
    }
  }

  String _getAuthErrorMessage(BiometricAuthResult result) {
    return switch (result) {
      BiometricAuthResult.cancelled => 'Autenticación cancelada',
      BiometricAuthResult.failed => 'Autenticación fallida',
      BiometricAuthResult.notAvailable => 'Biometría no disponible',
      BiometricAuthResult.error => 'Error de autenticación',
      BiometricAuthResult.success => '',
    };
  }

  /// Vista de bóveda cerrada (estado bloqueado).
  Widget _buildLockedVaultView(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(privateCodexAuthStateProvider(initiallyAuthenticatedForTest));

    return Stack(
      fit: StackFit.expand,
      children: [
        // Fondo de obsidiana con textura sutil
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.obsidiana,
                const Color(0xFF1A1A2E),
                AppColors.obsidiana,
              ],
            ),
          ),
        ),

        // Patrón geométrico prehispánico sutil (obsidiana y oro)
        CustomPaint(
          size: Size.infinite,
          painter: _VaultPatternPainter(),
        ),

        // Contenido centrado y desplazable para soportar escalado 200%
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icono de códice/pergamino con oro
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.oro.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.oro.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.menu_book_rounded,
                        size: 60,
                        color: AppColors.oro,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Título: Códice Privado
                  Text(
                    'Códice Privado',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: PrivateCodexContrastConstants.vaultTitleColor,
                      letterSpacing: 1.2,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Subtítulo empático
                  Text(
                    'Tus ofrendas descansen seguras bajo el sello de obsidiana.\nSolo tú puedes leerlas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: PrivateCodexContrastConstants.vaultSubtitleColor
                          .withValues(alpha: PrivateCodexContrastConstants.vaultSubtitleAlpha),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Mensaje de error si hubo fallo
                  if (authState.authError != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: PrivateCodexContrastConstants.errorIconColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: PrivateCodexContrastConstants.errorIconColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: PrivateCodexContrastConstants.errorIconColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              authState.authError!,
                              style: TextStyle(
                                color: PrivateCodexContrastConstants.errorTextColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Botón principal: Desbloquear Códice Privado
                  Semantics(
                    button: true,
                    label: 'Desbloquear Códice Privado',
                    hint: authState.isAuthenticating ? 'Autenticando...' : 'Toca para autenticar con huella, FaceID o PIN',
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          key: privateCodexUnlockButtonKey,
                          onPressed: authState.isAuthenticating
                              ? null
                              : () => _authenticate(ref, context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PrivateCodexContrastConstants.unlockButtonBgColor,
                            foregroundColor: PrivateCodexContrastConstants.unlockButtonTextColor,
                            disabledBackgroundColor: AppColors.oro.withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            shadowColor: AppColors.oro.withValues(alpha: 0.3),
                          ),
                          child: authState.isAuthenticating
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(PrivateCodexContrastConstants.unlockButtonTextColor),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.fingerprint_rounded,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Desbloquear Códice Privado',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Botón secundario: Volver al Valle
                  Semantics(
                    button: true,
                    label: 'Regresar al Valle de Teotihuacán',
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      child: TextButton(
                        key: privateCodexBackButtonKey,
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: PrivateCodexContrastConstants.backButtonColor
                              .withValues(alpha: PrivateCodexContrastConstants.backButtonAlpha),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Regresar al Valle',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Espacio extra al final para scroll en escalado 200%
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Vista desbloqueada: Calendario Agrícola con selector mes/año, filtro y cuadrícula.
  Widget _buildUnlockedCalendarView(BuildContext context, WidgetRef ref) {
    final currentMonth = ref.watch(privateCodexCurrentMonthProvider);
    final filter = ref.watch(privateCodexEmotionFilterProvider);
    final entriesAsync = ref.watch(privateCodexMonthEntriesProvider);

    return Container(
      color: PrivateCodexContrastConstants.gridBgColor,
      child: CustomScrollView(
        slivers: [
          // Header con título y botón cerrar
          SliverToBoxAdapter(child: _buildCalendarHeader(context, ref)),

          // Selector de mes/año
          SliverToBoxAdapter(child: _buildMonthSelector(context, ref, currentMonth)),

          // Filtro de emociones (5 climas prehispánicos)
          SliverToBoxAdapter(child: _buildEmotionFilter(context, ref, filter)),

          // Cuadrícula del calendario
          entriesAsync.when(
            data: (entriesByDay) => _buildCalendarGridSliver(context, ref, currentMonth, entriesByDay, filter),
            loading: () => SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: PrivateCodexContrastConstants.loadingColor),
              ),
            ),
            error: (error, stackTrace) => SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: PrivateCodexContrastConstants.errorIconColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No pudimos cargar el calendario',
                        style: TextStyle(
                          color: PrivateCodexContrastConstants.errorTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: PrivateCodexContrastConstants.errorTextColor.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Header del calendario desbloqueado.
  Widget _buildCalendarHeader(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: PrivateCodexContrastConstants.headerBgColor,
        boxShadow: [
          BoxShadow(
            color: AppColors.obsidiana.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Título
          Flexible(
            child: Text(
              'Calendario Agrícola',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: PrivateCodexContrastConstants.headerTitleColor,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          // Botón cerrar/volver
          Semantics(
            button: true,
            label: 'Cerrar Códice Privado y volver al Valle',
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              child: IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: PrivateCodexContrastConstants.headerIconColor
                      .withValues(alpha: PrivateCodexContrastConstants.headerIconAlpha),
                  size: 28,
                ),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Cerrar Códice',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Selector de mes/año con flechas navegables.
  Widget _buildMonthSelector(BuildContext context, WidgetRef ref, DateTime currentMonth) {
    final monthFormat = DateFormat('MMMM yyyy', 'es_MX');

    return Container(
      key: privateCodexMonthSelectorKey,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: PrivateCodexContrastConstants.monthSelectorBgColor,
        border: Border(
          bottom: BorderSide(
            color: PrivateCodexContrastConstants.monthSelectorBorderColor
                .withValues(alpha: PrivateCodexContrastConstants.monthSelectorBorderAlpha),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Flecha mes anterior
          Semantics(
            button: true,
            label: 'Mes anterior',
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              child: IconButton(
                key: privateCodexPreviousMonthKey,
                icon: Icon(
                  Icons.chevron_left_rounded,
                  color: PrivateCodexContrastConstants.monthSelectorTextColor,
                  size: 28,
                ),
                onPressed: () {
                  ref.read(privateCodexCurrentMonthProvider.notifier).state =
                      DateTime(currentMonth.year, currentMonth.month - 1);
                },
                tooltip: 'Mes anterior',
              ),
            ),
          ),

          // Mes y año actual
          Flexible(
            child: Text(
              monthFormat.format(currentMonth).capitalizeFirst(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: PrivateCodexContrastConstants.monthSelectorTextColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Flecha mes siguiente
          Semantics(
            button: true,
            label: 'Mes siguiente',
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              child: IconButton(
                key: privateCodexNextMonthKey,
                icon: Icon(
                  Icons.chevron_right_rounded,
                  color: PrivateCodexContrastConstants.monthSelectorTextColor,
                  size: 28,
                ),
                onPressed: () {
                  ref.read(privateCodexCurrentMonthProvider.notifier).state =
                      DateTime(currentMonth.year, currentMonth.month + 1);
                },
                tooltip: 'Mes siguiente',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Filtro horizontal de los 5 climas prehispánicos + "Todos".
  Widget _buildEmotionFilter(BuildContext context, WidgetRef ref, CodexEmotionFilter currentFilter) {
    final filters = CodexEmotionFilter.values;

    return Container(
      key: privateCodexFilterKey,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: PrivateCodexContrastConstants.monthSelectorBgColor,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: filters.map((filter) {
            final isSelected = filter == currentFilter;
            final emotionColor = filter.emotion != null
                ? Color(int.parse(filter.emotion!.colorHex.replaceFirst('#', '0xFF')))
                : PrivateCodexContrastConstants.filterChipSelectedBgColor;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Semantics(
                button: true,
                label: 'Filtrar por ${filter.label}',
                selected: isSelected,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  child: FilterChip(
                    key: ValueKey('filter_${filter.name}'),
                    label: Text(
                      filter.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? PrivateCodexContrastConstants.filterChipSelectedTextColor
                            : PrivateCodexContrastConstants.filterChipUnselectedTextColor
                                .withValues(alpha: PrivateCodexContrastConstants.filterChipUnselectedTextAlpha),
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      ref.read(privateCodexEmotionFilterProvider.notifier).state = filter;
                    },
                    backgroundColor: PrivateCodexContrastConstants.filterChipUnselectedBgColor,
                    selectedColor: emotionColor,
                    checkmarkColor: PrivateCodexContrastConstants.filterChipSelectedTextColor,
                    side: BorderSide(
                      color: PrivateCodexContrastConstants.filterChipBorderColor
                          .withValues(alpha: PrivateCodexContrastConstants.filterChipBorderAlpha),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Cuadrícula del Calendario Agrícola como SliverGrid para CustomScrollView.
  Widget _buildCalendarGridSliver(
    BuildContext context,
    WidgetRef ref,
    DateTime currentMonth,
    Map<int, List<DiaryEntry>> entriesByDay,
    CodexEmotionFilter filter,
  ) {
    final daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    final firstWeekday = DateTime(currentMonth.year, currentMonth.month, 1).weekday; // 1=Lun, 7=Dom
    final today = DateTime.now();
    final isCurrentMonth = today.year == currentMonth.year && today.month == currentMonth.month;

    // Calcular celdas totales (incluyendo días vacíos al inicio)
    final leadingEmptyCells = (firstWeekday - 1) % 7; // 0 para Lunes, 6 para Domingo
    final totalCells = leadingEmptyCells + daysInMonth;

    return SliverPadding(
      key: privateCodexGridKey,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index < leadingEmptyCells) {
              // Celdas vacías antes del primer día del mes
              return const SizedBox.shrink();
            }

            final day = index - leadingEmptyCells + 1;
            final isToday = isCurrentMonth && day == today.day;
            final dayEntries = entriesByDay[day] ?? [];
            final hasEntries = dayEntries.isNotEmpty;

            // Determinar emoción predominante del día (para badge)
            PrehispanicEmotion? predominantEmotion;
            String? wateredSeedId;
            bool triggeredSos = false;

            if (hasEntries) {
              // Contar emociones para encontrar la predominante
              final emotionCounts = <PrehispanicEmotion, int>{};
              for (final entry in dayEntries) {
                emotionCounts[entry.emotion] = (emotionCounts[entry.emotion] ?? 0) + 1;
                if (entry.wateredSeedId != null) {
                  wateredSeedId = entry.wateredSeedId;
                }
                if (entry.triggeredSos) {
                  triggeredSos = true;
                }
              }
              predominantEmotion = emotionCounts.entries
                  .reduce((a, b) => a.value >= b.value ? a : b)
                  .key;
            }

            final cellKey = ValueKey('codex_day_cell_${currentMonth.year}_${currentMonth.month}_$day');

            return _DayCell(
              key: cellKey,
              day: day,
              hasEntries: hasEntries,
              predominantEmotion: predominantEmotion,
              wateredSeedId: wateredSeedId,
              triggeredSos: triggeredSos,
              isToday: isToday,
              onTap: hasEntries
                  ? () => _showCodexDayParchmentSheet(context, ref, dayEntries, day, currentMonth)
                  : null,
            );
          },
          childCount: totalCells,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1.0,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
      ),
    );
  }

  /// Muestra el pergamino del día con todas las entradas (CodexDayParchmentSheet).
  void _showCodexDayParchmentSheet(
    BuildContext context,
    WidgetRef ref,
    List<DiaryEntry> entries,
    int day,
    DateTime currentMonth,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CodexDayParchmentSheet(
        entries: entries,
        day: day,
        month: currentMonth.month,
        year: currentMonth.year,
      ),
    );
  }
}

/// Celda individual del día en el Calendario Agrícola.
class _DayCell extends StatelessWidget {
  const _DayCell({
    super.key,
    required this.day,
    required this.hasEntries,
    this.predominantEmotion,
    this.wateredSeedId,
    this.triggeredSos = false,
    this.isToday = false,
    this.onTap,
  });

  final int day;
  final bool hasEntries;
  final PrehispanicEmotion? predominantEmotion;
  final String? wateredSeedId;
  final bool triggeredSos;
  final bool isToday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final scale = textScaler.scale(1.0).clamp(1.0, 2.0);
    // Tamaño de fuente base (el Text widget aplica textScaler automáticamente)
    // A 200%: 14 * 2.0 = 28px físico. Iconos se escalan manualmente.
    const baseFontSize = 14.0;
    // Tamaños máximos para iconos (escalados manualmente por textScaler)
    final maxIconSize = (14 * scale).clamp(1.0, 16.0);
    final maxSosIconSize = (12 * scale).clamp(1.0, 14.0);
    final spacing = (2.0 * scale).clamp(2.0, 3.0);

    return Semantics(
      button: onTap != null,
      label: hasEntries
          ? 'Día $day, ${predominantEmotion?.deity ?? "con entradas"}, toca para ver detalle'
          : 'Día $day, parcela en descanso',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            splashColor: AppColors.jade.withValues(alpha: 0.1),
            highlightColor: AppColors.jade.withValues(alpha: 0.05),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: PrivateCodexContrastConstants.dayCellBorderColor
                      .withValues(alpha: PrivateCodexContrastConstants.dayCellBorderAlpha),
                  width: 1,
                ),
                color: hasEntries
                    ? _getEmotionBackgroundColor()
                    : PrivateCodexContrastConstants.dayCellEmptyBgColor
                        .withValues(alpha: PrivateCodexContrastConstants.dayCellEmptyBgAlpha),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Contenido principal centrado - usar LayoutBuilder + SizedBox para evitar overflow
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Usar 100% de la altura disponible para que quepa en celdas pequeñas (ej. 50px en móvil a 200%)
                      final maxContentHeight = constraints.maxHeight;
                      return SizedBox(
                        height: maxContentHeight,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Número del día
                            Text(
                              '$day',
                              style: TextStyle(
                                fontSize: baseFontSize,
                                fontWeight: FontWeight.w700,
                                color: hasEntries
                                    ? Colors.white
                                    : PrivateCodexContrastConstants.dayCellEmptyTextColor
                                        .withValues(alpha: PrivateCodexContrastConstants.dayCellEmptyTextAlpha),
                              ),
                            ),
                            // Indicador de semilla/brotes si hay wateredSeedId
                            if (hasEntries && wateredSeedId != null) ...[
                              SizedBox(height: spacing),
                              Icon(
                                Icons.grass_rounded,
                                size: maxIconSize,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ],
                            // Indicador SOS si triggeredSos
                            if (hasEntries && triggeredSos) ...[
                              SizedBox(height: spacing),
                              Icon(
                                Icons.favorite_rounded,
                                size: maxSosIconSize,
                                color: AppColors.rojoGrana.withValues(alpha: 0.9),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),

                  // Badge de emoción en esquina superior derecha si hay entradas
                  if (hasEntries && predominantEmotion != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          // Usar colorHex de PrehispanicEmotion en lugar de .color
                          color: Color(int.parse(predominantEmotion!.colorHex.replaceFirst('#', '0xFF')))
                              .withValues(alpha: PrivateCodexContrastConstants.badgeBackgroundAlpha),
                          shape: BoxShape.circle,
                        ),
                        child: _getEmotionIcon(predominantEmotion!),
                      ),
                    ),

                  // Indicador "hoy" - anillo dorado sutil
                  if (isToday)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.oro,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getEmotionBackgroundColor() {
    if (predominantEmotion == null) {
      return PrivateCodexContrastConstants.dayCellEmptyBgColor
          .withValues(alpha: PrivateCodexContrastConstants.dayCellEmptyBgAlpha);
    }
    // Usar colorHex de PrehispanicEmotion
    final color = Color(int.parse(predominantEmotion!.colorHex.replaceFirst('#', '0xFF')));
    return color.withValues(alpha: 0.85);
  }

  Widget _getEmotionIcon(PrehispanicEmotion emotion) {
    return Icon(
      switch (emotion) {
        PrehispanicEmotion.tlalocLluvia => Icons.grain_rounded, // Gota de lluvia
        PrehispanicEmotion.tonatiuhSol => Icons.wb_sunny_rounded,
        PrehispanicEmotion.ehecatlViento => Icons.air_rounded,
        PrehispanicEmotion.mixcoatlTormenta => Icons.flash_on_rounded,
        PrehispanicEmotion.metztliNoche => Icons.nights_stay_rounded,
      },
      size: 12,
      // Usar colorHex de PrehispanicEmotion
      color: Color(int.parse(emotion.colorHex.replaceFirst('#', '0xFF'))),
    );
  }
}

/// Pergamino del Códice que muestra el detalle de un día con entradas (CodexDayParchmentSheet).
class CodexDayParchmentSheet extends ConsumerWidget {
  const CodexDayParchmentSheet({
    super.key,
    required this.entries,
    required this.day,
    required this.month,
    required this.year,
  });

  final List<DiaryEntry> entries;
  final int day;
  final int month;
  final int year;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ordenar entradas por hora (más recientes primero)
    final sortedEntries = List<DiaryEntry>.from(entries)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final dateFormat = DateFormat('d \'de\' MMMM', 'es_MX');
    final dateStr = dateFormat.format(DateTime(year, month, day)).capitalizeFirst();
    final timeFormat = DateFormat('HH:mm', 'es_MX');

    return DraggableScrollableSheet(
      key: privateCodexParchmentKey,
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: PrivateCodexContrastConstants.parchmentBgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: AppColors.obsidiana.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Mango de arrastre
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.obsidiana.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header del pergamino
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    // Fecha del día
                    Expanded(
                      child: Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: PrivateCodexContrastConstants.parchmentTitleColor,
                        ),
                      ),
                    ),
                    // Botón cerrar
                    Semantics(
                      button: true,
                      label: 'Cerrar pergamino del día',
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                        child: IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: PrivateCodexContrastConstants.closeButtonTextColor,
                            size: 26,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Cerrar',
                          style: IconButton.styleFrom(
                            backgroundColor: PrivateCodexContrastConstants.closeButtonBgColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Divisor
              Divider(
                color: PrivateCodexContrastConstants.parchmentDividerColor
                    .withValues(alpha: PrivateCodexContrastConstants.parchmentDividerAlpha),
                height: 1,
                indent: 20,
                endIndent: 20,
              ),

              // Lista de entradas del día
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  itemCount: sortedEntries.length,
                  itemBuilder: (context, index) {
                    final entry = sortedEntries[index];
                    return _ParchmentEntryCard(
                      key: ValueKey('parchment_entry_${entry.id}'),
                      entry: entry,
                      timeFormat: timeFormat,
                      index: index,
                      total: sortedEntries.length,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Tarjeta individual de entrada dentro del pergamino.
class _ParchmentEntryCard extends ConsumerWidget {
  const _ParchmentEntryCard({
    super.key,
    required this.entry,
    required this.timeFormat,
    required this.index,
    required this.total,
  });

  final DiaryEntry entry;
  final DateFormat timeFormat;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emotion = entry.emotion;
    final emotionColor = Color(int.parse(emotion.colorHex.replaceFirst('#', '0xFF')));
    final localTime = entry.createdAt.toLocal();
    final timeStr = timeFormat.format(localTime);

    // Provider para la pluma
    final featherAsync = ref.watch(_featherByIdProvider(entry.featherId));

    // Provider para la semilla (si hay wateredSeedId)
    final seedAsync = entry.wateredSeedId != null
        ? ref.watch(_seedByIdProvider(entry.wateredSeedId!))
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado: hora + badge de emoción
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Badge de emoción (círculo con icono)
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: emotionColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            // Hora
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: PrivateCodexContrastConstants.parchmentTextColor
                    .withValues(alpha: 0.7),
              ),
            ),
            const Spacer(),
            // Indicador SOS si aplica
            if (entry.triggeredSos)
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.rojoGrana.withValues(alpha: PrivateCodexContrastConstants.parchmentBadgeBgAlpha),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        size: 12,
                        color: AppColors.rojoGrana,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Apoyo solicitado',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.rojoGrana,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 8),

        // Clima emocional: deidad
        Row(
          children: [
            Flexible(
              child: Text(
                emotion.deity,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: PrivateCodexContrastConstants.parchmentTextColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '(${emotion.label})',
                style: TextStyle(
                  fontSize: 12,
                  color: PrivateCodexContrastConstants.parchmentTextColor.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Semilla regada si hay wateredSeedId
        if (entry.wateredSeedId != null && seedAsync != null)
          seedAsync.when(
            data: (seed) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.jade.withValues(alpha: PrivateCodexContrastConstants.parchmentBadgeBgAlpha),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.grass_rounded,
                    size: 14,
                    color: AppColors.jade,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Semilla regada: ${seed.name}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.jade,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.jade.withValues(alpha: PrivateCodexContrastConstants.parchmentBadgeBgAlpha),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.grass_rounded,
                    size: 14,
                    color: AppColors.jade,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Semilla regada: ${entry.wateredSeedId}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.jade,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Pluma de Sabiduría
        featherAsync.when(
          data: (feather) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: feather.color.withValues(alpha: PrivateCodexContrastConstants.parchmentBadgeBgAlpha),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: feather.color.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 16,
                      color: feather.color,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        feather.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: feather.color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  feather.message,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: PrivateCodexContrastConstants.parchmentTextColor
                        .withValues(alpha: 0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // Contenido de la entrada (texto íntegro descifrado)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: PrivateCodexContrastConstants.parchmentDividerColor
                  .withValues(alpha: PrivateCodexContrastConstants.parchmentDividerAlpha),
            ),
          ),
          child: Text(
            entry.content,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: PrivateCodexContrastConstants.parchmentTextColor
                  .withValues(alpha: PrivateCodexContrastConstants.parchmentTextAlpha),
            ),
          ),
        ),

        // Separador entre entradas (excepto la última)
        if (index < total - 1) ...[
          const SizedBox(height: 20),
          Divider(
            color: PrivateCodexContrastConstants.parchmentDividerColor
                .withValues(alpha: PrivateCodexContrastConstants.parchmentDividerAlpha),
            height: 1,
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

/// Painter para el patrón geométrico de la bóveda.
class _VaultPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.oro.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    const patternSize = 20.0;

    for (var x = -spacing; x < size.width + spacing; x += spacing) {
      for (var y = -spacing; y < size.height + spacing; y += spacing) {
        // Dibujar glifos prehispánicos simplificados (círculos concéntricos tipo Tláloc)
        final center = Offset(x, y);
        canvas.drawCircle(center, patternSize * 0.5, paint);
        canvas.drawCircle(center, patternSize * 0.3, paint);
        canvas.drawCircle(center, patternSize * 0.1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Extensión para capitalizar primera letra.
extension StringExtension on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}