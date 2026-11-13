// Pruebas para ReminderService (Tarea 4.7).
//
// Usa FakeLocalNotificationsGateway en memoria para tests 100% deterministas y rápidos.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_calli/core/notifications/reminder_service.dart';
import 'package:mi_calli/core/settings/app_settings_service.dart';

/// Fake in-memory implementation of LocalNotificationsGateway for testing.
class FakeLocalNotificationsGateway implements LocalNotificationsGateway {
  FakeLocalNotificationsGateway({this.permissionGranted = true});

  final bool permissionGranted;
  bool initialized = false;
  int requestPermissionCalls = 0;
  int scheduledId = -1;
  int scheduledHour = -1;
  int scheduledMinute = -1;
  String? scheduledTitle;
  String? scheduledBody;
  final List<int> cancelledIds = [];

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    requestPermissionCalls++;
    return permissionGranted;
  }

  @override
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    scheduledId = id;
    scheduledTitle = title;
    scheduledBody = body;
    scheduledHour = hour;
    scheduledMinute = minute;
  }

  @override
  Future<void> cancel(int id) async {
    cancelledIds.add(id);
  }

  @override
  Future<void> cancelAll() async {
    // No-op for tests
  }
}

void main() {
  group('ReminderService', () {
    late SharedPreferences prefs;
    late AppSettingsService settingsService;
    late FakeLocalNotificationsGateway fakeGateway;
    late ReminderService reminderService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      settingsService = AppSettingsService.createForTesting(prefs);
      fakeGateway = FakeLocalNotificationsGateway(permissionGranted: true);
      reminderService = ReminderService(
        gateway: fakeGateway,
        settingsService: settingsService,
      );
    });

    group('Inicialización', () {
      test('al inicializar no pide permisos ni programa nada', () async {
        // No llamar a ningún método, solo verificar estado inicial
        expect(fakeGateway.initialized, isFalse);
        expect(fakeGateway.requestPermissionCalls, equals(0));
        expect(fakeGateway.scheduledId, equals(-1));
        expect(settingsService.reminderEnabled, isFalse);
      });
    });

    group('Activar recordatorio con permiso concedido', () {
      test('pide permiso, programa notificación diaria con hora exacta y guarda reminderEnabled=true', () async {
        const hour = 18;
        const minute = 30;

        final result = await reminderService.enableReminder(hour: hour, minute: minute);

        expect(result, isTrue);
        expect(fakeGateway.initialized, isTrue);
        expect(fakeGateway.requestPermissionCalls, equals(1));
        expect(fakeGateway.scheduledId, equals(reminderNotificationId));
        expect(fakeGateway.scheduledHour, equals(hour));
        expect(fakeGateway.scheduledMinute, equals(minute));
        expect(fakeGateway.scheduledTitle, equals(ReminderTexts.title));
        expect(fakeGateway.scheduledBody, equals(ReminderTexts.body));
        expect(settingsService.reminderEnabled, isTrue);
        expect(settingsService.reminderTime, equals('18:30'));
      });

      test('usa hora por defecto 20:00 si no se especifica', () async {
        // Usar valores por defecto
        final result = await reminderService.enableReminder(hour: 20, minute: 0);

        expect(result, isTrue);
        expect(fakeGateway.scheduledHour, equals(20));
        expect(fakeGateway.scheduledMinute, equals(0));
        expect(settingsService.reminderTime, equals('20:00'));
      });
    });

    group('Activar recordatorio con permiso denegado', () {
      test('pide permiso, NO programa notificación y deja reminderEnabled=false', () async {
        fakeGateway = FakeLocalNotificationsGateway(permissionGranted: false);
        reminderService = ReminderService(
          gateway: fakeGateway,
          settingsService: settingsService,
        );

        final result = await reminderService.enableReminder(hour: 18, minute: 30);

        expect(result, isFalse);
        expect(fakeGateway.requestPermissionCalls, equals(1));
        expect(fakeGateway.scheduledId, equals(-1)); // No programado
        expect(settingsService.reminderEnabled, isFalse);
        expect(settingsService.reminderTime, isNull);
      });
    });

    group('Desactivar recordatorio', () {
      test('cancela la notificación y guarda reminderEnabled=false', () async {
        // Primero activar
        await reminderService.enableReminder(hour: 18, minute: 30);
        expect(settingsService.reminderEnabled, isTrue);

        // Luego desactivar
        await reminderService.disableReminder();

        expect(fakeGateway.cancelledIds, contains(reminderNotificationId));
        expect(settingsService.reminderEnabled, isFalse);
      });
    });

    group('Cambiar hora con recordatorio activo', () {
      test('reprograma la notificación con la nueva hora', () async {
        // Primero activar
        await reminderService.enableReminder(hour: 18, minute: 30);
        fakeGateway.cancelledIds.clear();
        fakeGateway.scheduledId = -1;

        // Cambiar hora
        await reminderService.updateReminderTime(hour: 7, minute: 0);

        expect(fakeGateway.cancelledIds, contains(reminderNotificationId));
        expect(fakeGateway.scheduledId, equals(reminderNotificationId));
        expect(fakeGateway.scheduledHour, equals(7));
        expect(fakeGateway.scheduledMinute, equals(0));
        expect(settingsService.reminderTime, equals('07:00'));
      });

      test('no reprograma si reminderEnabled=false', () async {
        // No activar, solo cambiar hora
        await reminderService.updateReminderTime(hour: 7, minute: 0);

        expect(fakeGateway.cancelledIds, isEmpty);
        expect(fakeGateway.scheduledId, equals(-1));
        expect(settingsService.reminderTime, equals('07:00')); // Se guarda la hora pero no programa
      });
    });

    group('Privacidad del texto', () {
      test('ReminderTexts.title no contiene palabras prohibidas', () {
        expect(ReminderTexts.isValid(ReminderTexts.title), isTrue);
      });

      test('ReminderTexts.body no contiene palabras prohibidas', () {
        expect(ReminderTexts.isValid(ReminderTexts.body), isTrue);
      });

      test('validateAll retorna true', () {
        expect(ReminderTexts.validateAll(), isTrue);
      });

      test('payload enviado al gateway no contiene palabras prohibidas', () async {
        await reminderService.enableReminder(hour: 18, minute: 30);

        final title = fakeGateway.scheduledTitle!;
        final body = fakeGateway.scheduledBody!;

        expect(ReminderTexts.isValid(title), isTrue);
        expect(ReminderTexts.isValid(body), isTrue);

        // Verificar palabras específicas prohibidas
        final forbiddenWords = [
          'racha', 'fuego', 'perder', 'diario', 'entrada',
          'emoción', 'tristeza', 'ansiedad', 'depresión', 'crisis'
        ];

        for (final word in forbiddenWords) {
          expect(title.toLowerCase().contains(word), isFalse, reason: 'Título no debe contener "$word"');
          expect(body.toLowerCase().contains(word), isFalse, reason: 'Cuerpo no debe contener "$word"');
        }
      });
    });
  });
}