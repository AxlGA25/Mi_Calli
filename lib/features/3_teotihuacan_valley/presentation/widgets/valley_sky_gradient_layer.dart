// Layer 0 — Cielo del Valle de Teotihuacán.
//
// AnimatedContainer que pinta el gradiente del cielo según las 4 fases
// del ciclo día/noche, con superposición opcional de clima emocional
// y astro celeste correspondiente (Sol/Luna/Constelación).

import 'package:flutter/material.dart';

import 'package:mi_calli/core/audio/ambient_audio_models.dart';
import 'package:mi_calli/core/constants/app_colors.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/prehispanic_emotion.dart';

/// Clave global para acceder a esta capa en tests.
final GlobalKey valleySkyLayerKey = GlobalKey(debugLabel: 'valleySkyLayer');

/// Widget que muestra el cielo del Valle con gradiente animado según
/// la fase horaria y/o el clima emocional activo.
class ValleySkyGradientLayer extends StatelessWidget {
  const ValleySkyGradientLayer({
    super.key,
    required this.timePhase,
    this.emotionOverride,
    this.hasXolotlRelic = false,
  });

  /// Fase horaria actual (dawn, day, dusk, night).
  final ValleyTimePhase timePhase;

  /// Clima emocional que sobrescribe la atmósfera (opcional).
  final PrehispanicEmotion? emotionOverride;

  /// Si el usuario tiene la reliquia de Xochiquétzal (mariposas).
  /// Se usa para decidir si mostrar mariposas en el cielo diurno.
  final bool hasXolotlRelic;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final gradient = _resolveGradient();
    final showCelestialBody = _shouldShowCelestialBody();
    final celestialAlignment = _celestialAlignment();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        children: [
          // Astro celeste (Sol/Luna/Constelación)
          if (showCelestialBody) _buildCelestialBody(context, celestialAlignment),

          // Superposición de clima emocional (niebla, lluvia, viento, etc.)
          if (emotionOverride != null) _buildEmotionOverlay(context),

          // Neblina suave al ras del horizonte en amanecer
          if (timePhase == ValleyTimePhase.dawn) _buildDawnMist(context),

          // Constelación de Venus en la noche (si no hay emotionOverride)
          if (timePhase == ValleyTimePhase.night && emotionOverride == null)
            _buildVenusConstellation(context),
        ],
      ),
    );
  }

  /// Resuelve el gradiente combinando fase horaria y emoción.
  LinearGradient _resolveGradient() {
    final baseGradient = _baseGradientForPhase(timePhase);

    if (emotionOverride == null) {
      return baseGradient;
    }

    // Mezcla suave: 70% fase horaria + 30% emoción
    final emotionGradient = _gradientForEmotion(emotionOverride!);
    return _blendGradients(baseGradient, emotionGradient, 0.7);
  }

  LinearGradient _baseGradientForPhase(ValleyTimePhase phase) {
    return switch (phase) {
      ValleyTimePhase.dawn => const LinearGradient(
          colors: [Color(0xFFFF9E80), Color(0xFFFFD180)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ValleyTimePhase.day => AppColors.gradientDia,
      ValleyTimePhase.dusk => const LinearGradient(
          colors: [Color(0xFF9D4EDD), Color(0xFFE76F51)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ValleyTimePhase.night => AppColors.gradientNoche,
    };
  }

  LinearGradient _gradientForEmotion(PrehispanicEmotion emotion) {
    return switch (emotion) {
      PrehispanicEmotion.tlalocLluvia => AppColors.gradientTlalocLluvia,
      PrehispanicEmotion.tonatiuhSol => AppColors.gradientTonatiuhSol,
      PrehispanicEmotion.ehecatlViento => AppColors.gradientEhecatlViento,
      PrehispanicEmotion.mixcoatlTormenta => AppColors.gradientMixcoatlTormenta,
      PrehispanicEmotion.metztliNoche => AppColors.gradientMetztliNoche,
    };
  }

  /// Mezcla dos gradientes con un factor [baseWeight] (0.0-1.0) para el base.
  LinearGradient _blendGradients(
    LinearGradient base,
    LinearGradient overlay,
    double baseWeight,
  ) {
    final baseColors = base.colors;
    final overlayColors = overlay.colors;
    final count = baseColors.length.clamp(0, overlayColors.length);

    final blendedColors = <Color>[];
    for (var i = 0; i < count; i++) {
      blendedColors.add(Color.lerp(baseColors[i], overlayColors[i], 1.0 - baseWeight)!);
    }

    return LinearGradient(
      colors: blendedColors,
      begin: base.begin,
      end: base.end,
    );
  }

  bool _shouldShowCelestialBody() {
    // Siempre mostrar astro salvo en emociones que lo ocultan
    if (emotionOverride == PrehispanicEmotion.metztliNoche ||
        emotionOverride == PrehispanicEmotion.mixcoatlTormenta) {
      return false;
    }
    return true;
  }

  Alignment _celestialAlignment() {
    // Posición del astro según fase
    return switch (timePhase) {
      ValleyTimePhase.dawn => const Alignment(-0.3, -0.6), // Sol naciente izquierda
      ValleyTimePhase.day => const Alignment(0.0, -0.7), // Sol cenital
      ValleyTimePhase.dusk => const Alignment(0.4, -0.3), // Sol poniente derecha
      ValleyTimePhase.night => const Alignment(-0.4, -0.6), // Luna izquierda
    };
  }

  Widget _buildCelestialBody(BuildContext context, Alignment alignment) {
    return Align(
      alignment: alignment,
      child: switch (timePhase) {
        ValleyTimePhase.dawn => _RisingSun(size: 80),
        ValleyTimePhase.day => _RadiantSun(size: 100),
        ValleyTimePhase.dusk => _SettingSun(size: 85),
        ValleyTimePhase.night => _MetztliMoon(size: 90),
      },
    );
  }

  Widget _buildEmotionOverlay(BuildContext context) {
    return switch (emotionOverride!) {
      PrehispanicEmotion.tlalocLluvia => const _TlalocRainOverlay(),
      PrehispanicEmotion.tonatiuhSol => const _TonatiuhGlowOverlay(),
      PrehispanicEmotion.ehecatlViento => const _EhecatlWindOverlay(),
      PrehispanicEmotion.mixcoatlTormenta => const _MixcoatlStormOverlay(),
      PrehispanicEmotion.metztliNoche => const _MetztliNightOverlay(),
    };
  }

  Widget _buildDawnMist(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.15,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.15),
                Colors.white.withValues(alpha: 0.05),
                Colors.transparent,
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVenusConstellation(BuildContext context) {
    return const _VenusConstellation();
  }
}

/// Sol naciente (amanecer)
class _RisingSun extends StatelessWidget {
  const _RisingSun({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xFFFFF3E0),
            const Color(0xFFFFD180),
            const Color(0xFFFF9E80).withValues(alpha: 0.3),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9E80).withValues(alpha: 0.4),
            blurRadius: size * 0.5,
            spreadRadius: size * 0.1,
          ),
        ],
      ),
    );
  }
}

/// Sol radiante (día)
class _RadiantSun extends StatelessWidget {
  const _RadiantSun({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Rayos
        ...List.generate(8, (i) {
          return Transform.rotate(
            angle: i * 45 * 3.14159 / 180,
            child: Container(
              width: 4,
              height: size * 0.6,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.oro.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
        // Disco solar
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.white,
                AppColors.oro,
                const Color(0xFFF59E0B),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.oro.withValues(alpha: 0.5),
                blurRadius: size * 0.6,
                spreadRadius: size * 0.15,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Sol poniente (atardecer)
class _SettingSun extends StatelessWidget {
  const _SettingSun({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xFFFFF3E0),
            const Color(0xFFE9C46A),
            const Color(0xFFE76F51),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE76F51).withValues(alpha: 0.5),
            blurRadius: size * 0.5,
            spreadRadius: size * 0.1,
          ),
        ],
      ),
    );
  }
}

/// Luna de Metztli (noche)
class _MetztliMoon extends StatelessWidget {
  const _MetztliMoon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment(-0.3, -0.3),
          radius: 0.8,
          colors: [
            const Color(0xFFF8F8FF),
            const Color(0xFFE0E0FF),
            const Color(0xFFB0B0E0),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.3),
            blurRadius: size * 0.4,
            spreadRadius: size * 0.05,
          ),
        ],
      ),
    );
  }
}

/// Constelación de Venus (estrellas formando patrón)
class _VenusConstellation extends StatefulWidget {
  const _VenusConstellation();

  @override
  State<_VenusConstellation> createState() => _VenusConstellationState();
}

class _VenusConstellationState extends State<_VenusConstellation>
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
          painter: _VenusConstellationPainter(_controller.value),
        );
      },
    );
  }
}

class _VenusConstellationPainter extends CustomPainter {
  _VenusConstellationPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7 + 0.3 * progress)
      ..style = PaintingStyle.fill;

    // Posiciones de la constelación (pentagrama de Venus)
    final points = [
      Offset(size.width * 0.15, size.height * 0.15),
      Offset(size.width * 0.35, size.height * 0.12),
      Offset(size.width * 0.28, size.height * 0.32),
      Offset(size.width * 0.12, size.height * 0.28),
      Offset(size.width * 0.22, size.height * 0.20),
    ];

    for (final point in points) {
      canvas.drawCircle(point, 1.5 + progress * 0.5, paint);
    }

    // Líneas conectando las estrellas
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2 + 0.1 * progress)
      ..strokeWidth = 0.8;

    for (var i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], linePaint);
    }
    canvas.drawLine(points.last, points.first, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _VenusConstellationPainter &&
        oldDelegate.progress != progress;
  }
}

/// Overlay de lluvia de Tláloc
class _TlalocRainOverlay extends StatelessWidget {
  const _TlalocRainOverlay();

  @override
  Widget build(BuildContext context) {
    return const _RainParticles();
  }
}

/// Overlay de brillo de Tonatiuh
class _TonatiuhGlowOverlay extends StatelessWidget {
  const _TonatiuhGlowOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.5,
          colors: [
            AppColors.oro.withValues(alpha: 0.15),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

/// Overlay de viento de Ehécatl
class _EhecatlWindOverlay extends StatelessWidget {
  const _EhecatlWindOverlay();

  @override
  Widget build(BuildContext context) {
    return const _WindParticles();
  }
}

/// Overlay de tormenta de Mixcóatl
class _MixcoatlStormOverlay extends StatelessWidget {
  const _MixcoatlStormOverlay();

  @override
  Widget build(BuildContext context) {
    return const _StormParticles();
  }
}

/// Overlay de noche de Metztli
class _MetztliNightOverlay extends StatelessWidget {
  const _MetztliNightOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.obsidiana.withValues(alpha: 0.3),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

/// Partículas de lluvia animadas
class _RainParticles extends StatefulWidget {
  const _RainParticles();

  @override
  State<_RainParticles> createState() => _RainParticlesState();
}

class _RainParticlesState extends State<_RainParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
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
          painter: _RainPainter(_controller.value),
        );
      },
    );
  }
}

class _RainPainter extends CustomPainter {
  _RainPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.turquesa.withValues(alpha: 0.5)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    const dropCount = 30;
    for (var i = 0; i < dropCount; i++) {
      final x = (i * 37.1 + progress * size.width) % size.width;
      final y = (i * 43.7 + progress * size.height * 1.5) % size.height;
      final length = 15.0 + (i % 3) * 5.0;

      canvas.drawLine(
        Offset(x, y),
        Offset(x - length * 0.3, y + length),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _RainPainter && oldDelegate.progress != progress;
  }
}

/// Partículas de viento animadas
class _WindParticles extends StatefulWidget {
  const _WindParticles();

  @override
  State<_WindParticles> createState() => _WindParticlesState();
}

class _WindParticlesState extends State<_WindParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
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
          painter: _WindPainter(_controller.value),
        );
      },
    );
  }
}

class _WindPainter extends CustomPainter {
  _WindPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.turquesa.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const streamCount = 8;
    for (var i = 0; i < streamCount; i++) {
      final startY = size.height * (0.15 + i * 0.1);
      final xOffset = progress * size.width;

      final path = Path()
        ..moveTo(-50, startY)
        ..cubicTo(
          size.width * 0.2 + xOffset * 0.5,
          startY - 20 * (i % 2 == 0 ? 1 : -1),
          size.width * 0.8 + xOffset * 0.5,
          startY + 20 * (i % 2 == 0 ? 1 : -1),
          size.width + 50,
          startY,
        );

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _WindPainter && oldDelegate.progress != progress;
  }
}

/// Partículas de tormenta
class _StormParticles extends StatefulWidget {
  const _StormParticles();

  @override
  State<_StormParticles> createState() => _StormParticlesState();
}

class _StormParticlesState extends State<_StormParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
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
          painter: _StormPainter(_controller.value),
        );
      },
    );
  }
}

class _StormPainter extends CustomPainter {
  _StormPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    // Relámpagos
    if (progress < 0.1) {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      final path = Path()
        ..moveTo(size.width * 0.3, 0)
        ..lineTo(size.width * 0.35, size.height * 0.2)
        ..lineTo(size.width * 0.28, size.height * 0.2)
        ..lineTo(size.width * 0.38, size.height * 0.5)
        ..lineTo(size.width * 0.32, size.height * 0.5)
        ..lineTo(size.width * 0.38, size.height * 0.8)
        ..lineTo(size.width * 0.28, size.height * 0.8);

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _StormPainter && oldDelegate.progress != progress;
  }
}