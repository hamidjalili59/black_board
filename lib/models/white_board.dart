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

  /// سازنده
  const WhiteBoard({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.strokes,
  });

  /// کلون کردن با مقادیر جدید
  WhiteBoard copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Stroke>? strokes,
  }) {
    return WhiteBoard(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      strokes: strokes ?? this.strokes,
    );
  }

  /// تابع کپی با اضافه کردن یک خط جدید
  WhiteBoard addStroke(Stroke stroke) {
    final newStrokes = List<Stroke>.from(strokes)..add(stroke);
    return copyWith(strokes: newStrokes, updatedAt: DateTime.now());
  }

  /// حذف یک خط از وایت‌بورد
  WhiteBoard removeStroke(String strokeId) {
    final newStrokes = strokes.where((s) => s.id != strokeId).toList();
    return copyWith(strokes: newStrokes, updatedAt: DateTime.now());
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

    return copyWith(strokes: newStrokes, updatedAt: DateTime.now());
  }

  @override
  String toString() {
    return 'WhiteBoard(id: $id, name: $name, strokes: ${strokes.length})';
  }
}
