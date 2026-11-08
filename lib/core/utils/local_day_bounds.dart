// Clase pura para calcular límites de día local en UTC.
// No depende de Flutter, sqflite ni ninguna otra librería.
// Usada por LocalDatabaseService y tests para consistencia.
//
// Cálculo del día siguiente: DateTime(año, mes, día + 1) en lugar de add(Duration(days: 1))
// para manejar correctamente cambios de horario (DST).
class LocalDayBounds {
  const LocalDayBounds._();

  /// Inicio del día local (00:00:00.000) en UTC.
  /// El [localDate] se interpreta en la zona horaria local del dispositivo.
  static DateTime startOfDayUtc(DateTime localDate) {
    final startOfDay = DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
      0,
      0,
      0,
      0,
    );
    return startOfDay.toUtc();
  }

  /// Inicio del día siguiente en UTC (00:00:00.000 del día siguiente).
  /// Calculado con DateTime(año, mes, día + 1) para evitar errores en cambios de horario.
  static DateTime startOfNextDayUtc(DateTime localDate) {
    final startOfNextDay = DateTime(
      localDate.year,
      localDate.month,
      localDate.day + 1,
      0,
      0,
      0,
      0,
    );
    return startOfNextDay.toUtc();
  }

  /// Trunca un DateTime a precisión de milisegundos (elimina microsegundos).
  /// Necesario para que la comparación de texto ISO 8601 sea correcta.
  static DateTime truncateToMillis(DateTime dt) {
    return DateTime.fromMillisecondsSinceEpoch(
      dt.millisecondsSinceEpoch,
      isUtc: dt.isUtc,
    );
  }

  /// Devuelve tupla (startUtc, endUtc) para consultas inclusivas de un rango de fechas locales.
  /// - startUtc: inicio del día [start] en UTC (inclusive)
  /// - endUtc: inicio del día después de [end] en UTC (exclusive)
  static ({DateTime startUtc, DateTime endUtc}) rangeUtc(DateTime start, DateTime end) {
    return (
      startUtc: startOfDayUtc(start),
      endUtc: startOfNextDayUtc(end),
    );
  }

  /// Devuelve el inicio UTC para "últimos N días" (incluye hoy y N-1 días anteriores).
  static DateTime sinceUtc(int days) {
    final today = DateTime.now();
    final since = today.subtract(Duration(days: days - 1));
    return startOfDayUtc(since);
  }
}