import '../models/point.dart';
import '../models/stroke.dart';
import '../models/stroke_style.dart';
import '../models/white_board.dart';
import 'dart:ui';
import '../generated/proto_models.dart';
// import drawing.pb.dart تا زمانی که تولید شود

/// کلاس مسئول تبدیل مدل‌های داخلی به Protobuf و برعکس
class ProtoConverter {
  /// تبدیل مدل نقطه داخلی به Protobuf
  static PointProto pointToProto(Point point) {
    return PointProto(
      x: point.x,
      y: point.y,
      pressure: point.pressure,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// تبدیل مدل نقطه Protobuf به مدل داخلی
  static Point pointFromProto(PointProto protoPoint) {
    return Point(
      x: protoPoint.x,
      y: protoPoint.y,
      pressure: protoPoint.pressure,
    );
  }

  /// تبدیل مدل سبک خط داخلی به Protobuf
  static StrokeStyleProto strokeStyleToProto(StrokeStyle style) {
    final color = style.color;
    // ایجاد مقدار رنگ به صورت دستی بدون استفاده از .value
    final colorValue =
        (color.alpha << 24) |
        (color.red << 16) |
        (color.green << 8) |
        color.blue;

    return StrokeStyleProto(
      color: colorValue.toRadixString(16).padLeft(8, '0'),
      width: style.thickness,
      isEraser: style.type == StrokeType.dotted,
    );
  }

  /// تبدیل مدل سبک خط Protobuf به مدل داخلی
  static StrokeStyle strokeStyleFromProto(StrokeStyleProto protoStyle) {
    return StrokeStyle(
      color: Color(int.parse(protoStyle.color, radix: 16)),
      thickness: protoStyle.width,
      type: protoStyle.isEraser ? StrokeType.dotted : StrokeType.solid,
    );
  }

  /// تبدیل مدل خط داخلی به Protobuf
  static StrokeProto strokeToProto(Stroke stroke) {
    final protoPoints = stroke.points.map(pointToProto).toList();
    return StrokeProto(
      id: stroke.id,
      points: protoPoints,
      style: strokeStyleToProto(stroke.style),
    );
  }

  /// تبدیل مدل خط Protobuf به مدل داخلی
  static Stroke strokeFromProto(StrokeProto protoStroke) {
    final points = protoStroke.points.map(pointFromProto).toList();

    return Stroke(
      id: protoStroke.id,
      points: points,
      startTime: DateTime.now().millisecondsSinceEpoch,
      style: strokeStyleFromProto(protoStroke.style),
    );
  }

  /// تبدیل مدل وایت‌بورد داخلی به Protobuf
  static WhiteBoardProto whiteBoardToProto(WhiteBoard whiteBoard) {
    final protoStrokes = whiteBoard.strokes.map(strokeToProto).toList();

    return WhiteBoardProto(
      id: whiteBoard.id,
      name: whiteBoard.name,
      createdAt: whiteBoard.createdAt.millisecondsSinceEpoch,
      updatedAt: whiteBoard.updatedAt.millisecondsSinceEpoch,
      strokes: protoStrokes,
    );
  }

  /// تبدیل مدل وایت‌بورد Protobuf به مدل داخلی
  static WhiteBoard whiteBoardFromProto(WhiteBoardProto protoWhiteBoard) {
    final strokes = protoWhiteBoard.strokes.map(strokeFromProto).toList();

    return WhiteBoard(
      id: protoWhiteBoard.id,
      name: protoWhiteBoard.name,
      createdAt: DateTime.fromMillisecondsSinceEpoch(protoWhiteBoard.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(protoWhiteBoard.updatedAt),
      strokes: strokes,
    );
  }
}
