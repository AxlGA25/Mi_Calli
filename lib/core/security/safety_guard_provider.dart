// Provider de Riverpod para SafetyGuardService.
// Inicializa el detector de crisis al arrancar la app.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'safety_guard_service.dart';

/// Provider que inicializa SafetyGuardService al arrancar la app.
///
/// Si la carga del JSON falla, usa los patrones de respaldo (fallbackPatterns)
/// y NO rompe el arranque de la aplicación.
final safetyGuardServiceProvider = FutureProvider<SafetyGuardService>((ref) async {
  try {
    final service = await SafetyGuardService.initialize();
    return service;
  } catch (e) {
    // Si falla por cualquier razón (asset faltante, JSON malformado, etc.),
    // devolvemos un servicio con patrones de respaldo para que la app continúe.
    // No relanzamos la excepción para no bloquear el arranque.
    return SafetyGuardService.createForTesting(SafetyGuardService.fallbackPatterns());
  }
});