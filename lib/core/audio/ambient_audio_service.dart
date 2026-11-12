// Servicio principal de audio ambiental del Valle de Teotihuacán.
//
// Gestiona la mezcla según clima emocional y hora, el estado de silencio
// y el ciclo de vida de la app (pausa en background, reanuda en foreground).
//
// Inicia silenciado por defecto (audioEnabled == false) hasta que el usuario
// lo active explícitamente (CONTEXT.md §5C e INSTRUCTIONS.md §2).

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ambient_audio_models.dart';
import 'ambient_audio_player_interface.dart';
import '../settings/app_settings_service.dart';
import '../settings/app_settings_provider.dart';
import '../../features/1_sanctuary_journal/models/prehispanic_emotion.dart';

/// Servicio que gestiona el audio ambiental del Valle.
///
/// - Mezcla pista horaria (ValleyTimePhase) + clima emocional (PrehispanicEmotion)
/// - Inicia silenciado (isMuted == true / audioEnabled == false)
/// - Pausa automática en background (AppLifecycleState.paused/inactive/hidden/detached)
/// - Reanuda en foreground solo si audioEnabled == true
/// - Persiste preferencia en AppSettingsService (shared_preferences)
class AmbientAudioService with WidgetsBindingObserver {
  AmbientAudioService({
    required AppSettingsService settingsService,
    AmbientAudioPlayerInterface? player,
    DateTime? now, // Para tests: inyectar hora fija
  })  : _settingsService = settingsService,
        _player = player ?? AudioplayersAmbientPlayer() {
    // Registrar observer de ciclo de vida
    WidgetsBinding.instance.addObserver(this);

    final referenceTime = now ?? DateTime.now();
    // Inicializar estado desde settings
    _isMuted = !_settingsService.audioEnabled;
    _currentTimePhase = ValleyTimePhase.fromHour(referenceTime.hour);
    // Inicializar configuración de pista con la fase horaria actual (sin override de emoción)
    _currentTrackConfig = AmbientAudioTrackConfig(timePhase: _currentTimePhase);
  }

  final AppSettingsService _settingsService;
  final AmbientAudioPlayerInterface _player;

  // Estado interno
  bool _isMuted = true; // Inicia silenciado por defecto
  bool _isPausedByLifecycle = false;
  ValleyTimePhase _currentTimePhase = ValleyTimePhase.day;
  PrehispanicEmotion? _activeEmotionOverride;
  AmbientAudioTrackConfig? _currentTrackConfig;
  StreamController<bool>? _playingStateController;

  // ─── Getters públicos ───

  /// Indica si el audio está silenciado (mute activado).
  bool get isMuted => _isMuted;

  /// Indica si el audio está habilitado (equivalente a !isMuted).
  bool get isAudioEnabled => !_isMuted;

  /// Indica si hay audio reproduciéndose activamente.
  bool get isPlaying => _player.isPlaying && !_isMuted && !_isPausedByLifecycle;

  /// Fase horaria actual.
  ValleyTimePhase get currentTimePhase => _currentTimePhase;

  /// Clima emocional activo que sobrescribe la pista horaria.
  PrehispanicEmotion? get activeEmotionOverride => _activeEmotionOverride;

  /// Configuración de la pista que debería estar sonando ahora.
  AmbientAudioTrackConfig? get currentTrackConfig => _currentTrackConfig;

  /// Stream de cambios en el estado de reproducción (para UI).
  Stream<bool> get playingStateStream {
    _playingStateController ??= StreamController<bool>.broadcast();
    return _playingStateController!.stream;
  }

  // ─── Inicialización y ciclo de vida ───

  /// Inicializa el servicio (llamar al arranque de la app).
  Future<void> initialize() async {
    // El estado inicial ya se cargó en el constructor desde settings
    // Si audioEnabled == true, iniciar reproducción de la pista actual
    if (!_isMuted) {
      await _playCurrentTrack();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _handleAppBackgrounded();
      case AppLifecycleState.resumed:
        _handleAppForegrounded();
    }
  }

  void _handleAppBackgrounded() {
    _isPausedByLifecycle = true;
    // Pausar inmediatamente para que no suene nada en background
    unawaited(_player.pause());
    _notifyPlayingStateChanged();
  }

  void _handleAppForegrounded() {
    final wasPausedByLifecycle = _isPausedByLifecycle;
    _isPausedByLifecycle = false;
    // Reanudar solo si el audio está habilitado
    if (!_isMuted) {
      unawaited(_resumeIfNeeded(wasPausedByLifecycle));
    }
    _notifyPlayingStateChanged();
  }

  Future<void> _resumeIfNeeded(bool wasPausedByLifecycle) async {
    if (_currentTrackConfig == null) return;

    if (wasPausedByLifecycle) {
      // Venimos de una pausa por ciclo de vida → resume (continúa desde pausa)
      await _player.resume();
    } else {
      // Venimos de un mute/unmute o primera vez → playLoop (carga y reproduce)
      await _player.playLoop(_currentTrackConfig!.assetPath);
    }
  }

  // ─── Control de mute / audio enabled ───

  /// Alterna el estado de mute (silencio ⇄ sonido).
  ///
  /// Persiste en AppSettingsService y sincroniza el reproductor inmediatamente.
  Future<void> toggleMute() async {
    // Si está silenciado (isMuted=true), queremos activar audio (enabled=true).
    // Si está activo (isMuted=false), queremos silenciar (enabled=false).
    // Por tanto: newEnabled = isMuted
    final newEnabled = isMuted;
    await setAudioEnabled(newEnabled);
  }

  /// Establece explícitamente si el audio está habilitado.
  ///
  /// Persiste en AppSettingsService y sincroniza el reproductor.
  Future<void> setAudioEnabled(bool enabled) async {
    _isMuted = !enabled;
    await _settingsService.setAudioEnabled(enabled);

    if (enabled) {
      // Activado: iniciar reproducción de la pista actual
      await _playCurrentTrack();
    } else {
      // Desactivado: detener/pausar inmediatamente
      await _player.stop();
    }
    _notifyPlayingStateChanged();
  }

  // ─── Actualización de atmósfera (hora + emoción) ───

  /// Actualiza la atmósfera sonora según fase horaria y/o clima emocional.
  ///
  /// - [timePhase]: fase horaria (si null, se calcula desde [now] o DateTime.now())
  /// - [emotionOverride]: emoción seleccionada en diario/valle (null = sin override)
  /// - [now]: hora de referencia (para tests; por defecto DateTime.now())
  ///
  /// Si el audio está habilitado y la app está en primer plano, cambia a la
  /// pista correspondiente si es distinta de la actual.
  Future<void> updateAtmosphere({
    ValleyTimePhase? timePhase,
    PrehispanicEmotion? emotionOverride,
    DateTime? now,
  }) async {
    final referenceTime = now ?? DateTime.now();
    final resolvedTimePhase = timePhase ?? ValleyTimePhase.fromHour(referenceTime.hour);

    // Actualizar estado interno
    _currentTimePhase = resolvedTimePhase;
    _activeEmotionOverride = emotionOverride;

    final newConfig = AmbientAudioTrackConfig(
      timePhase: resolvedTimePhase,
      activeEmotionOverride: emotionOverride,
    );

    // Si la pista no cambió, no hacer nada
    if (_currentTrackConfig == newConfig) {
      return;
    }

    _currentTrackConfig = newConfig;

    // Solo cambiar pista si audio habilitado y app en foreground
    if (!_isMuted && !_isPausedByLifecycle) {
      await _playCurrentTrack();
    }
  }

  /// Fuerza recálculo de la fase horaria desde la hora actual.
  Future<void> refreshTimePhase() async {
    await updateAtmosphere(now: DateTime.now());
  }

  // ─── Reproducción interna ───

  Future<void> _playCurrentTrack() async {
    if (_currentTrackConfig == null) return;

    final assetPath = _currentTrackConfig!.assetPath;
    await _player.playLoop(assetPath);
    _notifyPlayingStateChanged();
  }

  void _notifyPlayingStateChanged() {
    _playingStateController?.add(isPlaying);
  }

  // ─── Limpieza ───

  /// Libera recursos del servicio.
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _player.dispose();
    await _playingStateController?.close();
    _playingStateController = null;
  }
}

/// Provider del servicio de audio ambiental (Riverpod).
///
/// Se inicializa perezosamente al primer uso. El AppSettingsService
/// debe estar disponible (sobrescrito en main.dart).
final ambientAudioServiceProvider = Provider<AmbientAudioService>((ref) {
  final settingsService = ref.watch(appSettingsServiceProvider);
  return AmbientAudioService(settingsService: settingsService);
});

/// Provider del estado de mute (para UI reactiva).
final ambientAudioMutedProvider = Provider<bool>((ref) {
  final service = ref.watch(ambientAudioServiceProvider);
  return service.isMuted;
});

/// Provider del estado de reproducción (para UI reactiva).
final ambientAudioPlayingProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(ambientAudioServiceProvider);
  return service.playingStateStream;
});

/// Provider de la fase horaria actual (para UI reactiva).
final ambientAudioTimePhaseProvider = Provider<ValleyTimePhase>((ref) {
  final service = ref.watch(ambientAudioServiceProvider);
  return service.currentTimePhase;
});

/// Provider del clima emocional override actual (para UI reactiva).
final ambientAudioEmotionOverrideProvider = Provider<PrehispanicEmotion?>((ref) {
  final service = ref.watch(ambientAudioServiceProvider);
  return service.activeEmotionOverride;
});

/// Provider de la configuración de pista actual (para UI reactiva).
final ambientAudioTrackConfigProvider = Provider<AmbientAudioTrackConfig?>((ref) {
  final service = ref.watch(ambientAudioServiceProvider);
  return service.currentTrackConfig;
});