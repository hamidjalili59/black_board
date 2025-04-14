/// مدل نقطه برای ذخیره مختصات و فشار قلم
class Point {
  /// موقعیت افقی نقطه
  final double x;

  /// موقعیت عمودی نقطه
  final double y;

  /// میزان فشار قلم (اختیاری)
  final double pressure;

  /// زمان ثبت نقطه (میلی‌ثانیه از ابتدای جلسه)
  final int timestamp;

  /// آیا این نقطه به صورت دلتا (تفاوت نسبت به نقطه قبلی) ذخیره شده است
  final bool isDelta;

  /// سازنده
  const Point({
    required this.x,
    required this.y,
    this.pressure = 1.0,
    this.timestamp = 0,
    this.isDelta = false,
  });

  /// کلون کردن نقطه با مقادیر جدید
  Point copyWith({
    double? x,
    double? y,
    double? pressure,
    int? timestamp,
    bool? isDelta,
  }) {
    return Point(
      x: x ?? this.x,
      y: y ?? this.y,
      pressure: pressure ?? this.pressure,
      timestamp: timestamp ?? this.timestamp,
      isDelta: isDelta ?? this.isDelta,
    );
  }

  /// ایجاد نقطه با مختصات دلتا
  static Point delta(Point previous, Point current) {
    return Point(
      x: current.x - previous.x,
      y: current.y - previous.y,
      pressure: current.pressure,
      timestamp: current.timestamp - previous.timestamp,
      isDelta: true,
    );
  }

  /// تبدیل نقطه دلتا به نقطه مطلق با استفاده از نقطه قبلی
  Point toAbsolute(Point previous) {
    if (!isDelta) return this;

    return Point(
      x: previous.x + x,
      y: previous.y + y,
      pressure: pressure,
      timestamp: previous.timestamp + timestamp,
      isDelta: false,
    );
  }

  /// محاسبه فاصله این نقطه تا نقطه دیگر
  double distanceTo(Point other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return dx * dx + dy * dy; // بدون جذر گرفتن برای بهینه‌سازی
  }

  @override
  String toString() =>
      'Point(x: $x, y: $y, pressure: $pressure, timestamp: $timestamp, isDelta: $isDelta)';

  /// تبدیل متن به نقطه
  static Point? fromString(String str) {
    try {
      final parts = str.split(',');
      if (parts.length >= 2) {
        return Point(
          x: double.parse(parts[0]),
          y: double.parse(parts[1]),
          pressure: parts.length > 2 ? double.parse(parts[2]) : 1.0,
          timestamp: parts.length > 3 ? int.parse(parts[3]) : 0,
          isDelta: parts.length > 4 ? parts[4] == 'true' : false,
        );
      }
    } catch (e) {
      // در صورت خطا نال برمی‌گرداند
    }
    return null;
  }

  /// تبدیل نقطه به متن
  String toCompactString() => '$x,$y,$pressure,$timestamp,$isDelta';
}
