// Pruebas unitarias para BreathingCycleEngine (motor puro de Dart, sin Flutter).

import 'package:flutter_test/flutter_test.dart';
import 'package:mi_calli/features/3_teotihuacan_valley/presentation/widgets/breathing_cycle_engine.dart';

void main() {
  group('BreathingCycleEngine', () {
    late BreathingCycleEngine engine;

    setUp(() {
      engine = BreathingCycleEngine();
    });

    test('estado inicial es idle con 0 ciclos', () {
      expect(engine.phase, equals(BreathingEnginePhase.idle));
      expect(engine.completedCycles, equals(0));
      expect(engine.secondsRemaining, equals(0));
      expect(engine.isRunning, isFalse);
    });

    test('start() inicia en fase inhale con 4 segundos', () {
      engine.start();
      expect(engine.phase, equals(BreathingEnginePhase.inhale));
      expect(engine.secondsRemaining, equals(4));
      expect(engine.isRunning, isTrue);
    });

    test('tick() avanza segundos y cambia fases correctamente', () {
      engine.start();

      // Segundo 1: inhale (3s restantes)
      expect(engine.tick(), isFalse);
      expect(engine.phase, equals(BreathingEnginePhase.inhale));
      expect(engine.secondsRemaining, equals(3));

      // Segundo 2: inhale (2s restantes)
      expect(engine.tick(), isFalse);
      expect(engine.secondsRemaining, equals(2));

      // Segundo 3: inhale (1s restantes)
      expect(engine.tick(), isFalse);
      expect(engine.secondsRemaining, equals(1));

      // Segundo 4: transición a hold (4s restantes en hold)
      expect(engine.tick(), isFalse);
      expect(engine.phase, equals(BreathingEnginePhase.hold));
      expect(engine.secondsRemaining, equals(4));

      // Segundos 5-8: hold
      expect(engine.tick(), isFalse); // 5
      expect(engine.secondsRemaining, equals(3));
      expect(engine.tick(), isFalse); // 6
      expect(engine.secondsRemaining, equals(2));
      expect(engine.tick(), isFalse); // 7
      expect(engine.secondsRemaining, equals(1));
      // Segundo 8: transición a exhale
      expect(engine.tick(), isFalse);
      expect(engine.phase, equals(BreathingEnginePhase.exhale));
      expect(engine.secondsRemaining, equals(6));

      // Segundos 9-14: exhale
      expect(engine.tick(), isFalse); // 9
      expect(engine.secondsRemaining, equals(5));
      expect(engine.tick(), isFalse); // 10
      expect(engine.secondsRemaining, equals(4));
      expect(engine.tick(), isFalse); // 11
      expect(engine.secondsRemaining, equals(3));
      expect(engine.tick(), isFalse); // 12
      expect(engine.secondsRemaining, equals(2));
      expect(engine.tick(), isFalse); // 13
      expect(engine.secondsRemaining, equals(1));
      // Segundo 14: ciclo completado, vuelve a inhale
      expect(engine.tick(), isTrue);
      expect(engine.completedCycles, equals(1));
      expect(engine.phase, equals(BreathingEnginePhase.inhale));
      expect(engine.secondsRemaining, equals(4));
    });

    test('ciclo 1 completo al segundo 14', () {
      engine.start();
      engine.tickMultiple(14);
      expect(engine.completedCycles, equals(1));
      expect(engine.phase, equals(BreathingEnginePhase.inhale));
    });

    test('tres ciclos completados al segundo 42', () {
      engine.start();
      engine.tickMultiple(42);
      expect(engine.completedCycles, equals(3));
      expect(engine.phase, equals(BreathingEnginePhase.inhale));
    });

    test('pause() detiene el motor y guarda estado', () {
      engine.start();
      engine.tickMultiple(5); // En medio de hold
      expect(engine.phase, equals(BreathingEnginePhase.hold));
      expect(engine.isRunning, isTrue);

      engine.pause();
      expect(engine.phase, equals(BreathingEnginePhase.paused));
      expect(engine.isRunning, isFalse);
      expect(engine.isPaused, isTrue);
      expect(engine.secondsRemaining, equals(3)); // 4 segundos de hold, pasó 1, quedan 3
    });

    test('resume() reanuda desde donde se pausó', () {
      engine.start();
      engine.tickMultiple(5); // En hold
      engine.pause();
      engine.resume();
      expect(engine.isRunning, isTrue);
      expect(engine.phase, equals(BreathingEnginePhase.hold));
      expect(engine.secondsRemaining, equals(3));
    });

    test('reset() vuelve a estado inicial', () {
      engine.start();
      engine.tickMultiple(20);
      expect(engine.completedCycles, greaterThan(0));

      engine.reset();
      expect(engine.phase, equals(BreathingEnginePhase.idle));
      expect(engine.completedCycles, equals(0));
      expect(engine.secondsRemaining, equals(0));
      expect(engine.isRunning, isFalse);
    });

    test('tick() sin start() lanza StateError', () {
      expect(() => engine.tick(), throwsA(isA<StateError>()));
    });

    test('tickMultiple() sin start() lanza StateError', () {
      expect(() => engine.tickMultiple(5), throwsA(isA<StateError>()));
    });

    test('pause() sin start() no cambia estado', () {
      engine.pause();
      expect(engine.phase, equals(BreathingEnginePhase.idle));
      expect(engine.isRunning, isFalse);
    });

    test('resume() sin pause() no cambia estado', () {
      engine.start();
      engine.resume(); // Ya está corriendo
      expect(engine.isRunning, isTrue);
      expect(engine.phase, equals(BreathingEnginePhase.inhale));
    });

    test('complete() marca como completado y detiene', () {
      engine.start();
      engine.complete();
      expect(engine.phase, equals(BreathingEnginePhase.completed));
      expect(engine.isRunning, isFalse);
      expect(engine.secondsRemaining, equals(0));
    });

    test('textos de fase son correctos', () {
      engine.start(); // inhale
      expect(engine.getPhaseText(), equals('Inhala'));

      engine.tickMultiple(4); // hold
      expect(engine.getPhaseText(), equals('Sostén'));

      engine.tickMultiple(4); // exhale
      expect(engine.getPhaseText(), equals('Exhala'));

      engine.pause();
      expect(engine.getPhaseText(), equals('Pausado'));

      engine.reset();
      engine.complete();
      expect(engine.getPhaseText(), equals('Completo'));
    });

    test('nombres de iconos de fase son correctos', () {
      engine.start(); // inhale
      expect(engine.getPhaseIconName(), equals('arrow_upward'));

      engine.tickMultiple(4); // hold
      expect(engine.getPhaseIconName(), equals('pause_circle_filled'));

      engine.tickMultiple(4); // exhale
      expect(engine.getPhaseIconName(), equals('arrow_downward'));
    });

    test('segundos restantes correctos en cada fase', () {
      engine.start();
      // inhale: 4, 3, 2, 1
      expect(engine.secondsRemaining, equals(4));
      engine.tick();
      expect(engine.secondsRemaining, equals(3));
      engine.tick();
      expect(engine.secondsRemaining, equals(2));
      engine.tick();
      expect(engine.secondsRemaining, equals(1));

      // hold: 4, 3, 2, 1
      engine.tick();
      expect(engine.secondsRemaining, equals(4));
      engine.tick();
      expect(engine.secondsRemaining, equals(3));
      engine.tick();
      expect(engine.secondsRemaining, equals(2));
      engine.tick();
      expect(engine.secondsRemaining, equals(1));

      // exhale: 6, 5, 4, 3, 2, 1
      engine.tick();
      expect(engine.secondsRemaining, equals(6));
      engine.tick();
      expect(engine.secondsRemaining, equals(5));
      engine.tick();
      expect(engine.secondsRemaining, equals(4));
      engine.tick();
      expect(engine.secondsRemaining, equals(3));
      engine.tick();
      expect(engine.secondsRemaining, equals(2));
      engine.tick();
      expect(engine.secondsRemaining, equals(1));

      // ciclo completado, vuelve a inhale con 4
      engine.tick();
      expect(engine.secondsRemaining, equals(4));
    });
  });
}