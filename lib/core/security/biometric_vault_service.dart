// Servicio de Bóveda Biométrica para proteger la app.
//
// - Autentica al abrir la app y al volver de segundo plano (después de 30s).
// - Usa WidgetsBindingObserver para detectar cambios de ciclo de vida.
// - Expone un stream/state para que la UI reaccione (bloqueada/desbloqueada).
// - Respeta el setting `app_lock_enabled` y nunca bloquea en `inactive`.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import 'biometric_auth_interface.dart';
import 'biometric_auth_impl.dart';
import 'biometric_auth_mock.dart';
import 'package:mi_calli/core/settings/app_settings_service.dart';

/// Estado de la bóveda biométrica.
enum BiometricVaultState {
  /// La bóveda está desbloqueada, la app es accesible.
  unlocked,

  /// La bóveda está bloqueada, esperando autenticación.
  locked,

  /// Autenticación en curso.
  authenticating,

  /// Error irrecuperable (ej. dispositivo sin biometría/PIN).
  error,
}

/// Servicio singleton que gestiona la bóveda biométrica y el ciclo de vida.
class BiometricVaultService extends WidgetsBindingObserver {
  BiometricVaultService._({
    required BiometricAuthInterface auth,
    required AppSettingsService settings,
  }) : _auth = auth,
       _settings = settings {
    _initializationFuture = _init();
  }

  final BiometricAuthInterface _auth;
  final AppSettingsService _settings;

  static BiometricVaultService? _instance;

  /// Instancia singleton para producción.
  static BiometricVaultService get instance {
    if (_instance == null) {
      // La instancia real se crea en main.dart después de inicializar AppSettingsService
      // Aquí solo retornamos null si no se ha inicializado, el provider lo manejará
      throw StateError('BiometricVaultService.instance llamado antes de inicializar. '
          'Usa BiometricVaultService.initialize() en main.dart');
    }
    return _instance!;
  }

  /// Inicializa la instancia singleton (llamar en main.dart).
  static Future<void> initialize() async {
    final settings = await AppSettingsService.create();
    _instance = BiometricVaultService._(
      auth: BiometricAuthImpl(),
      settings: settings,
    );
    WidgetsBinding.instance.addObserver(_instance!);
  }

  /// Crea una instancia para testing con mock.
  static BiometricVaultService createForTesting({
    required BiometricAuthMock authMock,
    required AppSettingsService settingsMock,
  }) {
    return BiometricVaultService._(
      auth: authMock,
      settings: settingsMock,
    );
  }

  /// Establece la instancia singleton para testing (solo para tests).
  static void setInstanceForTesting(BiometricVaultService? instance) {
    _instance = instance;
  }

  final StreamController<BiometricVaultState> _stateController =
      StreamController<BiometricVaultState>.broadcast();

  /// Stream del estado de la bóveda (para UI reactiva).
  Stream<BiometricVaultState> get stateStream => _stateController.stream;

  /// Estado actual (síncrono).
  BiometricVaultState _currentState = BiometricVaultState.locked;

  BiometricVaultState get currentState => _currentState;

  bool _isAppInBackground = false;
  bool _hasAuthenticatedOnce = false;
  DateTime? _backgroundTime;
  Timer? _lockTimer;
  bool _deviceSupportsAuth = false;
  late final Future<void> _initializationFuture;

  /// Future que se completa cuando la inicialización asíncrona termina.
  /// Útil para tests que necesitan esperar a que _deviceSupportsAuth esté listo.
  Future<void> get initializationComplete => _initializationFuture;

  Future<void> _init() async {
    _currentState = BiometricVaultState.locked;
    _stateController.add(_currentState);
    _deviceSupportsAuth = await _auth.canCheckBiometrics();
  }

  /// Inicia la autenticación inicial al arrancar la app.
  Future<BiometricAuthResult> authenticateOnStart({
    String localizedReason = 'Desbloquea Refugio Quetzalcóatl para acceder a tu diario',
  }) async {
    // Si el candado está desactivado, no autenticar
    if (!_settings.appLockEnabled) {
      _currentState = BiometricVaultState.unlocked;
      _hasAuthenticatedOnce = true;
      _stateController.add(_currentState);
      return BiometricAuthResult.success;
    }

    // Si el dispositivo no soporta autenticación, no bloquear
    if (!_deviceSupportsAuth) {
      _currentState = BiometricVaultState.unlocked;
      _hasAuthenticatedOnce = true;
      _stateController.add(_currentState);
      return BiometricAuthResult.notAvailable;
    }

    if (_hasAuthenticatedOnce && _currentState == BiometricVaultState.unlocked) {
      return BiometricAuthResult.success;
    }

    _currentState = BiometricVaultState.authenticating;
    _stateController.add(_currentState);

    final result = await _auth.authenticate(
      localizedReason: localizedReason,
      stickyAuth: true,
      biometricOnly: false, // Permitir PIN/patrón como respaldo
    );

    if (result == BiometricAuthResult.success) {
      _currentState = BiometricVaultState.unlocked;
      _hasAuthenticatedOnce = true;
    } else if (result == BiometricAuthResult.notAvailable) {
      _currentState = BiometricVaultState.unlocked; // No bloquear si no hay biometría
      _hasAuthenticatedOnce = true;
    } else {
      _currentState = BiometricVaultState.locked;
    }
    _stateController.add(_currentState);
    return result;
  }

  /// Solicita autenticación manual (ej. botón "Desbloquear" en UI).
  Future<BiometricAuthResult> requestUnlock({
    String localizedReason = 'Autentícate para acceder a tu diario',
  }) async {
    // Si el candado está desactivado, desbloquear directo
    if (!_settings.appLockEnabled) {
      _currentState = BiometricVaultState.unlocked;
      _hasAuthenticatedOnce = true;
      _stateController.add(_currentState);
      return BiometricAuthResult.success;
    }

    // Si el dispositivo no soporta autenticación, no bloquear
    if (!_deviceSupportsAuth) {
      _currentState = BiometricVaultState.unlocked;
      _hasAuthenticatedOnce = true;
      _stateController.add(_currentState);
      return BiometricAuthResult.notAvailable;
    }

    _currentState = BiometricVaultState.authenticating;
    _stateController.add(_currentState);

    final result = await _auth.authenticate(
      localizedReason: localizedReason,
      stickyAuth: true,
      biometricOnly: false,
    );

    if (result == BiometricAuthResult.success) {
      _currentState = BiometricVaultState.unlocked;
    } else if (result == BiometricAuthResult.notAvailable) {
      _currentState = BiometricVaultState.unlocked;
    } else {
      _currentState = BiometricVaultState.locked;
    }
    _stateController.add(_currentState);
    return result;
  }

  /// Bloquea la bóveda manualmente (solo si el candado está activado).
  void lock() {
    if (!_settings.appLockEnabled || !_deviceSupportsAuth) return;
    _currentState = BiometricVaultState.locked;
    _stateController.add(_currentState);
  }

  /// Verifica si el dispositivo soporta autenticación.
  Future<bool> isDeviceSupported() async {
    return _auth.canCheckBiometrics();
  }

  /// Obtiene los tipos de biometría disponibles.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    return _auth.getAvailableBiometrics();
  }

  // ─── WidgetsBindingObserver ───

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Si el candado está desactivado, no hacer nada
    if (!_settings.appLockEnabled) return;

    // Si el dispositivo no soporta autenticación, no bloquear nunca
    if (!_deviceSupportsAuth) return;

    // Si no se ha autenticado nunca, no bloquear al volver
    if (!_hasAuthenticatedOnce) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App va a segundo plano o se cierra/oculta (iOS)
        // Iniciar timer de 30 segundos para bloquear
        _isAppInBackground = true;
        _backgroundTime = DateTime.now();
        _startLockTimer();
        break;

      case AppLifecycleState.inactive:
        // Estado breve del sistema (avisos, diálogo de biometría, etc.)
        // NO bloquear, NO iniciar timer
        break;

      case AppLifecycleState.resumed:
        // App vuelve a primer plano
        _cancelLockTimer();
        if (_isAppInBackground) {
          _isAppInBackground = false;
          final elapsed = DateTime.now().difference(_backgroundTime ?? DateTime.now());
          // Si pasaron más de 30s, bloquear y pedir autenticación
          if (elapsed.inSeconds >= 30 && _currentState == BiometricVaultState.unlocked) {
            _currentState = BiometricVaultState.locked;
            _stateController.add(_currentState);
          }
          // Si pasaron menos de 30s, mantener desbloqueado (no hacer nada)
        }
        break;
    }
  }

  /// Inicia el timer de 30 segundos para bloquear la app.
  void _startLockTimer() {
    _cancelLockTimer();
    _lockTimer = Timer(const Duration(seconds: 30), () {
      if (_isAppInBackground && _currentState == BiometricVaultState.unlocked) {
        _currentState = BiometricVaultState.locked;
        _stateController.add(_currentState);
      }
    });
  }

  /// Cancela el timer de bloqueo.
  void _cancelLockTimer() {
    _lockTimer?.cancel();
    _lockTimer = null;
  }

  /// Limpia recursos (para tests o cierre de app).
  void dispose() {
    _cancelLockTimer();
    WidgetsBinding.instance.removeObserver(this);
    _auth.stopAuthentication();
    _stateController.close();
    _instance = null;
  }
}

/// Provider de Riverpod para el estado de la bóveda biométrica.
///
/// La UI puede escuchar con:
///   final vaultState = ref.watch(biometricVaultStateProvider);
///   ref.listen(biometricVaultStateProvider, (prev, next) { ... });
final biometricVaultStateProvider = StreamProvider<BiometricVaultState>((ref) {
  // El servicio se inicializa en main.dart, aquí solo accedemos a la instancia
  // Si no está inicializada, retornamos un stream que emite locked
  if (BiometricVaultService._instance == null) {
    return Stream.value(BiometricVaultState.locked);
  }
  return BiometricVaultService.instance.stateStream;
});

/// Provider para acceder al servicio (para llamadas imperativas).
final biometricVaultServiceProvider = Provider<BiometricVaultService>((ref) {
  if (BiometricVaultService._instance == null) {
    throw StateError('BiometricVaultService no inicializado. Llama a initialize() en main.dart');
  }
  return BiometricVaultService.instance;
});