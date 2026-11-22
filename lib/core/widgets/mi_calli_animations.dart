// Kit de animaciones reutilizables de Mi Calli:
// 1. MiCalliPageRoute: transiciones Fade + Slide (300ms) con soporte reduceMotion.
// 2. BouncyTap: microinteracción AnimatedScale + háptica sin bloquear InkWell.
// 3. AmateShimmerBox: skeleton loading con shimmer nativo sin dependencias extra.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Transición suave entre pantallas (Fade + desplazamiento vertical sutil).
class MiCalliPageRoute<T> extends PageRouteBuilder<T> {
  MiCalliPageRoute({required WidgetBuilder builder, super.settings})
    : super(
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder:
            (context, animation, secondaryAnimation) => builder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          if (MediaQuery.disableAnimationsOf(context)) {
            return child;
          }

          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.045),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      );
}

/// Envuelve cualquier botón o zona táctil para darle rebote suave al presionar.
/// Usa Listener (no compite con InkWell/GestureDetector ni crea ConstrainedBox).
class BouncyTap extends StatefulWidget {
  const BouncyTap({
    super.key,
    required this.child,
    this.scaleDown = 0.93,
    this.enableHaptics = false,
    this.reduceMotion = false,
  });

  final Widget child;
  final double scaleDown;
  final bool enableHaptics;
  final bool reduceMotion;

  @override
  State<BouncyTap> createState() => _BouncyTapState();
}

class _BouncyTapState extends State<BouncyTap> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
    if (value && widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveReduceMotion =
        widget.reduceMotion || MediaQuery.disableAnimationsOf(context);
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: (_isPressed && !effectiveReduceMotion) ? widget.scaleDown : 1.0,
        duration:
            effectiveReduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Caja de carga tipo Skeleton con efecto shimmer en tonos cálidos de papel amate.
class AmateShimmerBox extends StatefulWidget {
  const AmateShimmerBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 10,
    this.baseColor = const Color(0xFFE8DFD1),
    this.highlightColor = const Color(0xFFFDF8EE),
  });

  final double? width;
  final double height;
  final double borderRadius;
  final Color baseColor;
  final Color highlightColor;

  @override
  State<AmateShimmerBox> createState() => _AmateShimmerBoxState();
}

class _AmateShimmerBoxState extends State<AmateShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.baseColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final slide = -1.5 + _controller.value * 3.0;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(slide - 0.6, -0.2),
              end: Alignment(slide + 0.6, 0.2),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
            ),
          ),
        );
      },
    );
  }
}
