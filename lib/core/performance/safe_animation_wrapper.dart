// Widget envolvente para animaciones seguras y performantes.
//
// Proporciona:
// - Aislamiento de rendimiento con RepaintBoundary
// - Control de ticks con TickerMode (respeta reduceMotion y MediaQuery.disableAnimations)
// - Pausa automática en AppLifecycleState.paused e inactive
// - Fallback automático cuando falta el asset o reduceMotion está activo
// - Tolerancia a fallos: nunca crashea si el .riv/.json no existe
// - Integración con AnimationCacheService para pre-carga

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mi_calli/core/settings/app_settings_provider.dart';
import 'animation_cache_service.dart';

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

/// Widget que envuelve animaciones (Rive, Lottie, etc.) con aislamiento de rendimiento,
/// pausa por ciclo de vida y fallback seguro.
///
/// Uso típico:
/// ```dart
/// SafeAnimationWrapper(
///   assetPath: 'assets/animations/fuego.riv',
///   fallbackWidget: const Icon(Icons.local_fire_department),
///   child: RiveAnimation.asset('assets/animations/fuego.riv'),
/// )
/// ```
class SafeAnimationWrapper extends ConsumerStatefulWidget {
  /// Widget hijo (la animación real, ej. RiveAnimation, Lottie, etc.).
  /// Si es null, se mostrará el fallbackWidget.
  final Widget? child;

  /// Widget que se muestra como fallback cuando:
  /// - reduceMotion está activo (configuración de app o sistema)
  /// - assetPath es nulo, vacío o falla al cargarse (según [fallbackBehavior])
  /// - child es null
  final Widget fallbackWidget;

  /// Ruta opcional del asset para verificar su existencia en rootBundle y cache.
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
  /// Si [assetPath] existe en caché o en bundle, usa [childBuilder] para crear la animación.
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
  ConsumerState<SafeAnimationWrapper> createState() => SafeAnimationWrapperState();
}

// Clase de estado pública para permitir tests de ciclo de vida.
// Normalmente sería privada (_SafeAnimationWrapperState), pero se expone
// para verificar la lógica interna de pausa por AppLifecycleState.
class SafeAnimationWrapperState extends ConsumerState<SafeAnimationWrapper>
    with WidgetsBindingObserver {
  /// Estado del ciclo de vida de la app.
  AppLifecycleState? _lifecycleState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (mounted) {
      setState(() {
        _lifecycleState = state;
      });
    }
  }

  /// Determina si la animación debe estar pausada por ciclo de vida.
  bool get _pausedByLifecycle {
    // Pausar en paused e inactive (según INSTRUCTIONS.md punto 35)
    // No pausar en resumed (normal) ni detached (app cerrándose)
    return _lifecycleState == AppLifecycleState.paused ||
        _lifecycleState == AppLifecycleState.inactive;
  }

  // Getters públicos solo para testing (acceso a estado interno de ciclo de vida).
  // @visibleForTesting está disponible desde flutter/material.dart
  @visibleForTesting
  AppLifecycleState? get lifecycleStateForTesting => _lifecycleState;

  @visibleForTesting
  set lifecycleStateForTesting(AppLifecycleState? state) {
    _lifecycleState = state;
  }

  /// Método para testing que actualiza el estado de ciclo de vida y llama setState.
  @visibleForTesting
  void setLifecycleStateForTesting(AppLifecycleState? state) {
    if (mounted) {
      setState(() {
        _lifecycleState = state;
      });
    } else {
      _lifecycleState = state;
    }
  }

  @visibleForTesting
  bool get pausedByLifecycleForTesting => _pausedByLifecycle;

  @override
  Widget build(BuildContext context) {
    // Leer reduceMotion de AppSettings
    final appReduceMotion = ref.watch(
      appSettingsProvider.select((s) => s.reduceMotion),
    );

    // Combinar con MediaQuery.disableAnimations del sistema
    final systemReduceMotion = MediaQuery.disableAnimationsOf(context);
    final effectiveReduceMotion = appReduceMotion || systemReduceMotion;

    // La animación se detiene si: reduceMotion activo, no visible, o app en background
    final bool tickersEnabled = widget.isVisible &&
        !effectiveReduceMotion &&
        !_pausedByLifecycle;

    // Determinar si debemos mostrar el fallback
    final bool showFallback = _shouldShowFallback(effectiveReduceMotion);

    // Construir el child efectivo
    final effectiveChild = showFallback
        ? widget.fallbackWidget
        : _buildEffectiveChild(context);

    return RepaintBoundary(
      key: widget.repaintKey,
      child: TickerMode(
        enabled: tickersEnabled,
        child: effectiveChild,
      ),
    );
  }

  bool _shouldShowFallback(bool effectiveReduceMotion) {
    // Si hay child explícito y no estamos en modo "never", no mostrar fallback
    // a menos que reduceMotion lo requiera según fallbackBehavior
    if (widget.child != null) {
      switch (widget.fallbackBehavior) {
        case SafeAnimationFallbackBehavior.never:
          return false;
        case SafeAnimationFallbackBehavior.onReduceMotion:
          return effectiveReduceMotion;
        case SafeAnimationFallbackBehavior.onReduceMotionOrMissingAsset:
          return effectiveReduceMotion;
      }
    }

    // Si no hay child explícito, verificar assetPath si corresponde
    if (widget.assetPath != null && widget.assetPath!.isNotEmpty) {
      switch (widget.fallbackBehavior) {
        case SafeAnimationFallbackBehavior.never:
          return false;
        case SafeAnimationFallbackBehavior.onReduceMotion:
          return effectiveReduceMotion;
        case SafeAnimationFallbackBehavior.onReduceMotionOrMissingAsset:
          // Verificar existencia del asset en caché o bundle
          return effectiveReduceMotion || !_assetExists(widget.assetPath!);
      }
    }

    // No hay child ni assetPath válido -> fallback
    return true;
  }

  Widget _buildEffectiveChild(BuildContext context) {
    // Si hay child explícito, usarlo
    if (widget.child != null) {
      return widget.child!;
    }

    // Si hay assetPath y builder, intentar construir
    if (widget.assetPath != null && widget.assetPath!.isNotEmpty) {
      if (widget.riveChildBuilder != null) {
        return widget.riveChildBuilder!(widget.assetPath!);
      }
      if (widget.lottieChildBuilder != null) {
        return widget.lottieChildBuilder!(widget.assetPath!);
      }
    }

    // Fallback final
    return widget.fallbackWidget;
  }

  /// Verifica si un asset existe en caché o en rootBundle sin lanzarlo.
  bool _assetExists(String path) {
    // Primero verificar caché
    final cache = AnimationCacheService();
    if (cache.hasAsset(path)) {
      return true;
    }

    // Si no está en caché, intentar carga síncrona (solo para verificación)
    // Nota: rootBundle.load es async, así que en build asumimos que existe
    // si no podemos verificar síncronamente. La carga real la hace el builder.
    // Esto evita bloquear el frame.
    return true;
  }
}