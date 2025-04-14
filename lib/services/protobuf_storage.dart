import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/white_board.dart';
import '../models/point.dart';
import 'proto_buffer_serializer.dart';

/// سرویس ذخیره‌سازی محلی Protobuf برای وایت‌بورد
class ProtobufStorage {
  static const String _fileExtension = '.pbwb'; // پسوند فایل پروتوباف وایت‌بورد
  static const String _whiteboardsDir = 'whiteboards'; // دایرکتوری ذخیره‌سازی
  static const bool _useCompression = true; // آیا داده‌ها فشرده شوند
  static const double _optimizationDistance =
      2.0; // فاصله حداقل بین نقاط (پیکسل)

  /// دریافت مسیر دایرکتوری ذخیره‌سازی
  static Future<Directory> get _storageDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final whiteboardsDir = Directory('${appDir.path}/$_whiteboardsDir');

    if (!await whiteboardsDir.exists()) {
      await whiteboardsDir.create(recursive: true);
    }

    return whiteboardsDir;
  }

  /// ذخیره وایت‌بورد
  static Future<bool> saveWhiteBoard(WhiteBoard whiteBoard) async {
    try {
      final storageDir = await _storageDirectory;
      final file = File(
        '${storageDir.path}${Platform.pathSeparator}${whiteBoard.id}$_fileExtension',
      );

      // بهینه‌سازی وایت‌بورد برای کاهش حجم
      final optimizedWhiteBoard = _optimizeWhiteBoard(whiteBoard);

      // سریالایز کردن به پروتوباف
      final bytes = ProtobufSerializer.serializeWhiteBoard(optimizedWhiteBoard);

      // فشرده‌سازی داده‌ها اگر فعال باشد
      final finalBytes = _useCompression ? _compressData(bytes) : bytes;

      // ذخیره در فایل
      await file.writeAsBytes(finalBytes);

      debugPrint(
        'وایت‌بورد با شناسه ${whiteBoard.id} با موفقیت ذخیره شد. '
        'اندازه اصلی: ${bytes.length} بایت، '
        'اندازه نهایی: ${finalBytes.length} بایت، '
        'نسبت فشرده‌سازی: ${(100 - (finalBytes.length * 100 / bytes.length)).toStringAsFixed(1)}%',
      );

      return true;
    } catch (e) {
      debugPrint('خطا در ذخیره‌سازی وایت‌بورد: $e');
      return false;
    }
  }

  /// بارگیری وایت‌بورد با شناسه
  static Future<WhiteBoard?> loadWhiteBoard(String id) async {
    try {
      final storageDir = await _storageDirectory;

      // حذف مسیر و دایرکتوری از id در صورت وجود
      final cleanId = id.split(Platform.pathSeparator).last.split('/').last;

      final file = File(
        '${storageDir.path}${Platform.pathSeparator}$cleanId$_fileExtension',
      );

      if (!await file.exists()) {
        debugPrint('فایل وایت‌بورد با شناسه $cleanId یافت نشد.');
        return null;
      }

      // خواندن بایت‌ها از فایل
      final bytes = await file.readAsBytes();

      // بررسی و فشرده‌گشایی داده‌ها در صورت لزوم
      final decompressedBytes = _tryDecompressData(bytes);

      // دسریالایز کردن از پروتوباف
      final whiteBoard = ProtobufSerializer.deserializeWhiteBoard(
        decompressedBytes,
      );

      debugPrint(
        'وایت‌بورد با شناسه $cleanId با موفقیت بارگیری شد. '
        'تعداد خطوط: ${whiteBoard.strokes.length}',
      );

      return whiteBoard;
    } catch (e) {
      debugPrint('خطا در بارگیری وایت‌بورد: $e');
      return null;
    }
  }

  /// دریافت فهرست شناسه‌های وایت‌بوردهای ذخیره شده
  static Future<List<String>> getSavedWhiteBoardIds() async {
    try {
      final storageDir = await _storageDirectory;
      final List<FileSystemEntity> files = await storageDir.list().toList();

      // فیلتر کردن فایل‌ها بر اساس پسوند و استخراج شناسه‌ها
      final ids =
          files
              .whereType<File>()
              .where((file) => file.path.endsWith(_fileExtension))
              .map((file) {
                // استفاده از basename برای استخراج نام فایل بدون وابستگی به پلتفرم
                final fileName = file.path.split(Platform.pathSeparator).last;
                return fileName.substring(
                  0,
                  fileName.length - _fileExtension.length,
                );
              })
              .toList();

      debugPrint('تعداد ${ids.length} وایت‌بورد ذخیره شده یافت شد.');
      return ids;
    } catch (e) {
      debugPrint('خطا در دریافت لیست وایت‌بوردها: $e');
      return [];
    }
  }

  /// حذف وایت‌بورد با شناسه
  static Future<bool> deleteWhiteBoard(String id) async {
    try {
      final storageDir = await _storageDirectory;

      // حذف مسیر و دایرکتوری از id در صورت وجود
      final cleanId = id.split(Platform.pathSeparator).last.split('/').last;

      final file = File(
        '${storageDir.path}${Platform.pathSeparator}$cleanId$_fileExtension',
      );

      if (!await file.exists()) {
        debugPrint('فایل وایت‌بورد با شناسه $cleanId برای حذف یافت نشد.');
        return false;
      }

      await file.delete();
      debugPrint('وایت‌بورد با شناسه $cleanId با موفقیت حذف شد.');
      return true;
    } catch (e) {
      debugPrint('خطا در حذف وایت‌بورد: $e');
      return false;
    }
  }

  /// بهینه‌سازی وایت‌بورد با کاهش تعداد نقاط و حذف نقاط زائد
  static WhiteBoard _optimizeWhiteBoard(WhiteBoard whiteBoard) {
    // ایجاد لیست جدید خطوط
    final optimizedStrokes =
        whiteBoard.strokes.map((stroke) {
          // اگر کمتر از 3 نقطه دارد، احتمالاً بهینه‌سازی مفید نیست
          if (stroke.points.length < 3) {
            return stroke;
          }

          // بهینه‌سازی نقاط با حذف نقاط زائد
          final optimizedPoints = _simplifyPoints(stroke.points);

          // اگر نقاط کمتر از 30% کاهش یافته، بهینه‌سازی مفید نبوده
          if (optimizedPoints.length > stroke.points.length * 0.7) {
            return stroke;
          }

          // بازگرداندن خط با نقاط بهینه‌شده
          return stroke.copyWith(points: optimizedPoints);
        }).toList();

    // بازگرداندن وایت‌بورد با خطوط بهینه‌شده
    return whiteBoard.copyWith(strokes: optimizedStrokes);
  }

  /// ساده‌سازی نقاط خط با حذف نقاط زائد (الگوریتم Douglas-Peucker ساده‌شده)
  static List<Point> _simplifyPoints(List<Point> points) {
    if (points.length <= 2) {
      return List.from(points);
    }

    // ایجاد لیست نقاط بهینه‌شده با نگه داشتن نقطه اول
    final result = <Point>[points.first];
    Point prevPoint = points.first;

    // بررسی سایر نقاط
    for (int i = 1; i < points.length - 1; i++) {
      final currentPoint = points[i];

      // محاسبه فاصله با نقطه قبلی
      final distance = _getDistanceBetweenPoints(prevPoint, currentPoint);

      // اگر فاصله کافی باشد، این نقطه را نگه می‌داریم
      if (distance >= _optimizationDistance) {
        result.add(currentPoint);
        prevPoint = currentPoint;
      }
    }

    // همیشه نقطه آخر را نگه می‌داریم
    result.add(points.last);

    return result;
  }

  /// محاسبه فاصله بین دو نقطه
  static double _getDistanceBetweenPoints(Point p1, Point p2) {
    final dx = p1.x - p2.x;
    final dy = p1.y - p2.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// فشرده‌سازی داده‌ها با استفاده از GZIP
  static Uint8List _compressData(List<int> data) {
    final compressedData = GZipEncoder().encode(data) ?? data;
    return Uint8List.fromList(compressedData);
  }

  /// تلاش برای فشرده‌گشایی داده‌ها
  static Uint8List _tryDecompressData(Uint8List data) {
    try {
      // بررسی هدر GZIP (شناسایی داده‌های فشرده)
      if (data.length > 2 && data[0] == 0x1F && data[1] == 0x8B) {
        final decompressedData = GZipDecoder().decodeBytes(data);
        return Uint8List.fromList(decompressedData);
      }
    } catch (e) {
      debugPrint('خطا در فشرده‌گشایی داده‌ها: $e - بازگشت به داده‌های اصلی');
    }

    // اگر مشکلی در فشرده‌گشایی بود یا داده‌ها فشرده نبودند، داده‌های اصلی را برمی‌گردانیم
    return data;
  }
}
