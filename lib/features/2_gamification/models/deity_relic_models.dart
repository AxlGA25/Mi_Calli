// Modelos para visitas de deidades y reliquias (Tarea 3.3 Parte A).
//
// Estos modelos representan las 3 reliquias desbloqueables de Tláloc, Xochiquétzal y Xólotl,
// así como el resultado de la evaluación de condiciones de desbloqueo.

/// Identificadores de las tres deidades que pueden visitar la chinampa.
enum DeityId {
  tlaloc,
  xochiquetzal,
  xolotl,
}

/// Catálogo inmutable de las 3 reliquias desbloqueables.
///
/// Cada entrada contiene: relicId único, deidad asociada, nombre para mostrar y descripción narrativa.
enum DeityRelicCatalog {
  /// Vasija Ceremonial de Jade - Tláloc
  /// Se desbloquea con 3+ entradas de diario con emotion_id == 'tlaloc_lluvia'.
  vasijaTlaloc(
    relicId: 'relic_vasija_tlaloc',
    deity: DeityId.tlaloc,
    deityName: 'Tláloc',
    name: 'Vasija Ceremonial de Jade',
    description:
        'Su máscara aparece formada en las nubes sobre la Pirámide de la Luna y deja una Vasija Ceremonial de Jade junto a la chinampa.',
  ),

  /// Mariposas Monarca Sagradas - Xochiquétzal
  /// Se desbloquea al cosechar 3+ plantas en la Chinampa (contador histórico).
  mariposasXochiquetzal(
    relicId: 'relic_mariposas_xochiquetzal',
    deity: DeityId.xochiquetzal,
    deityName: 'Xochiquétzal',
    name: 'Mariposas Monarca Sagradas',
    description:
        'Rodea el jardín con Mariposas Monarca animadas que se quedan revoloteando permanentemente en los días soleados.',
  ),

  /// Compañero Xoloitzcuintle Místico - Xólotl
  /// Se desbloquea escribiendo en el diario después de las 21:00 hrs local
  /// O acumulando 2+ entradas con emotion_id == 'metztli_noche'.
  xolotlCompanion(
    relicId: 'relic_xolotl_companion',
    deity: DeityId.xolotl,
    deityName: 'Xólotl',
    name: 'Compañero Xoloitzcuintle Místico',
    description:
        'Un perro xoloitzcuintle místico con grabados luminosos aparece acostado al lado de Quetzalcóatl durante las noches para hacerle compañía.',
  );

  const DeityRelicCatalog({
    required this.relicId,
    required this.deity,
    required this.deityName,
    required this.name,
    required this.description,
  });

  /// ID único de la reliquia (clave primaria en user_inventory).
  final String relicId;

  /// Deidad asociada a esta reliquia.
  final DeityId deity;

  /// Nombre de la deidad para mostrar en UI.
  final String deityName;

  /// Nombre de la reliquia para mostrar en UI.
  final String name;

  /// Descripción narrativa de la visita y la reliquia.
  final String description;

  /// Busca una reliquia por su relicId.
  ///
  /// Retorna null si no existe ninguna reliquia con ese ID.
  static DeityRelicCatalog? fromRelicId(String id) {
    for (final relic in DeityRelicCatalog.values) {
      if (relic.relicId == id) return relic;
    }
    return null;
  }
}

/// Representa una reliquia desbloqueada en el inventario del usuario.
///
/// Inmutable. Se crea al leer de user_inventory (item_type == 'RELIC').
class UnlockedRelic {
  const UnlockedRelic({
    required this.catalog,
    required this.unlockedAt,
    required this.quantity,
  });

  /// Entrada del catálogo que define esta reliquia.
  final DeityRelicCatalog catalog;

  /// Momento UTC en que se desbloqueó por primera vez (nunca cambia).
  final DateTime unlockedAt;

  /// Cantidad (siempre 1 para reliquias únicas).
  final int quantity;

  /// ID único de la reliquia (delegado al catálogo).
  String get relicId => catalog.relicId;

  /// Deidad asociada (delegado al catálogo).
  DeityId get deity => catalog.deity;

  /// Nombre de la deidad (delegado al catálogo).
  String get deityName => catalog.deityName;

  /// Nombre de la reliquia (delegado al catálogo).
  String get name => catalog.name;

  /// Descripción narrativa (delegado al catálogo).
  String get description => catalog.description;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnlockedRelic &&
          runtimeType == other.runtimeType &&
          catalog == other.catalog &&
          unlockedAt == other.unlockedAt &&
          quantity == other.quantity;

  @override
  int get hashCode => Object.hash(catalog, unlockedAt, quantity);

  @override
  String toString() =>
      'UnlockedRelic(catalog: $catalog, unlockedAt: $unlockedAt, quantity: $quantity)';
}

/// Resultado de la evaluación de condiciones de desbloqueo de reliquias.
///
/// Contiene la lista completa de reliquias desbloqueadas hasta ahora y
/// la lista de las que se acaban de desbloquear en esta evaluación (para mostrar la visita una sola vez).
class DeityVisitEvaluationResult {
  const DeityVisitEvaluationResult({
    required this.allUnlockedRelics,
    required this.newlyUnlockedRelics,
  });

  /// Todas las reliquias desbloqueadas hasta ahora (leídas de user_inventory).
  final List<UnlockedRelic> allUnlockedRelics;

  /// Únicamente las reliquias que se desbloquearon por primera vez en esta evaluación.
  final List<UnlockedRelic> newlyUnlockedRelics;

  /// True si hay al menos una visita nueva para mostrar al usuario.
  bool get hasNewVisits => newlyUnlockedRelics.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeityVisitEvaluationResult &&
          runtimeType == other.runtimeType &&
          _listEquals(allUnlockedRelics, other.allUnlockedRelics) &&
          _listEquals(newlyUnlockedRelics, other.newlyUnlockedRelics);

  @override
  int get hashCode => Object.hashAll([
    ...allUnlockedRelics.map((r) => r.hashCode),
    ...newlyUnlockedRelics.map((r) => r.hashCode),
  ]);

  @override
  String toString() =>
      'DeityVisitEvaluationResult(allUnlockedRelics: $allUnlockedRelics, newlyUnlockedRelics: $newlyUnlockedRelics)';

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}