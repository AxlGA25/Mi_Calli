/// Modelo para el catálogo de semillas de la Chinampa Sagrada
///
/// Se carga desde `assets/data/seeds_catalog.json`.
/// Cada semilla tiene `waterings_needed` (CONTEXT.md punto 4) y
/// `affinity_emotion` para el riego doble (+2) cuando coincide la emoción.
enum SeedRarity { comun, rara, sagrada }

class SeedCatalogItem {
  final String seedId;
  final String name;
  final SeedRarity rarity;
  final int wateringsNeeded;
  final String affinityEmotion;
  final String description;
  final List<String> spriteStages;

  const SeedCatalogItem({
    required this.seedId,
    required this.name,
    required this.rarity,
    required this.wateringsNeeded,
    required this.affinityEmotion,
    required this.description,
    required this.spriteStages,
  });

  factory SeedCatalogItem.fromJson(Map<String, dynamic> json) {
    return SeedCatalogItem(
      seedId: json['seed_id'] as String,
      name: json['name'] as String,
      rarity: SeedRarity.values.firstWhere(
        (e) => e.name == (json['rarity'] as String).toLowerCase(),
        orElse: () => SeedRarity.comun,
      ),
      wateringsNeeded: json['waterings_needed'] as int,
      affinityEmotion: json['affinity_emotion'] as String,
      description: json['description'] as String,
      spriteStages: (json['sprite_stages'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seed_id': seedId,
      'name': name,
      'rarity': rarity.name,
      'waterings_needed': wateringsNeeded,
      'affinity_emotion': affinityEmotion,
      'description': description,
      'sprite_stages': spriteStages,
    };
  }

  /// Verifica si la emoción dada coincide con la afinidad de la semilla
  /// (para aplicar riego doble +2 según CONTEXT.md punto 4).
  bool hasAffinityWith(String emotionId) => affinityEmotion == emotionId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeedCatalogItem &&
          runtimeType == other.runtimeType &&
          seedId == other.seedId;

  @override
  int get hashCode => seedId.hashCode;

  @override
  String toString() =>
      'SeedCatalogItem(seedId: $seedId, name: $name, rarity: $rarity, '
      'wateringsNeeded: $wateringsNeeded, affinityEmotion: $affinityEmotion)';
}