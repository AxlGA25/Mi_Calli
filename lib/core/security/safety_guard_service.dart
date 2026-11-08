// SafetyGuardService - Detector local de palabras clave de crisis.
//
// - Carga patrones desde assets/data/crisis_patterns.json
// - Normaliza el texto: minúsculas, sin acentos, puntuación a espacios, espacios colapsados
// - Compila cada expresión regular una sola vez
// - Si el JSON falta o está dañado, usa una lista mínima incorporada
// - NUNCA imprime, registra ni guarda el texto analizado ni la frase coincidente
// - Solo devuelve la categoría (ideacion, autolesion, desesperanza)
//
// Cumple INSTRUCTIONS.md §1 y CONTEXT.md §2.

import 'dart:convert';

import 'package:flutter/services.dart';

/// Resultado de una verificación de seguridad.
class SafetyCheckResult {
  const SafetyCheckResult({
    required this.matched,
    this.category,
  });

  /// true si algún patrón coincidió.
  final bool matched;

  /// Categoría del patrón que coincidió (ideacion, autolesion, desesperanza).
  /// null si no hubo coincidencia.
  final String? category;

  @override
  String toString() {
    return 'SafetyCheckResult(matched: $matched, category: $category)';
  }
}

/// Patrón de crisis compilado.
class CompiledPattern {
  CompiledPattern({
    required this.id,
    required this.category,
    required this.regex,
    this.unlessPatterns,
  });

  final String id;
  final String category;
  final RegExp regex;
  final List<RegExp>? unlessPatterns;
}

/// Excepción para errores de carga de patrones de crisis.
class CrisisPatternsLoadException implements Exception {
  const CrisisPatternsLoadException(this.message);

  final String message;

  @override
  String toString() => 'CrisisPatternsLoadException: $message';
}

/// Servicio singleton para detectar palabras clave de crisis.
class SafetyGuardService {
  SafetyGuardService._({
    List<CompiledPattern>? patterns,
  }) : _patterns = patterns ?? fallbackPatterns();

  static SafetyGuardService? _instance;

  final List<CompiledPattern> _patterns;

  /// Inicializa el servicio cargando patrones desde el asset JSON.
  ///
  /// Si el asset falta o está dañado, usa la lista mínima incorporada
  /// y registra solo el ID del patrón inválido (sin texto de usuario).
  static Future<SafetyGuardService> initialize() async {
    if (_instance != null) return _instance!;

    final service = await _loadFromAsset();
    _instance = service;
    return service;
  }

  /// Crea una instancia para testing con patrones inyectados.
  static SafetyGuardService createForTesting(List<CompiledPattern> patterns) {
    return SafetyGuardService._(patterns: patterns);
  }

  /// Obtiene la instancia (debe llamarse después de initialize()).
  static SafetyGuardService get instance {
    if (_instance == null) {
      throw StateError(
        'SafetyGuardService no inicializado. Llama a initialize() primero.',
      );
    }
    return _instance!;
  }

  /// Verifica si el texto contiene palabras clave de crisis.
  ///
  /// Devuelve un [SafetyCheckResult] con matched y category.
  /// NUNCA incluye el texto analizado ni la frase coincidente en el resultado.
  SafetyCheckResult check(String text) {
    final normalized = normalize(text);

    for (final pattern in _patterns) {
      final match = pattern.regex.firstMatch(normalized);
      if (match != null) {
        // Verificar excepciones (unless)
        if (_hasUnlessMatch(normalized, pattern, match.end)) {
          continue; // Esta coincidencia se anula, probar siguiente patrón
        }
        return SafetyCheckResult(matched: true, category: pattern.category);
      }
    }

    return const SafetyCheckResult(matched: false, category: null);
  }

  /// Método de conveniencia que devuelve solo si hay coincidencia.
  ///
  /// Nombrado según INSTRUCTIONS.md §1 punto 20.
  bool containsCrisisKeywords(String text) {
    return check(text).matched;
  }

  /// Normaliza el texto para comparación:
  /// - Minúsculas
  /// - Elimina acentos y diéresis
  /// - Convierte puntuación en espacios
  /// - Colapsa espacios repetidos
  static String normalize(String text) {
    // Tabla de reemplazo de acentos y diéresis
    const accents = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
      'Á': 'a',
      'É': 'e',
      'Í': 'i',
      'Ó': 'o',
      'Ú': 'u',
      'Ü': 'u',
      'Ñ': 'n',
    };

    final buffer = StringBuffer();
    for (final char in text.toLowerCase().runes) {
      final c = String.fromCharCode(char);
      buffer.write(accents[c] ?? c);
    }

    // Convertir puntuación y símbolos en espacios, mantener letras/números/espacios
    String normalized = buffer.toString().replaceAllMapped(
      RegExp(r'[^\p{L}\p{N}\s]', unicode: true),
      (m) => ' ',
    );

    // Colapsar espacios múltiples y recortar
    return normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Verifica si hay una coincidencia de "unless" después de la posición dada.
  /// Busca hasta 3 palabras después del final de la coincidencia principal.
  bool _hasUnlessMatch(
    String normalized,
    CompiledPattern pattern,
    int matchEnd,
  ) {
    final unlessPatterns = pattern.unlessPatterns;
    if (unlessPatterns == null || unlessPatterns.isEmpty) {
      return false;
    }

    // Extraer las siguientes ~3 palabras (aprox 30 chars)
    final remaining = normalized.substring(matchEnd).trim();
    final words = remaining.split(RegExp(r'\s+'));
    final lookahead = words.take(3).join(' ');

    for (final unlessRegex in unlessPatterns) {
      if (unlessRegex.hasMatch(lookahead)) {
        return true;
      }
    }
    return false;
  }

  /// Carga patrones desde el asset JSON.
  static Future<SafetyGuardService> _loadFromAsset() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/crisis_patterns.json',
      );
      final Map<String, dynamic> jsonMap = json.decode(jsonString) as Map<String, dynamic>;

      final version = jsonMap['version'] as int?;
      if (version != 1) {
        throw CrisisPatternsLoadException('Versión no soportada: $version');
      }

      final patternsJson = jsonMap['patterns'] as List<dynamic>?;
      if (patternsJson == null || patternsJson.isEmpty) {
        throw CrisisPatternsLoadException('Lista de patrones vacía');
      }

      final compiledPatterns = <CompiledPattern>[];
      for (final p in patternsJson) {
        try {
          final id = p['id'] as String;
          final category = p['category'] as String;
          final regexStr = p['regex'] as String;
          final unlessList = (p['unless'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList();

          final regex = RegExp(regexStr);
          final unlessPatterns = unlessList?.map((s) => RegExp(s)).toList();

          compiledPatterns.add(
            CompiledPattern(
              id: id,
              category: category,
              regex: regex,
              unlessPatterns: unlessPatterns,
            ),
          );
        } on FormatException {
          // Patrón con regex inválida: omitir y registrar solo el ID
          final id = (p as Map<String, dynamic>)['id'] as String? ?? 'unknown';
          // No imprimimos el texto del usuario ni la regex fallida
          // Solo el ID para depuración
          // ignore: avoid_print
          print('[SafetyGuardService] Patrón inválido omitido: $id');
        }
      }

      if (compiledPatterns.isEmpty) {
        throw CrisisPatternsLoadException('No se pudo compilar ningún patrón');
      }

      return SafetyGuardService._(patterns: compiledPatterns);
    } on PlatformException catch (e) {
      // Asset no encontrado
      // ignore: avoid_print
      print('[SafetyGuardService] Asset no encontrado: ${e.message}. Usando patrones de respaldo.');
      return SafetyGuardService._();
    } on FormatException catch (e) {
      // JSON malformado
      // ignore: avoid_print
      print('[SafetyGuardService] JSON malformado: $e. Usando patrones de respaldo.');
      return SafetyGuardService._();
    } on CrisisPatternsLoadException catch (e) {
      // Error de validación
      // ignore: avoid_print
      print('[SafetyGuardService] $e. Usando patrones de respaldo.');
      return SafetyGuardService._();
    }
  }

  /// Patrones mínimos incorporados (fallback).
  /// Solo frases de ideación, sin métodos ni detalles de cómo hacerse daño.
  static List<CompiledPattern> fallbackPatterns() {
    return [
      CompiledPattern(
        id: 'fallback_ideacion_01',
        category: 'ideacion',
        regex: RegExp(r'\bquiero (morir|morirme|desaparecer)\b'),
        unlessPatterns: [
          RegExp(r'de (la )?(risa|hambre|sueno|calor|frio|pena|verguenza|ganas|nervios|envidia|flojera|aburrimiento)'),
          RegExp(r'(el|este|ese) (calor|frio|ruido|trafico)'),
        ],
      ),
      CompiledPattern(
        id: 'fallback_ideacion_02',
        category: 'ideacion',
        regex: RegExp(r'\bme quiero (morir|matar)\b'),
        unlessPatterns: [
          RegExp(r'de (la )?(risa|hambre|sueno|calor|frio|pena|verguenza|ganas|nervios|envidia|flojera|aburrimiento)'),
          RegExp(r'(el|este|ese) (calor|frio|ruido|trafico)'),
        ],
      ),
      CompiledPattern(
        id: 'fallback_ideacion_03',
        category: 'ideacion',
        regex: RegExp(r'\bya no quiero vivir\b'),
      ),
      CompiledPattern(
        id: 'fallback_ideacion_04',
        category: 'ideacion',
        regex: RegExp(r'\bno quiero seguir viviendo\b'),
      ),
      CompiledPattern(
        id: 'fallback_ideacion_05',
        category: 'ideacion',
        regex: RegExp(r'\bquitarme la vida\b'),
      ),
    ];
  }
}