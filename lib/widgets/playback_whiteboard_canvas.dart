import 'package:flutter/material.dart';
import '../models/white_board.dart';
import '../models/stroke.dart';

/// ویجت کنوس برای نمایش وایت‌بورد در حالت بازپخش
class PlaybackWhiteBoardCanvas extends StatelessWidget {
  final WhiteBoard whiteBoard;
  final Color backgroundColor;

  const PlaybackWhiteBoardCanvas({
    super.key,
    required this.whiteBoard,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      width: double.infinity,
      height: double.infinity,
      child: CustomPaint(
        painter: PlaybackWhiteBoardPainter(
          whiteBoard: whiteBoard,
          backgroundColor: backgroundColor,
        ),
      ),
    );
  }
}

/// کلاس طراح (painter) برای رسم خطوط روی کنوس در حالت بازپخش
class PlaybackWhiteBoardPainter extends CustomPainter {
  final WhiteBoard whiteBoard;
  final Color backgroundColor;

  PlaybackWhiteBoardPainter({
    required this.whiteBoard,
    this.backgroundColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // رنگ پس‌زمینه
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = backgroundColor,
    );

    // رسم خطوط
    for (final stroke in whiteBoard.strokes) {
      _drawStroke(canvas, stroke);
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
  bool shouldRepaint(covariant PlaybackWhiteBoardPainter oldDelegate) {
    return whiteBoard != oldDelegate.whiteBoard ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}
