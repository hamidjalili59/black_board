import 'package:flutter/material.dart';
import '../models/stroke.dart';
import '../models/point.dart';
import '../models/stroke_style.dart';

/// کامپوننت نمایش و ویرایش وایت‌بورد protobuf
class DrawingCanvasPanel extends StatelessWidget {
  final List<Stroke> strokes;
  final Stroke? currentStroke;
  final Function(Offset) onPanStart;
  final Function(Offset) onPanUpdate;
  final Function() onPanEnd;

  const DrawingCanvasPanel({
    super.key,
    required this.strokes,
    this.currentStroke,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) => onPanStart(details.localPosition),
      onPanUpdate: (details) => onPanUpdate(details.localPosition),
      onPanEnd: (details) => onPanEnd(),
      child: CustomPaint(
        painter: _StrokePainter(strokes: strokes, currentStroke: currentStroke),
        size: Size.infinite,
      ),
    );
  }
}

/// طراح سفارشی برای رسم خط‌ها
class _StrokePainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? currentStroke;

  _StrokePainter({required this.strokes, this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    // رسم تمام خط‌های ذخیره شده
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }

    // رسم خط در حال ایجاد
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!);
    }
  }

  /// رسم یک خط
  void _drawStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    final path = Path();
    final points = stroke.points;
    final paint =
        Paint()
          ..color = stroke.style.color
          ..strokeWidth = stroke.style.thickness
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;

    // اعمال نوع خط
    if (stroke.style.type == StrokeType.dotted) {
      paint.strokeCap = StrokeCap.round;
      paint.strokeJoin = StrokeJoin.round;
      paint.style = PaintingStyle.stroke;
      // ایجاد دش پترن برای خط نقطه‌چین
      paint.strokeWidth = stroke.style.thickness * 0.8;
    }

    // حرکت به نقطه اول
    if (points.isNotEmpty) {
      final firstPoint = _pointToOffset(points.first);
      path.moveTo(firstPoint.dx, firstPoint.dy);
    }

    // اگر فقط یک نقطه داریم، یک دایره کوچک رسم می‌کنیم
    if (points.length == 1) {
      final point = _pointToOffset(points.first);
      canvas.drawCircle(point, stroke.style.thickness / 2, paint);
      return;
    }

    // رسم خط بین نقاط
    if (stroke.style.type == StrokeType.dotted) {
      // رسم خط نقطه‌چین
      for (int i = 0; i < points.length - 1; i += 2) {
        final start = _pointToOffset(points[i]);
        final end =
            i + 1 < points.length ? _pointToOffset(points[i + 1]) : start;
        canvas.drawLine(start, end, paint);
      }
    } else {
      // رسم خط ممتد
      for (int i = 1; i < points.length; i++) {
        final prev = _pointToOffset(points[i - 1]);
        final curr = _pointToOffset(points[i]);

        // ایجاد خط صاف
        path.lineTo(curr.dx, curr.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  /// تبدیل Point به Offset
  Offset _pointToOffset(Point point) {
    return Offset(point.x, point.y);
  }

  @override
  bool shouldRepaint(covariant _StrokePainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.currentStroke != currentStroke;
  }
}
