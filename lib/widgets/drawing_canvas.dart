import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../models/drawing_model.dart';

/// ویجت کنوس اختصاصی برای رسم خطوط با قابلیت تنظیم نرمی
class DrawingCanvas extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? currentStroke;

  DrawingCanvas({required this.strokes, this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    // رسم خطوط قبلی
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }

    // رسم خط در حال ترسیم
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!);
    }
  }

  /// رسم یک خط با استفاده از path
  void _drawStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    final path = stroke.toPath();
    final paint =
        Paint()
          ..color = Color(stroke.style.color)
          ..strokeWidth = stroke.style.width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant DrawingCanvas oldDelegate) {
    return strokes.length != oldDelegate.strokes.length ||
        currentStroke != oldDelegate.currentStroke;
  }
}

/// پنل کنوس برای رسم خطوط با قابلیت تشخیص حرکات انگشت
class DrawingCanvasPanel extends StatelessWidget {
  final List<Stroke> strokes;
  final Stroke? currentStroke;
  final Function(Offset) onPanStart;
  final Function(Offset) onPanUpdate;
  final Function() onPanEnd;

  const DrawingCanvasPanel({
    Key? key,
    required this.strokes,
    this.currentStroke,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) => onPanStart(details.localPosition),
      onPanUpdate: (details) => onPanUpdate(details.localPosition),
      onPanEnd: (details) => onPanEnd(),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: CustomPaint(
          painter: DrawingCanvas(
            strokes: strokes,
            currentStroke: currentStroke,
          ),
        ),
      ),
    );
  }
}
