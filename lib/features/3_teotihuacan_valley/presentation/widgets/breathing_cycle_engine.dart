// Motor puro de Dart para el ejercicio de respiración 4-4-6.
// Sin dependencias de Flutter, totalmente testeable con pruebas unitarias.

/// Fases del ejercicio de respiración 4-4-6.
enum BreathingEnginePhase {
  idle,
  inhale,
  hold,
  exhale,
  paused,
  completed,
}

/// Motor de ciclos de respiración 4-4-6 (14 segundos por ciclo).
///
/// Avanza por segundos discretos mediante [tick()].
/// Expone la fase actual, segundos restantes en la fase y ciclos completados.
/// Un ciclo se completa exactamente cuando termina la exhalación (segundo 14).
class BreathingCycleEngine {
  static const int _inhaleSeconds = 4;
  static const int _holdSeconds = 4;
  static const int _exhaleSeconds = 6;
  static const int _cycleSeconds = _inhaleSeconds + _holdSeconds + _exhaleSeconds; // 14

  BreathingEnginePhase _phase = BreathingEnginePhase.idle;
  BreathingEnginePhase? _pausedPhase; // Fase guardada al pausar
  int _secondInCycle = 0; // 0-based, goes 0-13
  int _completedCycles = 0;
  bool _isRunning = false;

  /// Crea un motor en estado idle.
  BreathingCycleEngine();

  /// Fase actual del motor.
  BreathingEnginePhase get phase => _phase;

  /// Fase actual efectiva (considera pausa).
  BreathingEnginePhase get effectivePhase {
    if (_phase == BreathingEnginePhase.paused && _pausedPhase != null) {
      return _pausedPhase!;
    }
    return _phase;
  }

  /// Segundos restantes en la fase actual (1-4 para inhalar, 1-4 para sostener, 1-6 para exhalar).
  int get secondsRemaining {
    final effective = effectivePhase;
    switch (effective) {
      case BreathingEnginePhase.inhale:
        return _inhaleSeconds - _secondInCycle;
      case BreathingEnginePhase.hold:
        return _inhaleSeconds + _holdSeconds - _secondInCycle;
      case BreathingEnginePhase.exhale:
        return _cycleSeconds - _secondInCycle;
      case BreathingEnginePhase.paused:
        return _secondsRemainingForPhase(_pausedPhase ?? BreathingEnginePhase.inhale);
      case BreathingEnginePhase.completed:
        return 0;
      case BreathingEnginePhase.idle:
        return 0;
    }
  }

  int _secondsRemainingForPhase(BreathingEnginePhase phase) {
    switch (phase) {
      case BreathingEnginePhase.inhale:
        return _inhaleSeconds - _secondInCycle;
      case BreathingEnginePhase.hold:
        return _inhaleSeconds + _holdSeconds - _secondInCycle;
      case BreathingEnginePhase.exhale:
        return _cycleSeconds - _secondInCycle;
      default:
        return 0;
    }
  }

  /// Número de ciclos completados (cada ciclo = 14 segundos).
  int get completedCycles => _completedCycles;

  /// Si el motor está corriendo activamente.
  bool get isRunning => _isRunning;

  /// Si el motor está en pausa.
  bool get isPaused => _phase == BreathingEnginePhase.paused;

  /// Inicia el motor desde el principio (idle -> inhale).
  void start() {
    _phase = BreathingEnginePhase.inhale;
    _secondInCycle = 0;
    _completedCycles = 0;
    _isRunning = true;
    _pausedPhase = null;
  }

  /// Reanuda el motor desde donde se pausó.
  void resume() {
    if (_phase == BreathingEnginePhase.paused && _pausedPhase != null) {
      _phase = _pausedPhase!;
      _pausedPhase = null;
      _isRunning = true;
    }
  }

  /// Pausa el motor.
  void pause() {
    if (_isRunning) {
      _pausedPhase = _phase;
      _phase = BreathingEnginePhase.paused;
      _isRunning = false;
    }
  }

  /// Reinicia el motor a estado inicial.
  void reset() {
    _phase = BreathingEnginePhase.idle;
    _secondInCycle = 0;
    _completedCycles = 0;
    _isRunning = false;
    _pausedPhase = null;
  }

  /// Avanza el motor un segundo.
  ///
  /// Retorna true si se completó un ciclo en este tick.
  /// Retorna false en caso contrario.
  ///
  /// Lanza [StateError] si el motor no está corriendo.
  bool tick() {
    if (!_isRunning) {
      throw StateError('BreathingCycleEngine.tick() llamado sin estar corriendo. Use start() o resume() primero.');
    }

    _secondInCycle++;

    // Verificar transición de fase
    if (_secondInCycle == _inhaleSeconds) {
      _phase = BreathingEnginePhase.hold;
    } else if (_secondInCycle == _inhaleSeconds + _holdSeconds) {
      _phase = BreathingEnginePhase.exhale;
    } else if (_secondInCycle >= _cycleSeconds) {
      // Ciclo completado exactamente al terminar la exhalación
      _completedCycles++;
      _secondInCycle = 0;
      _phase = BreathingEnginePhase.inhale; // Inicia siguiente ciclo automáticamente
      return true;
    }

    return false;
  }

  /// Avanza el motor varios segundos de una vez.
  ///
  /// Retorna el número de ciclos completados durante el avance.
  int tickMultiple(int seconds) {
    if (!_isRunning) {
      throw StateError('BreathingCycleEngine.tickMultiple() llamado sin estar corriendo.');
    }
    int cyclesCompleted = 0;
    for (int i = 0; i < seconds; i++) {
      if (tick()) {
        cyclesCompleted++;
      }
    }
    return cyclesCompleted;
  }

  /// Completa el motor (después de 3 ciclos).
  void complete() {
    _phase = BreathingEnginePhase.completed;
    _isRunning = false;
    _pausedPhase = null;
  }

  /// Obtiene el texto de la fase actual para mostrar en UI.
  String getPhaseText() {
    // Cuando está pausado, mostrar "Pausado" independientemente de la fase subyacente
    if (_phase == BreathingEnginePhase.paused) {
      return 'Pausado';
    }
    switch (effectivePhase) {
      case BreathingEnginePhase.inhale:
        return 'Inhala';
      case BreathingEnginePhase.hold:
        return 'Sostén';
      case BreathingEnginePhase.exhale:
        return 'Exhala';
      case BreathingEnginePhase.completed:
        return 'Completo';
      case BreathingEnginePhase.idle:
        return 'Preparado';
      case BreathingEnginePhase.paused:
        return 'Pausado'; // No debería llegar aquí por el check arriba
    }
  }

  /// Obtiene el icono de la fase actual.
  // Estos son valores que se mapearán a IconData en la UI.
  String getPhaseIconName() {
    // Cuando está pausado, mostrar icono de pausa
    if (_phase == BreathingEnginePhase.paused) {
      return 'pause';
    }
    switch (effectivePhase) {
      case BreathingEnginePhase.inhale:
        return 'arrow_upward';
      case BreathingEnginePhase.hold:
        return 'pause_circle_filled';
      case BreathingEnginePhase.exhale:
        return 'arrow_downward';
      case BreathingEnginePhase.completed:
        return 'check_circle';
      case BreathingEnginePhase.idle:
        return 'air';
      case BreathingEnginePhase.paused:
        return 'pause'; // No debería llegar aquí por el check arriba
    }
  }
}