// Interfaz y implementaciones del reproductor de audio ambiental.
//
// Define un contrato limpio para reproducir bucles de audio ambiental,
// con una implementación real (audioplayers) y una mock para tests.

import 'package:audioplayers/audioplayers.dart' show AudioPlayer, ReleaseMode, PlayerState, AssetSource;
import 'package:flutter/services.dart';

/// Interfaz para el reproductor de audio ambiental.
///
/// Métodos asíncronos que no lanzan excepciones por assets faltantes.
abstract interface class AmbientAudioPlayerInterface {
  /// Reproduce un asset de audio en bucle con el volumen especificado.
  ///
  /// Si el asset no existe en el bundle, falla silenciosamente (no lanza).
  Future<void> playLoop(String assetPath, {double volume = 1.0});

  /// Pausa la reproducción actual.
  Future<void> pause();

  /// Reanuda la reproducción pausada.
  Future<void> resume();

  /// Detiene la reproducción y libera el recurso actual.
  Future<void> stop();

  /// Libera recursos del reproductor.
  Future<void> dispose();

  /// Indica si hay audio reproduciéndose actualmente.
  bool get isPlaying;

  /// Ruta del asset que se está reproduciendo (o se reproducía).
  String? get currentAssetPath;
}

/// Implementación real usando `package:audioplayers/audioplayers.dart`.
///
/// Envuelve [AudioPlayer] en modo [ReleaseMode.loop].
/// Verifica la existencia del asset en el rootBundle antes de reproducir
/// para nunca fallar si assets/audio/ solo tiene .gitkeep.
class AudioplayersAmbientPlayer implements AmbientAudioPlayerInterface {
  AudioplayersAmbientPlayer();

  // Importación diferida para evitar dependencia en tests mock
  late final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> playLoop(String assetPath, {double volume = 1.0}) async {
    // Verificar que el asset existe en el bundle antes de intentar reproducir
    final assetExists = await _assetExistsInBundle(assetPath);
    if (!assetExists) {
      // Asset no existe: falla silenciosamente, no lanza excepción
      return;
    }

    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(volume.clamp(0.0, 1.0));
      await _player.play(AssetSource(assetPath));
    } catch (_) {
      // Cualquier error de reproducción (formato, permisos, etc.) se ignora
      // para mantener la estabilidad de la app.
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (_) {
      // Ignorar errores
    }
  }

  @override
  Future<void> resume() async {
    try {
      await _player.resume();
    } catch (_) {
      // Ignorar errores
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {
      // Ignorar errores
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await _player.dispose();
    } catch (_) {
      // Ignorar errores
    }
  }

  @override
  bool get isPlaying => _player.state == PlayerState.playing;

  @override
  String? get currentAssetPath => null; // audioplayers no expone el source actual fácilmente

  /// Verifica si un asset existe en el bundle de la app.
  Future<bool> _assetExistsInBundle(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Implementación mock en memoria para tests unitarios.
///
/// Registra llamadas y estado sin reproducir audio real.
/// Incluye flag [simulateMissingAsset] para probar manejo de assets faltantes.
class MockAmbientAudioPlayer implements AmbientAudioPlayerInterface {
  MockAmbientAudioPlayer({this.simulateMissingAsset = false});

  /// Si true, playLoop actuará como si el asset no existiera.
  final bool simulateMissingAsset;

  bool _isPlaying = false;
  String? _currentAssetPath;
  int _playCallCount = 0;
  int _pauseCallCount = 0;
  int _stopCallCount = 0;
  int _resumeCallCount = 0;
  int _disposeCallCount = 0;

  @override
  Future<void> playLoop(String assetPath, {double volume = 1.0}) async {
    _playCallCount++;
    if (simulateMissingAsset) {
      // Simula asset faltante: no cambia estado
      return;
    }
    _isPlaying = true;
    _currentAssetPath = assetPath;
  }

  @override
  Future<void> pause() async {
    _pauseCallCount++;
    _isPlaying = false;
  }

  @override
  Future<void> resume() async {
    _resumeCallCount++;
    if (_currentAssetPath != null) {
      _isPlaying = true;
    }
  }

  @override
  Future<void> stop() async {
    _stopCallCount++;
    _isPlaying = false;
    _currentAssetPath = null;
  }

  @override
  Future<void> dispose() async {
    _disposeCallCount++;
    _isPlaying = false;
    _currentAssetPath = null;
  }

  @override
  bool get isPlaying => _isPlaying;

  @override
  String? get currentAssetPath => _currentAssetPath;

  /// Contador de llamadas a playLoop.
  int get playCallCount => _playCallCount;

  /// Contador de llamadas a pause.
  int get pauseCallCount => _pauseCallCount;

  /// Contador de llamadas a stop.
  int get stopCallCount => _stopCallCount;

  /// Contador de llamadas a resume.
  int get resumeCallCount => _resumeCallCount;

  /// Contador de llamadas a dispose.
  int get disposeCallCount => _disposeCallCount;

  /// Reinicia todos los contadores y estado (útil entre tests).
  void reset() {
    _isPlaying = false;
    _currentAssetPath = null;
    _playCallCount = 0;
    _pauseCallCount = 0;
    _stopCallCount = 0;
    _resumeCallCount = 0;
    _disposeCallCount = 0;
  }
}