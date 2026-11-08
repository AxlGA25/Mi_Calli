// Implementación real de autenticación biométrica usando local_auth.
//
// Usa stickyAuth=true y biometricOnly=false para permitir PIN/patrón como respaldo.

import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

import 'biometric_auth_interface.dart';

/// Implementación de producción usando local_auth.
class BiometricAuthImpl implements BiometricAuthInterface {
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException {
      // Dispositivo sin soporte o error de permisos
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return <BiometricType>[];
    } catch (_) {
      return <BiometricType>[];
    }
  }

  @override
  Future<BiometricAuthResult> authenticate({
    required String localizedReason,
    bool stickyAuth = true,
    bool biometricOnly = false,
  }) async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          biometricOnly: biometricOnly,
          // useErrorDialogs: true, // deprecated
          // sensitiveTransaction: false, // deprecated
        ),
      );

      if (didAuthenticate) {
        return BiometricAuthResult.success;
      }
      return BiometricAuthResult.cancelled;
    } on PlatformException catch (e) {
      // Manejar errores específicos de local_auth
      switch (e.code) {
        case 'NotAvailable':
        case 'not_available':
        case 'BiometricNotAvailable':
          return BiometricAuthResult.notAvailable;
        case 'NotEnrolled':
        case 'not_enrolled':
        case 'BiometricNotEnrolled':
          return BiometricAuthResult.notAvailable;
        case 'LockedOut':
        case 'locked_out':
        case 'BiometricLockedOut':
          return BiometricAuthResult.failed;
        case 'PermanentlyLockedOut':
        case 'permanently_locked_out':
          return BiometricAuthResult.failed;
        case 'UserCancel':
        case 'user_cancel':
        case 'UserCancelled':
          return BiometricAuthResult.cancelled;
        case 'UserFallback':
        case 'user_fallback':
          // Usuario usó fallback (PIN/patrón) - se maneja como éxito si biometricOnly=false
          return BiometricAuthResult.cancelled;
        default:
          return BiometricAuthResult.error;
      }
    } catch (_) {
      return BiometricAuthResult.error;
    }
  }

  @override
  void stopAuthentication() {
    _localAuth.stopAuthentication();
  }
}