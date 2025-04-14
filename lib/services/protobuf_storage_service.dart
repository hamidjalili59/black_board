import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/stroke.dart';
import '../models/white_board.dart';
import 'protobuf_converter.dart';
import 'proto_buffer_serializer.dart';

/// سرویس ذخیره‌سازی محلی Protobuf برای وایت‌بورد
class ProtobufStorageService {
  static final ProtobufStorageService _instance =
      ProtobufStorageService._internal();
  bool _isInitialized = false;
  late Directory _appDirectory;
  static const String _fileExtension = '.pbwb'; // پسوند فایل پروتوباف وایت‌بورد
  static const String _whiteboardsDir = 'whiteboards'; // دایرکتوری ذخیره‌سازی

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
      final whiteboardDir = Directory('${_appDirectory.path}/$_whiteboardsDir');

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

  /// دریافت مسیر دایرکتوری ذخیره‌سازی
  Future<Directory> get _storageDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final whiteboardsDir = Directory('${appDir.path}/$_whiteboardsDir');

    if (!await whiteboardsDir.exists()) {
      await whiteboardsDir.create(recursive: true);
    }

    return whiteboardsDir;
  }

  /// ذخیره وایت‌بورد
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

      final storageDir = await _storageDirectory;
      final file = File('${storageDir.path}/${whiteBoard.id}$_fileExtension');

      // سریالایز کردن به پروتوباف
      final bytes = ProtobufSerializer.serializeWhiteBoard(whiteBoard);

      // ذخیره در فایل
      await file.writeAsBytes(bytes);

      debugPrint(
        'وایت‌بورد با شناسه ${whiteBoard.id} با موفقیت ذخیره شد. '
        'اندازه: ${bytes.length} بایت',
      );

      return true;
    } catch (e) {
      debugPrint('خطا در ذخیره‌سازی وایت‌بورد: $e');
      return false;
    }
  }

  /// بارگیری وایت‌بورد با شناسه
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

      final storageDir = await _storageDirectory;
      final file = File('${storageDir.path}/$id$_fileExtension');

      if (!await file.exists()) {
        debugPrint('فایل وایت‌بورد با شناسه $id یافت نشد.');
        return null;
      }

      // خواندن بایت‌ها از فایل
      final bytes = await file.readAsBytes();

      // دسریالایز کردن از پروتوباف
      final whiteBoard = ProtobufSerializer.deserializeWhiteBoard(bytes);

      debugPrint(
        'وایت‌بورد با شناسه $id با موفقیت بارگیری شد. '
        'تعداد خطوط: ${whiteBoard.strokes.length}',
      );

      return whiteBoard;
    } catch (e) {
      debugPrint('خطا در بارگیری وایت‌بورد: $e');
      return null;
    }
  }

  /// دریافت فهرست شناسه‌های وایت‌بوردهای ذخیره شده
  Future<List<String>> getSavedWhiteBoardIds() async {
    if (!_isInitialized && !kIsWeb) {
      await initialize();
    }

    try {
      if (kIsWeb) {
        // برای وب، از localStorage استفاده می‌کنیم
        // در این مثال پیاده‌سازی نشده است
        return [];
      }

      final storageDir = await _storageDirectory;
      final List<FileSystemEntity> files = await storageDir.list().toList();

      // فیلتر کردن فایل‌ها بر اساس پسوند و استخراج شناسه‌ها
      final ids =
          files
              .whereType<File>()
              .where((file) => file.path.endsWith(_fileExtension))
              .map((file) {
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
  Future<bool> deleteWhiteBoard(String id) async {
    if (!_isInitialized && !kIsWeb) {
      await initialize();
    }

    try {
      if (kIsWeb) {
        // برای وب، از localStorage استفاده می‌کنیم
        // در این مثال پیاده‌سازی نشده است
        return false;
      }

      final storageDir = await _storageDirectory;
      final file = File('${storageDir.path}/$id$_fileExtension');

      if (!await file.exists()) {
        debugPrint('فایل وایت‌بورد با شناسه $id برای حذف یافت نشد.');
        return false;
      }

      await file.delete();
      debugPrint('وایت‌بورد با شناسه $id با موفقیت حذف شد.');
      return true;
    } catch (e) {
      debugPrint('خطا در حذف وایت‌بورد: $e');
      return false;
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
