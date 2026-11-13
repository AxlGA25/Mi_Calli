// Pantalla principal del Valle de Teotihuacán (Tarea 4.3).
//
// Stack que compone las 5 capas visuales del Valle con el ciclo día/noche.
// Incluye HUD superior (Layer 4) y 5 zonas táctiles accesibles en Layer 3.
// Acepta currentTimeOverride y emotionOverride para testing y control externo.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

import 'package:mi_calli/core/audio/ambient_audio_models.dart';
import 'package:mi_calli/core/audio/ambient_audio_service.dart';
import 'package:mi_calli/core/performance/safe_animation_wrapper.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/prehispanic_emotion.dart';
import 'package:mi_calli/features/1_sanctuary_journal/presentation/sanctuary_journal_screen.dart';
import 'package:mi_calli/features/1_sanctuary_journal/presentation/private_codex_screen.dart';
import 'package:mi_calli/features/2_gamification/models/deity_relic_models.dart';
import 'package:mi_calli/features/2_gamification/providers/relics_provider.dart';
import 'package:mi_calli/features/2_gamification/services/tonalpohualli_generator.dart';
import 'package:mi_calli/features/2_gamification/presentation/tonalpohualli_scroll_dialog.dart';
import 'package:mi_calli/features/3_teotihuacan_valley/presentation/widgets/chinampa_bottom_sheet.dart';
import 'package:mi_calli/features/3_teotihuacan_valley/presentation/widgets/sacred_fire_status_dialog.dart';
import 'package:mi_calli/features/3_teotihuacan_valley/presentation/widgets/valley_pyramids_background_layer.dart';
import 'package:mi_calli/features/3_teotihuacan_valley/presentation/widgets/valley_scenic_elements_layer.dart';
import 'package:mi_calli/features/3_teotihuacan_valley/presentation/widgets/valley_sky_gradient_layer.dart';
import 'package:mi_calli/features/3_teotihuacan_valley/presentation/widgets/valley_top_hud_layer.dart';
import 'package:mi_calli/features/3_teotihuacan_valley/presentation/widgets/valley_weather_particles_layer.dart';

/// Clave global para la pantalla completa (tests de integración).
final GlobalKey teotihuacanValleyScreenKey = GlobalKey(debugLabel: 'teotihuacanValleyScreen');

/// Pantalla principal del Valle de Teotihuacán.
///
/// Composición de capas (de fondo a frente):
/// 1. ValleySkyGradientLayer - Cielo con gradiente, astro, clima emocional
/// 2. ValleyPyramidsBackgroundLayer - Pirámides del Sol, Luna y Templo de los Códices
/// 3. ValleyWeatherParticlesLayer - Partículas de clima (lluvia, viento, tormenta, estrellas, luciérnagas)
/// 4. ValleyScenicElementsLayer - Elementos protagonistas + 5 zonas táctiles accesibles
/// 5. ValleyTopHudLayer - HUD superior con 3 botones (Audio, Ajustes, Caracol SOS)
///
/// Parámetros opcionales para control externo y testing:
/// - [currentTimeOverride]: Si se proporciona, fuerza la fase horaria calculando desde esta hora local.
/// - [emotionOverride]: Si se proporciona, fuerza el clima emocional (sobreescribe el provider).
/// - [forceVenusAvailable]: Si true, fuerza la disponibilidad de la Constelación de Venus (testing).
class TeotihuacanValleyScreen extends ConsumerWidget {
  const TeotihuacanValleyScreen({
    super.key,
    this.currentTimeOverride,
    this.emotionOverride,
    this.forceVenusAvailable = false,
  });

  /// Hora actual forzada para calcular la fase horaria (para testing/demo).
  /// Si es null, usa la hora local actual o el provider reactivo.
  final DateTime? currentTimeOverride;

  /// Clima emocional forzado (para testing/demo o escritura en diario).
  /// Si es null, usa el provider reactivo.
  final PrehispanicEmotion? emotionOverride;

  /// Si true, fuerza la disponibilidad de la Constelación de Venus (para testing).
  final bool forceVenusAvailable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Leer estado reactivo del audio ambiental
    final providerTimePhase = ref.watch(ambientAudioCurrentTimePhaseProvider);
    final providerEmotionOverride = ref.watch(ambientAudioCurrentEmotionOverrideProvider);
    final hasTlalocRelic = ref.watch(userRelicsProvider).maybeWhen(
      data: (relics) => relics.any((r) => r.deity == DeityId.tlaloc),
      orElse: () => false,
    );
    final hasXochiquetzalRelic = ref.watch(userRelicsProvider).maybeWhen(
      data: (relics) => relics.any((r) => r.deity == DeityId.xochiquetzal),
      orElse: () => false,
    );
    final hasXolotlRelic = ref.watch(userRelicsProvider).maybeWhen(
      data: (relics) => relics.any((r) => r.deity == DeityId.xolotl),
      orElse: () => false,
    );
    // Disponibilidad de la lectura del Tonalpohualli (Constelación de Venus)
    final isVenusAvailable = ref.watch(isTonalpohualliAvailableProvider).maybeWhen(
      data: (available) => available,
      orElse: () => false,
    );

    // Resolver fase horaria: override > provider > hora local actual
    final resolvedTimePhase = currentTimeOverride != null
        ? ValleyTimePhase.fromHour(currentTimeOverride!.toLocal().hour)
        : providerTimePhase;

    // Resolver clima emocional: override > provider
    final resolvedEmotionOverride = emotionOverride ?? providerEmotionOverride;

    // Xólotl es visible de noche O si tiene la reliquia de noche
    final showXolotl = resolvedTimePhase == ValleyTimePhase.night || hasXolotlRelic;

    return OrientationBuilder(
      builder: (context, orientation) {
        return SafeArea(
          top: true,
          bottom: true,
          left: false,
          right: false,
          child: Scaffold(
            key: teotihuacanValleyScreenKey,
            extendBodyBehindAppBar: true,
            backgroundColor: Colors.transparent,
            // Sin FAB, sin AppBar, sin Drawer, sin BottomNavigationBar
            body: _ValleyStack(
              timePhase: resolvedTimePhase,
              emotionOverride: resolvedEmotionOverride,
              hasTlalocRelic: hasTlalocRelic,
              hasXochiquetzalRelic: hasXochiquetzalRelic,
              hasXolotlRelic: hasXolotlRelic,
              showXolotl: showXolotl,
              isVenusAvailable: isVenusAvailable,
              forceVenusAvailable: forceVenusAvailable,
              orientation: orientation,
            ),
          ),
        );
      },
    );
  }
}

/// Stack principal con las 5 capas visuales.
class _ValleyStack extends ConsumerWidget {
  const _ValleyStack({
    required this.timePhase,
    required this.emotionOverride,
    required this.hasTlalocRelic,
    required this.hasXochiquetzalRelic,
    required this.hasXolotlRelic,
    required this.showXolotl,
    required this.isVenusAvailable,
    required this.forceVenusAvailable,
    required this.orientation,
  });

  final ValleyTimePhase timePhase;
  final PrehispanicEmotion? emotionOverride;
  final bool hasTlalocRelic;
  final bool hasXochiquetzalRelic;
  final bool hasXolotlRelic;
  final bool showXolotl;
  final bool isVenusAvailable;
  final bool forceVenusAvailable;
  final Orientation orientation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Callbacks para las 5 zonas táctiles
    void openSanctuaryJournal() {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const SanctuaryJournalScreen(),
        ),
      );
    }

    void openChinampa() {
      ChinampaBottomSheet.show(context);
    }

    void openSacredFire() {
      SacredFireStatusDialog.show(context);
    }

    void openCodex() {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const PrivateCodexScreen(),
        ),
      );
    }

    Future<void> openVenusReading() async {
      final generator = ref.read(tonalpohualliGeneratorProvider);
      final reading = await generator.generateWeeklyReading(markAsOpened: true);
      if (reading != null && context.mounted) {
        // Invalidar provider de disponibilidad para que se actualice
        ref.invalidate(isTonalpohualliAvailableProvider);
        // Mostrar diálogo usando el método estático
        await TonalpohualliScrollDialog.show(context, reading: reading);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay entradas suficientes para la lectura astral esta semana'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 0: Cielo (gradiente + astro + clima emocional overlay)
        ValleySkyGradientLayer(
          key: valleySkyLayerKey,
          timePhase: timePhase,
          emotionOverride: emotionOverride,
          hasXolotlRelic: hasXolotlRelic,
        ),

        // Layer 1: Pirámides de fondo + Templo de los Códices (con RepaintBoundary)
        RepaintBoundary(
          key: valleyPyramidsLayerKey,
          child: ValleyPyramidsBackgroundLayer(
            timePhase: timePhase,
            emotionOverride: emotionOverride,
          ),
        ),

        // Layer 2: Partículas de clima (con SafeAnimationWrapper + RepaintBoundary)
        // La key va en ValleyWeatherParticlesLayer para testing
        SafeAnimationWrapper(
          fallbackBehavior: SafeAnimationFallbackBehavior.onReduceMotion,
          // El fallback son partículas estáticas (CustomPaint estático)
          fallbackWidget: _StaticWeatherParticles(
            emotionOverride: emotionOverride,
            timePhase: timePhase,
          ),
          child: RepaintBoundary(
            key: valleyWeatherParticlesLayerKey,
            child: ValleyWeatherParticlesLayer(
              emotionOverride: emotionOverride,
              timePhase: timePhase,
            ),
          ),
        ),

        // Layer 3: Elementos escénicos protagonistas + 5 zonas táctiles (con RepaintBoundary)
        RepaintBoundary(
          key: valleyScenicElementsLayerKey,
          child: ValleyScenicElementsLayer(
            timePhase: timePhase,
            emotionOverride: emotionOverride,
            hasXochiquetzalRelic: hasXochiquetzalRelic,
            hasXolotlRelic: hasXolotlRelic,
            showXolotl: showXolotl,
            hasTlalocRelic: hasTlalocRelic,
            onOpenSanctuaryJournal: openSanctuaryJournal,
            onOpenChinampa: openChinampa,
            onOpenSacredFire: openSacredFire,
            onOpenCodex: openCodex,
            onOpenVenusReading: openVenusReading,
            forceVenusAvailable: forceVenusAvailable,
          ),
        ),

        // Layer 4: HUD Superior con 3 botones flotantes
        ValleyTopHudLayer(
          onOpenSettings: () {
            // El HUD maneja su propio modal provisional de ajustes
          },
          onOpenSanctuaryJournal: openSanctuaryJournal,
          onOpenCodex: openCodex,
        ),

        // Indicador de reducción de movimiento (accesibilidad)
        if (MediaQuery.maybeOf(context)?.disableAnimations == true)
          const _ReduceMotionIndicator(),
      ],
    );
  }
}

/// Partículas estáticas para fallback cuando reduceMotion está activo.
class _StaticWeatherParticles extends StatelessWidget {
  const _StaticWeatherParticles({
    required this.emotionOverride,
    required this.timePhase,
  });

  final PrehispanicEmotion? emotionOverride;
  final ValleyTimePhase timePhase;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _StaticWeatherPainter(
        emotionOverride: emotionOverride,
        timePhase: timePhase,
      ),
    );
  }
}

class _StaticWeatherPainter extends CustomPainter {
  _StaticWeatherPainter({
    required this.emotionOverride,
    required this.timePhase,
  });

  final PrehispanicEmotion? emotionOverride;
  final ValleyTimePhase timePhase;

  @override
  void paint(Canvas canvas, Size size) {
    // Dibujar partículas estáticas según emoción
    if (emotionOverride == PrehispanicEmotion.tlalocLluvia) {
      _drawStaticRain(canvas, size);
    } else if (emotionOverride == PrehispanicEmotion.ehecatlViento) {
      _drawStaticWind(canvas, size);
    } else if (emotionOverride == PrehispanicEmotion.mixcoatlTormenta) {
      _drawStaticStorm(canvas, size);
    }

    // En noche, dibujar estrellas estáticas y luciérnagas estáticas
    if (timePhase == ValleyTimePhase.night) {
      _drawStaticStars(canvas, size);
      _drawStaticFireflies(canvas, size);
    }
  }

  void _drawStaticRain(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF48CAE4).withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    const dropCount = 40;
    for (var i = 0; i < dropCount; i++) {
      final seedX = (i * 37.1) % size.width;
      final seedY = (i * 43.7) % size.height;
      final length = 12.0 + (i % 3) * 6.0;

      canvas.drawLine(
        Offset(seedX, seedY),
        Offset(seedX - length * 0.2, seedY + length),
        paint,
      );
    }
  }

  void _drawStaticWind(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF48CAE4).withValues(alpha: 0.35)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const streamCount = 8;
    for (var i = 0; i < streamCount; i++) {
      final startY = size.height * (0.15 + i * 0.1);
      final path = Path();
      path.moveTo(-30, startY);

      for (var x = -30.0; x < size.width + 30; x += 5.0) {
        final y = startY + math.sin(x * 0.01) * 15;
        path.lineTo(x, y);
      }

      canvas.drawPath(path, paint);
    }
  }

  void _drawStaticStorm(Canvas canvas, Size size) {
    // Lluvia intensa estática
    _drawStaticRain(canvas, size);
    // Viento estático
    _drawStaticWind(canvas, size);
    // Relámpago estático (una línea zigzag)
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.3, 0)
      ..lineTo(size.width * 0.35, size.height * 0.2)
      ..lineTo(size.width * 0.28, size.height * 0.2)
      ..lineTo(size.width * 0.38, size.height * 0.5)
      ..lineTo(size.width * 0.32, size.height * 0.5)
      ..lineTo(size.width * 0.38, size.height * 0.8);

    canvas.drawPath(path, paint);
  }

  void _drawStaticStars(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    const starCount = 50;
    for (var i = 0; i < starCount; i++) {
      final seed = i * 17.3;
      final x = (seed * 11.7) % size.width;
      final y = (seed * 7.3) % (size.height * 0.6);
      final radius = 1.0 + (i % 3) * 0.5;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  void _drawStaticFireflies(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE9C46A).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    const fireflyCount = 15;
    for (var i = 0; i < fireflyCount; i++) {
      final seed = i * 23.7;
      final x = size.width * 0.1 + (seed * 11.7) % (size.width * 0.8);
      final y = size.height * 0.5 + (seed * 7.3) % (size.height * 0.3);
      final radius = 1.5 + (i % 2) * 1.0;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _StaticWeatherPainter &&
        oldDelegate.emotionOverride != emotionOverride &&
        oldDelegate.timePhase != timePhase;
  }
}

/// Indicador visual cuando el usuario tiene "reducir movimiento" activado.
class _ReduceMotionIndicator extends StatelessWidget {
  const _ReduceMotionIndicator();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.accessibility_new_rounded,
              size: 14,
              color: const Color(0xFFE9C46A),
            ),
            const SizedBox(width: 6),
            Text(
              'Movimiento reducido',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}