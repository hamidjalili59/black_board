import 'dart:ui';

/// استایل خط برای تعیین نحوه نمایش خط
class StrokeStyle {
  /// رنگ خط
  final Color color;

  /// ضخامت خط
  final double thickness;

  /// آیا خط دارای سایه است
  final bool hasShadow;

  /// شفافیت خط (۰ تا ۱)
  final double opacity;

  /// نوع خط (نقطه‌چین، خط‌چین و غیره)
  final StrokeType type;

  /// سازنده
  const StrokeStyle({
    this.color = const Color(0xFF000000),
    this.thickness = 2.0,
    this.hasShadow = false,
    this.opacity = 1.0,
    this.type = StrokeType.solid,
  });

  /// کلون کردن استایل با مقادیر جدید
  StrokeStyle copyWith({
    Color? color,
    double? thickness,
    bool? hasShadow,
    double? opacity,
    StrokeType? type,
  }) {
    return StrokeStyle(
      color: color ?? this.color,
      thickness: thickness ?? this.thickness,
      hasShadow: hasShadow ?? this.hasShadow,
      opacity: opacity ?? this.opacity,
      type: type ?? this.type,
    );
  }

  @override
  String toString() {
    return 'StrokeStyle(color: $color, thickness: $thickness, hasShadow: $hasShadow, opacity: $opacity, type: $type)';
  }
}

/// انواع خطوط قابل رسم
enum StrokeType {
  /// خط ساده
  solid,

  /// خط‌چین
  dashed,

  /// نقطه‌چین
  dotted,

  /// خط مواج
  wavy,
}
