import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/annotation_model.dart';
import '../providers/pdf_provider.dart';

class AnnotationLayer extends StatefulWidget {
  final double pageWidth;
  final double pageHeight;

  const AnnotationLayer({
    super.key,
    required this.pageWidth,
    required this.pageHeight,
  });

  @override
  State<AnnotationLayer> createState() => _AnnotationLayerState();
}

class _AnnotationLayerState extends State<AnnotationLayer> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PdfProvider>();
    final annotations = provider.currentAnnotations;
    final selected = provider.selectedAnnotation;
    final mode = provider.editorMode;

    return SizedBox(
      width: widget.pageWidth,
      height: widget.pageHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Finished Drawings & Highlighters
          CustomPaint(
            size: Size(widget.pageWidth, widget.pageHeight),
            painter: _DrawingsPainter(
              annotations: annotations.where((a) =>
                  a.type == AnnotationType.drawing ||
                  a.type == AnnotationType.highlight).toList(),
              pageWidth: widget.pageWidth,
              pageHeight: widget.pageHeight,
            ),
          ),

          // 2. In-progress drawing stroke
          if (provider.currentDrawingPoints.isNotEmpty)
            CustomPaint(
              size: Size(widget.pageWidth, widget.pageHeight),
              painter: _CurrentStrokePainter(
                points: provider.currentDrawingPoints,
                color: provider.penColor,
                strokeWidth: provider.editorMode == EditorMode.highlight
                    ? provider.strokeWidth * 3.5
                    : provider.strokeWidth,
                isHighlight: provider.editorMode == EditorMode.highlight,
                pageWidth: widget.pageWidth,
                pageHeight: widget.pageHeight,
              ),
            ),

          // 3. Interactive Objects (Signatures, Text, Shapes, Stamps)
          ...annotations
              .where((a) =>
                  a.type != AnnotationType.drawing &&
                  a.type != AnnotationType.highlight)
              .map((ann) => _buildInteractiveAnnotation(context, provider, ann, selected?.id == ann.id)),

          // 4. Touch capture layer for drawing mode
          if (mode == EditorMode.draw || mode == EditorMode.highlight)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (details) {
                  final x = (details.localPosition.dx / widget.pageWidth).clamp(0.0, 1.0);
                  final y = (details.localPosition.dy / widget.pageHeight).clamp(0.0, 1.0);
                  provider.startDrawing(DrawingPoint(x: x, y: y));
                },
                onPanUpdate: (details) {
                  final x = (details.localPosition.dx / widget.pageWidth).clamp(0.0, 1.0);
                  final y = (details.localPosition.dy / widget.pageHeight).clamp(0.0, 1.0);
                  provider.updateDrawing(DrawingPoint(x: x, y: y));
                },
                onPanEnd: (_) {
                  provider.finishDrawing();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInteractiveAnnotation(
    BuildContext context,
    PdfProvider provider,
    AnnotationModel ann,
    bool isSelected,
  ) {
    final double left = ann.x * widget.pageWidth;
    final double top = ann.y * widget.pageHeight;
    final double width = math.max(30.0, ann.width * widget.pageWidth);
    final double height = math.max(24.0, ann.height * widget.pageHeight);

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        onTap: () {
          provider.selectAnnotation(ann);
        },
        onDoubleTap: () {
          if (ann.type == AnnotationType.text) {
            _showEditTextDialog(context, provider, ann);
          }
        },
        onPanUpdate: (details) {
          final newX = ((left + details.delta.dx) / widget.pageWidth).clamp(0.0, 1.0 - ann.width);
          final newY = ((top + details.delta.dy) / widget.pageHeight).clamp(0.0, 1.0 - ann.height);
          ann.x = newX;
          ann.y = newY;
          provider.updateAnnotation(ann);
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Content
            Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                border: isSelected
                    ? Border.all(color: Colors.blueAccent, width: 2)
                    : null,
                color: isSelected ? Colors.blueAccent.withOpacity(0.05) : null,
              ),
              child: _buildAnnotationContent(ann),
            ),

            // Delete Button (when selected)
            if (isSelected)
              Positioned(
                right: -12,
                top: -12,
                child: GestureDetector(
                  onTap: () => provider.removeAnnotation(ann.id),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                    ),
                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),

            // Resize Handle (when selected)
            if (isSelected)
              Positioned(
                right: -8,
                bottom: -8,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    final newW = ((width + details.delta.dx) / widget.pageWidth).clamp(0.05, 0.95);
                    final newH = ((height + details.delta.dy) / widget.pageHeight).clamp(0.03, 0.95);
                    ann.width = newW;
                    ann.height = newH;
                    provider.updateAnnotation(ann);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                    ),
                    child: const Icon(Icons.open_in_full, size: 12, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnotationContent(AnnotationModel ann) {
    switch (ann.type) {
      case AnnotationType.signature:
        if (ann.imageBytes != null) {
          return Image.memory(
            ann.imageBytes!,
            fit: BoxFit.contain,
          );
        }
        return const Center(child: Text('Signature', style: TextStyle(color: Colors.grey)));

      case AnnotationType.text:
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.yellow.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            ann.text ?? 'Text Note',
            style: TextStyle(
              color: ann.color,
              fontSize: ann.fontSize,
              fontWeight: ann.isBold ? FontWeight.bold : FontWeight.normal,
              fontStyle: ann.isItalic ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        );

      case AnnotationType.shape:
        return _buildShapeWidget(ann);

      case AnnotationType.stamp:
        return _buildStampWidget(ann);

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildShapeWidget(AnnotationModel ann) {
    if (ann.shapeType == ShapeType.rectangle) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: ann.color, width: ann.strokeWidth),
        ),
      );
    } else if (ann.shapeType == ShapeType.circle) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ann.color, width: ann.strokeWidth),
        ),
      );
    } else if (ann.shapeType == ShapeType.redaction) {
      return Container(
        color: Colors.black,
      );
    } else if (ann.shapeType == ShapeType.checkmark) {
      return Icon(
        Icons.check,
        color: ann.color,
        size: 32,
      );
    } else if (ann.shapeType == ShapeType.cross) {
      return Icon(
        Icons.close,
        color: ann.color,
        size: 32,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildStampWidget(AnnotationModel ann) {
    String text = 'APPROVED';
    Color color = const Color(0xFF2E7D32);

    switch (ann.stampType) {
      case StampType.approved:
        text = 'APPROVED';
        color = const Color(0xFF2E7D32);
        break;
      case StampType.confidential:
        text = 'CONFIDENTIAL';
        color = const Color(0xFFC62828);
        break;
      case StampType.draft:
        text = 'DRAFT';
        color = const Color(0xFFEF6C00);
        break;
      case StampType.paid:
        text = 'PAID';
        color = const Color(0xFF1565C0);
        break;
      case StampType.rejected:
        text = 'REJECTED';
        color = const Color(0xFFB71C1C);
        break;
      case StampType.finalVersion:
        text = 'FINAL';
        color = const Color(0xFF6A1B9A);
        break;
      default:
        text = 'VERIFIED';
        color = const Color(0xFF00695C);
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2.5),
        borderRadius: BorderRadius.circular(6),
        color: color.withOpacity(0.08),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _showEditTextDialog(BuildContext context, PdfProvider provider, AnnotationModel ann) {
    final controller = TextEditingController(text: ann.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Text Note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter text...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ann.text = controller.text;
              provider.updateAnnotation(ann);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _DrawingsPainter extends CustomPainter {
  final List<AnnotationModel> annotations;
  final double pageWidth;
  final double pageHeight;

  _DrawingsPainter({
    required this.annotations,
    required this.pageWidth,
    required this.pageHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final ann in annotations) {
      if (ann.points == null || ann.points!.length < 2) continue;

      final isHighlight = ann.type == AnnotationType.highlight;
      final paint = Paint()
        ..color = ann.color.withOpacity(isHighlight ? 0.35 : 1.0)
        ..strokeWidth = isHighlight ? ann.strokeWidth * 3.5 : ann.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      path.moveTo(ann.points![0].x * pageWidth, ann.points![0].y * pageHeight);
      for (int i = 1; i < ann.points!.length; i++) {
        path.lineTo(ann.points![i].x * pageWidth, ann.points![i].y * pageHeight);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingsPainter oldDelegate) => true;
}

class _CurrentStrokePainter extends CustomPainter {
  final List<DrawingPoint> points;
  final Color color;
  final double strokeWidth;
  final bool isHighlight;
  final double pageWidth;
  final double pageHeight;

  _CurrentStrokePainter({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.isHighlight,
    required this.pageWidth,
    required this.pageHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color.withOpacity(isHighlight ? 0.35 : 1.0)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(points[0].x * pageWidth, points[0].y * pageHeight);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].x * pageWidth, points[i].y * pageHeight);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CurrentStrokePainter oldDelegate) => true;
}
