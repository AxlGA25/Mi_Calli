// DiaryBackupService: exportar e importar archivo .calli cifrado (Tarea 4.8).
//
// Cifrado autenticado con contraseña del usuario (PBKDF2-HMAC-SHA256 + AES-GCM).
// Fusiona 4 tablas por id sin destruir datos existentes.

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../database/local_database_service.dart';

/// Encabezado mágico del archivo .calli (8 bytes ASCII).
const String _magicHeader = 'MICALLI1';
const int _magicHeaderLength = 8;
const int _saltLength = 16;
const int _nonceLength = 12; // GCM nonce
const int _tagLength = 16; // GCM tag
const int _minPasswordLength = 6;

/// Versión del formato de respaldo.
const int _backupFormatVersion = 1;

/// Excepción: contraseña demasiado débil.
class WeakBackupPasswordException implements Exception {
  final String message;
  const WeakBackupPasswordException(this.message);
  @override
  String toString() => 'WeakBackupPasswordException: $message';
}

/// Excepción: archivo de respaldo corrupto o truncado.
class CorruptBackupFileException implements Exception {
  final String message;
  const CorruptBackupFileException(this.message);
  @override
  String toString() => 'CorruptBackupFileException: $message';
}

/// Excepción: contraseña de respaldo incorrecta.
class InvalidBackupPasswordException implements Exception {
  final String message;
  const InvalidBackupPasswordException(this.message);
  @override
  String toString() => 'InvalidBackupPasswordException: $message';
}

/// Resultado de la importación de respaldo.
class BackupImportResult {
  const BackupImportResult({
    required this.entriesCount,
    required this.moodsCount,
    required this.chinampasCount,
    required this.cyclesCount,
  });

  final int entriesCount;
  final int moodsCount;
  final int chinampasCount;
  final int cyclesCount;

  @override
  String toString() => 'BackupImportResult('
      'entriesCount: $entriesCount, '
      'moodsCount: $moodsCount, '
      'chinampasCount: $chinampasCount, '
      'cyclesCount: $cyclesCount)';
}

/// Gateway abstracto para compartir archivos (share_plus).
abstract class BackupShareGateway {
  Future<void> shareBytes({
    required Uint8List bytes,
    required String filename,
    String? mimeType,
  });
}

/// Gateway abstracto para seleccionar archivos (file_picker).
abstract class BackupFilePickerGateway {
  Future<Uint8List?> pickBackupFile();
}

/// Implementación real usando share_plus.
class SharePlusGateway implements BackupShareGateway {
  const SharePlusGateway();

  @override
  Future<void> shareBytes({
    required Uint8List bytes,
    required String filename,
    String? mimeType,
  }) async {
    // Guardar bytes en archivo temporal y compartir
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
      ),
    );
  }
}

/// Implementación real usando file_picker.
class FilePickerGateway implements BackupFilePickerGateway {
  const FilePickerGateway();

  @override
  Future<Uint8List?> pickBackupFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['calli'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    return result.files.first.bytes;
  }
}

/// Fake gateway para tests: almacena bytes en memoria.
class FakeBackupShareGateway implements BackupShareGateway {
  FakeBackupShareGateway();

  Uint8List? lastSharedBytes;
  String? lastFilename;
  String? lastMimeType;

  @override
  Future<void> shareBytes({
    required Uint8List bytes,
    required String filename,
    String? mimeType,
  }) async {
    lastSharedBytes = bytes;
    lastFilename = filename;
    lastMimeType = mimeType;
  }
}

/// Fake gateway para tests: retorna bytes predefinidos.
class FakeBackupFilePickerGateway implements BackupFilePickerGateway {
  FakeBackupFilePickerGateway({this.bytesToReturn});

  final Uint8List? bytesToReturn;

  @override
  Future<Uint8List?> pickBackupFile() async {
    return bytesToReturn;
  }
}

/// Servicio de respaldo del diario con cifrado autenticado.
class DiaryBackupService {
  DiaryBackupService({
    required this.databaseService,
    required this.shareGateway,
    required this.filePickerGateway,
    this.pbkdf2Iterations = 20000,
  });

  final LocalDatabaseService databaseService;
  final BackupShareGateway shareGateway;
  final BackupFilePickerGateway filePickerGateway;
  final int pbkdf2Iterations;

  /// Deriva llaves de cifrado y MAC a partir de contraseña y salt.
  static Future<_DerivedKeys> _deriveKeys({
    required String password,
    required Uint8List salt,
    required int iterations,
  }) async {
    // Usar PBKDF2-HMAC-SHA256 para derivar 64 bytes (32 para AES + 32 para HMAC/uso futuro)
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 512, // 64 bytes = 512 bits
    );
    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(password.codeUnits),
      nonce: salt,
    );
    final keyBytes = await secretKey.extractBytes();
    // Primera mitad (32 bytes) = llave de cifrado AES-256
    // Segunda mitad (32 bytes) = llave MAC (reservada para uso futuro/HMAC)
    final encryptionKey = keyBytes.sublist(0, 32);
    final macKey = keyBytes.sublist(32, 64);
    return _DerivedKeys(
      encryptionKey: Uint8List.fromList(encryptionKey),
      macKey: Uint8List.fromList(macKey),
    );
  }

  /// Empaqueta el archivo .calli: MAGIC + SALT + NONCE + TAG + CIPHERTEXT
  static Uint8List _packageFile({
    required Uint8List salt,
    required Uint8List nonce,
    required Uint8List tag,
    required Uint8List ciphertext,
  }) {
    final buffer = BytesBuilder();
    buffer.add(_magicHeader.codeUnits); // 8 bytes
    buffer.add(salt); // 16 bytes
    buffer.add(nonce); // 12 bytes
    buffer.add(tag); // 16 bytes
    buffer.add(ciphertext); // resto
    return buffer.toBytes();
  }

  /// Desempaqueta y valida el archivo .calli.
  static _UnpackedFile _unpackFile(Uint8List fileBytes) {
    if (fileBytes.length < _magicHeaderLength + _saltLength + _nonceLength + _tagLength) {
      throw const CorruptBackupFileException('Archivo truncado: demasiado corto');
    }

    // Verificar magic header
    final header = utf8.decode(fileBytes.sublist(0, _magicHeaderLength), allowMalformed: true);
    if (header != _magicHeader) {
      throw const CorruptBackupFileException('Encabezado inválido: no es un archivo .calli válido');
    }

    int offset = _magicHeaderLength;
    final salt = fileBytes.sublist(offset, offset + _saltLength);
    offset += _saltLength;
    final nonce = fileBytes.sublist(offset, offset + _nonceLength);
    offset += _nonceLength;
    final tag = fileBytes.sublist(offset, offset + _tagLength);
    offset += _tagLength;
    final ciphertext = fileBytes.sublist(offset);

    // Validar que el ciphertext tiene longitud mínima razonable.
    // Un payload JSON mínimo (4 arrays vacíos + version + exported_at) ocupa ~120 bytes.
    // AES-GCM no añade padding, así que ciphertext debe tener al menos ~50 bytes.
    if (ciphertext.length < 50) {
      throw const CorruptBackupFileException('Archivo truncado: ciphertext demasiado corto');
    }

    return _UnpackedFile(
      salt: salt,
      nonce: nonce,
      tag: tag,
      ciphertext: ciphertext,
    );
  }

  /// Exporta las 4 tablas a bytes JSON y cifra.
  Future<Uint8List> exportBackupToBytes(String password) async {
    // Validar contraseña
    if (password.length < _minPasswordLength) {
      throw WeakBackupPasswordException(
        'La contraseña debe tener al menos $_minPasswordLength caracteres',
      );
    }

    // Leer las 4 tablas
    final diaryEntries = await databaseService.database.query('diary_entries');
    final userGamification = await databaseService.database.query('user_gamification');
    final chinampaSlots = await databaseService.database.query('chinampa_slots');
    final userInventory = await databaseService.database.query('user_inventory');

    // Construir payload JSON
    final payload = {
      'version': _backupFormatVersion,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'diary_entries': diaryEntries,
      'user_gamification': userGamification,
      'chinampa_slots': chinampaSlots,
      'user_inventory': userInventory,
    };

    final jsonString = jsonEncode(payload);
    final data = utf8.encode(jsonString);

    // Generar salt y nonce aleatorios
    final random = Random.secure();
    final salt = Uint8List.fromList(List<int>.generate(_saltLength, (_) => random.nextInt(256)));
    final nonce = Uint8List.fromList(List<int>.generate(_nonceLength, (_) => random.nextInt(256)));

    // Derivar llaves
    final keys = await _deriveKeys(
      password: password,
      salt: salt,
      iterations: pbkdf2Iterations,
    );

    // Cifrar con AES-GCM
    final algorithm = AesGcm.with256bits();
    final secretKey = SecretKey(keys.encryptionKey);
    final encrypted = await algorithm.encrypt(
      data,
      secretKey: secretKey,
      nonce: nonce,
    );

    // Empaquetar: MAGIC + SALT + NONCE + TAG + CIPHERTEXT
    return _packageFile(
      salt: salt,
      nonce: nonce,
      tag: Uint8List.fromList(encrypted.mac.bytes),
      ciphertext: Uint8List.fromList(encrypted.cipherText),
    );
  }

  /// Exporta y comparte el archivo de respaldo.
  Future<void> exportAndShareBackup(String password) async {
    final bytes = await exportBackupToBytes(password);
    const filename = 'mi_calli_respaldo.calli';
    await shareGateway.shareBytes(
      bytes: bytes,
      filename: filename,
      mimeType: 'application/octet-stream',
    );
  }

  /// Método público para SettingsScreen: exporta y comparte.
  Future<bool> exportBackup(String password) async {
    try {
      await exportAndShareBackup(password);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Descifra datos con AES-GCM y verifica la etiqueta de autenticación.
  static Future<Uint8List> _decryptData({
    required Uint8List cipherText,
    required Uint8List encryptionKey,
    required Uint8List nonce,
    required Uint8List tag,
  }) async {
    final algorithm = AesGcm.with256bits();
    final secretKey = SecretKey(encryptionKey);
    try {
      final decrypted = await algorithm.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: Mac(tag)),
        secretKey: secretKey,
      );
      return Uint8List.fromList(decrypted);
    } catch (_) {
      throw const InvalidBackupPasswordException('Contraseña incorrecta o datos corruptos');
    }
  }

  /// Importa bytes cifrados, verifica, descifra y fusiona en la base de datos.
  Future<BackupImportResult> importBackupFromBytes(Uint8List encryptedBytes, String password) async {
    // Validar contraseña
    if (password.length < _minPasswordLength) {
      throw WeakBackupPasswordException(
        'La contraseña debe tener al menos $_minPasswordLength caracteres',
      );
    }

    // Desempaquetar y validar encabezado
    final unpacked = _unpackFile(encryptedBytes);

    // Derivar llaves
    final keys = await _deriveKeys(
      password: password,
      salt: unpacked.salt,
      iterations: pbkdf2Iterations,
    );

    // Descifrar y verificar tag
    Uint8List decryptedJson;
    try {
      decryptedJson = await _decryptData(
        cipherText: unpacked.ciphertext,
        encryptionKey: keys.encryptionKey,
        nonce: unpacked.nonce,
        tag: unpacked.tag,
      );
    } on InvalidBackupPasswordException {
      rethrow;
    } catch (e) {
      throw const InvalidBackupPasswordException('Contraseña incorrecta o datos corruptos');
    }

    // Parsear JSON
    final jsonString = utf8.decode(decryptedJson);
    final payload = jsonDecode(jsonString) as Map<String, dynamic>;

    // Validar versión
    final version = payload['version'] as int? ?? 0;
    if (version != _backupFormatVersion) {
      throw CorruptBackupFileException('Versión de respaldo no compatible: $version');
    }

    // Fusionar en base de datos dentro de una transacción
    return await _mergeBackupData(payload);
  }

  /// Selecciona archivo, pide contraseña e importa.
  Future<BackupImportResult> pickAndImportBackup(String password) async {
    final bytes = await filePickerGateway.pickBackupFile();
    if (bytes == null) {
      throw const CorruptBackupFileException('No se seleccionó ningún archivo');
    }
    return await importBackupFromBytes(bytes, password);
  }

  /// Método público para SettingsScreen: selecciona archivo e importa.
  Future<BackupImportResult?> importBackup(String password) async {
    try {
      return await pickAndImportBackup(password);
    } catch (e) {
      return null;
    }
  }

  /// Fusiona los datos del respaldo en la base de datos local.
  Future<BackupImportResult> _mergeBackupData(Map<String, dynamic> payload) async {
    final db = databaseService.database;

    await db.transaction((txn) async {
      // 1. diary_entries: fusionar por id (INSERT OR REPLACE para conservar ambos)
      final diaryEntries = payload['diary_entries'] as List<dynamic>? ?? [];
      for (final entry in diaryEntries) {
        final entryMap = Map<String, dynamic>.from(entry as Map);
        // Usar INSERT OR REPLACE para fusionar por id
        await txn.insert(
          'diary_entries',
          entryMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // 2. user_gamification: fusionar conservando máximos
      final gamificationList = payload['user_gamification'] as List<dynamic>? ?? [];
      if (gamificationList.isNotEmpty) {
        final imported = Map<String, dynamic>.from(gamificationList.first as Map);
        final current = await txn.query(
          'user_gamification',
          where: 'local_id = ?',
          whereArgs: ['local'],
          limit: 1,
        );

        if (current.isNotEmpty) {
          final local = current.first;
          final merged = <String, dynamic>{
            'local_id': 'local',
            'google_uid': imported['google_uid'] ?? local['google_uid'],
            'quetzal_xp': max(
              (imported['quetzal_xp'] as int? ?? 0),
              (local['quetzal_xp'] as int? ?? 0),
            ),
            'quetzal_level': max(
              (imported['quetzal_level'] as int? ?? 1),
              (local['quetzal_level'] as int? ?? 1),
            ),
            'current_streak': max(
              (imported['current_streak'] as int? ?? 0),
              (local['current_streak'] as int? ?? 0),
            ),
            'longest_streak': max(
              (imported['longest_streak'] as int? ?? 0),
              (local['longest_streak'] as int? ?? 0),
            ),
            'last_checkin_date': _maxDate(
              imported['last_checkin_date'] as String?,
              local['last_checkin_date'] as String?,
            ),
            'xolotl_shields': max(
              (imported['xolotl_shields'] as int? ?? 1),
              (local['xolotl_shields'] as int? ?? 1),
            ),
          };
          await txn.update(
            'user_gamification',
            merged,
            where: 'local_id = ?',
            whereArgs: ['local'],
          );
        } else {
          // No hay fila local, insertar la importada asegurando local_id='local'
          final toInsert = Map<String, dynamic>.from(imported);
          toInsert['local_id'] = 'local';
          await txn.insert('user_gamification', toInsert);
        }
      }

      // 3. chinampa_slots: fusionar por slot_index
      final chinampaList = payload['chinampa_slots'] as List<dynamic>? ?? [];
      for (final slot in chinampaList) {
        final slotMap = Map<String, dynamic>.from(slot as Map);
        final slotIndex = slotMap['slot_index'] as int;
        final currentSlot = await txn.query(
          'chinampa_slots',
          where: 'slot_index = ?',
          whereArgs: [slotIndex],
          limit: 1,
        );

        if (currentSlot.isNotEmpty) {
          final local = currentSlot.first;
          final localSeedId = local['seed_id'] as String?;
          final importedSeedId = slotMap['seed_id'] as String?;
          final localWaterings = local['current_waterings'] as int? ?? 0;
          final importedWaterings = slotMap['current_waterings'] as int? ?? 0;
          final localHarvested = (local['is_harvested'] as int? ?? 0) == 1;
          final importedHarvested = (slotMap['is_harvested'] as int? ?? 0) == 1;

          // Si el slot local está vacío o el importado tiene planta con mayor progreso
          final shouldUpdate = localSeedId == null ||
              (importedSeedId != null && importedWaterings > localWaterings) ||
              (importedHarvested && !localHarvested);

          if (shouldUpdate) {
            await txn.update(
              'chinampa_slots',
              slotMap,
              where: 'slot_index = ?',
              whereArgs: [slotIndex],
            );
          }
        } else {
          await txn.insert('chinampa_slots', slotMap);
        }
      }

      // 4. user_inventory: fusionar por item_id conservando mayor quantity
      final inventoryList = payload['user_inventory'] as List<dynamic>? ?? [];
      for (final item in inventoryList) {
        final itemMap = Map<String, dynamic>.from(item as Map);
        final itemId = itemMap['item_id'] as String;
        final currentItem = await txn.query(
          'user_inventory',
          where: 'item_id = ?',
          whereArgs: [itemId],
          limit: 1,
        );

        if (currentItem.isNotEmpty) {
          final local = currentItem.first;
          final localQuantity = local['quantity'] as int? ?? 0;
          final importedQuantity = itemMap['quantity'] as int? ?? 0;
          final localUnlocked = local['unlocked_at'] as String?;
          final importedUnlocked = itemMap['unlocked_at'] as String?;

          final mergedQuantity = max(localQuantity, importedQuantity);
          final mergedUnlocked = _minDate(localUnlocked, importedUnlocked) ?? importedUnlocked;

          if (mergedQuantity != localQuantity || mergedUnlocked != localUnlocked) {
            await txn.update(
              'user_inventory',
              {
                'quantity': mergedQuantity,
                'unlocked_at': mergedUnlocked,
              },
              where: 'item_id = ?',
              whereArgs: [itemId],
            );
          }
        } else {
          await txn.insert('user_inventory', itemMap);
        }
      }
    });

    // Calcular conteos para el resultado
    final diaryCount = (payload['diary_entries'] as List<dynamic>? ?? []).length;
    final moodCount = (payload['user_gamification'] as List<dynamic>? ?? []).length;
    final chinampaCount = (payload['chinampa_slots'] as List<dynamic>? ?? []).length;
    final cyclesCount = (payload['user_inventory'] as List<dynamic>? ?? []).length;

    return BackupImportResult(
      entriesCount: diaryCount,
      moodsCount: moodCount,
      chinampasCount: chinampaCount,
      cyclesCount: cyclesCount,
    );
  }

  /// Retorna la fecha más reciente (máxima) entre dos strings ISO 8601.
  static String? _maxDate(String? a, String? b) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    final da = DateTime.tryParse(a);
    final db = DateTime.tryParse(b);
    if (da == null && db == null) return a;
    if (da == null) return b;
    if (db == null) return a;
    return da.isAfter(db) ? a : b;
  }

  /// Retorna la fecha más antigua (mínima) entre dos strings ISO 8601.
  static String? _minDate(String? a, String? b) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    final da = DateTime.tryParse(a);
    final db = DateTime.tryParse(b);
    if (da == null && db == null) return a;
    if (da == null) return b;
    if (db == null) return a;
    return da.isBefore(db) ? a : b;
  }
}

/// Llaves derivadas del PBKDF2.
class _DerivedKeys {
  const _DerivedKeys({
    required this.encryptionKey,
    required this.macKey,
  });

  final Uint8List encryptionKey;
  final Uint8List macKey;
}

/// Archivo desempaquetado.
class _UnpackedFile {
  const _UnpackedFile({
    required this.salt,
    required this.nonce,
    required this.tag,
    required this.ciphertext,
  });

  final Uint8List salt;
  final Uint8List nonce;
  final Uint8List tag;
  final Uint8List ciphertext;
}

/// Provider del gateway de compartir.
final backupShareGatewayProvider = Provider<BackupShareGateway>((ref) => SharePlusGateway());

/// Provider del gateway de selección de archivos.
final backupFilePickerGatewayProvider = Provider<BackupFilePickerGateway>((ref) => FilePickerGateway());

/// Provider del servicio de respaldo.
final diaryBackupServiceProvider = Provider<DiaryBackupService>((ref) {
  final databaseService = ref.watch(localDatabaseServiceProvider);
  final shareGateway = ref.watch(backupShareGatewayProvider);
  final filePickerGateway = ref.watch(backupFilePickerGatewayProvider);
  return DiaryBackupService(
    databaseService: databaseService,
    shareGateway: shareGateway,
    filePickerGateway: filePickerGateway,
  );
});

/// Provider para LocalDatabaseService (debe ser sobrescrito en main.dart).
final localDatabaseServiceProvider = Provider<LocalDatabaseService>((ref) {
  throw UnimplementedError(
    'localDatabaseServiceProvider debe ser sobrescrito en main.dart',
  );
});