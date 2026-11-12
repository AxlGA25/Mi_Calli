// Layer 2 — Partículas de clima (lluvia, viento, tormentas, estrellas, luciérnagas).
//
// Widgets animados que superponen efectos de partículas según el
// clima emocional activo y la fase horaria.
// Se envuelven en SafeAnimationWrapper (en la pantalla) para respetar reduceMotion.

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:mi_calli/core/audio/ambient_audio_models.dart';
import 'package:mi_calli/core/constants/app_colors.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/prehispanic_emotion.dart';

/// Clave global para acceder a esta capa en tests.
final GlobalKey valleyWeatherParticlesLayerKey = GlobalKey(debugLabel: 'valleyWeatherParticlesLayer');

/// Widget que muestra partículas de clima según el emotionOverride y la fase horaria.
class ValleyWeatherParticlesLayer extends StatelessWidget {
  const ValleyWeatherParticlesLayer({
    super.key,
    this.emotionOverride,
    required this.timePhase,
  });

  /// Clima emocional que determina qué partículas mostrar.
  final PrehispanicEmotion? emotionOverride;

  /// Fase horaria actual (para estrellas/luciérnagas en noche).
  final ValleyTimePhase timePhase;

  @override
  Widget build(BuildContext context) {
    // Si hay clima emocional, mostrar sus partículas
    if (emotionOverride != null) {
      return switch (emotionOverride!) {
        PrehispanicEmotion.tlalocLluvia => const _RainParticlesWidget(),
        PrehispanicEmotion.ehecatlViento => const _WindParticlesWidget(),
        PrehispanicEmotion.mixcoatlTormenta => const _StormParticlesWidget(),
        // Tonatiuh y Metztli no tienen partículas específicas (usan overlays en Layer 0)
        PrehispanicEmotion.tonatiuhSol => const SizedBox.shrink(),
        PrehispanicEmotion.metztliNoche => const SizedBox.shrink(),
      };
    }

    // Sin clima emocional: mostrar estrellas/luciérnagas en noche
    if (timePhase == ValleyTimePhase.night) {
      return const _NightAmbientParticlesWidget();
    }

    // En otras fases sin emoción, no mostrar nada
    return const SizedBox.shrink();
  }
}

/// Partículas ambientales nocturnas (estrellas titilando + luciérnagas)
class _NightAmbientParticlesWidget extends StatefulWidget {
  const _NightAmbientParticlesWidget();

  @override
  State<_NightAmbientParticlesWidget> createState() => _NightAmbientParticlesWidgetState();
}

class _NightAmbientParticlesWidgetState extends State<_NightAmbientParticlesWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
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
          size: Size.infinite,
          painter: _NightAmbientPainter(_controller.value),
        );
      },
    );
  }
}

class _NightAmbientPainter extends CustomPainter {
  _NightAmbientPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    // Estrellas titilando (parte superior 60% de la pantalla)
    final starPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5 + 0.4 * progress)
      ..style = PaintingStyle.fill;

    const starCount = 60;
    for (var i = 0; i < starCount; i++) {
      final seed = i * 17.3;
      final x = (seed * 11.7) % size.width;
      final y = (seed * 7.3) % (size.height * 0.6);
      final baseRadius = 1.0 + (i % 3) * 0.5;
      final radius = baseRadius * (0.7 + 0.3 * progress);

      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }

    // Luciérnagas en la parte baja (últimos 40% de la pantalla)
    final fireflyPaint = Paint()
      ..color = const Color(0xFFE9C46A).withValues(alpha: 0.4 + 0.4 * progress)
      ..style = PaintingStyle.fill;

    const fireflyCount = 20;
    for (var i = 0; i < fireflyCount; i++) {
      final seed = i * 23.7;
      final x = size.width * 0.1 + (seed * 11.7) % (size.width * 0.8);
      final y = size.height * 0.5 + (seed * 7.3) % (size.height * 0.35);
      final baseRadius = 1.5 + (i % 2) * 1.0;
      final radius = baseRadius * (0.6 + 0.4 * progress);

      canvas.drawCircle(Offset(x, y), radius, fireflyPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _NightAmbientPainter && oldDelegate.progress != progress;
  }
}

/// Lluvia de Tláloc - partículas de gotas cayendo
class _RainParticlesWidget extends StatefulWidget {
  const _RainParticlesWidget();

  @override
  State<_RainParticlesWidget> createState() => _RainParticlesWidgetState();
}

class _RainParticlesWidgetState extends State<_RainParticlesWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat();
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
          size: Size.infinite,
          painter: _RainParticlesPainter(_controller.value),
        );
      },
    );
  }
}

class _RainParticlesPainter extends CustomPainter {
  _RainParticlesPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.turquesa.withValues(alpha: 0.6)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    const dropCount = 50;
    for (var i = 0; i < dropCount; i++) {
      // Posición pseudo-aleatoria basada en índice
      final seedX = (i * 37.1) % size.width;
      final seedY = (i * 43.7) % size.height;
      final speedVariation = 1.0 + (i % 4) * 0.3;
      final length = 12.0 + (i % 3) * 6.0;

      final x = (seedX + progress * size.width * 0.1) % size.width;
      final y = (seedY + progress * size.height * speedVariation) % size.height;

      canvas.drawLine(
        Offset(x, y),
        Offset(x - length * 0.2, y + length),
        paint,
      );
    }

    // Gotas más gruesas en primer plano (simulación de profundidad)
    final foregroundPaint = Paint()
      ..color = AppColors.turquesa.withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const fgDropCount = 15;
    for (var i = 0; i < fgDropCount; i++) {
      final seedX = (i * 73.3 + size.width * 0.5) % size.width;
      final seedY = (i * 59.9 + size.height * 0.5) % size.height;
      final speedVariation = 1.5 + (i % 3) * 0.4;
      final length = 20.0 + (i % 2) * 8.0;

      final x = (seedX + progress * size.width * 0.15) % size.width;
      final y = (seedY + progress * size.height * speedVariation) % size.height;

      canvas.drawLine(
        Offset(x, y),
        Offset(x - length * 0.3, y + length),
        foregroundPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _RainParticlesPainter && oldDelegate.progress != progress;
  }
}

/// Viento de Ehécatl - líneas de corriente animadas
class _WindParticlesWidget extends StatefulWidget {
  const _WindParticlesWidget();

  @override
  State<_WindParticlesWidget> createState() => _WindParticlesWidgetState();
}

class _WindParticlesWidgetState extends State<_WindParticlesWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
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
          size: Size.infinite,
          painter: _WindParticlesPainter(_controller.value),
        );
      },
    );
  }
}

class _WindParticlesPainter extends CustomPainter {
  _WindParticlesPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.turquesa.withValues(alpha: 0.35)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const streamCount = 12;
    for (var i = 0; i < streamCount; i++) {
      final startY = size.height * (0.08 + i * 0.07);
      final amplitude = 15.0 + (i % 3) * 8.0;
      final frequency = 0.008 + (i % 2) * 0.004;

      final path = Path();
      path.moveTo(-30, startY);

      for (var x = -30.0; x < size.width + 30; x += 5.0) {
        final waveOffset = math.sin((x + progress * size.width) * frequency) * amplitude;
        final y = startY + waveOffset + progress * 30 * (i % 2 == 0 ? 1 : -1);
        path.lineTo(x, y);
      }

      canvas.drawPath(path, paint);
    }

    // Partículas de polvo/hojas arrastradas por el viento
    final particlePaint = Paint()
      ..color = AppColors.turquesa.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    const particleCount = 25;
    for (var i = 0; i < particleCount; i++) {
      final seed = i * 17.3;
      final x = (seed * 11.7 + progress * size.width * 0.8) % (size.width + 60) - 30;
      final baseY = size.height * (0.15 + (i % 8) * 0.08);
      final y = baseY + math.sin((seed + progress * 20) * 0.1) * 20;
      final radius = 1.5 + (i % 3) * 0.8;

      canvas.drawCircle(Offset(x, y), radius, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _WindParticlesPainter && oldDelegate.progress != progress;
  }
}

/// Tormenta de Mixcóatl - lluvia intensa + relámpagos + viento
class _StormParticlesWidget extends StatefulWidget {
  const _StormParticlesWidget();

  @override
  State<_StormParticlesWidget> createState() => _StormParticlesWidgetState();
}

class _StormParticlesWidgetState extends State<_StormParticlesWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _lightningTimer;
  double _lightningProgress = 0.0;
  int _lightningPhase = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    )..repeat();

    // Relámpagos cada 2-5 segundos
    _scheduleLightning();
  }

  void _scheduleLightning() {
    _lightningTimer?.cancel();
    final delay = Duration(milliseconds: 2000 + (DateTime.now().millisecond % 3000));
    _lightningTimer = Timer(delay, () {
      if (mounted) {
        setState(() {
          _lightningProgress = 1.0;
          _lightningPhase = DateTime.now().millisecond % 3;
        });
        // Desvanecer relámpago
        Timer(const Duration(milliseconds: 80), () {
          if (mounted) {
            setState(() => _lightningProgress = 0.0);
          }
        });
        _scheduleLightning();
      }
    });
  }

  @override
  void dispose() {
    _lightningTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _StormParticlesPainter(
            rainProgress: _controller.value,
            lightningProgress: _lightningProgress,
            lightningPhase: _lightningPhase,
          ),
        );
      },
    );
  }
}

class _StormParticlesPainter extends CustomPainter {
  _StormParticlesPainter({
    required this.rainProgress,
    required this.lightningProgress,
    required this.lightningPhase,
  });

  final double rainProgress;
  final double lightningProgress;
  final int lightningPhase;

  @override
  void paint(Canvas canvas, Size size) {
    // Lluvia intensa (más gotas, más rápidas)
    final rainPaint = Paint()
      ..color = AppColors.turquesa.withValues(alpha: 0.7)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    const dropCount = 80;
    for (var i = 0; i < dropCount; i++) {
      final seedX = (i * 23.7) % size.width;
      final seedY = (i * 31.1) % size.height;
      final speedVariation = 1.5 + (i % 5) * 0.4;
      final length = 18.0 + (i % 4) * 5.0;

      final x = (seedX + rainProgress * size.width * 0.05) % size.width;
      final y = (seedY + rainProgress * size.height * speedVariation) % size.height;

      canvas.drawLine(
        Offset(x, y),
        Offset(x - length * 0.25, y + length),
        rainPaint,
      );
    }

    // Viento horizontal (líneas diagonales)
    final windPaint = Paint()
      ..color = AppColors.turquesa.withValues(alpha: 0.25)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const windStreamCount = 10;
    for (var i = 0; i < windStreamCount; i++) {
      final startY = size.height * (0.1 + i * 0.08);
      final path = Path();
      path.moveTo(-50, startY);

      for (var x = -50.0; x < size.width + 50; x += 8.0) {
        final y = startY + math.sin((x + rainProgress * size.width) * 0.01) * 12;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, windPaint);
    }

    // Relámpagos
    if (lightningProgress > 0.0) {
      _drawLightning(canvas, size);
    }
  }

  void _drawLightning(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9 * lightningProgress)
      ..strokeWidth = 2.5 + lightningProgress * 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3 * lightningProgress)
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final startX = size.width * (0.25 + lightningPhase * 0.25);
    final path = Path();
    path.moveTo(startX, 0);

    // Ramificación principal
    double currentX = startX;
    double currentY = 0.0;

    for (var segment = 0; segment < 6; segment++) {
      final nextY = currentY + size.height / 7;
      final nextX = currentX + (size.width * 0.15 - 30.0) * (math.Random(segment * 7 + lightningPhase * 100).nextDouble() - 0.5);

      path.lineTo(nextX, nextY);

      // Rama secundaria ocasional
      if (segment % 2 == 0 && math.Random(segment + lightningPhase * 50).nextDouble() < 0.3) {
        final branchPath = Path();
        branchPath.moveTo(currentX, currentY);
        branchPath.lineTo(
          currentX + (math.Random(segment * 11 + lightningPhase * 200).nextDouble() - 0.5) * 60,
          nextY,
        );
        canvas.drawPath(branchPath, paint);
        canvas.drawPath(branchPath, glowPaint);
      }

      currentX = nextX;
      currentY = nextY;
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);

    // Flash de pantalla completa
    if (lightningProgress > 0.5) {
      final flashPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.15 * lightningProgress);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), flashPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _StormParticlesPainter &&
        (oldDelegate.rainProgress != rainProgress ||
         oldDelegate.lightningProgress != lightningProgress ||
         oldDelegate.lightningPhase != lightningPhase);
  }
}