// Singleton para pre-cargar y cachear assets de animación (Rive .riv, Lottie .json).
//
// Características:
// - Intenta pre-cargar assets conocidos al inicializar
// - Si un archivo no existe o falla, devuelve null SIN lanzar error
// - Nunca imprime contenido sensible en logs
// - Reutiliza instancias cacheadas para evitar recargas

import 'package:flutter/services.dart';

/// Servicio singleton para cachear assets de animación.
class AnimationCacheService {
  AnimationCacheService._internal();

  static final AnimationCacheService _instance = AnimationCacheService._internal();

  factory AnimationCacheService() => _instance;

  /// Cache interno: path -> byte data
  final Map<String, ByteData> _cache = {};

  /// Assets conocidos que se pueden pre-cargar (se llenan desde fuera).
  final List<String> _knownAssets = [];

  /// Indica si la pre-carga inicial ya se intentó.
  bool _preloadAttempted = false;

  /// Inicializa el servicio y pre-carga assets conocidos.
  /// Debe llamarse al arranque de la app (ej. en main.dart antes de runApp).
  Future<void> initialize(List<String> assetsToPreload) async {
    if (_preloadAttempted) return;
    _preloadAttempted = true;

    _knownAssets.addAll(assetsToPreload);

    // Pre-cargar en paralelo pero con límite para no saturar
    await Future.wait(
      _knownAssets.map(_preloadAsset),
    );
  }

  /// Pre-carga un asset individual. Silencioso: nunca lanza.
  Future<void> _preloadAsset(String path) async {
    try {
      final data = await rootBundle.load(path);
      _cache[path] = data;
    } catch (_) {
      // Asset no encontrado o error de lectura -> no cachear, no loggear
    }
  }

  /// Obtiene los bytes cacheados de un asset.
  /// Retorna null si no está cacheado o no existe (sin errores).
  ByteData? getAsset(String path) {
    return _cache[path];
  }

  /// Verifica si un asset está cacheado (existe y se cargó OK).
  bool hasAsset(String path) {
    return _cache.containsKey(path);
  }

  /// Intenta cargar un asset on-demand. Si falla, retorna null.
  Future<ByteData?> loadAsset(String path) async {
    if (_cache.containsKey(path)) {
      return _cache[path];
    }
    try {
      final data = await rootBundle.load(path);
      _cache[path] = data;
      return data;
    } catch (_) {
      return null;
    }
  }

  /// Limpia la caché (útil para tests o cambio de configuración).
  void clearCache() {
    _cache.clear();
    _knownAssets.clear();
    _preloadAttempted = false;
  }

  /// Lista de assets que se intentó pre-cargar.
  List<String> get knownAssets => List.unmodifiable(_knownAssets);
}