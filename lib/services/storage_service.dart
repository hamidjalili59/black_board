import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/drawing_model.dart';

/// سرویس ذخیره‌سازی محلی برای وایت‌بورد
class StorageService {
  static final StorageService _instance = StorageService._internal();
  bool _isInitialized = false;
  late Directory _appDirectory;

  // سینگلتون پترن
  factory StorageService() {
    return _instance;
  }

  StorageService._internal();

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
      final whiteboardDir = Directory('${_appDirectory.path}/whiteboards');

      // اگر دایرکتوری وجود ندارد، آن را ایجاد می‌کنیم
      if (!await whiteboardDir.exists()) {
        await whiteboardDir.create(recursive: true);
      }

      _isInitialized = true;

      debugPrint('Storage Service initialized at: ${whiteboardDir.path}');
    } catch (e) {
      debugPrint('Failed to initialize storage service: $e');
    }
  }

  /// ذخیره وایت‌بورد به صورت محلی
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

      final dirPath = '${_appDirectory.path}/whiteboards';
      final dir = Directory(dirPath);

      // اطمینان از وجود دایرکتوری
      if (!await dir.exists()) {
        debugPrint('ایجاد دایرکتوری whiteboards: $dirPath');
        await dir.create(recursive: true);
      }

      final filePath = '$dirPath/${whiteBoard.id}.json';
      final file = File(filePath);

      debugPrint(
        'ذخیره وایت‌بورد با شناسه ${whiteBoard.id} در مسیر: $filePath',
      );
      debugPrint('تعداد خطوط: ${whiteBoard.strokes.length}');

      final jsonData = jsonEncode(whiteBoard.toJson());
      debugPrint('داده JSON ایجاد شد با طول: ${jsonData.length}');

      await file.writeAsString(jsonData, flush: true);

      debugPrint('وایت‌بورد با موفقیت ذخیره شد در: ${file.path}');
      return true;
    } catch (e, stackTrace) {
      debugPrint('خطا در ذخیره وایت‌بورد: $e');
      debugPrint('جزئیات خطا: $stackTrace');
      return false;
    }
  }

  /// بارگیری وایت‌بورد از حافظه محلی
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

      final filePath = '${_appDirectory.path}/whiteboards/$id.json';
      final file = File(filePath);

      debugPrint('تلاش برای خواندن وایت‌بورد از مسیر: $filePath');

      if (!await file.exists()) {
        debugPrint('فایل وایت‌بورد پیدا نشد: $filePath');
        return null;
      }

      debugPrint('فایل وایت‌بورد یافت شد. در حال خواندن...');
      final jsonData = await file.readAsString();
      debugPrint(
        'محتوای JSON خوانده شد: ${jsonData.substring(0, min(100, jsonData.length))}...',
      ); // نمایش 100 کاراکتر اول

      final json = jsonDecode(jsonData);
      debugPrint('تبدیل JSON به Map انجام شد.');

      final whiteboard = WhiteBoard.fromJson(json);
      debugPrint('تبدیل JSON به WhiteBoard با موفقیت انجام شد.');
      debugPrint('تعداد خطوط بارگذاری شده: ${whiteboard.strokes.length}');

      return whiteboard;
    } catch (e, stackTrace) {
      debugPrint('خطا در بارگیری وایت‌بورد: $e');
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

      final dirPath = '${_appDirectory.path}/whiteboards';
      final dir = Directory(dirPath);

      debugPrint('تلاش برای خواندن لیست وایت‌بوردها از مسیر: $dirPath');

      if (!await dir.exists()) {
        debugPrint('دایرکتوری وایت‌بوردها وجود ندارد: $dirPath');
        return [];
      }

      final files = await dir.list().toList();
      debugPrint('تعداد فایل‌های یافت شده: ${files.length}');

      // لاگ مسیر تمام فایل‌ها
      for (var file in files) {
        debugPrint(
          'فایل یافت شده: ${file.path}, نوع: ${file is File ? "File" : "Directory"}',
        );
      }

      // استخراج شناسه‌ها از نام فایل‌ها
      final ids =
          files
              .where(
                (entity) => entity is File && entity.path.endsWith('.json'),
              )
              .map((file) {
                // استفاده از Platform.pathSeparator برای سازگاری با همه سیستم‌عامل‌ها
                final pathParts = file.path.split(Platform.pathSeparator);
                final fileName =
                    pathParts.isNotEmpty
                        ? pathParts.last
                        : file.path.split('/').last;
                final id = fileName.substring(
                  0,
                  fileName.length - 5,
                ); // حذف پسوند .json
                debugPrint('شناسه استخراج شده: $id از فایل: $fileName');
                return id;
              })
              .toList();

      debugPrint('تعداد شناسه‌های استخراج شده: ${ids.length}');
      return ids;
    } catch (e, stackTrace) {
      debugPrint('خطا در دریافت لیست وایت‌بوردها: $e');
      debugPrint('جزئیات خطا: $stackTrace');
      return [];
    }
  }

  /// حذف وایت‌بورد از حافظه محلی
  Future<bool> deleteWhiteBoard(String id) async {
    if (!_isInitialized && !kIsWeb) {
      await initialize();
    }

    try {
      if (kIsWeb) {
        // برای وب، از localStorage استفاده می‌کنیم
        // در این مثال پیاده‌سازی نشده است
        return true;
      }

      final file = File('${_appDirectory.path}/whiteboards/$id.json');

      if (!await file.exists()) {
        return false;
      }

      await file.delete();

      return true;
    } catch (e) {
      debugPrint('Failed to delete whiteboard: $e');
      return false;
    }
  }
}
