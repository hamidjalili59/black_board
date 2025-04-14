import 'dart:ui';
import 'dart:math' as math;

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

  /// زمان پایان رسم خط (میلی‌ثانیه)
  final int endTime;

  /// سبک نمایش خط
  final StrokeStyle style;

  /// آیا نقاط به صورت دلتا ذخیره شده‌اند
  final bool isDeltaEncoded;

  /// محدوده مستطیلی خط
  Rect? _boundingRect;

  /// سازنده
  Stroke({
    required this.id,
    required this.points,
    required this.startTime,
    int? endTime,
    required this.style,
    this.isDeltaEncoded = false,
  }) : endTime =
           endTime ??
           startTime + (points.isNotEmpty ? points.last.timestamp : 0);

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
    // محاسبه زمان پایان جدید
    final newEndTime =
        startTime +
        math
            .max(points.isNotEmpty ? points.last.timestamp : 0, point.timestamp)
            .toInt();

    return copyWith(points: newPoints, endTime: newEndTime);
  }

  /// کلون کردن خط با مقادیر جدید
  Stroke copyWith({
    String? id,
    List<Point>? points,
    int? startTime,
    int? endTime,
    StrokeStyle? style,
    bool? isDeltaEncoded,
  }) {
    return Stroke(
      id: id ?? this.id,
      points: points ?? this.points,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      style: style ?? this.style,
      isDeltaEncoded: isDeltaEncoded ?? this.isDeltaEncoded,
    );
  }

  /// تبدیل خط به فرمت دلتا برای ذخیره‌سازی بهینه
  Stroke toDeltaEncoded() {
    if (isDeltaEncoded || points.length < 2) return this;

    final encodedPoints = <Point>[];
    encodedPoints.add(points.first); // نقطه اول به صورت مطلق ذخیره می‌شود

    for (int i = 1; i < points.length; i++) {
      encodedPoints.add(Point.delta(points[i - 1], points[i]));
    }

    return copyWith(points: encodedPoints, isDeltaEncoded: true);
  }

  /// تبدیل خط از فرمت دلتا به فرمت مطلق برای نمایش
  Stroke toAbsoluteEncoded() {
    if (!isDeltaEncoded) return this;

    final decodedPoints = <Point>[];
    decodedPoints.add(points.first); // نقطه اول همیشه مطلق است

    for (int i = 1; i < points.length; i++) {
      decodedPoints.add(points[i].toAbsolute(decodedPoints[i - 1]));
    }

    return copyWith(points: decodedPoints, isDeltaEncoded: false);
  }

  /// دریافت نقاط خط تا یک زمان مشخص (برای بازپخش)
  List<Point> getPointsUntil(int timestamp) {
    if (points.isEmpty) return [];

    // اول باید خط را به حالت مطلق تبدیل کنیم اگر به صورت دلتا است
    final absoluteStroke = isDeltaEncoded ? toAbsoluteEncoded() : this;

    // زمان نسبی برای مقایسه (تفاوت با زمان شروع خط)
    final relativeTimestamp = timestamp - absoluteStroke.startTime;

    if (relativeTimestamp <= 0) {
      // اگر هنوز زمان شروع خط نرسیده، لیست خالی برمی‌گردانیم
      return [];
    }

    if (relativeTimestamp >= absoluteStroke.duration) {
      // اگر از زمان پایان خط گذشته، همه نقاط را برمی‌گردانیم
      return List.from(absoluteStroke.points);
    }

    // نقاط تا زمان مشخص شده
    return absoluteStroke.points
        .where((p) => p.timestamp <= relativeTimestamp)
        .toList();
  }

  /// محاسبه نقاط بین دو زمان مشخص (برای بازپخش با seek)
  List<Point> getPointsBetween(int startTimestamp, int endTimestamp) {
    if (points.isEmpty) return [];

    final absoluteStroke = isDeltaEncoded ? toAbsoluteEncoded() : this;
    return absoluteStroke.points.where((p) {
      final pointTime = absoluteStroke.startTime + p.timestamp;
      return pointTime >= startTimestamp && pointTime <= endTimestamp;
    }).toList();
  }

  /// محاسبه طول کل خط
  double get length {
    if (points.length < 2) return 0;

    // اگر نقاط دلتا هستند، ابتدا باید به مطلق تبدیل شوند
    final absolutePoints = isDeltaEncoded ? toAbsoluteEncoded().points : points;

    double total = 0;
    for (int i = 1; i < absolutePoints.length; i++) {
      total += absolutePoints[i].distanceTo(absolutePoints[i - 1]);
    }
    return total;
  }

  /// محاسبه محدوده مستطیل احاطه‌کننده خط
  Rect get bounds {
    if (points.isEmpty) {
      return Rect.zero;
    }

    // اگر نقاط دلتا هستند، ابتدا باید به مطلق تبدیل شوند
    final absolutePoints = isDeltaEncoded ? toAbsoluteEncoded().points : points;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final point in absolutePoints) {
      minX = math.min(minX, point.x);
      minY = math.min(minY, point.y);
      maxX = math.max(maxX, point.x);
      maxY = math.max(maxY, point.y);
    }

    // اضافه کردن نصف ضخامت به هر طرف برای در نظر گرفتن ضخامت خط
    final halfWidth = style.thickness / 2;
    return Rect.fromLTRB(
      minX - halfWidth,
      minY - halfWidth,
      maxX + halfWidth,
      maxY + halfWidth,
    );
  }

  /// محاسبه و بازگرداندن محدوده مستطیلی خط
  Rect get boundingRect {
    if (_boundingRect != null) return _boundingRect!;
    _boundingRect = bounds;
    return _boundingRect!;
  }

  /// دریافت مدت زمان کل خط به میلی‌ثانیه
  int get duration => endTime - startTime;

  @override
  String toString() {
    return 'Stroke(id: $id, points: ${points.length}, startTime: $startTime, endTime: $endTime, isDelta: $isDeltaEncoded)';
  }
}
