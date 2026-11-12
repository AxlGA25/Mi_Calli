// Pruebas para AmbientAudioService.
//
// Cubre:
// - Inicio silenciado por defecto
// - toggleMute() activa/desactiva y persiste
// - ValleyTimePhase.fromHour mapea correctamente 24 horas
// - Pausa en background (paused/inactive) y reanuda en resumed
// - Assets faltantes no rompen el servicio

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_calli/core/audio/ambient_audio_models.dart';
import 'package:mi_calli/core/audio/ambient_audio_player_interface.dart';
import 'package:mi_calli/core/audio/ambient_audio_service.dart';
import 'package:mi_calli/core/settings/app_settings_service.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/prehispanic_emotion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ValleyTimePhase', () {
    test('fromHour mapea 06-08 a dawn (Amanecer Tlahuizcalpan)', () {
      for (final hour in [6, 7, 8]) {
        expect(ValleyTimePhase.fromHour(hour), equals(ValleyTimePhase.dawn));
      }
    });

    test('fromHour mapea 09-17 a day (Día Solar Tonatiuh)', () {
      for (final hour in [9, 10, 12, 15, 17]) {
        expect(ValleyTimePhase.fromHour(hour), equals(ValleyTimePhase.day));
      }
    });

    test('fromHour mapea 18-19 a dusk (Atardecer Nepantla)', () {
      for (final hour in [18, 19]) {
        expect(ValleyTimePhase.fromHour(hour), equals(ValleyTimePhase.dusk));
      }
    });

    test('fromHour mapea 20-23 y 00-05 a night (Noche Estrellada Metztli)', () {
      for (final hour in [20, 21, 22, 23, 0, 1, 3, 5]) {
        expect(ValleyTimePhase.fromHour(hour), equals(ValleyTimePhase.night));
      }
    });

    test('getters nahuatlName, spanishName, defaultAudioAssetPath', () {
      expect(ValleyTimePhase.dawn.nahuatlName, 'Tlahuizcalpan');
      expect(ValleyTimePhase.dawn.spanishName, 'Amanecer');
      expect(ValleyTimePhase.dawn.defaultAudioAssetPath, 'assets/audio/ambient_dawn.mp3');

      expect(ValleyTimePhase.day.nahuatlName, 'Tonatiuh');
      expect(ValleyTimePhase.day.spanishName, 'Día Solar');
      expect(ValleyTimePhase.day.defaultAudioAssetPath, 'assets/audio/ambient_day.mp3');

      expect(ValleyTimePhase.dusk.nahuatlName, 'Nepantla');
      expect(ValleyTimePhase.dusk.spanishName, 'Atardecer');
      expect(ValleyTimePhase.dusk.defaultAudioAssetPath, 'assets/audio/ambient_dusk.mp3');

      expect(ValleyTimePhase.night.nahuatlName, 'Metztli');
      expect(ValleyTimePhase.night.spanishName, 'Noche Estrellada');
      expect(ValleyTimePhase.night.defaultAudioAssetPath, 'assets/audio/ambient_night.mp3');
    });
  });

  group('AmbientAudioTrackConfig', () {
    test('usa pista horaria cuando no hay emotionOverride', () {
      const config = AmbientAudioTrackConfig(
        timePhase: ValleyTimePhase.dawn,
        activeEmotionOverride: null,
      );
      expect(config.assetPath, 'assets/audio/ambient_dawn.mp3');
      expect(config.isEmotionOverride, false);
    });

    test('usa pista de emoción cuando hay emotionOverride', () {
      const config = AmbientAudioTrackConfig(
        timePhase: ValleyTimePhase.day,
        activeEmotionOverride: PrehispanicEmotion.tlalocLluvia,
      );
      expect(config.assetPath, 'assets/audio/weather_tlaloc_lluvia.mp3');
      expect(config.isEmotionOverride, true);
    });

    test('equality compara timePhase y emotionOverride', () {
      const config1 = AmbientAudioTrackConfig(
        timePhase: ValleyTimePhase.dawn,
        activeEmotionOverride: PrehispanicEmotion.tonatiuhSol,
      );
      const config2 = AmbientAudioTrackConfig(
        timePhase: ValleyTimePhase.dawn,
        activeEmotionOverride: PrehispanicEmotion.tonatiuhSol,
      );
      const config3 = AmbientAudioTrackConfig(
        timePhase: ValleyTimePhase.day,
        activeEmotionOverride: PrehispanicEmotion.tonatiuhSol,
      );
      expect(config1 == config2, true);
      expect(config1 == config3, false);
    });
  });

  group('AmbientAudioService', () {
    late SharedPreferences prefs;
    late AppSettingsService settingsService;
    late MockAmbientAudioPlayer mockPlayer;
    late AmbientAudioService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      settingsService = AppSettingsService.createForTesting(prefs);
      mockPlayer = MockAmbientAudioPlayer();
      // Usar 07:00 (dawn) como hora fija para tests determinísticos
      service = AmbientAudioService(
        settingsService: settingsService,
        player: mockPlayer,
        now: DateTime(2024, 1, 1, 7, 0, 0),
      );
      await service.initialize();
    });

    tearDown(() async {
      await service.dispose();
    });

    test('inicia silenciado (isMuted == true, isPlaying == false)', () {
      expect(service.isMuted, true);
      expect(service.isAudioEnabled, false);
      expect(service.isPlaying, false);
      expect(mockPlayer.playCallCount, 0);
    });

    test('updateAtmosphere no reproduce nada si está silenciado', () async {
      await service.updateAtmosphere(
        timePhase: ValleyTimePhase.day,
        emotionOverride: PrehispanicEmotion.tonatiuhSol,
      );
      expect(mockPlayer.playCallCount, 0);
      expect(service.isPlaying, false);
    });

    test('toggleMute() activa sonido, persiste audio_enabled=true y reproduce pista horaria', () async {
      await service.toggleMute();

      expect(service.isMuted, false);
      expect(service.isAudioEnabled, true);
      expect(settingsService.audioEnabled, true);
      expect(mockPlayer.playCallCount, 1);
      expect(mockPlayer.currentAssetPath, 'assets/audio/ambient_dawn.mp3');
      expect(mockPlayer.isPlaying, true);
    });

    test('toggleMute() con emotionOverride reproduce pista de emoción', () async {
      await service.updateAtmosphere(
        timePhase: ValleyTimePhase.day,
        emotionOverride: PrehispanicEmotion.ehecatlViento,
      );
      await service.toggleMute();

      expect(service.isMuted, false);
      expect(mockPlayer.playCallCount, 1);
      expect(mockPlayer.currentAssetPath, 'assets/audio/weather_ehecatl_viento.mp3');
    });

    test('toggleMute() segunda llamada silencia, persiste audio_enabled=false y detiene reproductor', () async {
      await service.toggleMute(); // Activar
      expect(service.isMuted, false);

      await service.toggleMute(); // Silenciar
      expect(service.isMuted, true);
      expect(settingsService.audioEnabled, false);
      expect(mockPlayer.stopCallCount, 1);
      expect(mockPlayer.isPlaying, false);
    });

    test('setAudioEnabled(true) activa y reproduce; setAudioEnabled(false) silencia y detiene', () async {
      await service.setAudioEnabled(true);
      expect(service.isAudioEnabled, true);
      expect(mockPlayer.playCallCount, 1);

      await service.setAudioEnabled(false);
      expect(service.isAudioEnabled, false);
      expect(mockPlayer.stopCallCount, 1);
    });

    test('updateAtmosphere cambia pista si audio habilitado y en foreground', () async {
      await service.setAudioEnabled(true); // Activar con dawn
      expect(mockPlayer.playCallCount, 1);
      expect(mockPlayer.currentAssetPath, 'assets/audio/ambient_dawn.mp3');

      // Cambiar a día
      await service.updateAtmosphere(timePhase: ValleyTimePhase.day);
      expect(mockPlayer.playCallCount, 2);
      expect(mockPlayer.currentAssetPath, 'assets/audio/ambient_day.mp3');

      // Cambiar a emoción override
      await service.updateAtmosphere(
        timePhase: ValleyTimePhase.day,
        emotionOverride: PrehispanicEmotion.mixcoatlTormenta,
      );
      expect(mockPlayer.playCallCount, 3);
      expect(mockPlayer.currentAssetPath, 'assets/audio/weather_mixcoatl_tormenta.mp3');

      // Quitar override → vuelve a pista horaria
      await service.updateAtmosphere(timePhase: ValleyTimePhase.day, emotionOverride: null);
      expect(mockPlayer.playCallCount, 4);
      expect(mockPlayer.currentAssetPath, 'assets/audio/ambient_day.mp3');
    });

    test('updateAtmosphere no cambia pista si es la misma configuración', () async {
      await service.setAudioEnabled(true);
      await service.updateAtmosphere(timePhase: ValleyTimePhase.dawn);
      final callCount1 = mockPlayer.playCallCount;

      // Misma configuración
      await service.updateAtmosphere(timePhase: ValleyTimePhase.dawn);
      expect(mockPlayer.playCallCount, callCount1);
    });

    test('didChangeAppLifecycleState.paused pausa reproductor y marca isPausedByLifecycle', () async {
      await service.setAudioEnabled(true);
      expect(service.isPlaying, true);

      // Simular background
      service.didChangeAppLifecycleState(AppLifecycleState.paused);

      expect(service.isPlaying, false);
      expect(mockPlayer.pauseCallCount, 1);
    });

    test('didChangeAppLifecycleState.inactive también pausa', () async {
      await service.setAudioEnabled(true);
      service.didChangeAppLifecycleState(AppLifecycleState.inactive);

      expect(service.isPlaying, false);
      expect(mockPlayer.pauseCallCount, 1);
    });

    test('didChangeAppLifecycleState.hidden y detached también pausan', () async {
      await service.setAudioEnabled(true);
      service.didChangeAppLifecycleState(AppLifecycleState.hidden);
      expect(service.isPlaying, false);

      await service.setAudioEnabled(true); // Re-activar
      service.didChangeAppLifecycleState(AppLifecycleState.detached);
      expect(service.isPlaying, false);
    });

    test('didChangeAppLifecycleState.resumed reanuda solo si audioEnabled == true', () async {
      await service.setAudioEnabled(true);
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(service.isPlaying, false);

      // Volver a foreground con audio habilitado → reanuda
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(service.isPlaying, true);
      expect(mockPlayer.resumeCallCount, 1);
    });

    test('didChangeAppLifecycleState.resumed NO reanuda si audioEnabled == false', () async {
      await service.setAudioEnabled(true);
      service.didChangeAppLifecycleState(AppLifecycleState.paused);

      // Silenciar mientras en background
      await service.setAudioEnabled(false);

      // Volver a foreground → NO reanuda
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(service.isPlaying, false);
      expect(mockPlayer.resumeCallCount, 0);
    });

    test('asset faltante no lanza excepción ni rompe estado (simulateMissingAsset)', () async {
      // Mock que simula asset faltante
      final failingPlayer = MockAmbientAudioPlayer(simulateMissingAsset: true);
      final failingSettings = AppSettingsService.createForTesting(prefs);
      final failingService = AmbientAudioService(
        settingsService: failingSettings,
        player: failingPlayer,
      );
      await failingService.initialize();

      await failingService.setAudioEnabled(true);
      // No debe lanzar aunque el asset no exista
      await failingService.updateAtmosphere(timePhase: ValleyTimePhase.night);

      expect(failingService.isAudioEnabled, true);
      // El servicio debe seguir funcional
      await failingService.setAudioEnabled(false);
      expect(failingService.isAudioEnabled, false);

      await failingService.dispose();
    });

    test('MockAmbientAudioPlayer con simulateMissingAsset no reproduce', () async {
      final mockPlayer = MockAmbientAudioPlayer(
        simulateMissingAsset: true,
        availableAssets: {'assets/audio/ambient_dawn.mp3'},
      );
      final mockSettings = AppSettingsService.createForTesting(prefs);
      final service = AmbientAudioService(
        settingsService: mockSettings,
        player: mockPlayer,
      );
      await service.initialize();

      await service.setAudioEnabled(true);
      expect(mockPlayer.playCallCount, 1);
      expect(mockPlayer.isPlaying, false); // simulateMissingAsset = true → no reproduce

      await service.dispose();
    });

    test('MockAmbientAudioPlayer con availableAssets reproduce solo los listados', () async {
      final mockPlayer = MockAmbientAudioPlayer(
        simulateMissingAsset: false,
        availableAssets: {'assets/audio/ambient_day.mp3'},
      );
      final mockSettings = AppSettingsService.createForTesting(prefs);
      final service = AmbientAudioService(
        settingsService: mockSettings,
        player: mockPlayer,
      );
      await service.initialize();

      await service.setAudioEnabled(true);
      // dawn no está en availableAssets
      await service.updateAtmosphere(timePhase: ValleyTimePhase.dawn);
      expect(mockPlayer.isPlaying, false);

      // day sí está
      await service.updateAtmosphere(timePhase: ValleyTimePhase.day);
      expect(mockPlayer.isPlaying, true);

      await service.dispose();
    });

    test('dispose limpia observer y reproductor', () async {
      await service.setAudioEnabled(true);
      await service.dispose();

      expect(mockPlayer.disposeCallCount, 1);
      // Después de dispose, no debe crashear al llamar métodos
      await service.setAudioEnabled(false);
      expect(service.isAudioEnabled, false);
    });
  });
}