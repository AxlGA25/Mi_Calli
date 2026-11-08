// Mock de autenticación biométrica para tests.
//
// Permite configurar el comportamiento esperado sin hardware real.

import 'package:local_auth/local_auth.dart';

import 'biometric_auth_interface.dart';

/// Mock configurable de BiometricAuthInterface para pruebas.
class BiometricAuthMock implements BiometricAuthInterface {
  /// Si el mock reporta que hay biometría disponible.
  bool canCheckBiometricsValue = true;

  /// Lista de biometrías simuladas disponibles.
  List<BiometricType> availableBiometricsValue = [
    BiometricType.fingerprint,
    BiometricType.face,
  ];

  /// Resultado que devolverá authenticate().
  BiometricAuthResult authenticateResult = BiometricAuthResult.success;

  /// Contador de cuántas veces se llamó a authenticate.
  int authenticateCallCount = 0;

  /// Último localizedReason pasado a authenticate.
  String? lastLocalizedReason;

  /// Último stickyAuth pasado a authenticate.
  bool? lastStickyAuth;

  /// Último biometricOnly pasado a authenticate.
  bool? lastBiometricOnly;

  /// Si stopAuthentication fue llamado.
  bool stopAuthenticationCalled = false;

  @override
  Future<bool> canCheckBiometrics() async {
    return canCheckBiometricsValue;
  }

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async {
    return availableBiometricsValue;
  }

  @override
  Future<BiometricAuthResult> authenticate({
    required String localizedReason,
    bool stickyAuth = true,
    bool biometricOnly = false,
  }) async {
    authenticateCallCount++;
    lastLocalizedReason = localizedReason;
    lastStickyAuth = stickyAuth;
    lastBiometricOnly = biometricOnly;
    return authenticateResult;
  }

  @override
  void stopAuthentication() {
    stopAuthenticationCalled = true;
  }

  /// Resetea el mock para un nuevo test.
  void reset() {
    canCheckBiometricsValue = true;
    availableBiometricsValue = [BiometricType.fingerprint, BiometricType.face];
    authenticateResult = BiometricAuthResult.success;
    authenticateCallCount = 0;
    lastLocalizedReason = null;
    lastStickyAuth = null;
    lastBiometricOnly = null;
    stopAuthenticationCalled = false;
  }

  /// Configura el mock para simular dispositivo sin biometría ni PIN.
  void setNotAvailable() {
    canCheckBiometricsValue = false;
    availableBiometricsValue = [];
    authenticateResult = BiometricAuthResult.notAvailable;
  }

  /// Configura el mock para simular fallo de autenticación.
  void setFailed() {
    authenticateResult = BiometricAuthResult.failed;
  }

  /// Configura el mock para simular cancelación por usuario.
  void setCancelled() {
    authenticateResult = BiometricAuthResult.cancelled;
  }
}