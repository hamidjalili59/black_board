import 'dart:ui';

import 'point.dart';
import 'stroke_style.dart';

/// مدل خط (استروک) برای ذخیره مجموعه‌ای از نقاط و سبک نمایش
class Stroke {
  /// شناسه منحصر به فرد خط
  final String id;

  /// لیست نقاط تشکیل‌دهنده خط
  final List<Point> points;

  /// زمان شروع رسم خط (میلی‌ثانیه)
  final int startTime;

  /// سبک نمایش خط
  final StrokeStyle style;

  /// محدوده مستطیلی خط
  Rect? _boundingRect;

  /// سازنده
  Stroke({
    required this.id,
    required this.points,
    required this.startTime,
    required this.style,
  });

  /// ایجاد یک خط جدید با یک نقطه شروع
  factory Stroke.create({
    required String id,
    required Point startPoint,
    required int startTime,
    StrokeStyle? style,
  }) {
    return Stroke(
      id: id,
      points: [startPoint],
      startTime: startTime,
      style: style ?? const StrokeStyle(),
    );
  }

  /// افزودن یک نقطه جدید به خط
  Stroke addPoint(Point point) {
    final newPoints = List<Point>.from(points)..add(point);
    return copyWith(points: newPoints);
  }

  /// کلون کردن خط با مقادیر جدید
  Stroke copyWith({
    String? id,
    List<Point>? points,
    int? startTime,
    StrokeStyle? style,
  }) {
    return Stroke(
      id: id ?? this.id,
      points: points ?? this.points,
      startTime: startTime ?? this.startTime,
      style: style ?? this.style,
    );
  }

  /// محاسبه طول کل خط
  double get length {
    if (points.length < 2) return 0;

    double total = 0;
    for (int i = 1; i < points.length; i++) {
      total += points[i].distanceTo(points[i - 1]);
    }
    return total;
  }

  /// محاسبه مرزهای خط (مستطیل دربرگیرنده)
  Rect get bounds {
    if (points.isEmpty) {
      return Rect.zero;
    }

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final point in points) {
      if (point.x < minX) minX = point.x;
      if (point.y < minY) minY = point.y;
      if (point.x > maxX) maxX = point.x;
      if (point.y > maxY) maxY = point.y;
    }

    // اضافه کردن نصف ضخامت خط به هر طرف مرز
    final halfThickness = style.thickness / 2;
    return Rect.fromLTRB(
      minX - halfThickness,
      minY - halfThickness,
      maxX + halfThickness,
      maxY + halfThickness,
    );
  }

  /// محاسبه و بازگرداندن محدوده مستطیلی خط
  Rect get boundingRect {
    if (_boundingRect != null) return _boundingRect!;

    if (points.isEmpty) {
      return Rect.zero;
    }

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;

    for (final point in points) {
      minX = point.x < minX ? point.x : minX;
      minY = point.y < minY ? point.y : minY;
      maxX = point.x > maxX ? point.x : maxX;
      maxY = point.y > maxY ? point.y : maxY;
    }

    // اضافه کردن ضخامت قلم به محدوده
    final halfWidth = style.thickness / 2;
    _boundingRect = Rect.fromLTRB(
      minX - halfWidth,
      minY - halfWidth,
      maxX + halfWidth,
      maxY + halfWidth,
    );

    return _boundingRect!;
  }

  @override
  String toString() {
    return 'Stroke(id: $id, points: ${points.length}, startTime: $startTime, style: $style)';
  }
}
