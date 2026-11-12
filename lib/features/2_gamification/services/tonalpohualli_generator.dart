// Generador de la Lectura del Tonalpohualli (Constelación de Venus).
//
// Algoritmo 100% local, sin IA externa.
// Reglas según CONTEXT.md punto 11 y docs/etapa_2_gamificacion_teotihuacan.md sección 6.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mi_calli/core/database/local_database_service.dart';
import 'package:mi_calli/core/settings/app_settings_provider.dart';
import 'package:mi_calli/core/settings/app_settings_service.dart';
import 'package:mi_calli/features/1_sanctuary_journal/data/diary_repository_provider.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/prehispanic_emotion.dart';
import 'package:mi_calli/features/2_gamification/models/tonalpohualli_models.dart';

/// Generador de lecturas astrales semanales (Tonalpohualli).
///
/// Combina frecuencias emocionales, actividad en la chinampa y el calendario
/// para producir una lectura poética en español de México.
class TonalpohualliGenerator {
  TonalpohualliGenerator(this._db, this._settings);

  final LocalDatabaseService _db;
  final AppSettingsService _settings;

  // ─── Constantes de emociones ───
  static const List<String> _allEmotionIds = [
    'tlaloc_lluvia',
    'tonatiuh_sol',
    'ehecatl_viento',
    'mixcoatl_tormenta',
    'metztli_noche',
  ];

  // ─── Disponibilidad (CONTEXT.md punto 11) ───

  /// Verifica si la lectura astral está disponible para el usuario.
  ///
  /// Reglas exactas:
  /// - Si no hubo entradas en diary_entries en los últimos 7 días → false
  /// - Si lastAstralReadingDate == todayYmd → false (ya abierta hoy)
  /// - Si lastAstralReadingDate != null:
  ///     * diffDays >= 7 → true
  ///     * Hoy es domingo (weekday == 7) y diffDays >= 1 → true
  ///     * Entre lastAstralReadingDate (exclusivo) y todayYmd (inclusivo) cruzó un domingo → true
  /// - Si lastAstralReadingDate == null (nunca abrió):
  ///     * Hoy es domingo → true
  ///     * Entre la entrada más antigua y hoy pasó un domingo o ≥7 días → true
  Future<bool> isReadingAvailable({DateTime? now}) async {
    final localNow = (now ?? DateTime.now()).toLocal();
    final todayYmd = _toYmd(localNow);

    // 1. Consultar entradas de los últimos 7 días (incluyendo hoy)
    // Inicio de ventana al inicio del día (00:00:00 local) antes de restar 6 días
    final startOfTodayLocal = DateTime(localNow.year, localNow.month, localNow.day);
    final sevenDaysAgo = startOfTodayLocal.subtract(const Duration(days: 6));
    final entries = await _db.getDiaryEntriesByDateRange(
      start: sevenDaysAgo,
      end: localNow.add(const Duration(days: 1)), // inclusive end
    );

    // Condición indispensable: sin entradas en 7 días → no disponible
    if (entries.isEmpty) {
      return false;
    }

    // 2. Leer última fecha de lectura
    final lastReadingDateStr = _settings.lastAstralReadingDate;

    // Si ya se abrió hoy → no disponible
    if (lastReadingDateStr == todayYmd) {
      return false;
    }

    // 3. Evaluar disponibilidad según lastAstralReadingDate
    if (lastReadingDateStr != null) {
      return _isAvailableWithPreviousReading(
        lastReadingDateStr: lastReadingDateStr,
        todayYmd: todayYmd,
        localNow: localNow,
      );
    } else {
      return await _isAvailableFirstTime(
        entries: entries,
        todayYmd: todayYmd,
        localNow: localNow,
      );
    }
  }

  /// Lógica cuando ya hay una lastAstralReadingDate previa.
  bool _isAvailableWithPreviousReading({
    required String lastReadingDateStr,
    required String todayYmd,
    required DateTime localNow,
  }) {
    final lastDate = _parseYmd(lastReadingDateStr);
    final todayDate = _parseYmd(todayYmd);

    if (lastDate == null || todayDate == null) return false;

    final diffDays = todayDate.difference(lastDate).inDays;

    // Regla: han pasado 7+ días calendario desde la última lectura
    if (diffDays >= 7) return true;

    // Regla: hoy es domingo y ha pasado al menos 1 día desde la última
    if (localNow.weekday == DateTime.sunday && diffDays >= 1) return true;

    // Regla: entre lastReadingDate (exclusivo) y todayYmd (inclusivo) cruzó un domingo
    // Esto mantiene la lectura disponible hasta que el usuario la abra
    return _crossedSundayBetween(lastDate, todayDate);
  }

  /// Lógica para primera vez (lastAstralReadingDate == null).
  Future<bool> _isAvailableFirstTime({
    required List<Map<String, dynamic>> entries,
    required String todayYmd,
    required DateTime localNow,
  }) async {
    final todayDate = _parseYmd(todayYmd);
    if (todayDate == null) return false;

    // Regla: hoy es domingo → disponible
    if (localNow.weekday == DateTime.sunday) return true;

    // Regla: entre la entrada más antigua HISTÓRICA y hoy pasó un domingo o ≥7 días
    // entries solo tiene últimos 7 días (máx diffDays = 6), así que consultamos la BD completa
    final allEntries = await _db.getDiaryEntriesByDateRange(
      start: DateTime(2000),
      end: localNow.add(const Duration(days: 1)),
    );
    if (allEntries.isEmpty) return false;

    final oldestEntry = allEntries.last;
    final oldestCreatedAtStr = oldestEntry['created_at'] as String;
    final oldestUtc = DateTime.parse(oldestCreatedAtStr).toUtc();
    final oldestLocal = oldestUtc.toLocal();
    // Usar DateTime.utc para que difference().inDays sea 100% exacto
    final oldestDate = DateTime.utc(oldestLocal.year, oldestLocal.month, oldestLocal.day);

    final diffDays = todayDate.difference(oldestDate).inDays;

    // Si han pasado 7+ días desde la primera entrada → disponible
    if (diffDays >= 7) return true;

    // Si entre la primera entrada y hoy cruzó un domingo → disponible
    return _crossedSundayBetween(oldestDate, todayDate);
  }

  /// Verifica si entre dos fechas (exclusivo inicio, inclusivo fin) cruzó un domingo.
  bool _crossedSundayBetween(DateTime startExclusive, DateTime endInclusive) {
    // Iterar desde startExclusive + 1 día hasta endInclusive
    var current = startExclusive.add(const Duration(days: 1));
    while (!current.isAfter(endInclusive)) {
      if (current.weekday == DateTime.sunday) return true;
      current = current.add(const Duration(days: 1));
    }
    return false;
  }

  /// Marca la lectura como abierta hoy (guarda todayYmd en last_astral_reading_date).
  Future<void> markReadingAsOpened({DateTime? now}) async {
    final localNow = (now ?? DateTime.now()).toLocal();
    final todayYmd = _toYmd(localNow);
    await _settings.setLastAstralReadingDate(todayYmd);
  }

  // ─── Generación de la Lectura ───

  /// Genera la lectura astral semanal completa.
  ///
  /// - Obtiene entradas de los últimos 7 días locales
  /// - Si no hay entradas, devuelve null
  /// - Construye vector V, determina Astro Regente, calcula C_total
  /// - Arma los 3 párrafos modulares
  /// - Si markAsOpened == true, guarda todayYmd en settings
  Future<WeeklyAstralReading?> generateWeeklyReading({
    DateTime? now,
    bool markAsOpened = false,
  }) async {
    final localNow = (now ?? DateTime.now()).toLocal();

    // Obtener entradas de los últimos 7 días (incluyendo hoy)
    // Inicio de ventana al inicio del día (00:00:00 local) antes de restar 6 días
    final startOfTodayLocal = DateTime(localNow.year, localNow.month, localNow.day);
    final sevenDaysAgo = startOfTodayLocal.subtract(const Duration(days: 6));
    final entries = await _db.getDiaryEntriesByDateRange(
      start: sevenDaysAgo,
      end: localNow.add(const Duration(days: 1)),
    );

    // Sin entradas → null
    if (entries.isEmpty) return null;

    // Construir vector V de frecuencias
    final emotionFrequencies = _buildEmotionVector(entries);

    // Determinar Astro Regente (max(V), desempate por entrada más reciente)
    final rulingEmotionId = _determineRulingEmotion(entries, emotionFrequencies);
    final rulingEmotion = PrehispanicEmotion.fromId(rulingEmotionId);

    // Calcular nourishedSproutsCount (C_total)
    final nourishedSproutsCount = _countNourishedSprouts(entries);

    // Total de entradas
    final totalEntries = entries.length;

    // Construir párrafos
    final openingParagraph = _buildOpeningParagraph(rulingEmotion);
    final bodyParagraph = _buildBodyParagraph(
      totalEntries: totalEntries,
      nourishedSproutsCount: nourishedSproutsCount,
    );
    final venusOmenParagraph = _buildVenusOmenParagraph(rulingEmotion);

    // Título místico
    final mysticTitle = _getMysticTitle(rulingEmotion);

    final reading = WeeklyAstralReading(
      rulingEmotion: rulingEmotion,
      mysticTitle: mysticTitle,
      emotionFrequencies: emotionFrequencies,
      totalEntries: totalEntries,
      nourishedSproutsCount: nourishedSproutsCount,
      openingParagraph: openingParagraph,
      bodyParagraph: bodyParagraph,
      venusOmenParagraph: venusOmenParagraph,
      generatedAt: DateTime.now().toUtc(),
    );

    // Marcar como abierta si se pide
    if (markAsOpened) {
      await markReadingAsOpened(now: now);
    }

    return reading;
  }

  /// Construye el vector V de frecuencias de las 5 emociones.
  Map<String, int> _buildEmotionVector(List<Map<String, dynamic>> entries) {
    final frequencies = <String, int>{};
    for (final emotionId in _allEmotionIds) {
      frequencies[emotionId] = 0;
    }
    for (final entry in entries) {
      final emotionId = entry['emotion_id'] as String;
      if (frequencies.containsKey(emotionId)) {
        frequencies[emotionId] = (frequencies[emotionId] ?? 0) + 1;
      }
    }
    return frequencies;
  }

  /// Determina la emoción predominante (Astro Regente).
  /// En caso de empate, desempata por la emoción de la entrada más reciente entre las empatadas.
  String _determineRulingEmotion(
    List<Map<String, dynamic>> entries,
    Map<String, int> frequencies,
  ) {
    // Encontrar el máximo
    int maxCount = 0;
    for (final count in frequencies.values) {
      if (count > maxCount) maxCount = count;
    }

    // Candidatos empatados
    final candidates = frequencies.entries
        .where((e) => e.value == maxCount)
        .map((e) => e.key)
        .toList();

    // Si solo uno, es el ganador
    if (candidates.length == 1) return candidates.first;

    // Desempate: emoción de la entrada más reciente entre las empatadas
    // entries viene ordenado DESC (más reciente primero)
    for (final entry in entries) {
      final emotionId = entry['emotion_id'] as String;
      if (candidates.contains(emotionId)) {
        return emotionId;
      }
    }

    // Fallback (no debería ocurrir)
    return candidates.first;
  }

  /// Cuenta brotes nutridos / riegos en la semana.
  /// Entradas con watered_seed_id != null.
  int _countNourishedSprouts(List<Map<String, dynamic>> entries) {
    int count = 0;
    for (final entry in entries) {
      final wateredSeedId = entry['watered_seed_id'];
      if (wateredSeedId != null && wateredSeedId is String && wateredSeedId.isNotEmpty) {
        count++;
      }
    }
    return count;
  }

  // ─── Plantillas de Texto (Español de México, cálido y poético) ───

  String _getMysticTitle(PrehispanicEmotion emotion) {
    return switch (emotion) {
      PrehispanicEmotion.tlalocLluvia => 'Bajo el Manto de Tláloc',
      PrehispanicEmotion.tonatiuhSol => 'El Resplandor de Tonatiuh',
      PrehispanicEmotion.ehecatlViento => 'El Aliento de Ehécatl',
      PrehispanicEmotion.mixcoatlTormenta => 'El Fuego de Mixcóatl',
      PrehispanicEmotion.metztliNoche => 'La Calma Estelar de Metztli',
    };
  }

  String _buildOpeningParagraph(PrehispanicEmotion rulingEmotion) {
    return switch (rulingEmotion) {
      PrehispanicEmotion.tlalocLluvia =>
          'Los sabios observadores del cielo vieron que las aguas de Tláloc '
          'bañaron tu valle esta semana. Cada gota que cayó sobre tu sembradío '
          'fue un susurro de la montaña, recordándote que la tristeza también riega '
          'y que de lo hondo brota lo más verde.',

      PrehispanicEmotion.tonatiuhSol =>
          'El Sol de Tonatiuh alzó su mirada dorada sobre tu camino y vio '
          'cómo la alegría florecía en cada rincón de tu chinampa. Los rayos '
          'besaron cada brote y tu corazón se abrió como flor de cempasúchil '
          'al mediodía.',

      PrehispanicEmotion.ehecatlViento =>
          'El Viento de Ehécatl cruzó los corredros de tu semana trayendo '
          'susurros de cambio. La ansiedad danzó entre las hojas, pero también '
          'limpió el aire estancado. Donde el viento pasa, nada queda igual.',

      PrehispanicEmotion.mixcoatlTormenta =>
          'La Tormenta de Mixcóatl rugió en los cielos de tu interior. '
          'El enojo y la frustración cayeron como granizo, pero también '
          'como lluvia que limpia la piedra. El fuego sagrado forja lo que el '
          'martillo solo rompería.',

      PrehispanicEmotion.metztliNoche =>
          'La Noche de Metztli extendió su manto violeta sobre tu valle. '
          'El cansancio llegó como neblina baja, invitando al reposo. '
          'En la quietud lunar, las semillas sueñan con el alba.',
    };
  }

  String _buildBodyParagraph({
    required int totalEntries,
    required int nourishedSproutsCount,
  }) {
    if (nourishedSproutsCount > 0) {
      return 'Tu chinampa guardó memoria de $nourishedSproutsCount brotes nutridos '
          'entre las $totalEntries ofrendas que dejaste en el altar. Cada riego fue '
          'una promesa cumplida, cada semilla bebida un pacto con la tierra. '
          'Quetzalcóatl sonríe al ver que tus manos no olvidaron el surco.';
    } else {
      return 'Esta semana entregaste $totalEntries ofrendas al altar sagrado, '
          'aunque la chinampa aún espera sus primeras semillas. No hay prisa: '
          'el valle sabe que quien prepara la tierra con paciencia cosecha con '
          'abundancia. Tu intención ya es siembra.';
    }
  }

  String _buildVenusOmenParagraph(PrehispanicEmotion rulingEmotion) {
    return switch (rulingEmotion) {
      PrehispanicEmotion.tlalocLluvia =>
          'Venus, lucero de la mañana, asoma sobre el horizonte y susurra: '
          '"Las aguas que hoy caen son los ríos del mañana. Confía en tu valle."',

      PrehispanicEmotion.tonatiuhSol =>
          'Venus brilla en el alba y te dice: "Tu luz no se apaga con la noche. '
          'Cada amanecer te encuentra más entero. Camina con el pecho abierto."',

      PrehispanicEmotion.ehecatlViento =>
          'Venus atraviesa el viento y murmura: "Lo que hoy agita tus ramas '
          'mañana serán alas. El cambio no te arrastra, te eleva."',

      PrehispanicEmotion.mixcoatlTormenta =>
          'Venus observa la tormenta y declara: "El rayo ilumina el camino '
          'que el miedo oculta. Tu fuego sagrado no quema, transforma."',

      PrehispanicEmotion.metztliNoche =>
          'Venus vela en la madrugada y promete: "El descanso no es rendición, '
          'es la raíz que se prepara para el vuelo. Mañana naces de nuevo."',
    };
  }

  // ─── Helpers ───

  /// Convierte DateTime local a string YYYY-MM-DD.
  String _toYmd(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  /// Parsea YYYY-MM-DD a DateTime (en UTC para cálculos de días puros).
  DateTime? _parseYmd(String ymd) {
    try {
      final parts = ymd.split('-');
      if (parts.length != 3) return null;
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      return DateTime.utc(year, month, day);
    } catch (_) {
      return null;
    }
  }
}

/// Provider del generador de Tonalpohualli.
final tonalpohualliGeneratorProvider = Provider<TonalpohualliGenerator>((ref) {
  final db = ref.watch(localDatabaseServiceProvider);
  final settings = ref.watch(appSettingsServiceProvider);
  return TonalpohualliGenerator(db, settings);
});

/// Provider reactivo de disponibilidad de la lectura astral.
///
/// Se actualiza cuando cambian las entradas de diario o la fecha.
final isTonalpohualliAvailableProvider = FutureProvider<bool>((ref) async {
  final generator = ref.watch(tonalpohualliGeneratorProvider);
  return generator.isReadingAvailable();
});