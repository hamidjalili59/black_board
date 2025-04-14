import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/point.dart';
import '../models/stroke.dart';
import '../models/stroke_style.dart';
import '../models/white_board.dart';
import 'protobuf_converter.dart';

/// سرویس ذخیره‌سازی محلی Protobuf برای وایت‌بورد
class ProtobufStorageService {
  static final ProtobufStorageService _instance =
      ProtobufStorageService._internal();
  bool _isInitialized = false;
  late Directory _appDirectory;

  // سینگلتون پترن
  factory ProtobufStorageService() {
    return _instance;
  }

  ProtobufStorageService._internal();

  /// راه‌اندازی سرویس ذخیره‌سازی
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (kIsWeb) {
        // روی وب، فایل فیزیکی نداریم
        _isInitialized = true;
        return;
      }

      // دریافت دایرکتوری برنامه
      _appDirectory = await getApplicationDocumentsDirectory();
      final whiteboardDir = Directory('${_appDirectory.path}/whiteboards_pb');

      // اگر دایرکتوری وجود ندارد، آن را ایجاد می‌کنیم
      if (!await whiteboardDir.exists()) {
        await whiteboardDir.create(recursive: true);
      }

      _isInitialized = true;

      debugPrint(
        'Protobuf Storage Service initialized at: ${whiteboardDir.path}',
      );
    } catch (e) {
      debugPrint('Failed to initialize protobuf storage service: $e');
    }
  }

  /// ذخیره وایت‌بورد به صورت Protobuf
  Future<bool> saveWhiteBoard(WhiteBoard whiteBoard) async {
    if (!_isInitialized && !kIsWeb) {
      await initialize();
    }

    try {
      if (kIsWeb) {
        // برای وب، از localStorage استفاده می‌کنیم
        // در این مثال پیاده‌سازی نشده است
        return true;
      }

      final dirPath = '${_appDirectory.path}/whiteboards_pb';
      final dir = Directory(dirPath);

      // اطمینان از وجود دایرکتوری
      if (!await dir.exists()) {
        debugPrint('ایجاد دایرکتوری whiteboards_pb: $dirPath');
        await dir.create(recursive: true);
      }

      final filePath = '$dirPath/${whiteBoard.id}.pb';
      final file = File(filePath);

      debugPrint(
        'ذخیره وایت‌بورد با شناسه ${whiteBoard.id} به صورت Protobuf در مسیر: $filePath',
      );
      debugPrint('تعداد خطوط: ${whiteBoard.strokes.length}');

      // بهینه‌سازی نقاط قبل از تبدیل به Protobuf
      final optimizedWhiteBoard = _optimizeWhiteBoard(whiteBoard);

      // تبدیل به Protobuf و ذخیره
      final bytes = ProtobufConverter.modelToBytes(optimizedWhiteBoard);
      debugPrint('اندازه فایل Protobuf: ${bytes.length} بایت');

      await file.writeAsBytes(bytes, flush: true);

      debugPrint(
        'وایت‌بورد با موفقیت به صورت Protobuf ذخیره شد در: ${file.path}',
      );
      return true;
    } catch (e, stackTrace) {
      debugPrint('خطا در ذخیره وایت‌بورد به صورت Protobuf: $e');
      debugPrint('جزئیات خطا: $stackTrace');
      return false;
    }
  }

  /// بارگیری وایت‌بورد از فایل Protobuf
  Future<WhiteBoard?> loadWhiteBoard(String id) async {
    if (!_isInitialized && !kIsWeb) {
      await initialize();
    }

    try {
      if (kIsWeb) {
        // برای وب، از localStorage استفاده می‌کنیم
        // در این مثال پیاده‌سازی نشده است
        return null;
      }

      final filePath = '${_appDirectory.path}/whiteboards_pb/$id.pb';
      final file = File(filePath);

      debugPrint('تلاش برای خواندن وایت‌بورد از فایل Protobuf: $filePath');

      if (!await file.exists()) {
        debugPrint('فایل Protobuf وایت‌بورد یافت نشد: $filePath');
        return null;
      }

      debugPrint('فایل Protobuf وایت‌بورد یافت شد. در حال خواندن...');
      final bytes = await file.readAsBytes();
      debugPrint('اندازه فایل Protobuf: ${bytes.length} بایت');

      final whiteBoard = ProtobufConverter.bytesToModel(bytes);
      debugPrint('وایت‌بورد با موفقیت از Protobuf بارگیری شد.');
      debugPrint('تعداد خطوط بارگیری شده: ${whiteBoard.strokes.length}');

      // اگر داده‌ها بهینه‌سازی شده بودند، باید به حالت اصلی برگردند
      final decompressedWhiteBoard = _decompressWhiteBoard(whiteBoard);

      return decompressedWhiteBoard;
    } catch (e, stackTrace) {
      debugPrint('خطا در بارگیری وایت‌بورد از Protobuf: $e');
      debugPrint('جزئیات خطا: $stackTrace');
      return null;
    }
  }

  /// دریافت لیست وایت‌بوردهای ذخیره شده
  Future<List<String>> getWhiteBoardIds() async {
    if (!_isInitialized && !kIsWeb) {
      await initialize();
    }

    try {
      if (kIsWeb) {
        // برای وب، از localStorage استفاده می‌کنیم
        // در این مثال پیاده‌سازی نشده است
        return [];
      }

      final dirPath = '${_appDirectory.path}/whiteboards_pb';
      final dir = Directory(dirPath);

      debugPrint(
        'تلاش برای خواندن لیست وایت‌بوردهای Protobuf از مسیر: $dirPath',
      );

      if (!await dir.exists()) {
        debugPrint('دایرکتوری وایت‌بوردهای Protobuf وجود ندارد: $dirPath');
        return [];
      }

      final files = await dir.list().toList();
      debugPrint('تعداد فایل‌های Protobuf یافت شده: ${files.length}');

      // لاگ مسیر تمام فایل‌ها
      for (var file in files) {
        debugPrint(
          'فایل Protobuf یافت شده: ${file.path}, نوع: ${file is File ? "File" : "Directory"}',
        );
      }

      // استخراج شناسه‌ها از نام فایل‌ها
      final ids =
          files
              .where((entity) => entity is File && entity.path.endsWith('.pb'))
              .map((file) {
                // استفاده از Platform.pathSeparator برای سازگاری با همه سیستم‌عامل‌ها
                final pathParts = file.path.split(Platform.pathSeparator);
                final fileName =
                    pathParts.isNotEmpty
                        ? pathParts.last
                        : file.path.split('/').last;
                final id = fileName.substring(
                  0,
                  fileName.length - 3,
                ); // حذف پسوند .pb
                debugPrint(
                  'شناسه Protobuf استخراج شده: $id از فایل: $fileName',
                );
                return id;
              })
              .toList();

      debugPrint('تعداد شناسه‌های Protobuf استخراج شده: ${ids.length}');
      return ids;
    } catch (e, stackTrace) {
      debugPrint('خطا در دریافت لیست وایت‌بوردهای Protobuf: $e');
      debugPrint('جزئیات خطا: $stackTrace');
      return [];
    }
  }

  /// بهینه‌سازی وایت‌بورد قبل از ذخیره‌سازی
  WhiteBoard _optimizeWhiteBoard(WhiteBoard whiteBoard) {
    // ایجاد لیست جدید از خطوط با نقاط فشرده شده
    final optimizedStrokes =
        whiteBoard.strokes.map((stroke) {
          final compressedPoints = ProtobufConverter.compressPoints(
            stroke.points,
          );
          return Stroke(
            id: stroke.id,
            points: compressedPoints,
            style: stroke.style,
            startTime: stroke.startTime,
          );
        }).toList();

    return WhiteBoard(
      id: whiteBoard.id,
      name: whiteBoard.name,
      createdAt: whiteBoard.createdAt,
      updatedAt: whiteBoard.updatedAt,
      strokes: optimizedStrokes,
    );
  }

  /// بازگرداندن وایت‌بورد بهینه‌سازی شده به حالت اصلی
  WhiteBoard _decompressWhiteBoard(WhiteBoard whiteBoard) {
    // ایجاد لیست جدید از خطوط با نقاط اصلی
    final decompressedStrokes =
        whiteBoard.strokes.map((stroke) {
          final decompressedPoints = ProtobufConverter.decompressPoints(
            stroke.points,
          );
          return Stroke(
            id: stroke.id,
            points: decompressedPoints,
            style: stroke.style,
            startTime: stroke.startTime,
          );
        }).toList();

    return WhiteBoard(
      id: whiteBoard.id,
      name: whiteBoard.name,
      createdAt: whiteBoard.createdAt,
      updatedAt: whiteBoard.updatedAt,
      strokes: decompressedStrokes,
    );
  }
}
