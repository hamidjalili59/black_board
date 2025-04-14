import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../models/drawing_model.dart';
import '../services/storage_service.dart';
import '../services/grpc_service.dart';

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
  StrokeStyle _currentStyle = StrokeStyle.defaultStyle();

  // وضعیت بارگذاری
  bool _isLoading = false;

  // وضعیت ذخیره‌سازی
  bool _isSaving = false;

  // آیا در حال رسم هستیم؟
  bool _isDrawing = false;

  // لیست شناسه‌های وایت‌بوردهای ذخیره شده
  List<String> _savedWhiteBoardIds = [];

  // گترها
  WhiteBoard? get whiteBoard => _whiteBoard;
  StrokeStyle get currentStyle => _currentStyle;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isDrawing => _isDrawing;
  List<String> get savedWhiteBoardIds => _savedWhiteBoardIds;
  Stroke? get currentStroke => _currentStroke;

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
  void createNewWhiteBoard({String name = 'New Whiteboard'}) {
    _whiteBoard = WhiteBoard(name: name, strokes: []);

    _currentStroke = null;
    notifyListeners();
  }

  /// بارگیری وایت‌بورد از حافظه محلی
  Future<void> loadWhiteBoard(String id) async {
    _isLoading = true;
    notifyListeners();

    final loaded = await _storageService.loadWhiteBoard(id);

    if (loaded != null) {
      _whiteBoard = loaded;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// دریافت لیست وایت‌بوردهای ذخیره شده
  Future<void> loadSavedWhiteBoardIds() async {
    _isLoading = true;
    notifyListeners();

    _savedWhiteBoardIds = await _storageService.getWhiteBoardIds();

    _isLoading = false;
    notifyListeners();
  }

  /// ذخیره وایت‌بورد فعلی
  Future<bool> saveCurrentWhiteBoard() async {
    if (_whiteBoard == null) return false;

    _isSaving = true;
    notifyListeners();

    final result = await _storageService.saveWhiteBoard(_whiteBoard!);

    // اگر ذخیره موفقیت‌آمیز بود، به سرور هم ارسال می‌کنیم
    if (result) {
      // ارسال به سرور (اختیاری)
      try {
        await _grpcService.saveWhiteBoard(_whiteBoard!);
      } catch (e) {
        debugPrint('Failed to sync with server: $e');
      }

      // به‌روزرسانی لیست وایت‌بوردهای ذخیره شده
      await loadSavedWhiteBoardIds();
    }

    _isSaving = false;
    notifyListeners();

    return result;
  }

  /// تنظیم سبک خط فعلی
  void setStrokeStyle({int? color, double? width, double? smoothness}) {
    final newColor = color ?? _currentStyle.color;
    final newWidth = width ?? _currentStyle.width;
    final newSmoothness = smoothness ?? _currentStyle.smoothness;

    _currentStyle = StrokeStyle(
      color: newColor,
      width: newWidth,
      smoothness: newSmoothness,
    );

    notifyListeners();
  }

  /// شروع رسم خط جدید
  void startStroke(ui.Offset position) {
    if (_whiteBoard == null) {
      createNewWhiteBoard();
    }

    final point = Point.fromOffset(position);

    _currentStroke = Stroke(points: [point], style: _currentStyle);

    _isDrawing = true;
    notifyListeners();
  }

  /// ادامه رسم خط
  void updateStroke(ui.Offset position) {
    if (!_isDrawing || _currentStroke == null) return;

    final point = Point.fromOffset(position);

    _currentStroke = Stroke(
      id: _currentStroke!.id,
      points: [..._currentStroke!.points, point],
      style: _currentStroke!.style,
    );

    notifyListeners();
  }

  /// پایان رسم خط
  void endStroke() {
    if (!_isDrawing || _currentStroke == null || _whiteBoard == null) return;

    // اگر خط حداقل دو نقطه داشته باشد، آن را ذخیره می‌کنیم
    if (_currentStroke!.points.length >= 2) {
      _whiteBoard = _whiteBoard!.addStroke(_currentStroke!);
    }

    _currentStroke = null;
    _isDrawing = false;
    notifyListeners();
  }

  /// پاک کردن وایت‌بورد
  void clearWhiteBoard() {
    if (_whiteBoard == null) return;

    _whiteBoard = _whiteBoard!.clearStrokes();
    _currentStroke = null;
    notifyListeners();
  }

  /// حذف آخرین خط
  void undoLastStroke() {
    if (_whiteBoard == null || _whiteBoard!.strokes.isEmpty) return;

    final strokes = List<Stroke>.from(_whiteBoard!.strokes);
    strokes.removeLast();

    _whiteBoard = _whiteBoard!.copyWith(strokes: strokes);
    notifyListeners();
  }
}
