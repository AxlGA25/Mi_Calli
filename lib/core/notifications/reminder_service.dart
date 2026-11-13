// ReminderService con flutter_local_notifications (Tarea 4.7).
//
// Recordatorio diario opcional a la hora elegida, mensaje genérico,
// permiso pedido solo al activarlo.
//
// Incluye abstracción LocalNotificationsGateway para tests deterministas.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:mi_calli/core/settings/app_settings_service.dart';
import 'package:mi_calli/core/settings/app_settings_provider.dart';

/// Textos discretos y compasivos para el recordatorio.
///
/// Regla estricta de privacidad: Ni el título ni el cuerpo pueden mencionar
/// jamás las palabras "racha", "fuego", "perder", "diario", "entrada",
/// "emoción", "tristeza", "ansiedad", "depresión" ni ningún contenido
/// escrito por la persona.
class ReminderTexts {
  static const String title = 'Mi Calli · Tu refugio te espera';
  static const String body =
      'Si hoy deseas regalarle unos minutos a tu jardín interior, aquí estamos.';

  // Palabras prohibidas que nunca deben aparecer en título ni cuerpo
  static const Set<String> _forbiddenWords = {
    'racha',
    'fuego',
    'perder',
    'diario',
    'entrada',
    'emoción',
    'tristeza',
    'ansiedad',
    'depresión',
    'crisis',
  };

  /// Verifica que un texto no contenga palabras prohibidas.
  static bool isValid(String text) {
    final lower = text.toLowerCase();
    for (final word in _forbiddenWords) {
      if (lower.contains(word)) return false;
    }
    return true;
  }

  /// Verifica que título y cuerpo cumplan la regla de privacidad.
  static bool validateAll() => isValid(title) && isValid(body);
}

/// ID único para la notificación de recordatorio diario.
const int reminderNotificationId = 42;

/// Canal de notificación para Android.
const String _androidChannelId = 'mi_calli_daily_reminder';
const String _androidChannelName = 'Recordatorio del Santuario';
const String _androidChannelDescription =
    'Recordatorio diario suave para visitar tu refugio';

/// Abstracción para el gateway de notificaciones locales.
///
/// Permite tests 100% deterministas y rápidos sin depender del plugin nativo.
abstract class LocalNotificationsGateway {
  /// Inicializa el gateway (configura canales, zonas horarias, etc.).
  Future<void> initialize();

  /// Solicita permiso de notificaciones al usuario.
  /// Retorna true si se concede, false si se deniega.
  Future<bool> requestPermission();

  /// Programa una notificación diaria a la hora y minuto indicados.
  ///
  /// Usa [DateTimeComponents.time] para repetición diaria.
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  });

  /// Cancela una notificación programada por su ID.
  Future<void> cancel(int id);

  /// Cancela todas las notificaciones programadas.
  Future<void> cancelAll();
}

/// Implementación real usando FlutterLocalNotificationsPlugin.
class FlutterLocalNotificationsGateway implements LocalNotificationsGateway {
  FlutterLocalNotificationsGateway();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize() async {
    // Inicializar zonas horarias de forma segura
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.local);

    // Configuración de inicialización para Android e iOS
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
    );

    await _plugin.initialize(initSettings);

    // Crear canal de notificación para Android
    const androidChannel = AndroidNotificationChannel(
      _androidChannelId,
      _androidChannelName,
      description: _androidChannelDescription,
      importance: Importance.defaultImportance,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  @override
  Future<bool> requestPermission() async {
    final result = await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // En Android 13+, requestPermissions retorna true si ya tiene permiso
    // o muestra el diálogo. En versiones anteriores, siempre retorna true.
    final androidResult = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Consideramos concedido si al menos una plataforma lo permite
    return (result ?? false) || (androidResult ?? true);
  }

  @override
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    // Calcular la próxima ocurrencia de la hora indicada
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Si la hora ya pasó hoy, programar para mañana
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      _androidChannelId,
      _androidChannelName,
      channelDescription: _androidChannelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  @override
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}

/// Servicio de recordatorios que coordina gateway y ajustes.
class ReminderService {
  ReminderService({
    required this.gateway,
    required this.settingsService,
  });

  final LocalNotificationsGateway gateway;
  final AppSettingsService settingsService;

  bool _initialized = false;

  /// Asegura que el gateway esté inicializado.
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await gateway.initialize();
      _initialized = true;
    }
  }

  /// Activa el recordatorio diario.
  ///
  /// - Inicializa el gateway
  /// - Pide permiso de notificaciones
  /// - Si se concede: guarda reminderEnabled=true y hora/minuto, programa notificación, retorna true
  /// - Si se deniega: asegura reminderEnabled=false, no programa nada, retorna false
  Future<bool> enableReminder({
    required int hour,
    required int minute,
  }) async {
    await _ensureInitialized();

    final granted = await gateway.requestPermission();

    if (!granted) {
      await settingsService.setReminderEnabled(false);
      return false;
    }

    final timeString = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    await settingsService.setReminderEnabled(true);
    await settingsService.setReminderTime(timeString);

    await gateway.scheduleDaily(
      id: reminderNotificationId,
      title: ReminderTexts.title,
      body: ReminderTexts.body,
      hour: hour,
      minute: minute,
    );

    return true;
  }

  /// Desactiva el recordatorio diario.
  ///
  /// Cancela la notificación programada y guarda reminderEnabled=false.
  Future<void> disableReminder() async {
    await _ensureInitialized();

    await gateway.cancel(reminderNotificationId);
    await settingsService.setReminderEnabled(false);
  }

  /// Actualiza la hora del recordatorio.
  ///
  /// Guarda la nueva hora/minuto. Si el recordatorio está activo, reprograma la notificación.
  Future<void> updateReminderTime({
    required int hour,
    required int minute,
  }) async {
    await _ensureInitialized();

    final timeString = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    await settingsService.setReminderTime(timeString);

    final currentState = settingsService.currentState;
    if (currentState.reminderEnabled) {
      await gateway.cancel(reminderNotificationId);
      await gateway.scheduleDaily(
        id: reminderNotificationId,
        title: ReminderTexts.title,
        body: ReminderTexts.body,
        hour: hour,
        minute: minute,
      );
    }
  }
}

/// Provider del gateway de notificaciones (para inyección en tests).
final localNotificationsGatewayProvider = Provider<LocalNotificationsGateway>(
  (ref) => FlutterLocalNotificationsGateway(),
);

/// Provider del ReminderService.
final reminderServiceProvider = Provider<ReminderService>((ref) {
  final gateway = ref.watch(localNotificationsGatewayProvider);
  final settingsService = ref.watch(appSettingsServiceProvider);
  return ReminderService(gateway: gateway, settingsService: settingsService);
});