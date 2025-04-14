import 'package:flutter/material.dart';
import '../models/white_board.dart';
import '../models/stroke.dart';

class WhiteBoardView extends StatelessWidget {
  final WhiteBoard whiteBoard;
  final bool readOnly;
  final Function(Stroke)? onStrokeAdded;

  const WhiteBoardView({
    Key? key,
    required this.whiteBoard,
    this.readOnly = false,
    this.onStrokeAdded,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: CustomPaint(
        painter: WhiteBoardPainter(whiteBoard: whiteBoard),
        child:
            readOnly
                ? SizedBox.expand()
                : GestureDetector(
                  onPanStart: _handlePanStart,
                  onPanUpdate: _handlePanUpdate,
                  onPanEnd: _handlePanEnd,
                ),
      ),
    );
  }

  void _handlePanStart(DragStartDetails details) {
    if (readOnly) return;
    // اینجا منطق شروع stroke جدید قرار می‌گیرد
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (readOnly) return;
    // اینجا منطق به‌روزرسانی stroke در حال کشیدن قرار می‌گیرد
  }

  void _handlePanEnd(DragEndDetails details) {
    if (readOnly) return;
    // اینجا منطق پایان stroke قرار می‌گیرد
  }
}

class WhiteBoardPainter extends CustomPainter {
  final WhiteBoard whiteBoard;

  WhiteBoardPainter({required this.whiteBoard});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in whiteBoard.strokes) {
      final path = Path();

      if (stroke.points.isNotEmpty) {
        path.moveTo(stroke.points.first.x, stroke.points.first.y);

        for (int i = 1; i < stroke.points.length; i++) {
          path.lineTo(stroke.points[i].x, stroke.points[i].y);
        }
      }

      final paint =
          Paint()
            ..color = stroke.style.color.withOpacity(stroke.style.opacity)
            ..strokeWidth = stroke.style.thickness
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..style = PaintingStyle.stroke;

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant WhiteBoardPainter oldDelegate) {
    return oldDelegate.whiteBoard != whiteBoard;
  }
}
