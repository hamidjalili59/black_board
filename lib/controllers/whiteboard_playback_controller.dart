import 'dart:async';
import 'package:flutter/material.dart';
import '../models/white_board.dart';
import '../models/stroke.dart';
import '../models/point.dart';

enum PlaybackState { playing, paused, stopped }

class WhiteBoardPlaybackController extends ChangeNotifier {
  final WhiteBoard originalWhiteBoard;
  late WhiteBoard _currentWhiteBoard;
  late WhiteBoard _absoluteBoard;

  // زمان مرجع برای نرمال‌سازی زمان‌ها
  late int _baseTime;

  PlaybackState _playbackState = PlaybackState.stopped;
  Timer? _timer;
  int _currentTimeMs = 0;
  double _playbackSpeed = 1.0;

  WhiteBoardPlaybackController({required this.originalWhiteBoard}) {
    // تبدیل به فرمت مطلق برای راحتی کار (بدون دلتا)
    _absoluteBoard =
        originalWhiteBoard.isDeltaEncoded
            ? originalWhiteBoard.toAbsoluteEncoded()
            : originalWhiteBoard;

    // محاسبه زمان مرجع (کمترین زمان شروع از بین استروک‌ها)
    _baseTime = _calculateBaseTime();

    // شروع با وایت‌بورد خالی (بدون استروک)
    _currentWhiteBoard = WhiteBoard(
      id: originalWhiteBoard.id,
      name: originalWhiteBoard.name,
      createdAt: originalWhiteBoard.createdAt,
      updatedAt: originalWhiteBoard.updatedAt,
      strokes: [],
      isDeltaEncoded: false,
      duration: _calculateTotalDuration(),
    );

    debugPrint("وایت‌بورد بازپخش ایجاد شد:");
    debugPrint("تعداد خطوط: ${_absoluteBoard.strokes.length}");
    debugPrint("زمان مرجع: $_baseTime");
    debugPrint("مدت کل: ${_calculateTotalDuration()} میلی‌ثانیه");
    debugPrint("وضعیت دلتا اصلی: ${originalWhiteBoard.isDeltaEncoded}");
    debugPrint("وضعیت دلتا مطلق: ${_absoluteBoard.isDeltaEncoded}");

    // اگر خطی وجود دارد، اطلاعات خط اول را نمایش دهیم
    if (_absoluteBoard.strokes.isNotEmpty) {
      final firstStroke = _absoluteBoard.strokes.first;
      debugPrint(
        "خط اول - شروع: ${firstStroke.startTime}, پایان: ${firstStroke.endTime}",
      );
      debugPrint(
        "نسبت به زمان مرجع: شروع: ${firstStroke.startTime - _baseTime}, پایان: ${firstStroke.endTime - _baseTime}",
      );
      debugPrint(
        "وضعیت دلتا خط اول: ${firstStroke.isDeltaEncoded}, تعداد نقاط: ${firstStroke.points.length}",
      );

      if (firstStroke.points.isNotEmpty) {
        final firstPoint = firstStroke.points.first;
        debugPrint("نقطه اول: $firstPoint");
      }

      // بررسی زمان‌بندی نقاط برای تشخیص مشکلات
      _inspectPoints();
    }

    // مطمئن شویم زمان جاری صفر است
    _currentTimeMs = 0;
    _updateStateAtCurrentTime();
  }

  // محاسبه زمان مرجع (کمترین زمان شروع از بین استروک‌ها)
  int _calculateBaseTime() {
    if (_absoluteBoard.strokes.isEmpty) return 0;

    // شروع با بیشترین مقدار ممکن برای زمان
    int minStartTime = double.maxFinite.toInt(); // مقدار ماکزیمم int
    for (final stroke in _absoluteBoard.strokes) {
      if (stroke.startTime < minStartTime) {
        minStartTime = stroke.startTime;
      }
    }

    return minStartTime;
  }

  // محاسبه مدت زمان کل بازپخش
  int _calculateTotalDuration() {
    if (_absoluteBoard.strokes.isEmpty) return 0;

    int maxEndTime = 0;
    for (final stroke in _absoluteBoard.strokes) {
      if (stroke.endTime > maxEndTime) {
        maxEndTime = stroke.endTime;
      }
    }

    // مدت زمان کل نسبت به زمان مرجع
    return maxEndTime - _baseTime;
  }

  WhiteBoard get currentWhiteBoard => _currentWhiteBoard;
  PlaybackState get state => _playbackState;
  int get currentTime => _currentTimeMs;
  int get duration => _calculateTotalDuration();
  double get playbackSpeed => _playbackSpeed;

  // متدها و خصوصیات برای سازگاری با ویجت‌های مختلف
  int get currentTimeMs => _currentTimeMs;
  int get totalDurationMs => _calculateTotalDuration();
  bool get isPlaying => _playbackState == PlaybackState.playing;
  double get progress =>
      totalDurationMs > 0 ? _currentTimeMs / totalDurationMs.toDouble() : 0.0;

  set playbackSpeed(double speed) {
    setPlaybackSpeed(speed);
  }

  void play() {
    if (_playbackState == PlaybackState.playing) return;

    // اگر به انتها رسیده است، از اول شروع کنیم
    if (_currentTimeMs >= duration) {
      _currentTimeMs = 0;
      _updateStateAtCurrentTime();
    }

    _playbackState = PlaybackState.playing;
    notifyListeners();

    _timer = Timer.periodic(
      Duration(milliseconds: (16 ~/ _playbackSpeed)),
      _tick,
    );
  }

  void pause() {
    if (_playbackState != PlaybackState.playing) return;

    _timer?.cancel();
    _playbackState = PlaybackState.paused;
    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
    _currentTimeMs = 0;
    _playbackState = PlaybackState.stopped;
    _updateStateAtCurrentTime();
    notifyListeners();
  }

  void seekTo(int timeMs) {
    _currentTimeMs = timeMs.clamp(0, duration);
    _updateStateAtCurrentTime();
    notifyListeners();
  }

  void _updateStateAtCurrentTime() {
    // زمان مطلق با توجه به زمان مرجع
    final absoluteTime = _baseTime + _currentTimeMs;

    debugPrint(
      "به‌روزرسانی وضعیت - زمان جاری: $_currentTimeMs میلی‌ثانیه، زمان مطلق: $absoluteTime",
    );

    final visibleStrokes = <Stroke>[];
    bool hasVisibleStrokes = false;

    // مرتب‌سازی استروک‌ها بر اساس زمان شروع
    final sortedStrokes = List<Stroke>.from(_absoluteBoard.strokes)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    for (final stroke in sortedStrokes) {
      // فقط خطوطی که شروع شده‌اند را بررسی کنیم
      if (stroke.startTime <= absoluteTime) {
        // لیست نقاط قابل نمایش تا زمان جاری را دریافت کنیم
        final points = _getVisiblePoints(stroke, absoluteTime);

        // اگر نقطه‌ای برای نمایش وجود دارد، خط را اضافه کنیم
        if (points.isNotEmpty) {
          visibleStrokes.add(
            stroke.copyWith(
              points: points,
              // زمان شروع و پایان را حفظ می‌کنیم
              startTime: stroke.startTime,
              endTime: stroke.endTime,
            ),
          );
          hasVisibleStrokes = true;
        }
      }
    }

    // به‌روزرسانی وایت‌بورد جاری با خطوط قابل نمایش
    _currentWhiteBoard = WhiteBoard(
      id: originalWhiteBoard.id,
      name: originalWhiteBoard.name,
      createdAt: originalWhiteBoard.createdAt,
      updatedAt: originalWhiteBoard.updatedAt,
      strokes: visibleStrokes,
      isDeltaEncoded: false,
      duration: duration,
    );

    debugPrint("تعداد خطوط قابل نمایش: ${visibleStrokes.length}");
    if (hasVisibleStrokes && visibleStrokes.isNotEmpty) {
      final firstStroke = visibleStrokes.first;
      final lastStroke = visibleStrokes.last;
      debugPrint(
        "اولین خط قابل نمایش - شروع: ${firstStroke.startTime}, پایان: ${firstStroke.endTime}",
      );
      debugPrint(
        "آخرین خط قابل نمایش - شروع: ${lastStroke.startTime}, پایان: ${lastStroke.endTime}",
      );
    }
  }

  // دریافت نقاط قابل نمایش یک خط تا زمان مشخص
  List<Point> _getVisiblePoints(Stroke stroke, int currentTime) {
    // اگر زمان از پایان خط گذشته، همه نقاط را نمایش می‌دهیم
    if (currentTime >= stroke.endTime) {
      return stroke.points;
    }

    // زمان نسبی برای فیلتر کردن نقاط
    final relativeTime = currentTime - stroke.startTime;

    // بررسی آیا همه timestamp‌های نقاط صفر هستند
    bool allZeroTimestamps = stroke.points.every((p) => p.timestamp == 0);

    if (allZeroTimestamps) {
      // اگر همه timestamp‌ها صفر هستند، نقاط را به صورت تدریجی نمایش می‌دهیم
      // بر اساس درصد گذشت زمان نسبی از کل زمان خط

      int strokeDuration = stroke.endTime - stroke.startTime;
      if (strokeDuration <= 0) return []; // اجتناب از تقسیم بر صفر

      double progress = relativeTime / strokeDuration.toDouble();
      int visibleCount = (stroke.points.length * progress).round();
      visibleCount = visibleCount.clamp(0, stroke.points.length);

      return stroke.points.sublist(0, visibleCount);
    } else {
      // حالت عادی - فیلتر کردن بر اساس timestamp
      return stroke.points
          .where((point) => point.timestamp <= relativeTime)
          .toList();
    }
  }

  // متدهای اضافی برای سازگاری با ویجت‌های مختلف
  void seekToTime(int timeMs) {
    seekTo(timeMs);
  }

  void seekToPosition(double position) {
    final targetTime = (position * totalDurationMs).round();
    seekTo(targetTime);
  }

  void increaseSpeed() {
    if (_playbackSpeed < 2.0) {
      setPlaybackSpeed(_playbackSpeed + 0.5);
    }
  }

  void decreaseSpeed() {
    if (_playbackSpeed > 0.5) {
      setPlaybackSpeed(_playbackSpeed - 0.5);
    }
  }

  void setPlaybackSpeed(double speed) {
    if (speed <= 0) return;

    bool wasPlaying = _playbackState == PlaybackState.playing;
    if (wasPlaying) {
      _timer?.cancel();
    }

    _playbackSpeed = speed;

    if (wasPlaying) {
      _timer = Timer.periodic(
        Duration(milliseconds: (16 ~/ _playbackSpeed)),
        _tick,
      );
    }

    notifyListeners();
  }

  void _tick(Timer timer) {
    // به‌روزرسانی زمان جاری
    _currentTimeMs += (16 * _playbackSpeed).toInt();

    // اگر به انتها رسیدیم، متوقف کنیم
    if (_currentTimeMs >= duration) {
      _timer?.cancel();
      _playbackState = PlaybackState.paused;
      _currentTimeMs = duration;
    }

    // به‌روزرسانی وضعیت وایت‌بورد جاری
    _updateStateAtCurrentTime();

    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // بررسی زمان‌بندی نقاط برای دیباگ
  void _inspectPoints() {
    debugPrint("\n====== بررسی نقاط برای دیباگ ======");

    for (int i = 0; i < _absoluteBoard.strokes.length; i++) {
      final stroke = _absoluteBoard.strokes[i];

      debugPrint("\nبررسی خط $i با ${stroke.points.length} نقطه:");
      debugPrint("زمان شروع خط: ${stroke.startTime}");
      debugPrint("زمان پایان خط: ${stroke.endTime}");

      if (stroke.points.isNotEmpty) {
        // بررسی اولین و آخرین نقطه
        final firstPoint = stroke.points.first;
        final lastPoint = stroke.points.last;

        debugPrint(
          "اولین نقطه: timestamp=${firstPoint.timestamp}, isDelta=${firstPoint.isDelta}",
        );
        debugPrint(
          "آخرین نقطه: timestamp=${lastPoint.timestamp}, isDelta=${lastPoint.isDelta}",
        );

        // بررسی timestamp همه نقاط
        int countZeroTimestamp = 0;
        for (final p in stroke.points) {
          if (p.timestamp == 0) countZeroTimestamp++;
        }

        if (countZeroTimestamp > 0) {
          debugPrint(
            "!!هشدار!! $countZeroTimestamp نقطه با timestamp صفر وجود دارد",
          );
        }
      } else {
        debugPrint("خط بدون نقطه!");
      }
    }

    debugPrint("====== پایان بررسی نقاط ======\n");
  }
}
