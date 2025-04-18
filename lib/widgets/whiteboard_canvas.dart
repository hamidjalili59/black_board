import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/whiteboard_provider.dart';
import '../models/stroke.dart';

/// ویجت کنوس وایت‌بورد برای رسم خطوط
class WhiteBoardCanvas extends StatelessWidget {
  final Color backgroundColor;

  const WhiteBoardCanvas({super.key, this.backgroundColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) => _handlePanStart(context, details),
      onPanUpdate: (details) => _handlePanUpdate(context, details),
      onPanEnd: (details) => _handlePanEnd(context),
      child: Container(
        color: backgroundColor,
        width: double.infinity,
        height: double.infinity,
        child: CustomPaint(
          painter: WhiteBoardPainter(
            provider: Provider.of<WhiteBoardProvider>(context),
            backgroundColor: backgroundColor,
          ),
        ),
      ),
    );
  }

  void _handlePanStart(BuildContext context, DragStartDetails details) {
    final provider = Provider.of<WhiteBoardProvider>(context, listen: false);
    provider.startStroke(details.localPosition);
  }

  void _handlePanUpdate(BuildContext context, DragUpdateDetails details) {
    final provider = Provider.of<WhiteBoardProvider>(context, listen: false);
    provider.updateStroke(details.localPosition);
  }

  void _handlePanEnd(BuildContext context) {
    final provider = Provider.of<WhiteBoardProvider>(context, listen: false);
    provider.endStroke();
  }
}

/// کلاس طراح (painter) برای رسم خطوط روی کنوس
class WhiteBoardPainter extends CustomPainter {
  final WhiteBoardProvider provider;
  final Color backgroundColor;

  WhiteBoardPainter({
    required this.provider,
    this.backgroundColor = Colors.white,
  }) : super(repaint: provider);

  @override
  void paint(Canvas canvas, Size size) {
    // رنگ پس‌زمینه
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = backgroundColor,
    );

    final whiteBoard = provider.whiteBoard;
    if (whiteBoard == null) return;

    // رسم خطوط ذخیره شده
    for (final stroke in whiteBoard.strokes) {
      _drawStroke(canvas, stroke);
    }

    // رسم خط در حال ترسیم (اگر وجود داشته باشد)
    if (provider.isDrawing) {
      // خط در حال رسم را نمایش می‌دهیم
      // برای دسترسی به خط فعلی، باید در Provider متدی اضافه کنیم
      _drawCurrentStroke(canvas);
    }
  }

  /// رسم خط در حال ترسیم
  void _drawCurrentStroke(Canvas canvas) {
    // دسترسی به خط فعلی از طریق گتر
    final currentStroke = provider.currentStroke;
    if (currentStroke != null && currentStroke.points.isNotEmpty) {
      _drawStroke(canvas, currentStroke);
    }
  }

  /// رسم یک خط
  void _drawStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    final paint =
        Paint()
          ..color = stroke.style.color
          ..strokeWidth = stroke.style.thickness
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;

    // رسم نقاط به صورت مستقیم
    if (stroke.points.length < 2) {
      // اگر فقط یک نقطه داریم، یک دایره کوچک رسم می‌کنیم
      if (stroke.points.length == 1) {
        final point = stroke.points[0];
        canvas.drawCircle(
          Offset(point.x, point.y),
          stroke.style.thickness / 2,
          paint,
        );
      }
      return;
    }

    // ایجاد مسیر برای رسم خط
    final path = Path();
    path.moveTo(stroke.points[0].x, stroke.points[0].y);

    // رسم خط میان نقاط
    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].x, stroke.points[i].y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WhiteBoardPainter oldDelegate) {
    return true; // همیشه دوباره رسم می‌کنیم
  }
}
