// Pruebas para AmbientAudioService (Notifier-based).
//
// Cubre:
// - Inicio silenciado por defecto
// - toggleMute() activa/desactiva y persiste
// - ValleyTimePhase.fromHour mapeo correcto
// - Ciclo de vida: pausa en background, reanuda en foreground
// - Assets faltantes no rompen el servicio

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mi_calli/core/audio/ambient_audio_models.dart';
import 'package:mi_calli/core/audio/ambient_audio_player_interface.dart';
import 'package:mi_calli/core/audio/ambient_audio_service.dart';
import 'package:mi_calli/core/settings/app_settings_provider.dart';
import 'package:mi_calli/core/settings/app_settings_service.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/prehispanic_emotion.dart';

void main() {
  // Configuración global para tests
  setUpAll(() {
    // SharedPreferences mock para tests
    SharedPreferences.setMockInitialValues({});
    // Inicializar binding de Flutter para WidgetsBindingObserver
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('ValleyTimePhase', () {
    test('fromHour mapea correctamente amanecer (6-8)', () {
      expect(ValleyTimePhase.fromHour(6), equals(ValleyTimePhase.dawn));
      expect(ValleyTimePhase.fromHour(7), equals(ValleyTimePhase.dawn));
      expect(ValleyTimePhase.fromHour(8), equals(ValleyTimePhase.dawn));
    });

    test('fromHour mapea correctamente día (9-17)', () {
      for (var h = 9; h <= 17; h++) {
        expect(ValleyTimePhase.fromHour(h), equals(ValleyTimePhase.day), reason: 'Hora $h');
      }
    });

    test('fromHour mapea correctamente atardecer (18-19)', () {
      expect(ValleyTimePhase.fromHour(18), equals(ValleyTimePhase.dusk));
      expect(ValleyTimePhase.fromHour(19), equals(ValleyTimePhase.dusk));
    });

    test('fromHour mapea correctamente noche (20-23, 0-5)', () {
      for (var h = 20; h <= 23; h++) {
        expect(ValleyTimePhase.fromHour(h), equals(ValleyTimePhase.night), reason: 'Hora $h');
      }
      for (var h = 0; h <= 5; h++) {
        expect(ValleyTimePhase.fromHour(h), equals(ValleyTimePhase.night), reason: 'Hora $h');
      }
    });

    test('nahuatlName y spanishName son correctos', () {
      expect(ValleyTimePhase.dawn.nahuatlName, 'Tlahuizcalpan');
      expect(ValleyTimePhase.dawn.spanishName, 'Amanecer');
      expect(ValleyTimePhase.day.nahuatlName, 'Tonatiuh');
      expect(ValleyTimePhase.day.spanishName, 'Día Solar');
      expect(ValleyTimePhase.dusk.nahuatlName, 'Nepantla');
      expect(ValleyTimePhase.dusk.spanishName, 'Atardecer');
      expect(ValleyTimePhase.night.nahuatlName, 'Metztli');
      expect(ValleyTimePhase.night.spanishName, 'Noche Estrellada');
    });

    test('defaultAudioAssetPath tiene rutas esperadas', () {
      expect(ValleyTimePhase.dawn.defaultAudioAssetPath, 'assets/audio/ambient_dawn.mp3');
      expect(ValleyTimePhase.day.defaultAudioAssetPath, 'assets/audio/ambient_day.mp3');
      expect(ValleyTimePhase.dusk.defaultAudioAssetPath, 'assets/audio/ambient_dusk.mp3');
      expect(ValleyTimePhase.night.defaultAudioAssetPath, 'assets/audio/ambient_night.mp3');
    });
  });

  group('AmbientAudioTrackConfig', () {
    test('usa pista horaria cuando no hay emotionOverride', () {
      const config = AmbientAudioTrackConfig(
        activeEmotionOverride: null,
        timePhase: ValleyTimePhase.day,
      );
      expect(config.assetPath, 'assets/audio/ambient_day.mp3');
      expect(config.isEmotionTrack, isFalse);
    });

    test('usa pista de emoción cuando hay emotionOverride', () {
      const config = AmbientAudioTrackConfig(
        activeEmotionOverride: PrehispanicEmotion.tlalocLluvia,
        timePhase: ValleyTimePhase.day,
      );
      expect(config.assetPath, 'assets/audio/weather_tlaloc_lluvia.mp3');
      expect(config.isEmotionTrack, isTrue);
    });

    test('igualdad funciona correctamente', () {
      const config1 = AmbientAudioTrackConfig(
        activeEmotionOverride: PrehispanicEmotion.tonatiuhSol,
        timePhase: ValleyTimePhase.dawn,
      );
      const config2 = AmbientAudioTrackConfig(
        activeEmotionOverride: PrehispanicEmotion.tonatiuhSol,
        timePhase: ValleyTimePhase.dawn,
      );
      const config3 = AmbientAudioTrackConfig(
        activeEmotionOverride: null,
        timePhase: ValleyTimePhase.dawn,
      );
      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
    });
  });

  group('MockAmbientAudioPlayer', () {
    late MockAmbientAudioPlayer player;

    setUp(() {
      player = MockAmbientAudioPlayer();
    });

    test('inicia con isPlaying = false', () {
      expect(player.isPlaying, isFalse);
      expect(player.currentAssetPath, isNull);
    });

    test('playLoop activa isPlaying y guarda assetPath', () async {
      await player.playLoop('assets/audio/test.mp3');
      expect(player.isPlaying, isTrue);
      expect(player.currentAssetPath, 'assets/audio/test.mp3');
      expect(player.playCallCount, 1);
    });

    test('pause desactiva isPlaying', () async {
      await player.playLoop('assets/audio/test.mp3');
      await player.pause();
      expect(player.isPlaying, isFalse);
      expect(player.pauseCallCount, 1);
    });

    test('resume reactiva isPlaying si hay assetPath', () async {
      await player.playLoop('assets/audio/test.mp3');
      await player.pause();
      await player.resume();
      expect(player.isPlaying, isTrue);
      expect(player.resumeCallCount, 1);
    });

    test('stop desactiva isPlaying y limpia assetPath', () async {
      await player.playLoop('assets/audio/test.mp3');
      await player.stop();
      expect(player.isPlaying, isFalse);
      expect(player.currentAssetPath, isNull);
      expect(player.stopCallCount, 1);
    });

    test('dispose limpia estado', () async {
      await player.playLoop('assets/audio/test.mp3');
      await player.dispose();
      expect(player.isPlaying, isFalse);
      expect(player.currentAssetPath, isNull);
      expect(player.disposeCallCount, 1);
    });

    test('simulateMissingAsset = true hace que playLoop no cambie estado', () async {
      final missingPlayer = MockAmbientAudioPlayer(simulateMissingAsset: true);
      await missingPlayer.playLoop('assets/audio/missing.mp3');
      expect(missingPlayer.isPlaying, isFalse);
      expect(missingPlayer.currentAssetPath, isNull);
      expect(missingPlayer.playCallCount, 1);
    });

    test('reset reinicia contadores y estado', () async {
      await player.playLoop('assets/audio/test.mp3');
      await player.pause();
      player.reset();
      expect(player.isPlaying, isFalse);
      expect(player.currentAssetPath, isNull);
      expect(player.playCallCount, 0);
      expect(player.pauseCallCount, 0);
    });
  });

  group('AmbientAudioNotifier', () {
    late ProviderContainer container;
    late AppSettingsService settingsService;
    late MockAmbientAudioPlayer mockPlayer;

    setUp(() async {
      // SharedPreferences limpio para cada test
      SharedPreferences.setMockInitialValues({});
      settingsService = await AppSettingsService.create();
      mockPlayer = MockAmbientAudioPlayer();

      // Container con overrides
      container = ProviderContainer(
        overrides: [
          appSettingsServiceProvider.overrideWithValue(settingsService),
          ambientAudioPlayerProvider.overrideWithValue(mockPlayer),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
    });

    test('inicia silenciado (isMuted = true, isPlaying = false)', () {
      final state = container.read(ambientAudioProvider);
      expect(state.isMuted, isTrue);
      expect(state.isPlaying, isFalse);
      expect(state.isPausedByLifecycle, isFalse);
      expect(mockPlayer.isPlaying, isFalse);
    });

    test('updateAtmosphere no reproduce nada si está silenciado', () async {
      await container.read(ambientAudioProvider.notifier).updateAtmosphere(
        timePhase: ValleyTimePhase.day,
        emotionOverride: PrehispanicEmotion.tonatiuhSol,
      );
      // Aunque se actualice la config, no debe reproducir porque está muteado
      expect(mockPlayer.playCallCount, 0);
      final state = container.read(ambientAudioProvider);
      expect(state.isPlaying, isFalse);
      expect(state.currentConfig.activeEmotionOverride, equals(PrehispanicEmotion.tonatiuhSol));
    });

    test('toggleMute() activa audio, persiste y reproduce pista horaria', () async {
      // Por defecto audioEnabled = false
      expect(settingsService.audioEnabled, isFalse);

      // Activar con toggleMute
      await container.read(ambientAudioProvider.notifier).toggleMute();

      // Debe persistir audio_enabled = true
      expect(settingsService.audioEnabled, isTrue);
      final state = container.read(ambientAudioProvider);
      expect(state.isMuted, isFalse);
      expect(state.isPlaying, isTrue);
      expect(mockPlayer.playCallCount, 1);
      expect(mockPlayer.currentAssetPath, contains('ambient_'));
    });

    test('toggleMute() con emotionOverride reproduce pista de emoción', () async {
      // Configurar emotionOverride antes de activar
      await container.read(ambientAudioProvider.notifier).updateAtmosphere(
        emotionOverride: PrehispanicEmotion.tlalocLluvia,
      );

      await container.read(ambientAudioProvider.notifier).toggleMute();

      expect(settingsService.audioEnabled, isTrue);
      expect(mockPlayer.currentAssetPath, 'assets/audio/weather_tlaloc_lluvia.mp3');
    });

    test('segundo toggleMute() silencia inmediatamente y persiste false', () async {
      // Activar
      await container.read(ambientAudioProvider.notifier).toggleMute();
      expect(settingsService.audioEnabled, isTrue);
      expect(mockPlayer.playCallCount, 1);

      // Desactivar
      await container.read(ambientAudioProvider.notifier).toggleMute();
      expect(settingsService.audioEnabled, isFalse);
      final state = container.read(ambientAudioProvider);
      expect(state.isMuted, isTrue);
      expect(state.isPlaying, isFalse);
      expect(mockPlayer.stopCallCount, 1);
    });

    test('setAudioEnabled(true) activa y reproduce', () async {
      await container.read(ambientAudioProvider.notifier).setAudioEnabled(true);

      expect(settingsService.audioEnabled, isTrue);
      final state = container.read(ambientAudioProvider);
      expect(state.isMuted, isFalse);
      expect(state.isPlaying, isTrue);
      expect(mockPlayer.playCallCount, 1);
    });

    test('setAudioEnabled(false) silencia y detiene', () async {
      await container.read(ambientAudioProvider.notifier).setAudioEnabled(true);
      await container.read(ambientAudioProvider.notifier).setAudioEnabled(false);

      expect(settingsService.audioEnabled, isFalse);
      final state = container.read(ambientAudioProvider);
      expect(state.isMuted, isTrue);
      expect(state.isPlaying, isFalse);
      expect(mockPlayer.stopCallCount, 1);
    });

    test('updateAtmosphere cambia pista si audio habilitado y en foreground', () async {
      await container.read(ambientAudioProvider.notifier).setAudioEnabled(true);
      final firstPlayCount = mockPlayer.playCallCount;

      // Cambiar a emotionOverride
      await container.read(ambientAudioProvider.notifier).updateAtmosphere(
        emotionOverride: PrehispanicEmotion.ehecatlViento,
      );

      expect(mockPlayer.playCallCount, firstPlayCount + 1);
      expect(mockPlayer.currentAssetPath, 'assets/audio/weather_ehecatl_viento.mp3');
      final state = container.read(ambientAudioProvider);
      expect(state.currentConfig.activeEmotionOverride, equals(PrehispanicEmotion.ehecatlViento));
    });

    test('updateAtmosphere no cambia pista si está silenciado', () async {
      // Asegurar que está silenciado
      await container.read(ambientAudioProvider.notifier).setAudioEnabled(false);
      mockPlayer.reset();

      await container.read(ambientAudioProvider.notifier).updateAtmosphere(
        emotionOverride: PrehispanicEmotion.mixcoatlTormenta,
      );

      expect(mockPlayer.playCallCount, 0);
      final state = container.read(ambientAudioProvider);
      expect(state.currentConfig.activeEmotionOverride, equals(PrehispanicEmotion.mixcoatlTormenta));
    });

    test('asset faltante no lanza excepción ni rompe estado', () async {
      // Usar player con simulateMissingAsset
      final missingPlayer = MockAmbientAudioPlayer(simulateMissingAsset: true);
      final containerWithMissing = ProviderContainer(
        overrides: [
          appSettingsServiceProvider.overrideWithValue(settingsService),
          ambientAudioPlayerProvider.overrideWithValue(missingPlayer),
        ],
      );

      await containerWithMissing.read(ambientAudioProvider.notifier).setAudioEnabled(true);

      final state = containerWithMissing.read(ambientAudioProvider);
      expect(state.isMuted, isFalse);
      // El player no reproduce, pero el servicio no crashea
      expect(missingPlayer.isPlaying, isFalse);
      expect(missingPlayer.playCallCount, 1);

      containerWithMissing.dispose();
    });
  });

  group('Riverpod Providers (reactivos)', () {
    late ProviderContainer container;
    late AppSettingsService settingsService;
    late MockAmbientAudioPlayer mockPlayer;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      settingsService = await AppSettingsService.create();
      mockPlayer = MockAmbientAudioPlayer();

      container = ProviderContainer(
        overrides: [
          appSettingsServiceProvider.overrideWithValue(settingsService),
          ambientAudioPlayerProvider.overrideWithValue(mockPlayer),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
    });

    test('ambientAudioIsMutedProvider refleja estado del servicio', () async {
      expect(container.read(ambientAudioIsMutedProvider), isTrue);

      await container.read(ambientAudioProvider.notifier).toggleMute();

      expect(container.read(ambientAudioIsMutedProvider), isFalse);
    });

    test('ambientAudioIsPlayingProvider refleja estado de reproducción', () async {
      expect(container.read(ambientAudioIsPlayingProvider), isFalse);

      await container.read(ambientAudioProvider.notifier).setAudioEnabled(true);

      expect(container.read(ambientAudioIsPlayingProvider), isTrue);
    });

    test('ambientAudioCurrentConfigProvider refleja configuración actual', () async {
      final config = container.read(ambientAudioCurrentConfigProvider);
      expect(config.timePhase, equals(ValleyTimePhase.fromHour(DateTime.now().hour)));
      expect(config.activeEmotionOverride, isNull);

      await container.read(ambientAudioProvider.notifier).updateAtmosphere(
        emotionOverride: PrehispanicEmotion.metztliNoche,
      );

      final newConfig = container.read(ambientAudioCurrentConfigProvider);
      expect(newConfig.activeEmotionOverride, equals(PrehispanicEmotion.metztliNoche));
      expect(newConfig.assetPath, 'assets/audio/weather_metztli_noche.mp3');
    });

    test('ambientAudioCurrentTimePhaseProvider refleja fase horaria', () {
      expect(container.read(ambientAudioCurrentTimePhaseProvider),
           equals(ValleyTimePhase.fromHour(DateTime.now().hour)));
    });

    test('ambientAudioCurrentEmotionOverrideProvider refleja emotion override', () async {
      expect(container.read(ambientAudioCurrentEmotionOverrideProvider), isNull);

      await container.read(ambientAudioProvider.notifier).updateAtmosphere(
        emotionOverride: PrehispanicEmotion.tonatiuhSol,
      );

      expect(container.read(ambientAudioCurrentEmotionOverrideProvider),
           equals(PrehispanicEmotion.tonatiuhSol));
    });

    test('ambientAudioIsPausedByLifecycleProvider refleja estado de pausa', () {
      expect(container.read(ambientAudioIsPausedByLifecycleProvider), isFalse);
    });
  });
}