// Diálogo del Estado del Fuego Sagrado (Tarea 4.3).
//
// Modal místico que muestra: racha actual, color/nombre de la llama,
// nivel de Quetzalcóatl, escudos de Xólotl y reliquias desbloqueadas.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

import 'package:mi_calli/core/constants/app_colors.dart';
import 'package:mi_calli/features/2_gamification/models/deity_relic_models.dart';
import 'package:mi_calli/features/2_gamification/models/gamification_models.dart';
import 'package:mi_calli/features/2_gamification/providers/relics_provider.dart';
import 'package:mi_calli/features/2_gamification/services/sacred_fire_and_evolution_service.dart';

/// Diálogo del estado del Fuego Sagrado.
class SacredFireStatusDialog extends ConsumerWidget {
  const SacredFireStatusDialog({super.key});

  /// Muestra el diálogo del Fuego Sagrado.
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const SacredFireStatusDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamificationStateAsync = ref.watch(gamificationStateProvider);
    final relicsAsync = ref.watch(userRelicsProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Semantics(
        label: 'Estado del Fuego Sagrado y evolución de Quetzalcóatl',
        child: gamificationStateAsync.when(
          loading: () => _buildLoadingDialog(context),
          error: (err, _) => _buildErrorDialog(context, err.toString()),
          data: (state) => relicsAsync.when(
            loading: () => _buildLoadingDialog(context),
            error: (err, _) => _buildErrorDialog(context, err.toString()),
            data: (relics) => _buildDialogContent(context, state, relics),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingDialog(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.obsidiana.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.oro, width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.jade),
            const SizedBox(height: 16),
            Text(
              'Consultando el Fuego Sagrado...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.pergaminoClaro),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorDialog(BuildContext context, String error) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.obsidiana.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.rojoGrana, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.rojoGrana, size: 48),
          const SizedBox(height: 16),
          Text(
            'Error al consultar el Fuego',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.pergaminoClaro),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.pergaminoClaro.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar', style: TextStyle(color: AppColors.jade)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogContent(
    BuildContext context,
    GamificationState state,
    List<UnlockedRelic> relics,
  ) {
    final sacredFireTier = state.sacredFireTier;
    final evolutionStage = state.evolutionStage;

    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: AppColors.obsidiana.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: sacredFireTier.primaryColor, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: sacredFireTier.primaryColor.withValues(alpha: 0.3),
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Encabezado con llama animada
          _buildHeader(context, sacredFireTier, state.currentStreak),

          // Contenido principal
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Racha y tier del fuego
                  _buildStreakSection(context, state, sacredFireTier),
                  const SizedBox(height: 20),

                  // Nivel de Quetzalcóatl
                  _buildQuetzalSection(context, state, evolutionStage),
                  const SizedBox(height: 20),

                  // Escudos de Xólotl
                  _buildXolotlShieldsSection(context, state),
                  const SizedBox(height: 20),

                  // Reliquias desbloqueadas
                  _buildRelicsSection(context, relics),
                ],
              ),
            ),
          ),

          // Botón de cierre
          _buildCloseButton(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SacredFireTier tier, int streak) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: BoxDecoration(
        color: tier.primaryColor.withValues(alpha: 0.15),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(
          bottom: BorderSide(color: tier.primaryColor.withValues(alpha: 0.3), width: 1.5),
        ),
      ),
      child: Column(
        children: [
          // Llama animada
          Semantics(
            label: 'Llama del Fuego Sagrado, ${tier.displayName}',
            child: _AnimatedFlame(tier: tier),
          ),
          const SizedBox(height: 12),
          // Título del tier
          Text(
            tier.displayName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: tier.primaryColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: 4),
          // Días de racha
          Text(
            streak == 0
                ? 'El fuego espera tu primera ofrenda'
                : 'Racha actual: $streak ${streak == 1 ? 'día' : 'días'}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.pergaminoClaro.withValues(alpha: 0.8),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakSection(BuildContext context, GamificationState state, SacredFireTier tier) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pergaminoClaro.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tier.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_fire_department_rounded, color: tier.primaryColor, size: 22),
              const SizedBox(width: 10),
              Text(
                'Fuego Sagrado',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.pergaminoClaro,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Racha actual',
                  '${state.currentStreak} ${state.currentStreak == 1 ? 'día' : 'días'}',
                  tier.primaryColor,
                ),
              ),
              Container(width: 1, height: 40, color: tier.primaryColor.withValues(alpha: 0.2)),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Mejor racha',
                  '${state.longestStreak} ${state.longestStreak == 1 ? 'día' : 'días'}',
                  AppColors.oro,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.pergaminoClaro.withValues(alpha: 0.6),
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildQuetzalSection(BuildContext context, GamificationState state, QuetzalEvolutionStage stage) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pergaminoClaro.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.jade.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.jade.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.jade, width: 1.5),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: AppColors.jade, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Quetzalcóatl',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.pergaminoClaro,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Nivel ${stage.levelNumber}',
                  stage.displayName,
                  AppColors.jade,
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.jade.withValues(alpha: 0.2)),
              Expanded(
                child: _buildXpProgress(context, state, stage),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildXpProgress(BuildContext context, GamificationState state, QuetzalEvolutionStage stage) {
    final nextStage = _getNextStage(stage);
    final currentMinXp = stage.minXp;
    final nextMinXp = nextStage?.minXp ?? state.quetzalXp;
    final progress = nextStage != null
        ? (state.quetzalXp - currentMinXp) / (nextMinXp - currentMinXp)
        : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'XP: ${state.quetzalXp}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.pergaminoClaro,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (nextStage != null)
              Text(
                'Siguiente: $nextMinXp',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.pergaminoClaro.withValues(alpha: 0.6),
                    ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.pergaminoClaro.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.jade),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_rounded, size: 14, color: AppColors.pergaminoClaro.withValues(alpha: 0.6)),
            const SizedBox(width: 4),
            Text(
              '${state.feathersCount} Plumas de Sabiduría',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.pergaminoClaro.withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      ],
    );
  }

  QuetzalEvolutionStage? _getNextStage(QuetzalEvolutionStage current) {
    final values = QuetzalEvolutionStage.values;
    final index = values.indexOf(current);
    if (index < values.length - 1) return values[index + 1];
    return null;
  }

  Widget _buildXolotlShieldsSection(BuildContext context, GamificationState state) {
    const maxShields = 2;
    final currentShields = state.xolotlShields.clamp(0, maxShields);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pergaminoClaro.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.turquesa.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_rounded, color: AppColors.turquesa, size: 22),
              const SizedBox(width: 10),
              Text(
                'Manto de Xólotl',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.pergaminoClaro,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Escudos que protegen tu racha si pierdes un día.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.pergaminoClaro.withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(maxShields, (index) {
              final isActive = index < currentShields;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Semantics(
                  label: isActive ? 'Escudo ${index + 1} activo' : 'Escudo ${index + 1} disponible',
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.turquesa.withValues(alpha: 0.2)
                          : AppColors.pergaminoClaro.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive ? AppColors.turquesa : AppColors.turquesa.withValues(alpha: 0.3),
                        width: isActive ? 2.5 : 1.5,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppColors.turquesa.withValues(alpha: 0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      isActive ? Icons.shield_rounded : Icons.shield_outlined,
                      color: isActive ? AppColors.turquesa : AppColors.turquesa.withValues(alpha: 0.4),
                      size: 28,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '$currentShields / $maxShields escudos',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: currentShields > 0 ? AppColors.turquesa : AppColors.pergaminoClaro.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelicsSection(BuildContext context, List<UnlockedRelic> relics) {
    final hasRelics = relics.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pergaminoClaro.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.oro.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.diamond_rounded, color: AppColors.oro, size: 22),
              const SizedBox(width: 10),
              Text(
                'Reliquias Desbloqueadas',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.pergaminoClaro,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasRelics)
            Center(
              child: Column(
                children: [
                  Icon(Icons.lock_outline_rounded, color: AppColors.pergaminoClaro.withValues(alpha: 0.3), size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Aún no has desbloqueado reliquias',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.pergaminoClaro.withValues(alpha: 0.6),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Escribe en tu diario, cosecha plantas\ny escribe de noche para invocar a los dioses.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.pergaminoClaro.withValues(alpha: 0.4),
                        ),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: relics.map((relic) => _buildRelicCard(context, relic)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildRelicCard(BuildContext context, UnlockedRelic relic) {
    final catalog = relic.catalog;
    final color = _getRelicColor(catalog);
    final icon = _getRelicIcon(catalog);

    return Semantics(
      label: 'Reliquia ${catalog.name}, desbloqueada',
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.5),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              catalog.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.pergaminoClaro,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              _getRelicShortDescription(catalog),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.pergaminoClaro.withValues(alpha: 0.5),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRelicColor(DeityRelicCatalog catalog) {
    return switch (catalog) {
      DeityRelicCatalog.vasijaTlaloc => AppColors.turquesa,
      DeityRelicCatalog.mariposasXochiquetzal => AppColors.rosaSuave,
      DeityRelicCatalog.xolotlCompanion => AppColors.turquesa,
    };
  }

  String _getRelicShortDescription(DeityRelicCatalog catalog) {
    return switch (catalog) {
      DeityRelicCatalog.vasijaTlaloc => '3+ entradas de lluvia',
      DeityRelicCatalog.mariposasXochiquetzal => '3+ plantas cosechadas',
      DeityRelicCatalog.xolotlCompanion => 'Escribir tras 21h o 2+ noches',
    };
  }

  IconData _getRelicIcon(DeityRelicCatalog catalog) {
    return switch (catalog) {
      DeityRelicCatalog.vasijaTlaloc => Icons.water_drop_rounded,
      DeityRelicCatalog.mariposasXochiquetzal => Icons.flutter_dash_rounded,
      DeityRelicCatalog.xolotlCompanion => Icons.pets_rounded,
    };
  }

  Widget _buildCloseButton(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Cerrar estado del Fuego Sagrado',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
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
                  'Cerrar',
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

/// Llama animada del Fuego Sagrado.
class _AnimatedFlame extends StatefulWidget {
  const _AnimatedFlame({required this.tier});

  final SacredFireTier tier;

  @override
  State<_AnimatedFlame> createState() => _AnimatedFlameState();
}

class _AnimatedFlameState extends State<_AnimatedFlame> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(100, 100),
          painter: _FlamePainter(
            progress: _controller.value,
            tier: widget.tier,
          ),
        );
      },
    );
  }
}

class _FlamePainter extends CustomPainter {
  _FlamePainter({required this.progress, required this.tier});

  final double progress;
  final SacredFireTier tier;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final baseY = size.height * 0.9;
    final colors = tier.gradientColors;

    // Base del brasero
    final basePaint = Paint()
      ..color = AppColors.obsidiana.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final basePath = Path()
      ..moveTo(centerX - 30, baseY)
      ..lineTo(centerX + 30, baseY)
      ..lineTo(centerX + 20, baseY - 15)
      ..lineTo(centerX - 20, baseY - 15)
      ..close();
    canvas.drawPath(basePath, basePaint);

    // Llamas (3 capas con diferentes fases)
    for (var i = 0; i < 3; i++) {
      _drawFlameLayer(canvas, centerX, baseY - 15, i, colors);
    }

    // Resplandor central
    final glowPaint = Paint()
      ..color = colors.first.withValues(alpha: 0.3 * (0.8 + 0.2 * progress))
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);

    canvas.drawCircle(
      Offset(centerX, baseY - 40 - 10 * progress),
      30 + 10 * progress,
      glowPaint,
    );
  }

  void _drawFlameLayer(Canvas canvas, double centerX, double baseY, int layerIndex, List<Color> colors) {
    final layerProgress = progress + layerIndex * 0.3;
    final flicker = math.sin(layerProgress * 2 * 3.14159).abs();
    final height = 50 + 15 * flicker;
    final width = 18 + 6 * flicker;
    final offsetX = (layerIndex - 1) * 8 + 4 * math.sin(layerProgress * 3.14159);

    final gradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        colors[0].withValues(alpha: 0.9),
        if (colors.length > 1) colors[1].withValues(alpha: 0.7) else colors[0].withValues(alpha: 0.5),
        if (colors.length > 2) colors[2].withValues(alpha: 0.4) else colors.last.withValues(alpha: 0.3),
        Colors.white.withValues(alpha: 0.2 * flicker),
      ],
      stops: const [0.0, 0.4, 0.7, 1.0],
    );

    final flamePaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(centerX + offsetX - width / 2, baseY - height, width, height),
      )
      ..style = PaintingStyle.fill;

    final flamePath = Path();
    flamePath.moveTo(centerX + offsetX, baseY);

    // Lado izquierdo
    for (var t = 0.0; t <= 1.0; t += 0.1) {
      final wave = math.sin(t * 3.14159 * 2 + layerProgress * 2) * width * 0.25;
      final y = baseY - t * height;
      final x = centerX + offsetX - width / 2 + wave;
      flamePath.lineTo(x, y);
    }

    // Punta
    flamePath.lineTo(centerX + offsetX, baseY - height);

    // Lado derecho
    for (var t = 1.0; t >= 0.0; t -= 0.1) {
      final wave = math.sin(t * 3.14159 * 2 + layerProgress * 2 + 1) * width * 0.25;
      final y = baseY - t * height;
      final x = centerX + offsetX + width / 2 + wave;
      flamePath.lineTo(x, y);
    }

    flamePath.close();
    canvas.drawPath(flamePath, flamePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _FlamePainter &&
        (oldDelegate.progress != progress || oldDelegate.tier != tier);
  }
}