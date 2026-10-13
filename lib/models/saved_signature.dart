import 'dart:convert';
import 'dart:typed_data';

class SavedSignature {
  final String id;
  final String title;
  final Uint8List imageBytes;
  final DateTime createdAt;

  SavedSignature({
    required this.id,
    required this.title,
    required this.imageBytes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'imageBytesBase64': base64Encode(imageBytes),
        'createdAt': createdAt.toIso8601String(),
      };

  factory SavedSignature.fromJson(Map<String, dynamic> json) => SavedSignature(
        id: json['id'] as String,
        title: json['title'] as String,
        imageBytes: base64Decode(json['imageBytesBase64'] as String),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}
