import 'package:json_annotation/json_annotation.dart';
import 'dart:ui' as ui;
import 'dart:math';

part 'drawing_model.g.dart';

@JsonSerializable()
class Point {
  final double x;
  final double y;
  final double pressure;
  final double timestamp;

  Point({
    required this.x,
    required this.y,
    this.pressure = 1.0,
    required this.timestamp,
  });

  factory Point.fromJson(Map<String, dynamic> json) => _$PointFromJson(json);
  Map<String, dynamic> toJson() => _$PointToJson(this);

  factory Point.fromOffset(
    ui.Offset offset, {
    double pressure = 1.0,
    double? timestamp,
  }) {
    return Point(
      x: offset.dx,
      y: offset.dy,
      pressure: pressure,
      timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch.toDouble(),
    );
  }

  ui.Offset toOffset() => ui.Offset(x, y);
}

@JsonSerializable()
class StrokeStyle {
  final int color;
  final double width;
  final double smoothness;

  StrokeStyle({
    required this.color,
    required this.width,
    required this.smoothness,
  });

  factory StrokeStyle.fromJson(Map<String, dynamic> json) =>
      _$StrokeStyleFromJson(json);
  Map<String, dynamic> toJson() => _$StrokeStyleToJson(this);

  factory StrokeStyle.defaultStyle() {
    final color = ui.Color.fromARGB(255, 0, 0, 0);
    return StrokeStyle(
      color:
          (color.red << 16) |
          (color.green << 8) |
          color.blue |
          (color.alpha << 24),
      width: 3.0,
      smoothness: 0.5,
    );
  }

  ui.Color toColor() => ui.Color(color);
}

@JsonSerializable()
class Stroke {
  final String id;
  final List<Point> points;
  final StrokeStyle style;

  Stroke({String? id, required this.points, required this.style})
    : id = id ?? _generateId();

  factory Stroke.fromJson(Map<String, dynamic> json) => _$StrokeFromJson(json);
  Map<String, dynamic> toJson() => _$StrokeToJson(this);

  static String _generateId() {
    return "${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}";
  }

  ui.Path toPath() {
    final path = ui.Path();

    if (points.isEmpty) return path;

    path.moveTo(points.first.x, points.first.y);

    if (points.length < 3) {
      // اگر تنها یک یا دو نقطه داریم، مستقیم رسم می‌کنیم
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].x, points[i].y);
      }
    } else {
      // منحنی بزیر برای رسم نرم خطوط استفاده می‌کنیم
      for (var i = 1; i < points.length - 1; i++) {
        final p0 = points[i - 1];
        final p1 = points[i];
        final p2 = points[i + 1];

        // محاسبه نقاط کنترل برای منحنی بزیر
        final smoothness = style.smoothness;
        final xc1 = (p0.x + p1.x) / 2;
        final yc1 = (p0.y + p1.y) / 2;
        final xc2 = (p1.x + p2.x) / 2;
        final yc2 = (p1.y + p2.y) / 2;

        // منحنی بزیر را رسم می‌کنیم
        path.quadraticBezierTo(
          p1.x * smoothness + (1 - smoothness) * xc1,
          p1.y * smoothness + (1 - smoothness) * yc1,
          xc2 * (1 - smoothness) + p1.x * smoothness,
          yc2 * (1 - smoothness) + p1.y * smoothness,
        );
      }

      // نقطه آخر
      path.lineTo(points.last.x, points.last.y);
    }

    return path;
  }
}

@JsonSerializable()
class WhiteBoard {
  final String id;
  final String name;
  final int createdAt;
  final int updatedAt;
  final List<Stroke> strokes;

  WhiteBoard({
    String? id,
    required this.name,
    int? createdAt,
    int? updatedAt,
    required this.strokes,
  }) : id = id ?? _generateId(),
       createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
       updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  factory WhiteBoard.fromJson(Map<String, dynamic> json) =>
      _$WhiteBoardFromJson(json);
  Map<String, dynamic> toJson() => _$WhiteBoardToJson(this);

  static String _generateId() {
    return "${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}";
  }

  WhiteBoard copyWith({
    String? id,
    String? name,
    int? createdAt,
    int? updatedAt,
    List<Stroke>? strokes,
  }) {
    return WhiteBoard(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now().millisecondsSinceEpoch,
      strokes: strokes ?? this.strokes,
    );
  }

  WhiteBoard addStroke(Stroke stroke) {
    return copyWith(
      strokes: [...strokes, stroke],
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  WhiteBoard updateStroke(Stroke updatedStroke) {
    final newStrokes =
        strokes.map((stroke) {
          if (stroke.id == updatedStroke.id) {
            return updatedStroke;
          }
          return stroke;
        }).toList();

    return copyWith(
      strokes: newStrokes,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  WhiteBoard removeStroke(String strokeId) {
    return copyWith(
      strokes: strokes.where((stroke) => stroke.id != strokeId).toList(),
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  WhiteBoard clearStrokes() {
    return copyWith(
      strokes: [],
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
