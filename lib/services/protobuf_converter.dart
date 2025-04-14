import 'dart:typed_data';
import 'package:flutter/foundation.dart';
// موقتاً مدل‌های مورد نیاز را import می‌کنیم
import '../models/point.dart';
import '../models/stroke.dart';
import '../models/stroke_style.dart';
import '../models/white_board.dart';
import 'dart:ui';

// ما فرض می‌کنیم که فایل‌های تولید شده از proto در این مسیر قرار دارند
// import '../generated/drawing.pb.dart' as pb;

/// سرویس تبدیل بین مدل‌های داخلی و Protobuf
class ProtobufConverter {
  /// تبدیل مدل داخلی WhiteBoard به Protobuf
  static dynamic convertToProto(WhiteBoard model) {
    try {
      /*
      final proto =
          pb.WhiteBoard()
            ..id = model.id
            ..name = model.name
            ..createdAt = model.createdAt
            ..updatedAt = model.updatedAt;

      // تبدیل خطوط
      for (final stroke in model.strokes) {
        final protoStroke = pb.Stroke()..id = stroke.id;

        // تبدیل سبک خط
        final protoStyle =
            pb.StrokeStyle()
              ..color = stroke.style.color
              ..width = stroke.style.thickness // width به thickness تغییر کرده
              ..smoothness = stroke.style.smoothness ?? 0;

        protoStroke.style = protoStyle;

        // تبدیل نقاط
        for (final point in stroke.points) {
          final protoPoint =
              pb.Point()
                ..x = point.x
                ..y = point.y
                ..pressure = point.pressure
                ..timestamp = DateTime.now().millisecondsSinceEpoch;

          protoStroke.points.add(protoPoint);
        }

        proto.strokes.add(protoStroke);
      }

      return proto;
      */

      // تا زمانی که فایل‌های protobuf تولید شوند، یک مقدار پیش‌فرض برمی‌گردانیم
      return Uint8List(0);
    } catch (e) {
      debugPrint('خطا در تبدیل به Protobuf: $e');
      rethrow;
    }
  }

  /// تبدیل Protobuf به مدل داخلی WhiteBoard
  static WhiteBoard convertFromProto(dynamic proto) {
    try {
      /*
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
              type: protoStroke.style.isEraser ? StrokeType.dotted : StrokeType.solid,
            );

            return Stroke(
              id: protoStroke.id, 
              points: points, 
              startTime: DateTime.now().millisecondsSinceEpoch,
              style: style
            );
          }).toList();

      return WhiteBoard(
        id: proto.id,
        name: proto.name,
        createdAt: DateTime.fromMillisecondsSinceEpoch(proto.createdAt),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(proto.updatedAt),
        strokes: strokes,
      );
      */

      // تا زمانی که فایل‌های protobuf تولید شوند، یک مقدار پیش‌فرض برمی‌گردانیم
      return WhiteBoard(
        id: 'temp',
        name: 'Temporary WhiteBoard',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        strokes: [],
      );
    } catch (e) {
      debugPrint('خطا در تبدیل از Protobuf: $e');
      rethrow;
    }
  }

  /// تبدیل مدل داخلی به آرایه بایت Protobuf
  static Uint8List modelToBytes(WhiteBoard model) {
    //final proto = convertToProto(model);
    //return proto.writeToBuffer();
    return Uint8List(0); // مقدار پیش‌فرض
  }

  /// تبدیل آرایه بایت Protobuf به مدل داخلی
  static WhiteBoard bytesToModel(Uint8List bytes) {
    //final proto = pb.WhiteBoard.fromBuffer(bytes);
    //return convertFromProto(proto);
    return WhiteBoard(
      id: 'temp',
      name: 'Temporary WhiteBoard',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      strokes: [],
    ); // مقدار پیش‌فرض
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
