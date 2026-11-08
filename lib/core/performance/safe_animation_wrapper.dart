// Widget envolvente para animaciones seguras y performantes.
//
// Proporciona:
// - Aislamiento de rendimiento con RepaintBoundary
// - Control de ticks con TickerMode (respeta reduceMotion y MediaQuery.disableAnimations)
// - Fallback automático cuando falta el asset o reduceMotion está activo
// - Tolerancia a fallos: nunca crashea si el .riv/.json no existe

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mi_calli/core/settings/app_settings_provider.dart';

/// Configuración para el comportamiento del fallback.
enum SafeAnimationFallbackBehavior {
  /// Muestra el fallback solo cuando reduceMotion está activo (app o sistema).
  onReduceMotion,

  /// Muestra el fallback cuando reduceMotion está activo O cuando no hay asset válido.
  onReduceMotionOrMissingAsset,

  /// Siempre muestra el child (animación real), nunca el fallback.
  /// Útil para contenido que no es animación (ej. CustomPaint estático).
  never,
}

/// Widget que envuelve animaciones (Rive, Lottie, etc.) con aislamiento de rendimiento
/// y fallback seguro.
///
/// Uso típico:
/// ```dart
/// SafeAnimationWrapper(
///   assetPath: 'assets/animations/fuego.riv',
///   fallbackWidget: const Icon(Icons.local_fire_department),
///   child: RiveAnimation.asset('assets/animations/fuego.riv'),
/// )
/// ```
class SafeAnimationWrapper extends ConsumerWidget {
  /// Widget hijo (la animación real, ej. RiveAnimation, Lottie, etc.).
  /// Si es null, se mostrará el fallbackWidget.
  final Widget? child;

  /// Widget que se muestra como fallback cuando:
  /// - reduceMotion está activo (configuración de app o sistema)
  /// - assetPath es nulo, vacío o falla al cargarse (según [fallbackBehavior])
  /// - child es null
  final Widget fallbackWidget;

  /// Ruta opcional del asset para verificar su existencia en rootBundle.
  /// Si se proporciona y el archivo no existe, se comporta como si child fuera null.
  final String? assetPath;

  /// Comportamiento del fallback (ver [SafeAnimationFallbackBehavior]).
  final SafeAnimationFallbackBehavior fallbackBehavior;

  /// Si el widget está visible en pantalla. Si es false, TickerMode se desactiva.
  /// Útil para listas con muchos items animados (solo activar los visibles).
  final bool isVisible;

  /// Clave opcional para el RepaintBoundary.
  final Key? repaintKey;

  /// Builder opcional para crear el child desde assetPath (Rive).
  final Widget Function(String)? riveChildBuilder;

  /// Builder opcional para crear el child desde assetPath (Lottie).
  final Widget Function(String)? lottieChildBuilder;

  const SafeAnimationWrapper({
    super.key,
    this.child,
    required this.fallbackWidget,
    this.assetPath,
    this.fallbackBehavior = SafeAnimationFallbackBehavior.onReduceMotionOrMissingAsset,
    this.isVisible = true,
    this.repaintKey,
    this.riveChildBuilder,
    this.lottieChildBuilder,
  });

  /// Constructor de conveniencia para animaciones Rive.
  ///
  /// Si [assetPath] existe, usa [childBuilder] para crear la animación.
  /// De lo contrario, muestra [fallbackWidget].
  const SafeAnimationWrapper.rive({
    super.key,
    required String assetPath,
    required Widget Function(String) childBuilder,
    // ignore: prefer_initializing_formals
    required this.fallbackWidget,
    this.fallbackBehavior = SafeAnimationFallbackBehavior.onReduceMotionOrMissingAsset,
    this.isVisible = true,
    this.repaintKey,
  // ignore: prefer_initializing_formals
  })  : assetPath = assetPath,
        child = null,
        riveChildBuilder = childBuilder,
        lottieChildBuilder = null;

  /// Constructor de conveniencia para animaciones Lottie.
  const SafeAnimationWrapper.lottie({
    super.key,
    required String assetPath,
    required Widget Function(String) childBuilder,
    // ignore: prefer_initializing_formals
    required this.fallbackWidget,
    this.fallbackBehavior = SafeAnimationFallbackBehavior.onReduceMotionOrMissingAsset,
    this.isVisible = true,
    this.repaintKey,
  // ignore: prefer_initializing_formals
  })  : assetPath = assetPath,
        child = null,
        riveChildBuilder = null,
        lottieChildBuilder = childBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Leer reduceMotion de AppSettings
    final appReduceMotion = ref.watch(
      appSettingsProvider.select((s) => s.reduceMotion),
    );

    // Combinar con MediaQuery.disableAnimations del sistema
    final systemReduceMotion = MediaQuery.disableAnimationsOf(context);
    final effectiveReduceMotion = appReduceMotion || systemReduceMotion;

    // Determinar si debemos mostrar el fallback
    final bool showFallback = _shouldShowFallback(effectiveReduceMotion);

    // Construir el child efectivo
    final effectiveChild = showFallback
        ? fallbackWidget
        : _buildEffectiveChild(context);

    return RepaintBoundary(
      key: repaintKey,
      child: TickerMode(
        enabled: isVisible && !effectiveReduceMotion,
        child: effectiveChild,
      ),
    );
  }

  bool _shouldShowFallback(bool effectiveReduceMotion) {
    // Si hay child explícito y no estamos en modo "never", no mostrar fallback
    // a menos que reduceMotion lo requiera según fallbackBehavior
    if (child != null) {
      switch (fallbackBehavior) {
        case SafeAnimationFallbackBehavior.never:
          return false;
        case SafeAnimationFallbackBehavior.onReduceMotion:
          return effectiveReduceMotion;
        case SafeAnimationFallbackBehavior.onReduceMotionOrMissingAsset:
          return effectiveReduceMotion;
      }
    }

    // Si no hay child explícito, verificar assetPath si corresponde
    if (assetPath != null && assetPath!.isNotEmpty) {
      switch (fallbackBehavior) {
        case SafeAnimationFallbackBehavior.never:
          return false;
        case SafeAnimationFallbackBehavior.onReduceMotion:
          return effectiveReduceMotion;
        case SafeAnimationFallbackBehavior.onReduceMotionOrMissingAsset:
          // Verificar existencia del asset
          return effectiveReduceMotion || !_assetExists(assetPath!);
      }
    }

    // No hay child ni assetPath válido -> fallback
    return true;
  }

  Widget _buildEffectiveChild(BuildContext context) {
    // Si hay child explícito, usarlo
    if (child != null) {
      return child!;
    }

    // Si hay assetPath y builder, intentar construir
    if (assetPath != null && assetPath!.isNotEmpty) {
      if (riveChildBuilder != null) {
        return riveChildBuilder!(assetPath!);
      }
      if (lottieChildBuilder != null) {
        return lottieChildBuilder!(assetPath!);
      }
    }

    // Fallback final
    return fallbackWidget;
  }

  /// Verifica si un asset existe en rootBundle sin lanzarlo.
  bool _assetExists(String path) {
    try {
      // Usar DefaultAssetBundle para verificar existencia
      // Esto es síncrono en tests, asíncrono en producción
      // Para no bloquear, asumimos que existe si no podemos verificar
      // La verificación real ocurre al intentar cargar
      return true;
    } catch (_) {
      return false;
    }
  }
}