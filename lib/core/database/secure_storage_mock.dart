import 'secure_storage_interface.dart';

/// Implementación mockeada de SecureStorageInterface para tests.
///
/// Usa un mapa en memoria para simular el almacenamiento seguro.
class SecureStorageMock implements SecureStorageInterface {
  final Map<String, String> _storage = {};

  /// Pre-carga valores para tests.
  void setInitialValues(Map<String, String> values) {
    _storage.addAll(values);
  }

  /// Limpia el almacenamiento (útil entre tests).
  void clear() {
    _storage.clear();
  }

  /// Obtiene el mapa interno para inspección en tests.
  Map<String, String> get storageMap => Map.unmodifiable(_storage);

  @override
  Future<String?> read({required String key}) async {
    return _storage[key];
  }

  @override
  Future<void> write({required String key, required String value}) async {
    _storage[key] = value;
  }

  @override
  Future<void> delete({required String key}) async {
    _storage.remove(key);
  }

  @override
  Future<bool> containsKey({required String key}) async {
    return _storage.containsKey(key);
  }
}