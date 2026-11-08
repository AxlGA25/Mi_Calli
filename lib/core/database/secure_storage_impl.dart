// Implementación real de SecureStorageInterface usando flutter_secure_storage.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'secure_storage_interface.dart';

// Implementación que usa flutter_secure_storage.
class SecureStorageImpl implements SecureStorageInterface {
  final FlutterSecureStorage _storage;

  SecureStorageImpl({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String?> read({required String key}) async {
    return _storage.read(key: key);
  }

  @override
  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  @override
  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }

  @override
  Future<bool> containsKey({required String key}) async {
    return _storage.containsKey(key: key);
  }
}