import 'package:uuid/uuid.dart';

import 'prehispanic_emotion.dart';

/// Modelo que representa una entrada del diario emocional.
///
/// Corresponde a la tabla `diary_entries` en la base de datos local cifrada
/// (`CONTEXT.md` sección 5A). El campo `content` es **secreto local**: nunca
/// sale del dispositivo, nunca se envía a la nube, nunca se imprime en logs.
class DiaryEntry {
  /// Identificador único (UUID v4).
  final String id;

  /// Fecha y hora de creación (UTC en ISO 8601).
  final DateTime createdAt;

  /// Emoción seleccionada (uno de los 5 climas prehispánicos).
  final PrehispanicEmotion emotion;

  /// Texto libre escrito por el usuario (CONFIDENCIAL, solo local).
  final String content;

  /// ID de la Pluma de Sabiduría entregada tras esta entrada.
  final String featherId;

  /// ID de la semilla que recibió riego extra por afinidad (opcional).
  final String? wateredSeedId;

  /// Indica si el filtro SOS detectó palabras de riesgo en esta entrada.
  final bool triggeredSos;

  const DiaryEntry({
    required this.id,
    required this.createdAt,
    required this.emotion,
    required this.content,
    required this.featherId,
    this.wateredSeedId,
    this.triggeredSos = false,
  });

  /// Crea una nueva entrada con ID generado automáticamente y fecha actual.
  factory DiaryEntry.create({
    required PrehispanicEmotion emotion,
    required String content,
    required String featherId,
    String? wateredSeedId,
    bool triggeredSos = false,
  }) {
    return DiaryEntry(
      id: const Uuid().v4(),
      createdAt: DateTime.now().toUtc(),
      emotion: emotion,
      content: content,
      featherId: featherId,
      wateredSeedId: wateredSeedId,
      triggeredSos: triggeredSos,
    );
  }

  /// Convierte la entrada a un mapa para insertar en SQLite.
  ///
  /// **IMPORTANTE**: El campo `content` nunca debe serializarse para envío
  /// a la nube ni para logs. Este método es solo para persistencia local.
  Map<String, dynamic> toDatabaseMap() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'emotion_id': emotion.id,
      'content': content,
      'feather_id': featherId,
      'watered_seed_id': wateredSeedId,
      'triggered_sos': triggeredSos ? 1 : 0,
    };
  }

  /// Crea una `DiaryEntry` desde una fila de la base de datos.
  factory DiaryEntry.fromDatabaseMap(Map<String, dynamic> map) {
    return DiaryEntry(
      id: map['id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      emotion: PrehispanicEmotion.fromId(map['emotion_id'] as String),
      content: map['content'] as String,
      featherId: map['feather_id'] as String,
      wateredSeedId: map['watered_seed_id'] as String?,
      triggeredSos: (map['triggered_sos'] as int) == 1,
    );
  }

  /// Convierte a JSON para exportación manual (archivo `.calli` cifrado).
  ///
  /// Solo se usa en `DiaryBackupService` cuando el usuario exporta su diario
  /// con su propia contraseña. Nunca se usa para respaldo automático en la nube.
  Map<String, dynamic> toExportJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'emotion_id': emotion.id,
      'content': content,
      'feather_id': featherId,
      'watered_seed_id': wateredSeedId,
      'triggered_sos': triggeredSos,
    };
  }

  /// Crea una `DiaryEntry` desde JSON de importación (archivo `.calli`).
  factory DiaryEntry.fromExportJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      emotion: PrehispanicEmotion.fromId(json['emotion_id'] as String),
      content: json['content'] as String,
      featherId: json['feather_id'] as String,
      wateredSeedId: json['watered_seed_id'] as String?,
      triggeredSos: json['triggered_sos'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiaryEntry && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'DiaryEntry(id: $id, emotion: ${emotion.id}, createdAt: $createdAt, '
      'triggeredSos: $triggeredSos)';
}