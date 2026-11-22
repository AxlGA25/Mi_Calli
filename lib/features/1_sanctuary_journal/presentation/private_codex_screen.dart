// PrivateCodexScreen - Códice Privado con autenticación biométrica y Calendario Agrícola.
//
// Incluye Hero desde el Templo del Códice, AnimatedSwitcher en cambio de mes,
// Skeleton Loading (AmateShimmerBox), BouncyTap táctil y alto contraste.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';

import 'package:mi_calli/core/constants/app_colors.dart';
import 'package:mi_calli/core/database/asset_loader_service.dart';
import 'package:mi_calli/core/security/biometric_auth_interface.dart';
import 'package:mi_calli/core/security/biometric_vault_service.dart';
import 'package:mi_calli/core/widgets/mi_calli_animations.dart';
import 'package:mi_calli/features/1_sanctuary_journal/data/diary_repository_provider.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/diary_entry.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/prehispanic_emotion.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/wisdom_feather.dart';
import 'package:mi_calli/features/2_gamification/models/seed_catalog_item.dart';

/// Constantes de contraste para PrivateCodexScreen (WCAG 4.5:1).
class PrivateCodexContrastConstants {
  static const Color vaultBgColor = AppColors.obsidiana;
  static const Color vaultTitleColor = AppColors.oro;
  static const Color vaultSubtitleColor = AppColors.pergaminoClaro;
  static const double vaultSubtitleAlpha = 0.8;
  static const Color unlockButtonBgColor = AppColors.oro;
  static const Color unlockButtonTextColor = AppColors.obsidiana;
  static const Color backButtonColor = AppColors.pergaminoClaro;
  static const double backButtonAlpha = 0.9;

  static const Color headerBgColor = AppColors.obsidiana;
  static const Color headerTitleColor = AppColors.oro;
  static const Color headerIconColor = AppColors.pergaminoClaro;
  static const double headerIconAlpha = 0.9;

  static const Color monthSelectorBgColor = AppColors.pergaminoClaro;
  static const Color monthSelectorTextColor = AppColors.obsidiana;
  static const Color monthSelectorBorderColor = AppColors.obsidiana;
  static const double monthSelectorBorderAlpha = 0.5;

  static const Color filterChipSelectedBgColor = AppColors.jade;
  static const Color filterChipSelectedTextColor = AppColors.obsidiana;
  static const Color filterChipUnselectedBgColor = AppColors.pergaminoClaro;
  static const Color filterChipUnselectedTextColor = AppColors.obsidiana;
  static const double filterChipUnselectedTextAlpha = 0.8;
  static const Color filterChipBorderColor = AppColors.obsidiana;
  static const double filterChipBorderAlpha = 0.2;

  static const Color gridBgColor = Color(0xFFFDFBF7);
  static const Color dayCellEmptyBgColor = Color(0xFF8B7D6B);
  static const double dayCellEmptyBgAlpha = 0.3;
  static const Color dayCellEmptyTextColor = AppColors.obsidiana;
  static const double dayCellEmptyTextAlpha = 0.8;
  static const Color dayCellBorderColor = AppColors.obsidiana;
  static const double dayCellBorderAlpha = 0.15;

  static const double badgeBackgroundAlpha = 0.25;

  static const Color parchmentBgColor = AppColors.pergaminoClaro;
  static const Color parchmentTitleColor = AppColors.obsidiana;
  static const Color parchmentTextColor = AppColors.obsidiana;
  static const double parchmentTextAlpha = 0.9;
  static const Color parchmentDividerColor = AppColors.obsidiana;
  static const double parchmentDividerAlpha = 0.5;
  static const double parchmentBadgeBgAlpha = 0.2;
  static const Color closeButtonBgColor = AppColors.obsidiana;
  static const Color closeButtonTextColor = AppColors.oro;

  static const Color loadingColor = AppColors.oro;
  static const Color errorIconColor = Color(0xFFB71C1C);
  static const Color errorTextColor = AppColors.obsidiana;

  PrivateCodexContrastConstants._();
}

/// Claves globales para testing.
final GlobalKey privateCodexScreenKey = GlobalKey(
  debugLabel: 'privateCodexScreen',
);
final ValueKey<String> privateCodexUnlockButtonKey = const ValueKey<String>(
  'private_codex_unlock_button',
);
final ValueKey<String> privateCodexBackButtonKey = const ValueKey<String>(
  'private_codex_back_button',
);
final ValueKey<String> privateCodexMonthSelectorKey = const ValueKey<String>(
  'private_codex_month_selector',
);
final ValueKey<String> privateCodexPreviousMonthKey = const ValueKey<String>(
  'private_codex_previous_month',
);
final ValueKey<String> privateCodexNextMonthKey = const ValueKey<String>(
  'private_codex_next_month',
);
final ValueKey<String> privateCodexFilterKey = const ValueKey<String>(
  'private_codex_filter',
);
final ValueKey<String> privateCodexGridKey = const ValueKey<String>(
  'private_codex_grid',
);
final ValueKey<String> privateCodexParchmentKey = const ValueKey<String>(
  'private_codex_parchment',
);

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
// PROVIDERS DE NIVEL SUPERIOR
// ============================================================================

final privateCodexAuthStateProvider =
    StateProvider.family<_PrivateCodexAuthState, bool>((
      ref,
      initiallyAuthenticatedForTest,
    ) {
      return _PrivateCodexAuthState(
        isAuthenticated: initiallyAuthenticatedForTest,
        isAuthenticating: false,
        authError: null,
      );
    });

final privateCodexCurrentMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final privateCodexEmotionFilterProvider = StateProvider<CodexEmotionFilter>(
  (ref) => CodexEmotionFilter.all,
);

typedef CodexDayEntriesMap = Map<int, List<DiaryEntry>>;

final privateCodexMonthEntriesProvider =
    FutureProvider.autoDispose<CodexDayEntriesMap>((ref) async {
      final currentMonth = ref.watch(privateCodexCurrentMonthProvider);
      final filter = ref.watch(privateCodexEmotionFilterProvider);
      final repository = ref.watch(diaryRepositoryProvider);

      final startOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
      final endOfMonth = DateTime(
        currentMonth.year,
        currentMonth.month + 1,
        0,
        23,
        59,
        59,
        999,
      );

      final entries = await repository.getEntriesByDateRange(
        start: startOfMonth,
        end: endOfMonth,
      );

      final CodexDayEntriesMap entriesByDay = {};
      for (final entry in entries) {
        final localDay = entry.createdAt.toLocal().day;
        if (filter.emotion != null && entry.emotion != filter.emotion) {
          continue;
        }
        entriesByDay.putIfAbsent(localDay, () => []).add(entry);
      }

      return entriesByDay;
    });

final _featherByIdProvider = FutureProvider.family<WisdomFeather, String>((
  ref,
  featherId,
) async {
  final feathers = await AssetLoaderService.instance.loadFeathers();
  try {
    return feathers.firstWhere((f) => f.featherId == featherId);
  } on StateError {
    throw AssetLoadException('Pluma no encontrada: $featherId');
  }
});

final _seedByIdProvider = FutureProvider.family<SeedCatalogItem, String>((
  ref,
  seedId,
) async {
  final seeds = await AssetLoaderService.instance.loadSeedsCatalog();
  try {
    return seeds.firstWhere((s) => s.seedId == seedId);
  } on StateError {
    throw AssetLoadException('Semilla no encontrada: $seedId');
  }
});

/// Pantalla principal del Códice Privado.
class PrivateCodexScreen extends ConsumerWidget {
  const PrivateCodexScreen({
    super.key,
    this.biometricAuthOverride,
    this.initiallyAuthenticatedForTest = false,
  });

  final BiometricAuthInterface? biometricAuthOverride;
  final bool initiallyAuthenticatedForTest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      key: privateCodexScreenKey,
      backgroundColor: PrivateCodexContrastConstants.vaultBgColor,
      body: Consumer(
        builder: (context, ref, child) {
          final authState = ref.watch(
            privateCodexAuthStateProvider(initiallyAuthenticatedForTest),
          );

          if (!authState.isAuthenticated) {
            return _buildLockedVaultView(context, ref);
          }

          return _buildUnlockedCalendarView(context, ref);
        },
      ),
    );
  }

  Future<void> _authenticate(WidgetRef ref, BuildContext context) async {
    final authStateNotifier = ref.read(
      privateCodexAuthStateProvider(initiallyAuthenticatedForTest).notifier,
    );
    authStateNotifier.state = authStateNotifier.state.copyWith(
      isAuthenticating: true,
    );

    try {
      const localizedReason =
          'Desbloquea tu Códice Privado para leer tus ofrendas pasadas';

      if (biometricAuthOverride != null) {
        final result = await biometricAuthOverride!.authenticate(
          localizedReason: localizedReason,
          stickyAuth: true,
          biometricOnly: false,
        );

        if (result == BiometricAuthResult.success ||
            result == BiometricAuthResult.notAvailable) {
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

      final vaultService = ref.read(biometricVaultServiceProvider);
      final result = await vaultService.requestUnlock(
        localizedReason: localizedReason,
      );

      if (result == BiometricAuthResult.success ||
          result == BiometricAuthResult.notAvailable) {
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

  /// Vista bloqueada (Bóveda de Obsidiana y Oro con Hero).
  Widget _buildLockedVaultView(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(
      privateCodexAuthStateProvider(initiallyAuthenticatedForTest),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0D151C),
                Color(0xFF1A2236),
                AppColors.obsidiana,
              ],
            ),
          ),
        ),
        CustomPaint(size: Size.infinite, painter: _VaultPatternPainter()),
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
                  Hero(
                    tag: 'hero_codex_internal',
                    child: Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFC857).withValues(alpha: 0.12),
                        border: Border.all(
                          color: const Color(
                            0xFFFFC857,
                          ).withValues(alpha: 0.75),
                          width: 2.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFFFC857,
                            ).withValues(alpha: 0.28),
                            blurRadius: 26,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.menu_book_rounded,
                          size: 54,
                          color: Color(0xFFFFC857),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Códice Privado',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: PrivateCodexContrastConstants.vaultTitleColor,
                      letterSpacing: 1.0,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tus ofrendas descansan seguras bajo el sello de obsidiana.\nSolo tú puedes leerlas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.55,
                      color: PrivateCodexContrastConstants.vaultSubtitleColor
                          .withValues(
                            alpha:
                                PrivateCodexContrastConstants
                                    .vaultSubtitleAlpha,
                          ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  if (authState.authError != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: PrivateCodexContrastConstants.errorIconColor
                            .withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: PrivateCodexContrastConstants.errorIconColor
                              .withValues(alpha: 0.45),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: PrivateCodexContrastConstants.errorIconColor,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              authState.authError!,
                              style: const TextStyle(
                                color: AppColors.pergaminoClaro,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  BouncyTap(
                    enableHaptics: !authState.isAuthenticating,
                    scaleDown: 0.96,
                    child: Semantics(
                      button: true,
                      label: 'Desbloquear Códice Privado',
                      hint:
                          authState.isAuthenticating
                              ? 'Autenticando...'
                              : 'Toca para autenticar con huella, FaceID o PIN',
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            key: privateCodexUnlockButtonKey,
                            onPressed:
                                authState.isAuthenticating
                                    ? null
                                    : () => _authenticate(ref, context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  PrivateCodexContrastConstants
                                      .unlockButtonBgColor,
                              foregroundColor:
                                  PrivateCodexContrastConstants
                                      .unlockButtonTextColor,
                              disabledBackgroundColor: AppColors.oro.withValues(
                                alpha: 0.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 6,
                              shadowColor: AppColors.oro.withValues(alpha: 0.4),
                            ),
                            child:
                                authState.isAuthenticating
                                    ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              PrivateCodexContrastConstants
                                                  .unlockButtonTextColor,
                                            ),
                                      ),
                                    )
                                    : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.fingerprint_rounded,
                                          size: 22,
                                        ),
                                        SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            'Desbloquear Códice Privado',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
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
                  ),
                  const SizedBox(height: 18),
                  BouncyTap(
                    child: Semantics(
                      button: true,
                      label: 'Regresar al Valle de Teotihuacán',
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        child: TextButton(
                          key: privateCodexBackButtonKey,
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: PrivateCodexContrastConstants
                                .backButtonColor
                                .withValues(
                                  alpha:
                                      PrivateCodexContrastConstants
                                          .backButtonAlpha,
                                ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Regresar al Valle',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Vista desbloqueada: Calendario Agrícola con skeleton shimmer y AnimatedSwitcher.
  Widget _buildUnlockedCalendarView(BuildContext context, WidgetRef ref) {
    final currentMonth = ref.watch(privateCodexCurrentMonthProvider);
    final filter = ref.watch(privateCodexEmotionFilterProvider);
    final entriesAsync = ref.watch(privateCodexMonthEntriesProvider);

    return Container(
      color: PrivateCodexContrastConstants.gridBgColor,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildCalendarHeader(context)),
          SliverToBoxAdapter(
            child: _buildMonthSelector(context, ref, currentMonth),
          ),
          SliverToBoxAdapter(child: _buildEmotionFilter(context, ref, filter)),
          SliverToBoxAdapter(child: _buildWeekdayHeader()),
          entriesAsync.when(
            data:
                (entriesByDay) => _buildCalendarGridSliver(
                  context,
                  ref,
                  currentMonth,
                  entriesByDay,
                ),
            loading:
                () =>
                    SliverToBoxAdapter(child: _buildCalendarLoadingSkeleton()),
            error:
                (error, _) => SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: PrivateCodexContrastConstants.errorIconColor,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No pudimos cargar el calendario',
                            style: TextStyle(
                              color:
                                  PrivateCodexContrastConstants.errorTextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: PrivateCodexContrastConstants
                                  .errorTextColor
                                  .withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
          SliverToBoxAdapter(child: _buildCalendarLegend()),
        ],
      ),
    );
  }

  /// Skeleton loading con shimmer cálido de papel amate mientras carga la BD.
  Widget _buildCalendarLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: PrivateCodexContrastConstants.loadingColor,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(child: Text(
                'Cargando parcelas del códice...',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.obsidiana.withValues(alpha: 0.55),
                ),
                overflow: TextOverflow.ellipsis,
              )),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 35,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.96,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemBuilder:
                (_, __) => const AmateShimmerBox(
                  borderRadius: 12,
                  baseColor: Color(0xFFECE2D0),
                  highlightColor: Color(0xFFFFFBF2),
                ),
          ),
        ],
      ),
    );
  }

  /// Header de obsidiana con SafeArea, Hero y cenefa dorada.
  Widget _buildCalendarHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PrivateCodexContrastConstants.headerBgColor,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFFFC857), width: 1.8),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.obsidiana.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 12, 12),
          child: Row(
            children: [
              Hero(
                tag: 'hero_codex_internal',
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC857).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFFFC857).withValues(alpha: 0.65),
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    color: Color(0xFFFFC857),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Calendario Agrícola',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: PrivateCodexContrastConstants.headerTitleColor,
                    letterSpacing: 0.4,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              BouncyTap(
                child: Semantics(
                  button: true,
                  label: 'Cerrar Códice Privado y volver al Valle',
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: PrivateCodexContrastConstants.headerIconColor
                            .withValues(
                              alpha:
                                  PrivateCodexContrastConstants.headerIconAlpha,
                            ),
                        size: 26,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Cerrar Códice',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Selector de mes/año con AnimatedSwitcher y BouncyTap en las flechas.
  Widget _buildMonthSelector(
    BuildContext context,
    WidgetRef ref,
    DateTime currentMonth,
  ) {
    final monthFormat = DateFormat('MMMM yyyy', 'es_MX');
    final monthLabel = monthFormat.format(currentMonth).capitalizeFirst();

    return Container(
      key: privateCodexMonthSelectorKey,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      color: PrivateCodexContrastConstants.gridBgColor,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: PrivateCodexContrastConstants.monthSelectorBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0A93B), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: AppColors.obsidiana.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            BouncyTap(
              enableHaptics: true,
              child: Semantics(
                button: true,
                label: 'Mes anterior',
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  child: IconButton(
                    key: privateCodexPreviousMonthKey,
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color:
                          PrivateCodexContrastConstants.monthSelectorTextColor,
                      size: 28,
                    ),
                    onPressed: () {
                      ref
                          .read(privateCodexCurrentMonthProvider.notifier)
                          .state = DateTime(
                        currentMonth.year,
                        currentMonth.month - 1,
                      );
                    },
                    tooltip: 'Mes anterior',
                  ),
                ),
              ),
            ),
            Flexible(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder:
                    (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.15),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                child: Text(
                  monthLabel,
                  key: ValueKey<String>(
                    '${currentMonth.year}_${currentMonth.month}',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: PrivateCodexContrastConstants.monthSelectorTextColor,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            BouncyTap(
              enableHaptics: true,
              child: Semantics(
                button: true,
                label: 'Mes siguiente',
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  child: IconButton(
                    key: privateCodexNextMonthKey,
                    icon: const Icon(
                      Icons.chevron_right_rounded,
                      color:
                          PrivateCodexContrastConstants.monthSelectorTextColor,
                      size: 28,
                    ),
                    onPressed: () {
                      ref
                          .read(privateCodexCurrentMonthProvider.notifier)
                          .state = DateTime(
                        currentMonth.year,
                        currentMonth.month + 1,
                      );
                    },
                    tooltip: 'Mes siguiente',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Filtro horizontal de los 5 climas prehispánicos + "Todos".
  Widget _buildEmotionFilter(
    BuildContext context,
    WidgetRef ref,
    CodexEmotionFilter currentFilter,
  ) {
    final filters = CodexEmotionFilter.values;

    return Container(
      key: privateCodexFilterKey,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      color: PrivateCodexContrastConstants.gridBgColor,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children:
              filters.map((filter) {
                final isSelected = filter == currentFilter;
                final emotionColor =
                    filter.emotion != null
                        ? Color(
                          int.parse(
                            filter.emotion!.colorHex.replaceFirst('#', '0xFF'),
                          ),
                        )
                        : PrivateCodexContrastConstants
                            .filterChipSelectedBgColor;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Semantics(
                    button: true,
                    label: 'Filtrar por ${filter.label}',
                    selected: isSelected,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      child: FilterChip(
                        key: ValueKey('filter_${filter.name}'),
                        label: Text(
                          filter.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color:
                                isSelected
                                    ? PrivateCodexContrastConstants
                                        .filterChipSelectedTextColor
                                    : PrivateCodexContrastConstants
                                        .filterChipUnselectedTextColor
                                        .withValues(
                                          alpha:
                                              PrivateCodexContrastConstants
                                                  .filterChipUnselectedTextAlpha,
                                        ),
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (_) {
                          ref
                              .read(privateCodexEmotionFilterProvider.notifier)
                              .state = filter;
                        },
                        backgroundColor:
                            PrivateCodexContrastConstants
                                .filterChipUnselectedBgColor,
                        selectedColor: emotionColor,
                        checkmarkColor:
                            PrivateCodexContrastConstants
                                .filterChipSelectedTextColor,
                        side: BorderSide(
                          color:
                              isSelected
                                  ? AppColors.obsidiana.withValues(alpha: 0.45)
                                  : PrivateCodexContrastConstants
                                      .filterChipBorderColor
                                      .withValues(
                                        alpha:
                                            PrivateCodexContrastConstants
                                                .filterChipBorderAlpha,
                                      ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
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

  /// Barra superior con los días de la semana (Lun a Dom).
  Widget _buildWeekdayHeader() {
    const days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Row(
        children:
            days
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.obsidiana.withValues(alpha: 0.65),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  /// Cuadrícula de días del Calendario Agrícola.
  Widget _buildCalendarGridSliver(
    BuildContext context,
    WidgetRef ref,
    DateTime currentMonth,
    CodexDayEntriesMap entriesByDay,
  ) {
    final daysInMonth =
        DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    final firstWeekday =
        DateTime(currentMonth.year, currentMonth.month, 1).weekday;
    final today = DateTime.now();
    final isCurrentMonth =
        today.year == currentMonth.year && today.month == currentMonth.month;

    final leadingEmptyCells = (firstWeekday - 1) % 7;
    final totalCells = leadingEmptyCells + daysInMonth;

    return SliverPadding(
      key: privateCodexGridKey,
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 16),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index < leadingEmptyCells) {
            return const SizedBox.shrink();
          }

          final day = index - leadingEmptyCells + 1;
          final isToday = isCurrentMonth && day == today.day;
          final dayEntries = entriesByDay[day] ?? [];
          final hasEntries = dayEntries.isNotEmpty;

          PrehispanicEmotion? predominantEmotion;
          String? wateredSeedId;
          bool triggeredSos = false;

          if (hasEntries) {
            final emotionCounts = <PrehispanicEmotion, int>{};
            for (final entry in dayEntries) {
              emotionCounts[entry.emotion] =
                  (emotionCounts[entry.emotion] ?? 0) + 1;
              if (entry.wateredSeedId != null) {
                wateredSeedId = entry.wateredSeedId;
              }
              if (entry.triggeredSos) {
                triggeredSos = true;
              }
            }
            predominantEmotion =
                emotionCounts.entries
                    .reduce((a, b) => a.value >= b.value ? a : b)
                    .key;
          }

          final cellKey = ValueKey(
            'codex_day_cell_${currentMonth.year}_${currentMonth.month}_$day',
          );

          return _DayCell(
            key: cellKey,
            day: day,
            hasEntries: hasEntries,
            predominantEmotion: predominantEmotion,
            wateredSeedId: wateredSeedId,
            triggeredSos: triggeredSos,
            isToday: isToday,
            onTap:
                hasEntries
                    ? () => _showCodexDayParchmentSheet(
                      context,
                      ref,
                      dayEntries,
                      day,
                      currentMonth,
                    )
                    : null,
          );
        }, childCount: totalCells),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 0.96,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
      ),
    );
  }

  Widget _buildCalendarLegend() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          _legendItem(
            color: const Color(0xFFE0A93B),
            outlined: true,
            label: 'Hoy',
          ),
          _legendItem(
            color: AppColors.jade,
            outlined: false,
            label: 'Día con ofrenda',
          ),
          _legendItem(
            color: const Color(0xFFE8DDCA),
            outlined: false,
            label: 'Parcela en descanso',
          ),
        ],
      ),
    );
  }

  Widget _legendItem({
    required Color color,
    required bool outlined,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: outlined ? Colors.transparent : color,
            borderRadius: BorderRadius.circular(4),
            border: outlined ? Border.all(color: color, width: 2) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.obsidiana.withValues(alpha: 0.72),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

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
      builder:
          (context) => CodexDayParchmentSheet(
            entries: entries,
            day: day,
            month: currentMonth.month,
            year: currentMonth.year,
          ),
    );
  }
}

/// Celda individual del día en el Calendario Agrícola (con rebote si tiene ofrendas).
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
    const baseFontSize = 14.0;
    final maxIconSize = (13 * scale).clamp(1.0, 15.0);
    final maxSosIconSize = (11 * scale).clamp(1.0, 13.0);

    final cell = Semantics(
      button: onTap != null,
      label:
          hasEntries
              ? 'Día $day, ${predominantEmotion?.deity ?? "con entradas"}, toca para ver detalle'
              : 'Día $day, parcela en descanso',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            splashColor: AppColors.jade.withValues(alpha: 0.16),
            highlightColor: AppColors.jade.withValues(alpha: 0.08),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      hasEntries
                          ? AppColors.obsidiana.withValues(alpha: 0.18)
                          : const Color(0xFFD9C7A7),
                  width: 1.1,
                ),
                color:
                    hasEntries
                        ? _getEmotionBackgroundColor()
                        : const Color(0xFFF3ECE0),
                boxShadow:
                    hasEntries
                        ? [
                          BoxShadow(
                            color: _getEmotionBackgroundColor().withValues(
                              alpha: 0.34,
                            ),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                        : null,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return SizedBox(
                        height: constraints.maxHeight,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '$day',
                              style: TextStyle(
                                fontSize: baseFontSize,
                                fontWeight: FontWeight.w800,
                                color:
                                    hasEntries
                                        ? Colors.white
                                        : PrivateCodexContrastConstants
                                            .dayCellEmptyTextColor
                                            .withValues(
                                              alpha:
                                                  PrivateCodexContrastConstants
                                                      .dayCellEmptyTextAlpha,
                                            ),
                              ),
                            ),
                            if (hasEntries &&
                                (wateredSeedId != null || triggeredSos))
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (wateredSeedId != null)
                                    Icon(
                                      Icons.grass_rounded,
                                      size: maxIconSize,
                                      color: Colors.white.withValues(
                                        alpha: 0.95,
                                      ),
                                    ),
                                  if (triggeredSos)
                                    Icon(
                                      Icons.favorite_rounded,
                                      size: maxSosIconSize,
                                      color: AppColors.rojoGrana,
                                    ),
                                ],
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  if (hasEntries && predominantEmotion != null)
                    Positioned(
                      top: 3,
                      right: 3,
                      child: Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: _getEmotionIcon(predominantEmotion!),
                      ),
                    ),
                  if (isToday)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE0A93B),
                              width: 2.4,
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

    if (!hasEntries) return cell;
    return BouncyTap(enableHaptics: true, scaleDown: 0.90, child: cell);
  }

  Color _getEmotionBackgroundColor() {
    if (predominantEmotion == null) {
      return const Color(0xFFF3ECE0);
    }
    final color = Color(
      int.parse(predominantEmotion!.colorHex.replaceFirst('#', '0xFF')),
    );
    return color.withValues(alpha: 0.94);
  }

  Widget _getEmotionIcon(PrehispanicEmotion emotion) {
    return Icon(
      switch (emotion) {
        PrehispanicEmotion.tlalocLluvia => Icons.grain_rounded,
        PrehispanicEmotion.tonatiuhSol => Icons.wb_sunny_rounded,
        PrehispanicEmotion.ehecatlViento => Icons.air_rounded,
        PrehispanicEmotion.mixcoatlTormenta => Icons.flash_on_rounded,
        PrehispanicEmotion.metztliNoche => Icons.nights_stay_rounded,
      },
      size: 11,
      color: Color(int.parse(emotion.colorHex.replaceFirst('#', '0xFF'))),
    );
  }
}

/// Pergamino del Códice que muestra el detalle de un día con entradas.
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
    final sortedEntries = List<DiaryEntry>.from(entries)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final dateFormat = DateFormat('d \'de\' MMMM', 'es_MX');
    final dateStr =
        dateFormat.format(DateTime(year, month, day)).capitalizeFirst();
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
            border: const Border(
              top: BorderSide(color: Color(0xFFFFC857), width: 2.2),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.obsidiana.withValues(alpha: 0.28),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0A93B).withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.menu_book_rounded,
                      color: Color(0xFFE0A93B),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color:
                              PrivateCodexContrastConstants.parchmentTitleColor,
                        ),
                      ),
                    ),
                    BouncyTap(
                      child: Semantics(
                        button: true,
                        label: 'Cerrar pergamino del día',
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          child: IconButton(
                            key: const ValueKey('codex_parchment_close_button'),
                            icon: const Icon(
                              Icons.close_rounded,
                              color:
                                  PrivateCodexContrastConstants
                                      .closeButtonTextColor,
                              size: 24,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            tooltip: 'Cerrar',
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  PrivateCodexContrastConstants
                                      .closeButtonBgColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                color: const Color(0xFFE0A93B).withValues(alpha: 0.55),
                height: 1,
                indent: 20,
                endIndent: 20,
              ),
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
    final emotionColor = Color(
      int.parse(emotion.colorHex.replaceFirst('#', '0xFF')),
    );
    final timeStr = timeFormat.format(entry.createdAt.toLocal());

    final featherAsync = ref.watch(_featherByIdProvider(entry.featherId));
    final seedAsync =
        entry.wateredSeedId != null
            ? ref.watch(_seedByIdProvider(entry.wateredSeedId!))
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: emotionColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
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
            if (entry.triggeredSos)
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.rojoGrana.withValues(
                      alpha:
                          PrivateCodexContrastConstants.parchmentBadgeBgAlpha,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        size: 12,
                        color: AppColors.rojoGrana,
                      ),
                      SizedBox(width: 4),
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
        const SizedBox(height: 6),
        Row(
          children: [
            Flexible(
              child: Text(
                emotion.deity,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: PrivateCodexContrastConstants.parchmentTextColor,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '(${emotion.label})',
                style: TextStyle(
                  fontSize: 12,
                  color: PrivateCodexContrastConstants.parchmentTextColor
                      .withValues(alpha: 0.65),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (entry.wateredSeedId != null && seedAsync != null)
          seedAsync.when(
            data: (seed) => _seedBadge('Semilla regada: ${seed.name}'),
            loading: () => const SizedBox.shrink(),
            error:
                (_, __) => _seedBadge('Semilla regada: ${entry.wateredSeedId}'),
          ),
        featherAsync.when(
          data:
              (feather) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: feather.color.withValues(
                    alpha: PrivateCodexContrastConstants.parchmentBadgeBgAlpha,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: feather.color.withValues(alpha: 0.45),
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
                              fontWeight: FontWeight.w700,
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
                            .withValues(alpha: 0.85),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE0A93B).withValues(alpha: 0.5),
            ),
          ),
          child: Text(
            entry.content,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: PrivateCodexContrastConstants.parchmentTextColor
                  .withValues(
                    alpha: PrivateCodexContrastConstants.parchmentTextAlpha,
                  ),
            ),
          ),
        ),
        if (index < total - 1) ...[
          const SizedBox(height: 18),
          Divider(
            color: const Color(0xFFE0A93B).withValues(alpha: 0.45),
            height: 1,
          ),
          const SizedBox(height: 18),
        ],
      ],
    );
  }

  Widget _seedBadge(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.jade.withValues(
          alpha: PrivateCodexContrastConstants.parchmentBadgeBgAlpha,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.grass_rounded, size: 14, color: AppColors.jade),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.jade,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Patrón geométrico sutil de la bóveda.
class _VaultPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = AppColors.oro.withValues(alpha: 0.05)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6;

    const spacing = 40.0;
    const patternSize = 20.0;

    for (var x = -spacing; x < size.width + spacing; x += spacing) {
      for (var y = -spacing; y < size.height + spacing; y += spacing) {
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

extension StringExtension on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
