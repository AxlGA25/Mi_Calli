// Interfaz y implementaciones del reproductor de audio ambiental.
//
// Define un contrato limpio para reproducir bucles de audio,
// con una implementación real (audioplayers) y un mock para tests.

import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

/// Interfaz para el reproductor de audio ambiental en bucle.
///
/// Contrato mínimo: reproducir en loop, pausar, reanudar, detener y liberar.
abstract interface class AmbientAudioPlayerInterface {
  /// Reproduce un asset de audio en bucle con el volumen dado.
  ///
  /// Debe manejar silenciosamente assets faltantes (no lanzar excepción).
  Future<void> playLoop(String assetPath, {double volume = 1.0});

  /// Pausa la reproducción actual (mantiene la posición).
  Future<void> pause();

  /// Reanuda la reproducción desde donde se pausó.
  Future<void> resume();

  /// Detiene la reproducción y reinicia la posición.
  Future<void> stop();

  /// Libera recursos del reproductor.
  Future<void> dispose();

  /// Indica si hay audio reproduciéndose actualmente.
  bool get isPlaying;

  /// Ruta del asset que se está reproduciendo (o se reprodujo por última vez).
  String? get currentAssetPath;
}

/// Implementación real usando `package:audioplayers/audioplayers.dart`.
///
/// Envuelve `AudioPlayer` en modo `ReleaseMode.loop`.
/// Verifica la existencia del asset en el `rootBundle` antes de reproducir
/// y captura cualquier excepción de asset faltante para degradarse limpiamente.
class AudioplayersAmbientPlayer implements AmbientAudioPlayerInterface {
  final AudioPlayer _player;
  String? _currentAssetPath;
  bool _isPlaying = false;
  bool _disposed = false;

  AudioplayersAmbientPlayer() : _player = AudioPlayer();

  @override
  Future<void> playLoop(String assetPath, {double volume = 1.0}) async {
    if (_disposed) return;

    // Verificar si el asset existe en el bundle antes de intentar reproducir.
    // Si no existe, degradarse silenciosamente sin lanzar excepción.
    final assetExists = await _checkAssetExists(assetPath);
    if (!assetExists) {
      _currentAssetPath = assetPath;
      _isPlaying = false;
      return;
    }

    try {
      await _player.setSourceAsset(assetPath);
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(volume.clamp(0.0, 1.0));
      await _player.resume();
      _currentAssetPath = assetPath;
      _isPlaying = true;
    } catch (_) {
      // Cualquier error de reproducción (asset corrupto, permisos, etc.)
      // se captura silenciosamente para no romper el estado de la app.
      _isPlaying = false;
    }
  }

  @override
  Future<void> pause() async {
    if (_disposed) return;
    try {
      await _player.pause();
      _isPlaying = false;
    } catch (_) {
      _isPlaying = false;
    }
  }

  @override
  Future<void> resume() async {
    if (_disposed) return;
    try {
      await _player.resume();
      _isPlaying = true;
    } catch (_) {
      _isPlaying = false;
    }
  }

  @override
  Future<void> stop() async {
    if (_disposed) return;
    try {
      await _player.stop();
      _isPlaying = false;
    } catch (_) {
      _isPlaying = false;
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await _player.dispose();
    } catch (_) {
      // Ignorar errores al liberar
    }
    _isPlaying = false;
    _currentAssetPath = null;
  }

  @override
  bool get isPlaying => _isPlaying;

  @override
  String? get currentAssetPath => _currentAssetPath;

  /// Verifica si un asset existe en el rootBundle.
  ///
  /// Retorna `false` silenciosamente si no existe o hay error.
  Future<bool> _checkAssetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Implementación en memoria para tests unitarios.
///
/// Registra llamadas y estado sin reproducir audio real.
/// Incluye flag `simulateMissingAsset` para verificar manejo de assets faltantes.
class MockAmbientAudioPlayer implements AmbientAudioPlayerInterface {
  String? _currentAssetPath;
  bool _isPlaying = false;
  bool _disposed = false;

  // Contadores para verificación en tests
  int playCallCount = 0;
  int pauseCallCount = 0;
  int stopCallCount = 0;
  int resumeCallCount = 0;
  int disposeCallCount = 0;

  /// Si `true`, `playLoop` simulará que el asset no existe.
  final bool simulateMissingAsset;

  /// Assets que se consideran "existentes" para el mock.
  final Set<String> availableAssets;

  MockAmbientAudioPlayer({
    this.simulateMissingAsset = false,
    this.availableAssets = const {},
  });

  @override
  Future<void> playLoop(String assetPath, {double volume = 1.0}) async {
    if (_disposed) return;
    playCallCount++;
    _currentAssetPath = assetPath;

    final assetExists = !simulateMissingAsset &&
        (availableAssets.isEmpty || availableAssets.contains(assetPath));

    if (!assetExists) {
      _isPlaying = false;
      return;
    }

    _isPlaying = true;
  }

  @override
  Future<void> pause() async {
    if (_disposed) return;
    pauseCallCount++;
    _isPlaying = false;
  }

  @override
  Future<void> resume() async {
    if (_disposed) return;
    resumeCallCount++;
    if (_currentAssetPath != null) {
      _isPlaying = true;
    }
  }

  @override
  Future<void> stop() async {
    if (_disposed) return;
    stopCallCount++;
    _isPlaying = false;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    disposeCallCount++;
    _disposed = true;
    _isPlaying = false;
    _currentAssetPath = null;
  }

  @override
  bool get isPlaying => _isPlaying;

  @override
  String? get currentAssetPath => _currentAssetPath;

  /// Reinicia contadores y estado (útil entre tests).
  void reset() {
    _currentAssetPath = null;
    _isPlaying = false;
    _disposed = false;
    playCallCount = 0;
    pauseCallCount = 0;
    stopCallCount = 0;
    resumeCallCount = 0;
    disposeCallCount = 0;
  }
}