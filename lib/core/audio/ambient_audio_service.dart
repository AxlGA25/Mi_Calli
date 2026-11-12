// Servicio principal de audio ambiental de Mi Calli.
//
// Gestiona la mezcla de audio según clima emocional y hora del día,
// el estado de silencio (mute), y el ciclo de vida de la app
// (pausa en background, reanuda en foreground).

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ambient_audio_models.dart';
import 'ambient_audio_player_interface.dart';
import '../settings/app_settings_provider.dart';
import '../settings/app_settings_service.dart';
import '../../features/1_sanctuary_journal/models/prehispanic_emotion.dart';

/// Estado inmutable del servicio de audio ambiental.
///
/// Se usa con Riverpod Notifier para reactividad automática.
class AmbientAudioState {
  const AmbientAudioState({
    required this.isMuted,
    required this.isPlaying,
    required this.isPausedByLifecycle,
    required this.currentConfig,
    required this.currentTimePhase,
    required this.currentEmotionOverride,
  });

  /// Estado inicial: silenciado, sin reproducir, fase horaria actual.
  factory AmbientAudioState.initial(AppSettingsService settingsService) {
    return AmbientAudioState(
      isMuted: !settingsService.audioEnabled,
      isPlaying: false,
      isPausedByLifecycle: false,
      currentConfig: AmbientAudioTrackConfig(
        timePhase: ValleyTimePhase.fromHour(DateTime.now().hour),
      ),
      currentTimePhase: ValleyTimePhase.fromHour(DateTime.now().hour),
      currentEmotionOverride: null,
    );
  }

  final bool isMuted;
  final bool isPlaying;
  final bool isPausedByLifecycle;
  final AmbientAudioTrackConfig currentConfig;
  final ValleyTimePhase currentTimePhase;
  final PrehispanicEmotion? currentEmotionOverride;

  AmbientAudioState copyWith({
    bool? isMuted,
    bool? isPlaying,
    bool? isPausedByLifecycle,
    AmbientAudioTrackConfig? currentConfig,
    ValleyTimePhase? currentTimePhase,
    PrehispanicEmotion? currentEmotionOverride,
  }) {
    return AmbientAudioState(
      isMuted: isMuted ?? this.isMuted,
      isPlaying: isPlaying ?? this.isPlaying,
      isPausedByLifecycle: isPausedByLifecycle ?? this.isPausedByLifecycle,
      currentConfig: currentConfig ?? this.currentConfig,
      currentTimePhase: currentTimePhase ?? this.currentTimePhase,
      currentEmotionOverride: currentEmotionOverride ?? this.currentEmotionOverride,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AmbientAudioState &&
        other.isMuted == isMuted &&
        other.isPlaying == isPlaying &&
        other.isPausedByLifecycle == isPausedByLifecycle &&
        other.currentConfig == currentConfig &&
        other.currentTimePhase == currentTimePhase &&
        other.currentEmotionOverride == currentEmotionOverride;
  }

  @override
  int get hashCode => Object.hash(
        isMuted,
        isPlaying,
        isPausedByLifecycle,
        currentConfig,
        currentTimePhase,
        currentEmotionOverride,
      );

  @override
  String toString() {
    return 'AmbientAudioState('
        'isMuted: $isMuted, '
        'isPlaying: $isPlaying, '
        'isPausedByLifecycle: $isPausedByLifecycle, '
        'currentConfig: $currentConfig, '
        'currentTimePhase: $currentTimePhase, '
        'currentEmotionOverride: ${currentEmotionOverride?.id ?? 'none'})';
  }
}

/// Servicio interno que maneja la lógica de reproducción y ciclo de vida.
///
/// No es un Notifier; es la implementación concreta que el Notifier usa.
class _AmbientAudioServiceImpl with WidgetsBindingObserver {
  _AmbientAudioServiceImpl({
    required AppSettingsService settingsService,
    required AmbientAudioPlayerInterface player,
    required void Function(AmbientAudioState) onStateChange,
  })  : _settingsService = settingsService,
        _player = player,
        _onStateChange = onStateChange {
    WidgetsBinding.instance.addObserver(this);
    // Estado inicial
    _state = AmbientAudioState.initial(settingsService);
    _onStateChange(_state);
  }

  final AppSettingsService _settingsService;
  final AmbientAudioPlayerInterface _player;
  final void Function(AmbientAudioState) _onStateChange;

  late AmbientAudioState _state;

  AmbientAudioState get state => _state;

  void _updateState(AmbientAudioState newState) {
    _state = newState;
    _onStateChange(_state);
  }

  Future<void> _playCurrentTrack() async {
    await _player.playLoop(_state.currentConfig.assetPath, volume: 1.0);
  }

  Future<void> setAudioEnabled(bool enabled) async {
    await _settingsService.setAudioEnabled(enabled);
    final newMuted = !enabled;

    if (enabled && !_state.isPausedByLifecycle) {
      await _playCurrentTrack();
      _updateState(_state.copyWith(isMuted: newMuted, isPlaying: true));
    } else {
      await _player.stop();
      _updateState(_state.copyWith(isMuted: newMuted, isPlaying: false));
    }
  }

  Future<void> toggleMute() async {
    await setAudioEnabled(!_settingsService.audioEnabled);
  }

  Future<void> updateAtmosphere({
    ValleyTimePhase? timePhase,
    PrehispanicEmotion? emotionOverride,
    DateTime? now,
  }) async {
    final referenceTime = now ?? DateTime.now();
    final newTimePhase = timePhase ?? ValleyTimePhase.fromHour(referenceTime.hour);
    final newEmotionOverride = emotionOverride;

    final newConfig = AmbientAudioTrackConfig(
      activeEmotionOverride: newEmotionOverride,
      timePhase: newTimePhase,
    );

    // Actualizar estado interno
    _updateState(_state.copyWith(
      currentTimePhase: newTimePhase,
      currentEmotionOverride: newEmotionOverride,
      currentConfig: newConfig,
    ));

    // Si el audio está activo y la app en primer plano, reproducir la nueva pista
    if (!_state.isMuted && !_state.isPausedByLifecycle) {
      await _playCurrentTrack();
      _updateState(_state.copyWith(isPlaying: true));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _updateState(_state.copyWith(isPausedByLifecycle: true, isPlaying: false));
        _player.pause();
      case AppLifecycleState.resumed:
        _updateState(_state.copyWith(isPausedByLifecycle: false));
        if (!_state.isMuted) {
          _playCurrentTrack();
          _updateState(_state.copyWith(isPlaying: true));
        }
    }
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _player.dispose();
  }
}

/// Notifier de Riverpod que expone [AmbientAudioState] y notifica cambios.
class AmbientAudioNotifier extends Notifier<AmbientAudioState> {
  late final _AmbientAudioServiceImpl _impl;

  @override
  AmbientAudioState build() {
    final settingsService = ref.watch(appSettingsServiceProvider);
    // El player se puede sobrescribir en tests via ambientAudioPlayerProvider
    final player = ref.watch(ambientAudioPlayerProvider);

    _impl = _AmbientAudioServiceImpl(
      settingsService: settingsService,
      player: player,
      onStateChange: (newState) {
        if (ref.mounted) {
          state = newState;
        }
      },
    );

    // Cleanup al desechar el provider
    ref.onDispose(() => _impl.dispose());

    return _impl.state;
  }

  /// Alterna el estado de silencio (mute).
  Future<void> toggleMute() => _impl.toggleMute();

  /// Establece explícitamente si el audio está habilitado.
  Future<void> setAudioEnabled(bool enabled) => _impl.setAudioEnabled(enabled);

  /// Actualiza la atmósfera (fase horaria y/o clima emocional).
  Future<void> updateAtmosphere({
    ValleyTimePhase? timePhase,
    PrehispanicEmotion? emotionOverride,
    DateTime? now,
  }) => _impl.updateAtmosphere(
        timePhase: timePhase,
        emotionOverride: emotionOverride,
        now: now,
      );
}

/// Provider del player de audio (permite sobrescribir en tests).
final ambientAudioPlayerProvider = Provider<AmbientAudioPlayerInterface>((ref) {
  return AudioplayersAmbientPlayer();
});

/// Provider del Notifier de audio ambiental (estado reactivo).
final ambientAudioProvider = NotifierProvider<AmbientAudioNotifier, AmbientAudioState>(
  AmbientAudioNotifier.new,
);

/// Provider de solo lectura para el estado de mute (para UI reactiva).
final ambientAudioIsMutedProvider = Provider<bool>((ref) {
  return ref.watch(ambientAudioProvider.select((s) => s.isMuted));
});

/// Provider de solo lectura para el estado de reproducción.
final ambientAudioIsPlayingProvider = Provider<bool>((ref) {
  return ref.watch(ambientAudioProvider.select((s) => s.isPlaying));
});

/// Provider de solo lectura para la configuración actual de pista.
final ambientAudioCurrentConfigProvider = Provider<AmbientAudioTrackConfig>((ref) {
  return ref.watch(ambientAudioProvider.select((s) => s.currentConfig));
});

/// Provider de solo lectura para la fase horaria actual.
final ambientAudioCurrentTimePhaseProvider = Provider<ValleyTimePhase>((ref) {
  return ref.watch(ambientAudioProvider.select((s) => s.currentTimePhase));
});

/// Provider de solo lectura para el emotion override actual.
final ambientAudioCurrentEmotionOverrideProvider = Provider<PrehispanicEmotion?>((ref) {
  return ref.watch(ambientAudioProvider.select((s) => s.currentEmotionOverride));
});

/// Provider de solo lectura para saber si está pausado por ciclo de vida.
final ambientAudioIsPausedByLifecycleProvider = Provider<bool>((ref) {
  return ref.watch(ambientAudioProvider.select((s) => s.isPausedByLifecycle));
});