import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// مدل نقطه در Protobuf
class PointProto {
  final double x;
  final double y;
  final double pressure;
  final int timestamp;

  PointProto({
    required this.x,
    required this.y,
    required this.pressure,
    required this.timestamp,
  });

  /// تبدیل به JSON
  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'pressure': pressure,
    'timestamp': timestamp,
  };

  /// ایجاد از JSON
  factory PointProto.fromJson(Map<String, dynamic> json) => PointProto(
    x: json['x'] as double,
    y: json['y'] as double,
    pressure: json['pressure'] as double,
    timestamp: json['timestamp'] as int,
  );

  /// تبدیل به بایت‌ها
  Uint8List toBuffer() => Uint8List.fromList(utf8.encode(jsonEncode(toJson())));

  /// ایجاد از بایت‌ها
  factory PointProto.fromBuffer(Uint8List buffer) => PointProto.fromJson(
    jsonDecode(utf8.decode(buffer)) as Map<String, dynamic>,
  );
}

/// مدل استایل خط در Protobuf
class StrokeStyleProto {
  final String color;
  final double width;
  final bool isEraser;

  StrokeStyleProto({
    required this.color,
    required this.width,
    required this.isEraser,
  });

  /// تبدیل به JSON
  Map<String, dynamic> toJson() => {
    'color': color,
    'width': width,
    'isEraser': isEraser,
  };

  /// ایجاد از JSON
  factory StrokeStyleProto.fromJson(Map<String, dynamic> json) =>
      StrokeStyleProto(
        color: json['color'] as String,
        width: json['width'] as double,
        isEraser: json['isEraser'] as bool,
      );

  /// تبدیل به بایت‌ها
  Uint8List toBuffer() => Uint8List.fromList(utf8.encode(jsonEncode(toJson())));

  /// ایجاد از بایت‌ها
  factory StrokeStyleProto.fromBuffer(Uint8List buffer) =>
      StrokeStyleProto.fromJson(
        jsonDecode(utf8.decode(buffer)) as Map<String, dynamic>,
      );
}

/// مدل خط در Protobuf
class StrokeProto {
  final String id;
  final List<PointProto> points;
  final StrokeStyleProto style;

  StrokeProto({required this.id, required this.points, required this.style});

  /// تبدیل به JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'points': points.map((p) => p.toJson()).toList(),
    'style': style.toJson(),
  };

  /// ایجاد از JSON
  factory StrokeProto.fromJson(Map<String, dynamic> json) => StrokeProto(
    id: json['id'] as String,
    points:
        (json['points'] as List)
            .map((p) => PointProto.fromJson(p as Map<String, dynamic>))
            .toList(),
    style: StrokeStyleProto.fromJson(json['style'] as Map<String, dynamic>),
  );

  /// تبدیل به بایت‌ها
  Uint8List toBuffer() => Uint8List.fromList(utf8.encode(jsonEncode(toJson())));

  /// ایجاد از بایت‌ها
  factory StrokeProto.fromBuffer(Uint8List buffer) => StrokeProto.fromJson(
    jsonDecode(utf8.decode(buffer)) as Map<String, dynamic>,
  );
}

/// مدل وایت‌بورد در Protobuf
class WhiteBoardProto {
  final String id;
  final String name;
  final int createdAt;
  final int updatedAt;
  final List<StrokeProto> strokes;

  WhiteBoardProto({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.strokes,
  });

  /// تبدیل به JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'strokes': strokes.map((s) => s.toJson()).toList(),
  };

  /// ایجاد از JSON
  factory WhiteBoardProto.fromJson(Map<String, dynamic> json) =>
      WhiteBoardProto(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: json['createdAt'] as int,
        updatedAt: json['updatedAt'] as int,
        strokes:
            (json['strokes'] as List)
                .map((s) => StrokeProto.fromJson(s as Map<String, dynamic>))
                .toList(),
      );

  /// تبدیل به بایت‌ها با فشرده‌سازی
  Uint8List toBuffer() {
    final jsonData = jsonEncode(toJson());
    // می‌توانیم از فشرده‌سازی برای کاهش اندازه استفاده کنیم
    try {
      final compressedData = gzip.encode(utf8.encode(jsonData));
      // اضافه کردن هدر مخصوص برای تشخیص داده فشرده شده
      final buffer = Uint8List(compressedData.length + 1);
      buffer[0] = 1; // نشانگر فشرده‌سازی
      buffer.setRange(1, buffer.length, compressedData);
      return buffer;
    } catch (e) {
      debugPrint('خطا در فشرده‌سازی داده: $e');
      // اگر فشرده‌سازی با خطا مواجه شد، داده را بدون فشرده‌سازی برمی‌گردانیم
      final rawData = utf8.encode(jsonData);
      final buffer = Uint8List(rawData.length + 1);
      buffer[0] = 0; // نشانگر عدم فشرده‌سازی
      buffer.setRange(1, buffer.length, rawData);
      return buffer;
    }
  }

  /// ایجاد از بایت‌ها
  factory WhiteBoardProto.fromBuffer(Uint8List buffer) {
    try {
      if (buffer.isEmpty) {
        throw FormatException('داده نامعتبر است');
      }

      // بررسی بایت اول برای تشخیص فشرده‌سازی
      final isCompressed = buffer[0] == 1;
      final data = buffer.sublist(1);

      final jsonData =
          isCompressed ? utf8.decode(gzip.decode(data)) : utf8.decode(data);

      return WhiteBoardProto.fromJson(
        jsonDecode(jsonData) as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('خطا در خواندن داده: $e');
      throw FormatException('خطا در خواندن داده: $e');
    }
  }
}
