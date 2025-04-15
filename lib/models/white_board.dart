import 'stroke.dart';

/// مدل وایت‌بورد برای نگهداری مجموعه‌ای از خطوط
class WhiteBoard {
  /// شناسه منحصر به فرد وایت‌بورد
  final String id;

  /// نام وایت‌بورد
  final String name;

  /// زمان ایجاد وایت‌بورد
  final DateTime createdAt;

  /// آخرین زمان به‌روزرسانی
  final DateTime updatedAt;

  /// لیست خطوط رسم شده
  final List<Stroke> strokes;

  /// آیا تمام خطوط به صورت دلتا ذخیره شده‌اند
  final bool isDeltaEncoded;

  /// مدت زمان کل جلسه به میلی‌ثانیه
  final int duration;

  /// سازنده
  WhiteBoard({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.strokes,
    this.isDeltaEncoded = false,
    int? duration,
  }) : duration = duration ?? _calculateDuration(strokes);

  /// محاسبه مدت زمان کل وایت‌بورد بر اساس خطوط
  static int _calculateDuration(List<Stroke> strokes) {
    if (strokes.isEmpty) return 0;

    int maxEndTime = 0;
    // شروع با بیشترین مقدار ممکن برای زمان
    int minStartTime = double.maxFinite.toInt(); // مقدار ماکزیمم int

    for (final stroke in strokes) {
      // اگر زمان پایان این استروک از حداکثر زمان بیشتر است، به‌روزرسانی کنیم
      if (stroke.endTime > maxEndTime) {
        maxEndTime = stroke.endTime;
      }

      // اگر زمان شروع این استروک از حداقل زمان کمتر است، به‌روزرسانی کنیم
      if (stroke.startTime < minStartTime) {
        minStartTime = stroke.startTime;
      }
    }

    // جلوگیری از مدت زمان منفی (احتیاطی)
    int duration = maxEndTime - minStartTime;
    return duration > 0 ? duration : maxEndTime;
  }

  /// کلون کردن با مقادیر جدید
  WhiteBoard copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Stroke>? strokes,
    bool? isDeltaEncoded,
    int? duration,
  }) {
    return WhiteBoard(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      strokes: strokes ?? this.strokes,
      isDeltaEncoded: isDeltaEncoded ?? this.isDeltaEncoded,
      duration: duration ?? this.duration,
    );
  }

  /// تابع کپی با اضافه کردن یک خط جدید
  WhiteBoard addStroke(Stroke stroke) {
    final newStrokes = List<Stroke>.from(strokes)..add(stroke);

    // محاسبه مجدد مدت زمان کل به صورت کامل
    final newDuration = _calculateDuration(newStrokes);

    return copyWith(
      strokes: newStrokes,
      updatedAt: DateTime.now(),
      duration: newDuration,
    );
  }

  /// حذف یک خط از وایت‌بورد
  WhiteBoard removeStroke(String strokeId) {
    final newStrokes = strokes.where((s) => s.id != strokeId).toList();

    // محاسبه مجدد مدت زمان کل
    final newDuration = _calculateDuration(newStrokes);

    return copyWith(
      strokes: newStrokes,
      updatedAt: DateTime.now(),
      duration: newDuration,
    );
  }

  /// به‌روزرسانی یک خط موجود
  WhiteBoard updateStroke(Stroke updatedStroke) {
    final newStrokes =
        strokes.map((stroke) {
          if (stroke.id == updatedStroke.id) {
            return updatedStroke;
          }
          return stroke;
        }).toList();

    // محاسبه مجدد مدت زمان کل
    final newDuration = _calculateDuration(newStrokes);

    return copyWith(
      strokes: newStrokes,
      updatedAt: DateTime.now(),
      duration: newDuration,
    );
  }

  /// تبدیل همه خطوط به حالت دلتا برای ذخیره‌سازی
  WhiteBoard toDeltaEncoded() {
    if (isDeltaEncoded) return this;

    final encodedStrokes =
        strokes.map((stroke) => stroke.toDeltaEncoded()).toList();
    return copyWith(strokes: encodedStrokes, isDeltaEncoded: true);
  }

  /// تبدیل همه خطوط به حالت مطلق برای نمایش
  WhiteBoard toAbsoluteEncoded() {
    if (!isDeltaEncoded) return this;

    final decodedStrokes =
        strokes.map((stroke) => stroke.toAbsoluteEncoded()).toList();
    return copyWith(strokes: decodedStrokes, isDeltaEncoded: false);
  }

  /// دریافت وضعیت وایت‌بورد در یک زمان مشخص (برای بازپخش)
  WhiteBoard getStateAtTime(int timestamp) {
    if (strokes.isEmpty) return this;

    // ابتدا به حالت مطلق تبدیل می‌کنیم
    final absoluteBoard = isDeltaEncoded ? toAbsoluteEncoded() : this;

    final visibleStrokes = <Stroke>[];

    for (final stroke in absoluteBoard.strokes) {
      if (stroke.startTime <= timestamp) {
        // خطوطی که قبل از این زمان شروع شده‌اند
        final pointsUntil = stroke.getPointsUntil(timestamp);

        if (pointsUntil.isNotEmpty) {
          visibleStrokes.add(stroke.copyWith(points: pointsUntil));
        }
      }
    }

    return absoluteBoard.copyWith(strokes: visibleStrokes);
  }

  /// دریافت خطوط جدید بین دو زمان (برای بازپخش تدریجی)
  Map<String, Stroke> getStrokesBetween(int startTime, int endTime) {
    if (strokes.isEmpty) return {};

    // ابتدا به حالت مطلق تبدیل می‌کنیم
    final absoluteBoard = isDeltaEncoded ? toAbsoluteEncoded() : this;

    final result = <String, Stroke>{};

    for (final stroke in absoluteBoard.strokes) {
      // اگر خط در محدوده زمانی مورد نظر است
      if (stroke.startTime <= endTime && stroke.endTime >= startTime) {
        final points = stroke.getPointsBetween(startTime, endTime);

        if (points.isNotEmpty) {
          result[stroke.id] = stroke.copyWith(points: points);
        }
      }
    }

    return result;
  }

  @override
  String toString() {
    return 'WhiteBoard(id: $id, name: $name, strokes: ${strokes.length}, duration: $duration ms, deltaEncoded: $isDeltaEncoded)';
  }
}
