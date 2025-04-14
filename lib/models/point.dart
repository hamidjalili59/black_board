/// مدل نقطه برای ذخیره مختصات و فشار قلم
class Point {
  /// موقعیت افقی نقطه
  final double x;

  /// موقعیت عمودی نقطه
  final double y;

  /// میزان فشار قلم (اختیاری)
  final double pressure;

  /// سازنده
  const Point({required this.x, required this.y, this.pressure = 1.0});

  /// کلون کردن نقطه با مقادیر جدید
  Point copyWith({double? x, double? y, double? pressure}) {
    return Point(
      x: x ?? this.x,
      y: y ?? this.y,
      pressure: pressure ?? this.pressure,
    );
  }

  /// محاسبه فاصله این نقطه تا نقطه دیگر
  double distanceTo(Point other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return dx * dx + dy * dy; // بدون جذر گرفتن برای بهینه‌سازی
  }

  @override
  String toString() => 'Point(x: $x, y: $y, pressure: $pressure)';

  /// تبدیل متن به نقطه
  static Point? fromString(String str) {
    try {
      final parts = str.split(',');
      if (parts.length >= 2) {
        return Point(
          x: double.parse(parts[0]),
          y: double.parse(parts[1]),
          pressure: parts.length > 2 ? double.parse(parts[2]) : 1.0,
        );
      }
    } catch (e) {
      // در صورت خطا نال برمی‌گرداند
    }
    return null;
  }

  /// تبدیل نقطه به متن
  String toCompactString() => '$x,$y,$pressure';
}
