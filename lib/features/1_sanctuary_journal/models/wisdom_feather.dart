import 'package:flutter/material.dart';

/// Modelo para las Plumas de Sabiduría (Wisdom Feather)
///
/// Se carga desde `assets/data/feathers.json` y se entrega al usuario
/// tras completar una entrada en el diario, según la emoción seleccionada.
class WisdomFeather {
  final String featherId;
  final String emotionId;
  final String name;
  final String colorHex;
  final String message;

  const WisdomFeather({
    required this.featherId,
    required this.emotionId,
    required this.name,
    required this.colorHex,
    required this.message,
  });

  /// Convierte el color hex a un objeto Color de Flutter.
  Color get color => Color(int.parse(colorHex.replaceFirst('#', '0xFF')));

  factory WisdomFeather.fromJson(Map<String, dynamic> json) {
    return WisdomFeather(
      featherId: json['feather_id'] as String,
      emotionId: json['emotion_id'] as String,
      name: json['name'] as String,
      colorHex: json['color_hex'] as String,
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'feather_id': featherId,
      'emotion_id': emotionId,
      'name': name,
      'color_hex': colorHex,
      'message': message,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WisdomFeather &&
          runtimeType == other.runtimeType &&
          featherId == other.featherId;

  @override
  int get hashCode => featherId.hashCode;

  @override
  String toString() =>
      'WisdomFeather(featherId: $featherId, name: $name, emotionId: $emotionId)';
}