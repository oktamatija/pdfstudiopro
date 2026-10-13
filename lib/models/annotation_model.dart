import 'dart:typed_data';
import 'package:flutter/material.dart';

enum AnnotationType {
  signature,
  text,
  drawing,
  highlight,
  shape,
  stamp,
}

enum ShapeType {
  rectangle,
  circle,
  checkmark,
  cross,
  redaction,
}

enum StampType {
  approved,
  confidential,
  draft,
  paid,
  rejected,
  finalVersion,
}

class DrawingPoint {
  final double x; // Normalized 0.0 to 1.0
  final double y; // Normalized 0.0 to 1.0

  DrawingPoint({required this.x, required this.y});

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
  factory DrawingPoint.fromJson(Map<String, dynamic> json) =>
      DrawingPoint(x: (json['x'] as num).toDouble(), y: (json['y'] as num).toDouble());
}

class AnnotationModel {
  final String id;
  final AnnotationType type;
  final int pageIndex;
  double x; // Normalized 0.0 to 1.0
  double y; // Normalized 0.0 to 1.0
  double width; // Normalized 0.0 to 1.0
  double height; // Normalized 0.0 to 1.0

  // Signature / Image Stamp
  Uint8List? imageBytes;

  // Text
  String? text;
  double fontSize;
  bool isBold;
  bool isItalic;

  // Styling
  int colorValue;
  double strokeWidth;
  double opacity;

  // Shape / Stamp
  ShapeType? shapeType;
  StampType? stampType;

  // Freehand drawing points
  List<DrawingPoint>? points;

  AnnotationModel({
    required this.id,
    required this.type,
    required this.pageIndex,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.imageBytes,
    this.text,
    this.fontSize = 16.0,
    this.isBold = false,
    this.isItalic = false,
    this.colorValue = 0xFF000000,
    this.strokeWidth = 2.0,
    this.opacity = 1.0,
    this.shapeType,
    this.stampType,
    this.points,
  });

  Color get color => Color(colorValue);

  AnnotationModel copyWith({
    String? id,
    AnnotationType? type,
    int? pageIndex,
    double? x,
    double? y,
    double? width,
    double? height,
    Uint8List? imageBytes,
    String? text,
    double? fontSize,
    bool? isBold,
    bool? isItalic,
    int? colorValue,
    double strokeWidth = 2.0,
    double? opacity,
    ShapeType? shapeType,
    StampType? stampType,
    List<DrawingPoint>? points,
  }) {
    return AnnotationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      pageIndex: pageIndex ?? this.pageIndex,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      imageBytes: imageBytes ?? this.imageBytes,
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      colorValue: colorValue ?? this.colorValue,
      strokeWidth: strokeWidth,
      opacity: opacity ?? this.opacity,
      shapeType: shapeType ?? this.shapeType,
      stampType: stampType ?? this.stampType,
      points: points ?? (this.points != null ? List.from(this.points!) : null),
    );
  }
}
