import '../models/point.dart';
import '../models/stroke.dart';
import '../models/stroke_style.dart';
import '../models/white_board.dart';
import 'dart:ui';
// import drawing.pb.dart تا زمانی که تولید شود

/// کلاس مسئول تبدیل مدل‌های داخلی به Protobuf و برعکس
class ProtoConverter {
  /// تبدیل مدل نقطه داخلی به Protobuf
  static dynamic pointToProto(Point point) {
    // تا زمانی که کلاس‌های protobuf تولید شوند، اینجا کامنت می‌ماند
    /*
    return blackboard.Point(
      x: point.x,
      y: point.y,
      pressure: point.pressure,
      timestamp: DateTime.now().millisecondsSinceEpoch, // چون point timestamp ندارد
    );
    */
    return null;
  }

  /// تبدیل مدل نقطه Protobuf به مدل داخلی
  static Point pointFromProto(dynamic protoPoint) {
    return Point(
      x: protoPoint.x,
      y: protoPoint.y,
      pressure: protoPoint.pressure,
    );
  }

  /// تبدیل مدل سبک خط داخلی به Protobuf
  static dynamic strokeStyleToProto(StrokeStyle style) {
    // تا زمانی که کلاس‌های protobuf تولید شوند، اینجا کامنت می‌ماند
    /*
    return blackboard.StrokeStyle(
      color: style.color.value.toRadixString(16).padLeft(8, '0'),
      width: style.thickness, // width به thickness تغییر کرده
      isEraser: style.type == StrokeType.dotted, // isEraser وجود ندارد، یک مثال جایگزین
    );
    */
    return null;
  }

  /// تبدیل مدل سبک خط Protobuf به مدل داخلی
  static StrokeStyle strokeStyleFromProto(dynamic protoStyle) {
    return StrokeStyle(
      color: Color(int.parse(protoStyle.color, radix: 16)),
      thickness: protoStyle.width,
      type: protoStyle.isEraser ? StrokeType.dotted : StrokeType.solid,
    );
  }

  /// تبدیل مدل خط داخلی به Protobuf
  static dynamic strokeToProto(Stroke stroke) {
    // تا زمانی که کلاس‌های protobuf تولید شوند، اینجا کامنت می‌ماند
    /*
    final protoStroke = blackboard.Stroke(
      id: stroke.id,
      style: strokeStyleToProto(stroke.style),
    );

    for (final point in stroke.points) {
      protoStroke.points.add(pointToProto(point));
    }

    return protoStroke;
    */
    return null;
  }

  /// تبدیل مدل خط Protobuf به مدل داخلی
  static Stroke strokeFromProto(dynamic protoStroke) {
    final points = protoStroke.points.map((p) => pointFromProto(p)).toList();

    return Stroke(
      id: protoStroke.id,
      points: points,
      startTime:
          DateTime.now()
              .millisecondsSinceEpoch, // چون کلاس Stroke نیاز به startTime دارد
      style: strokeStyleFromProto(protoStroke.style),
    );
  }

  /// تبدیل مدل وایت‌بورد داخلی به Protobuf
  static dynamic whiteBoardToProto(WhiteBoard whiteBoard) {
    // تا زمانی که کلاس‌های protobuf تولید شوند، اینجا کامنت می‌ماند
    /*
    final protoWhiteBoard = blackboard.WhiteBoard(
      id: whiteBoard.id,
      name: whiteBoard.name,
      createdAt: whiteBoard.createdAt.millisecondsSinceEpoch,
      updatedAt: whiteBoard.updatedAt.millisecondsSinceEpoch,
    );

    for (final stroke in whiteBoard.strokes) {
      protoWhiteBoard.strokes.add(strokeToProto(stroke));
    }

    return protoWhiteBoard;
    */
    return null;
  }

  /// تبدیل مدل وایت‌بورد Protobuf به مدل داخلی
  static WhiteBoard whiteBoardFromProto(dynamic protoWhiteBoard) {
    // تا زمانی که کلاس‌های protobuf تولید شوند، اینجا کامنت می‌ماند
    /*
    final strokes = protoWhiteBoard.strokes.map((s) => strokeFromProto(s)).toList();

    return WhiteBoard(
      id: protoWhiteBoard.id,
      name: protoWhiteBoard.name,
      createdAt: DateTime.fromMillisecondsSinceEpoch(protoWhiteBoard.createdAt.toInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(protoWhiteBoard.updatedAt.toInt()),
      strokes: strokes,
    );
    */

    return WhiteBoard(
      id: 'temp',
      name: 'Temporary',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      strokes: [],
    );
  }
}
