import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/white_board.dart';
import '../models/stroke.dart';
import '../models/point.dart';
import '../models/stroke_style.dart';
import '../services/protobuf_storage.dart';

/// Provider مدیریت وایت‌بورد با استفاده از Protobuf
class ProtobufWhiteBoardProvider extends ChangeNotifier {
  // وایت‌بورد فعلی
  WhiteBoard? _whiteBoard;
  // خط در حال رسم
  Stroke? _currentStroke;
  // وضعیت بارگذاری
  bool _isLoading = false;
  // وضعیت ذخیره
  bool _isSaving = false;
  // لیست شناسه‌های ذخیره شده
  List<String> _savedWhiteBoardIds = [];

  // تنظیمات قلم
  StrokeStyle _strokeStyle = const StrokeStyle(
    color: Colors.black,
    thickness: 2.0,
    type: StrokeType.solid,
  );

  // گترها
  WhiteBoard? get whiteBoard => _whiteBoard;
  Stroke? get currentStroke => _currentStroke;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  List<String> get savedWhiteBoardIds => _savedWhiteBoardIds;
  StrokeStyle get strokeStyle => _strokeStyle;

  // ستر برای تنظیمات قلم
  set strokeStyle(StrokeStyle style) {
    _strokeStyle = style;
    notifyListeners();
  }

  // تغییر ضخامت قلم
  void setThickness(double thickness) {
    _strokeStyle = _strokeStyle.copyWith(thickness: thickness);
    notifyListeners();
  }

  // تغییر رنگ قلم
  void setColor(Color color) {
    _strokeStyle = _strokeStyle.copyWith(color: color);
    notifyListeners();
  }

  // تغییر نوع قلم
  void setStrokeType(StrokeType type) {
    _strokeStyle = _strokeStyle.copyWith(type: type);
    notifyListeners();
  }

  // ایجاد وایت‌بورد جدید
  void createNewWhiteBoard({String? name}) {
    _whiteBoard = WhiteBoard(
      id: const Uuid().v4(),
      name: name ?? 'وایت‌بورد جدید',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      strokes: [],
    );
    notifyListeners();
  }

  // پاک کردن وایت‌بورد فعلی
  void clearWhiteBoard() {
    if (_whiteBoard != null) {
      _whiteBoard = _whiteBoard!.copyWith(
        strokes: [],
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  // شروع کشیدن خط
  void startStroke(Offset position) {
    if (_whiteBoard == null) {
      createNewWhiteBoard();
    }

    final point = Point(x: position.dx, y: position.dy, pressure: 1.0);

    _currentStroke = Stroke(
      id: const Uuid().v4(),
      points: [point],
      startTime: DateTime.now().millisecondsSinceEpoch,
      style: _strokeStyle,
    );

    notifyListeners();
  }

  // به‌روزرسانی خط در حال کشیدن
  void updateStroke(Offset position) {
    if (_currentStroke == null) return;

    final point = Point(x: position.dx, y: position.dy, pressure: 1.0);

    _currentStroke = _currentStroke!.copyWith(
      points: [..._currentStroke!.points, point],
    );

    notifyListeners();
  }

  // پایان کشیدن خط
  void endStroke() {
    if (_whiteBoard == null || _currentStroke == null) return;

    // اضافه کردن خط به وایت‌بورد
    _whiteBoard = _whiteBoard!.copyWith(
      strokes: [..._whiteBoard!.strokes, _currentStroke!],
      updatedAt: DateTime.now(),
    );

    // پاک کردن خط جاری
    _currentStroke = null;

    notifyListeners();
  }

  // برگشت آخرین خط (Undo)
  void undoLastStroke() {
    if (_whiteBoard == null || _whiteBoard!.strokes.isEmpty) return;

    final strokes = List<Stroke>.from(_whiteBoard!.strokes);
    strokes.removeLast();

    _whiteBoard = _whiteBoard!.copyWith(
      strokes: strokes,
      updatedAt: DateTime.now(),
    );

    notifyListeners();
  }

  // ذخیره وایت‌بورد فعلی
  Future<bool> saveCurrentWhiteBoard() async {
    if (_whiteBoard == null) return false;

    _isSaving = true;
    notifyListeners();

    try {
      final result = await ProtobufStorage.saveWhiteBoard(_whiteBoard!);
      return result;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // بارگیری وایت‌بورد
  Future<void> loadWhiteBoard(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final loadedWhiteBoard = await ProtobufStorage.loadWhiteBoard(id);
      _whiteBoard = loadedWhiteBoard;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // دریافت لیست وایت‌بوردها
  Future<void> loadSavedWhiteBoardIds() async {
    _isLoading = true;
    notifyListeners();

    try {
      _savedWhiteBoardIds = await ProtobufStorage.getSavedWhiteBoardIds();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
