import 'package:flutter/material.dart';
import '../models/drawing_model.dart' as drawing;
import '../services/storage_service.dart';
import '../services/grpc_service.dart';
import 'package:uuid/uuid.dart';
import '../models/white_board.dart';
import '../models/stroke.dart';
import '../models/point.dart';
import '../models/stroke_style.dart';
import '../services/protobuf_storage.dart';

/// Provider مربوط به وایت‌بورد برای مدیریت وضعیت
class WhiteBoardProvider extends ChangeNotifier {
  // سرویس‌ها
  final _storageService = StorageService();
  final _grpcService = GrpcService();

  // وایت‌بورد فعلی
  WhiteBoard? _whiteBoard;

  // خط در حال رسم
  Stroke? _currentStroke;

  // سبک خط فعلی
  drawing.StrokeStyle _currentStyle = drawing.StrokeStyle.defaultStyle();

  // وضعیت بارگذاری
  bool _isLoading = false;

  // وضعیت ذخیره‌سازی
  bool _isSaving = false;

  // آیا در حال رسم هستیم؟
  bool _isDrawing = false;

  // لیست شناسه‌های وایت‌بوردهای ذخیره شده
  List<String> _savedWhiteBoardIds = [];

  // تنظیمات قلم
  StrokeStyle _strokeStyle = const StrokeStyle(
    color: Color(0xFF000000),
    thickness: 2.0,
    type: StrokeType.solid,
  );

  // گترها
  WhiteBoard? get whiteBoard => _whiteBoard;
  drawing.StrokeStyle get currentStyle => _currentStyle;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isDrawing => _isDrawing;
  List<String> get savedWhiteBoardIds => _savedWhiteBoardIds;
  Stroke? get currentStroke => _currentStroke;
  StrokeStyle get strokeStyle => _strokeStyle;

  WhiteBoardProvider() {
    _initialize();
  }

  /// راه‌اندازی اولیه
  Future<void> _initialize() async {
    await _storageService.initialize();

    // بارگیری لیست وایت‌بوردهای ذخیره شده
    await loadSavedWhiteBoardIds();
  }

  /// ایجاد وایت‌بورد جدید
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

  /// بارگیری وایت‌بورد از حافظه محلی
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

  /// دریافت لیست وایت‌بوردهای ذخیره شده
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

  /// ذخیره وایت‌بورد فعلی
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

  /// تنظیم سبک خط فعلی
  void setStrokeStyle({int? color, double? width, double? smoothness}) {
    final newColor = color ?? _currentStyle.color;
    final newWidth = width ?? _currentStyle.width;
    final newSmoothness = smoothness ?? _currentStyle.smoothness;

    _currentStyle = drawing.StrokeStyle(
      color: newColor,
      width: newWidth,
      smoothness: newSmoothness,
    );

    notifyListeners();
  }

  /// شروع رسم خط جدید
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

  /// ادامه رسم خط
  void updateStroke(Offset position) {
    if (_currentStroke == null) return;

    final point = Point(x: position.dx, y: position.dy, pressure: 1.0);

    _currentStroke = _currentStroke!.copyWith(
      points: [..._currentStroke!.points, point],
    );

    notifyListeners();
  }

  /// پایان رسم خط
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

  /// پاک کردن وایت‌بورد
  void clearWhiteBoard() {
    if (_whiteBoard != null) {
      _whiteBoard = _whiteBoard!.copyWith(
        strokes: [],
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  /// حذف آخرین خط
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
}
