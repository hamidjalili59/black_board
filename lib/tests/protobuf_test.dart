import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/point.dart';
import '../models/stroke.dart';
import '../models/stroke_style.dart';
import '../models/white_board.dart';
import '../services/protobuf_storage.dart';
import '../services/proto_buffer_serializer.dart';

/// نمونه تست برای بررسی عملکرد ذخیره‌سازی Protobuf
Future<void> testProtobufConversion() async {
  debugPrint('=== شروع تست تبدیل Protobuf ===');

  // 1. ایجاد یک وایت‌بورد نمونه
  final whiteBoard = WhiteBoard(
    id: 'test-board-1',
    name: 'وایت‌بورد تست',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    strokes: [
      Stroke(
        id: 'stroke-1',
        points: [
          Point(x: 10, y: 20, pressure: 1.0),
          Point(x: 30, y: 40, pressure: 0.8),
          Point(x: 50, y: 60, pressure: 0.6),
        ],
        startTime: DateTime.now().millisecondsSinceEpoch,
        style: StrokeStyle(
          color: Colors.red,
          thickness: 2.0,
          type: StrokeType.solid,
        ),
      ),
      Stroke(
        id: 'stroke-2',
        points: [
          Point(x: 100, y: 200, pressure: 0.9),
          Point(x: 300, y: 400, pressure: 0.7),
        ],
        startTime: DateTime.now().millisecondsSinceEpoch,
        style: StrokeStyle(
          color: Colors.blue,
          thickness: 3.0,
          type: StrokeType.dotted,
        ),
      ),
    ],
  );

  debugPrint('وایت‌بورد نمونه ایجاد شد با ${whiteBoard.strokes.length} خط');

  // 2. تبدیل به Protobuf (روش جدید)
  final bytesNew = ProtobufSerializer.serializeWhiteBoard(whiteBoard);
  debugPrint(
    'تبدیل به Protobuf با سریالایزر جدید انجام شد. اندازه: ${bytesNew.length} بایت',
  );

  // 3. ذخیره در فایل
  final result = await ProtobufStorage.saveWhiteBoard(whiteBoard);
  debugPrint('ذخیره در فایل: ${result ? "موفق" : "ناموفق"}');

  // 4. بازیابی از Protobuf (روش جدید)
  final recoveredWhiteBoardNew = ProtobufSerializer.deserializeWhiteBoard(
    bytesNew,
  );
  debugPrint('بازیابی از Protobuf با سریالایزر جدید انجام شد');

  // 5. بازیابی از فایل
  final loadedWhiteBoard = await ProtobufStorage.loadWhiteBoard(whiteBoard.id);
  debugPrint(
    'بازیابی از فایل: ${loadedWhiteBoard != null ? "موفق" : "ناموفق"}',
  );

  // 6. بررسی نتایج
  debugPrint('=== مقایسه نتایج ===');
  debugPrint('شناسه وایت‌بورد اصلی: ${whiteBoard.id}');
  debugPrint(
    'شناسه وایت‌بورد بازیابی شده (سریالایزر): ${recoveredWhiteBoardNew.id}',
  );
  if (loadedWhiteBoard != null) {
    debugPrint('شناسه وایت‌بورد بازیابی شده (فایل): ${loadedWhiteBoard.id}');
  }

  debugPrint('نام وایت‌بورد اصلی: ${whiteBoard.name}');
  debugPrint(
    'نام وایت‌بورد بازیابی شده (سریالایزر): ${recoveredWhiteBoardNew.name}',
  );
  if (loadedWhiteBoard != null) {
    debugPrint('نام وایت‌بورد بازیابی شده (فایل): ${loadedWhiteBoard.name}');
  }

  debugPrint('تعداد خطوط اصلی: ${whiteBoard.strokes.length}');
  debugPrint(
    'تعداد خطوط بازیابی شده (سریالایزر): ${recoveredWhiteBoardNew.strokes.length}',
  );
  if (loadedWhiteBoard != null) {
    debugPrint(
      'تعداد خطوط بازیابی شده (فایل): ${loadedWhiteBoard.strokes.length}',
    );
  }

  // 7. بررسی لیست شناسه‌ها
  final ids = await ProtobufStorage.getSavedWhiteBoardIds();
  debugPrint('تعداد شناسه‌های ذخیره شده: ${ids.length}');
  debugPrint('شناسه‌ها: $ids');

  debugPrint('=== پایان تست تبدیل Protobuf ===');
}

/// تابع اصلی برای اجرای تست
void runProtobufTest() {
  testProtobufConversion();
}
