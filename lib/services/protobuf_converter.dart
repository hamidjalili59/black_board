import 'package:flutter/foundation.dart';
// موقتاً مدل‌های مورد نیاز را import می‌کنیم
import '../models/point.dart';
import '../models/stroke.dart';
import '../models/stroke_style.dart';
import '../models/white_board.dart';
import 'dart:ui';
import '../generated/proto_models.dart';

/// سرویس تبدیل بین مدل‌های داخلی و Protobuf
class ProtobufConverter {
  /// تبدیل مدل داخلی WhiteBoard به Protobuf
  static WhiteBoardProto convertToProto(WhiteBoard model) {
    try {
      final strokes =
          model.strokes.map((stroke) {
            // تبدیل نقاط
            final points =
                stroke.points
                    .map(
                      (point) => PointProto(
                        x: point.x,
                        y: point.y,
                        pressure: point.pressure,
                        timestamp: DateTime.now().millisecondsSinceEpoch,
                      ),
                    )
                    .toList();

            // تبدیل سبک خط
            final style = StrokeStyleProto(
              color: stroke.style.color.value.toRadixString(16).padLeft(8, '0'),
              width: stroke.style.thickness,
              isEraser: stroke.style.type == StrokeType.dotted,
            );

            return StrokeProto(id: stroke.id, points: points, style: style);
          }).toList();

      return WhiteBoardProto(
        id: model.id,
        name: model.name,
        createdAt: model.createdAt.millisecondsSinceEpoch,
        updatedAt: model.updatedAt.millisecondsSinceEpoch,
        strokes: strokes,
      );
    } catch (e) {
      debugPrint('خطا در تبدیل به Protobuf: $e');
      rethrow;
    }
  }

  /// تبدیل Protobuf به مدل داخلی WhiteBoard
  static WhiteBoard convertFromProto(WhiteBoardProto proto) {
    try {
      // تبدیل خطوط
      final strokes =
          proto.strokes.map((protoStroke) {
            // تبدیل نقاط
            final points =
                protoStroke.points
                    .map(
                      (protoPoint) => Point(
                        x: protoPoint.x,
                        y: protoPoint.y,
                        pressure: protoPoint.pressure,
                      ),
                    )
                    .toList();

            // تبدیل سبک خط
            final style = StrokeStyle(
              color: Color(int.parse(protoStroke.style.color, radix: 16)),
              thickness: protoStroke.style.width,
              type:
                  protoStroke.style.isEraser
                      ? StrokeType.dotted
                      : StrokeType.solid,
            );

            return Stroke(
              id: protoStroke.id,
              points: points,
              startTime: DateTime.now().millisecondsSinceEpoch,
              style: style,
            );
          }).toList();

      return WhiteBoard(
        id: proto.id,
        name: proto.name,
        createdAt: DateTime.fromMillisecondsSinceEpoch(proto.createdAt),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(proto.updatedAt),
        strokes: strokes,
      );
    } catch (e) {
      debugPrint('خطا در تبدیل از Protobuf: $e');
      rethrow;
    }
  }

  /// تبدیل مدل داخلی به آرایه بایت Protobuf
  static Uint8List modelToBytes(WhiteBoard model) {
    final proto = convertToProto(model);
    return proto.toBuffer();
  }

  /// تبدیل آرایه بایت Protobuf به مدل داخلی
  static WhiteBoard bytesToModel(Uint8List bytes) {
    final proto = WhiteBoardProto.fromBuffer(bytes);
    return convertFromProto(proto);
  }

  /// بهینه‌سازی داده‌ها با فشرده‌سازی نقاط (ذخیره تفاوت بین نقاط به جای مقادیر مطلق)
  static List<Point> compressPoints(List<Point> points) {
    if (points.isEmpty) return [];

    final result = [points.first];

    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];

      result.add(
        Point(
          x: curr.x - prev.x, // ذخیره تفاوت
          y: curr.y - prev.y, // ذخیره تفاوت
          pressure: curr.pressure,
        ),
      );
    }

    return result;
  }

  /// بازگرداندن نقاط فشرده شده به حالت اصلی
  static List<Point> decompressPoints(List<Point> compressedPoints) {
    if (compressedPoints.isEmpty) return [];

    final result = [compressedPoints.first];

    for (var i = 1; i < compressedPoints.length; i++) {
      final prev = result.last;
      final curr = compressedPoints[i];

      result.add(
        Point(
          x: prev.x + curr.x, // بازگرداندن مقدار مطلق
          y: prev.y + curr.y, // بازگرداندن مقدار مطلق
          pressure: curr.pressure,
        ),
      );
    }

    return result;
  }
}
