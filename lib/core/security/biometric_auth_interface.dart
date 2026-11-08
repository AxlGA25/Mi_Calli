// Interfaz para autenticación biométrica (local_auth).
//
// Permite inyectar implementaciones reales o mocks para tests.

import 'package:local_auth/local_auth.dart';

/// Resultado de la autenticación biométrica.
enum BiometricAuthResult {
  /// Autenticación exitosa.
  success,

  /// Usuario canceló la autenticación.
  cancelled,

  /// Falló la autenticación (demasiados intentos, error, etc.).
  failed,

  /// El dispositivo no tiene biometría ni PIN/patrón configurado.
  notAvailable,

  /// Error inesperado.
  error,
}

/// Interfaz para autenticación biométrica/local_auth.
///
/// Implementaciones:
/// - [BiometricAuthImpl] : usa local_auth real (producción).
/// - [BiometricAuthMock] : configurable para tests.
abstract class BiometricAuthInterface {
  /// Verifica si el dispositivo soporta autenticación biométrica o PIN/patrón.
  Future<bool> canCheckBiometrics();

  /// Obtiene la lista de tipos de biometría disponibles.
  Future<List<BiometricType>> getAvailableBiometrics();

  /// Autentifica al usuario con biometría o PIN/patrón del dispositivo.
  ///
  /// Parámetros:
  /// - [localizedReason]: Texto mostrado al usuario explicando por qué se autentica.
  /// - [stickyAuth]: Si true, el diálogo sigue visible al volver de segundo plano.
  /// - [biometricOnly]: Si true, SOLO permite biometría (no PIN/patrón).
  ///   Usar false para permitir PIN/patrón como respaldo.
  Future<BiometricAuthResult> authenticate({
    required String localizedReason,
    bool stickyAuth = true,
    bool biometricOnly = false,
  });

  /// Detiene cualquier autenticación en curso.
  void stopAuthentication();
}