// Servicio de base de datos local cifrada con SQLCipher.
//
// - Usa `sqflite_sqlcipher` para cifrado AES-256.
// - La llave (32 bytes aleatorios, base64) se genera una sola vez y
//   se guarda en `SecureStorageInterface` (flutter_secure_storage en prod).
// - **Nunca** imprime la llave ni el campo `content` de diary_entries en logs.
//
// Tablas (CONTEXT.md sección 5A):
// - diary_entries
// - user_gamification
// - chinampa_slots
// - user_inventory
//
// NOTA: Las pruebas de integración con base de datos real (SQLCipher en dispositivo)
// se realizarán en el punto de control 1 (checkpoint 1) usando un dispositivo físico.
// Los tests unitarios actuales usan mocks que replican la lógica de límites UTC.

import 'dart:convert';
import 'dart:math';

import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart' as path;

import '../utils/local_day_bounds.dart';
import 'secure_storage_interface.dart';
import 'secure_storage_impl.dart';
import 'secure_storage_mock.dart';

/// Excepción para errores de base de datos.
class DatabaseException implements Exception {
  final String message;
  const DatabaseException(this.message);
  @override
  String toString() => 'DatabaseException: $message';
}

/// Servicio singleton para la base de datos local cifrada.
class LocalDatabaseService {
  LocalDatabaseService._({
    required this.secureStorage,
    String? databasePath,
  }) : _databasePath = databasePath;

  final SecureStorageInterface secureStorage;
  final String? _databasePath;

  Database? _database;
  bool _isInitialized = false;

  static const String _keyStorageKey = 'refugio_db_encryption_key';
  static const String _dbFileName = 'refugio_quetzalcoatl.db';

  /// Instancia singleton para producción.
  static LocalDatabaseService? _instance;

  /// Inicializa el singleton de producción.
  /// Debe llamarse una vez al arrancar la app.
  static Future<LocalDatabaseService> initializeProduction({
    String? databasePath,
  }) async {
    if (_instance != null) return _instance!;

    final secureStorage = SecureStorageImpl();
    _instance = LocalDatabaseService._(
      secureStorage: secureStorage,
      databasePath: databasePath,
    );
    await _instance!._ensureInitialized();
    return _instance!;
  }

  /// Crea una instancia para tests con almacenamiento mockeado.
  static LocalDatabaseService createForTesting({
    required SecureStorageMock secureStorage,
    String? databasePath,
  }) {
    return LocalDatabaseService._(
      secureStorage: secureStorage,
      databasePath: databasePath,
    );
  }

  /// Obtiene la instancia singleton (debe llamarse después de initializeProduction).
  static LocalDatabaseService get instance {
    if (_instance == null) {
      throw StateError(
        'LocalDatabaseService no inicializado. Llama a initializeProduction() primero.',
      );
    }
    return _instance!;
  }

  /// Asegura que la base de datos esté inicializada.
  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    final key = await _getOrCreateEncryptionKey();
    _database = await _openDatabase(key);
    await _createTables();
    await _insertInitialData();
    _isInitialized = true;
  }

  /// Genera o recupera la llave de cifrado (32 bytes = 256 bits).
  Future<String> _getOrCreateEncryptionKey() async {
    final existingKey = await secureStorage.read(key: _keyStorageKey);
    if (existingKey != null) {
      return existingKey;
    }

    // Generar 32 bytes aleatorios criptográficamente seguros
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final keyBase64 = base64Encode(bytes);

    // Guardar en almacenamiento seguro
    await secureStorage.write(key: _keyStorageKey, value: keyBase64);
    return keyBase64;
  }

  /// Abre la base de datos con la llave de cifrado.
  Future<Database> _openDatabase(String keyBase64) async {
    final dbPath = _databasePath ?? await _getDefaultDbPath();

    // sqflite_sqlcipher espera el password como String (clave en hex o base64)
    return openDatabase(
      dbPath,
      version: 1,
      password: keyBase64,
      onOpen: (db) {
        // Verificar que el cifrado funciona intentando leer
        // (si la llave es incorrecta, esto fallará)
        db.rawQuery('PRAGMA cipher_version');
      },
    );
  }

  Future<String> _getDefaultDbPath() async {
    // En producción, getDatabasesPath() de sqflite da el directorio correcto
    // Para tests podemos inyectar una ruta via _databasePath
    // Nota: sqflite provee getDatabasesPath() pero no lo importamos aquí
    // para evitar dependencia en tests; usamos path package.
    // En la app real, se usaría getDatabasesPath() de sqflite.
    return path.join(
      _databasePath ?? '.',
      _dbFileName,
    );
  }

  /// Crea las 4 tablas según CONTEXT.md sección 5A.
  Future<void> _createTables() async {
    final db = _database!;
    await db.transaction((txn) async {
      // 1. diary_entries
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS diary_entries (
          id TEXT PRIMARY KEY,
          created_at TEXT NOT NULL,
          emotion_id TEXT NOT NULL,
          content TEXT NOT NULL,
          feather_id TEXT NOT NULL,
          watered_seed_id TEXT,
          triggered_sos INTEGER NOT NULL DEFAULT 0
        )
      ''');

      // 2. user_gamification
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS user_gamification (
          local_id TEXT PRIMARY KEY,
          google_uid TEXT,
          quetzal_xp INTEGER NOT NULL DEFAULT 0,
          quetzal_level INTEGER NOT NULL DEFAULT 1,
          current_streak INTEGER NOT NULL DEFAULT 0,
          longest_streak INTEGER NOT NULL DEFAULT 0,
          last_checkin_date TEXT,
          xolotl_shields INTEGER NOT NULL DEFAULT 1
        )
      ''');

      // 3. chinampa_slots
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS chinampa_slots (
          slot_index INTEGER PRIMARY KEY,
          seed_id TEXT,
          current_waterings INTEGER NOT NULL DEFAULT 0,
          is_harvested INTEGER NOT NULL DEFAULT 0,
          planted_at TEXT
        )
      ''');

      // 4. user_inventory
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS user_inventory (
          item_id TEXT PRIMARY KEY,
          item_type TEXT NOT NULL,
          quantity INTEGER NOT NULL DEFAULT 1,
          unlocked_at TEXT NOT NULL
        )
      ''');
    });
  }

  /// Inserta datos iniciales: fila user_gamification y 4 slots vacíos.
  Future<void> _insertInitialData() async {
    final db = _database!;

    await db.transaction((txn) async {
      // Insertar fila inicial de user_gamification si no existe
      final existingGamification = await txn.query(
        'user_gamification',
        where: 'local_id = ?',
        whereArgs: ['local'],
      );

      if (existingGamification.isEmpty) {
        await txn.insert('user_gamification', {
          'local_id': 'local',
          'google_uid': null,
          'quetzal_xp': 0,
          'quetzal_level': 1,
          'current_streak': 0,
          'longest_streak': 0,
          'last_checkin_date': null,
          'xolotl_shields': 1,
        });
      }

      // Insertar 4 slots vacíos de chinampa si no existen
      for (int i = 0; i < 4; i++) {
        final existingSlot = await txn.query(
          'chinampa_slots',
          where: 'slot_index = ?',
          whereArgs: [i],
        );

        if (existingSlot.isEmpty) {
          await txn.insert('chinampa_slots', {
            'slot_index': i,
            'seed_id': null,
            'current_waterings': 0,
            'is_harvested': 0,
            'planted_at': null,
          });
        }
      }
    });
  }

  // ─── API Pública ───

  /// Inicializa la base de datos (llama a _ensureInitialized).
  /// Útil para tests y para inicialización explícita.
  Future<void> initialize() async {
    await _ensureInitialized();
  }

  /// Obtiene la base de datos (lanza si no inicializada).
  Database get database {
    if (_database == null) {
      throw StateError('Base de datos no inicializada. Llama a _ensureInitialized() primero.');
    }
    return _database!;
  }

  /// Verifica si la base está inicializada.
  bool get isInitialized => _isInitialized;

  // ─── diary_entries ───

  /// Inserta una entrada de diario.
  ///
  /// Almacena created_at en UTC con precisión de milisegundos (sin microsegundos)
  /// para que la comparación de texto ISO 8601 sea correcta.
  Future<int> insertDiaryEntry({
    required String id,
    required DateTime createdAt,
    required String emotionId,
    required String content,
    required String featherId,
    String? wateredSeedId,
    bool triggeredSos = false,
  }) async {
    final createdAtMillis = LocalDayBounds.truncateToMillis(createdAt);
    return _database!.insert('diary_entries', {
      'id': id,
      'created_at': createdAtMillis.toIso8601String(),
      'emotion_id': emotionId,
      'content': content,
      'feather_id': featherId,
      'watered_seed_id': wateredSeedId,
      'triggered_sos': triggeredSos ? 1 : 0,
    });
  }

  /// Obtiene entradas por rango de fechas (inclusive, usando fecha local YYYY-MM-DD).
  ///
  /// Según CONTEXT.md punto 7: las fechas se calculan con la fecha local del dispositivo.
  /// Convierte los límites a UTC y consulta con created_at >= ? AND created_at < ?
  /// para no depender de la función date() de SQLite.
  Future<List<Map<String, dynamic>>> getDiaryEntriesByDateRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final bounds = LocalDayBounds.rangeUtc(start, end);

    return _database!.query(
      'diary_entries',
      where: 'created_at >= ? AND created_at < ?',
      whereArgs: [bounds.startUtc.toIso8601String(), bounds.endUtc.toIso8601String()],
      orderBy: 'created_at DESC',
    );
  }

  /// Cuenta emociones en los últimos N días (usando fecha local).
  ///
  /// Incluye el día de hoy y [days-1] días anteriores.
  /// Convierte el límite a UTC y consulta con created_at >= ?
  /// para no depender de la función date() de SQLite.
  Future<Map<String, int>> countEmotionsLastDays(int days) async {
    final sinceUtc = LocalDayBounds.sinceUtc(days);

    final rows = await _database!.query(
      'diary_entries',
      columns: ['emotion_id'],
      where: 'created_at >= ?',
      whereArgs: [sinceUtc.toIso8601String()],
    );

    final counts = <String, int>{};
    for (final row in rows) {
      final emotion = row['emotion_id'] as String;
      counts[emotion] = (counts[emotion] ?? 0) + 1;
    }
    return counts;
  }

  // ─── user_gamification ───

  /// Obtiene el estado de gamificación (única fila con local_id='local').
  Future<Map<String, dynamic>?> getGamificationState() async {
    final rows = await _database!.query(
      'user_gamification',
      where: 'local_id = ?',
      whereArgs: ['local'],
      limit: 1,
    );
    return rows.isNotEmpty ? rows.first : null;
  }

  /// Actualiza campos de gamificación.
  Future<int> updateGamification(Map<String, dynamic> values) async {
    return _database!.update(
      'user_gamification',
      values,
      where: 'local_id = ?',
      whereArgs: ['local'],
    );
  }

  /// Actualiza google_uid al iniciar sesión.
  Future<int> setGoogleUid(String googleUid) async {
    return _database!.update(
      'user_gamification',
      {'google_uid': googleUid},
      where: 'local_id = ?',
      whereArgs: ['local'],
    );
  }

  /// Limpia google_uid al cerrar sesión / borrar respaldo.
  Future<int> clearGoogleUid() async {
    return _database!.update(
      'user_gamification',
      {'google_uid': null},
      where: 'local_id = ?',
      whereArgs: ['local'],
    );
  }

  // ─── chinampa_slots ───

  /// Obtiene todos los slots de la chinampa.
  Future<List<Map<String, dynamic>>> getAllChinampaSlots() async {
    return _database!.query(
      'chinampa_slots',
      orderBy: 'slot_index',
    );
  }

  /// Obtiene un slot específico.
  Future<Map<String, dynamic>?> getChinampaSlot(int slotIndex) async {
    final rows = await _database!.query(
      'chinampa_slots',
      where: 'slot_index = ?',
      whereArgs: [slotIndex],
      limit: 1,
    );
    return rows.isNotEmpty ? rows.first : null;
  }

  /// Planta una semilla en un slot.
  Future<int> plantSeed({
    required int slotIndex,
    required String seedId,
    required DateTime plantedAt,
  }) async {
    return _database!.update(
      'chinampa_slots',
      {
        'seed_id': seedId,
        'current_waterings': 0,
        'is_harvested': 0,
        'planted_at': plantedAt.toIso8601String(),
      },
      where: 'slot_index = ?',
      whereArgs: [slotIndex],
    );
  }

  /// Riega las plantas activas (suma +1 o +2 según afinidad).
  Future<int> waterPlants({
    required List<int> slotIndexes,
    required String currentEmotionId,
    required Map<String, String> seedAffinities, // seedId -> affinityEmotion
  }) async {
    int updated = 0;
    for (final slotIndex in slotIndexes) {
      final slot = await getChinampaSlot(slotIndex);
      if (slot == null) continue;

      final seedId = slot['seed_id'] as String?;
      final isHarvested = (slot['is_harvested'] as int) == 1;
      if (seedId == null || isHarvested) continue;

      final affinity = seedAffinities[seedId];
      final waterAmount = (affinity == currentEmotionId) ? 2 : 1;

      final newWaterings = (slot['current_waterings'] as int) + waterAmount;

      // Verificar si florece (necesitamos waterings_needed del catálogo)
      // Este método solo actualiza el contador; la lógica de floración
      // se maneja en el controlador superior.
      updated += await _database!.update(
        'chinampa_slots',
        {'current_waterings': newWaterings},
        where: 'slot_index = ?',
        whereArgs: [slotIndex],
      );
    }
    return updated;
  }

  /// Marca un slot como cosechado.
  Future<int> harvestSlot(int slotIndex) async {
    return _database!.update(
      'chinampa_slots',
      {'is_harvested': 1},
      where: 'slot_index = ?',
      whereArgs: [slotIndex],
    );
  }

  /// Vacía un slot (después de cosechar y retirar).
  Future<int> clearSlot(int slotIndex) async {
    return _database!.update(
      'chinampa_slots',
      {
        'seed_id': null,
        'current_waterings': 0,
        'is_harvested': 0,
        'planted_at': null,
      },
      where: 'slot_index = ?',
      whereArgs: [slotIndex],
    );
  }

  // ─── user_inventory ───

  /// Obtiene todo el inventario.
  Future<List<Map<String, dynamic>>> getInventory() async {
    return _database!.query('user_inventory');
  }

  /// Añade o actualiza un item en el inventario.
  Future<int> upsertInventoryItem({
    required String itemId,
    required String itemType, // 'SEED' o 'RELIC'
    required int quantity,
    required DateTime unlockedAt,
  }) async {
    return _database!.insert(
      'user_inventory',
      {
        'item_id': itemId,
        'item_type': itemType,
        'quantity': quantity,
        'unlocked_at': unlockedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtiene un item específico.
  Future<Map<String, dynamic>?> getInventoryItem(String itemId) async {
    final rows = await _database!.query(
      'user_inventory',
      where: 'item_id = ?',
      whereArgs: [itemId],
      limit: 1,
    );
    return rows.isNotEmpty ? rows.first : null;
  }

  /// Cierra la base de datos.
  Future<void> close() async {
    await _database?.close();
    _database = null;
    _isInitialized = false;
  }
}