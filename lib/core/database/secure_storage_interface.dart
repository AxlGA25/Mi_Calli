/// Interfaz para almacenamiento seguro (flutter_secure_storage).
///
/// Permite inyectar implementaciones mockeadas para tests.
abstract class SecureStorageInterface {
  /// Lee un valor por clave.
  Future<String?> read({required String key});

  /// Escribe un valor por clave.
  Future<void> write({required String key, required String value});

  /// Elimina un valor por clave.
  Future<void> delete({required String key});

  /// Verifica si existe una clave.
  Future<bool> containsKey({required String key});
}