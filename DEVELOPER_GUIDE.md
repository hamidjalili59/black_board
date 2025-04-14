# راهنمای توسعه‌دهندگان وایت‌بورد هوشمند

این سند جزئیات فنی پروژه وایت‌بورد هوشمند را برای توسعه‌دهندگان جدید شرح می‌دهد. با مطالعه این راهنما، شما با ساختار کد، معماری پروژه و چگونگی پیاده‌سازی قابلیت‌های اصلی آشنا خواهید شد.

## معماری برنامه

این پروژه از معماری MVVM (Model-View-ViewModel) استفاده می‌کند:

- **Model**: کلاس‌های داده‌ای در دایرکتوری `models/`
- **View**: رابط کاربری در `views/` و `widgets/`
- **ViewModel**: کلاس‌های provider در دایرکتوری `providers/`

همچنین از چندین سرویس برای مدیریت ذخیره‌سازی و ارتباطات استفاده می‌کند.

## مدل‌های داده

### مجموعه مدل‌ها

در این برنامه از دو مجموعه مدل استفاده شده است:

1. **مدل‌های اصلی** (`stroke.dart`، `point.dart`، `white_board.dart`، `stroke_style.dart`): برای کار با وایت‌بورد در برنامه
2. **مدل‌های JSON** (`drawing_model.dart`): مدل‌های اصلی قدیمی که پشتیبانی JSON دارند (برای سازگاری با نسخه‌های قدیمی)

### ساختار مدل‌های اصلی

#### Point

```dart
class Point {
  final double x;
  final double y;
  final double pressure;

  // سازنده و متدها
}
```

#### StrokeStyle

```dart
enum StrokeType { solid, dotted, dashed }

class StrokeStyle {
  final Color color;
  final double thickness;
  final StrokeType type;
  final bool hasShadow;
  final double opacity;

  // سازنده و متدها
}
```

#### Stroke

```dart
class Stroke {
  final String id;
  final List<Point> points;
  final StrokeStyle style;
  final int startTime;

  // محاسبه bounds برای تعیین محدوده خط
  Rect get bounds { ... }

  // سازنده و متدها
}
```

#### WhiteBoard

```dart
class WhiteBoard {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Stroke> strokes;

  // متدهای مدیریت خطوط
  WhiteBoard addStroke(Stroke stroke) { ... }
  WhiteBoard removeStroke(String strokeId) { ... }
  WhiteBoard clearStrokes() { ... }
}
```

## ذخیره‌سازی با Protobuf

### تنظیمات Protobuf

فایل تعریف Protobuf در `proto/black_board.proto` قرار دارد و ساختارهای داده را برای ذخیره‌سازی مشخص می‌کند:

```protobuf
message PointProto {
  double x = 1;
  double y = 2;
  double pressure = 3;
}

message StrokeStyleProto {
  int32 color = 1;
  double thickness = 2;
  int32 type = 3;
  bool has_shadow = 4;
  double opacity = 5;
}

message StrokeProto {
  string id = 1;
  repeated PointProto points = 2;
  StrokeStyleProto style = 3;
  int64 start_time = 4;
}

message WhiteBoardProto {
  string id = 1;
  string name = 2;
  int64 created_at = 3;
  int64 updated_at = 4;
  repeated StrokeProto strokes = 5;
}
```

### مراحل سریالایز و دسریالایز

#### تبدیل به Protobuf:

```dart
// تبدیل مدل داخلی به پروتوباف
WhiteBoardProto convertToProto(WhiteBoard whiteBoard) {
  return WhiteBoardProto()
    ..id = whiteBoard.id
    ..name = whiteBoard.name
    ..createdAt = whiteBoard.createdAt.millisecondsSinceEpoch
    ..updatedAt = whiteBoard.updatedAt.millisecondsSinceEpoch
    ..strokes.addAll(whiteBoard.strokes.map(convertStrokeToProto));
}
```

#### تبدیل از Protobuf:

```dart
// تبدیل پروتوباف به مدل داخلی
WhiteBoard convertFromProto(WhiteBoardProto proto) {
  return WhiteBoard(
    id: proto.id,
    name: proto.name,
    createdAt: DateTime.fromMillisecondsSinceEpoch(proto.createdAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(proto.updatedAt),
    strokes: proto.strokes.map(convertStrokeFromProto).toList(),
  );
}
```

### فرآیند ذخیره‌سازی و بارگیری

#### ذخیره‌سازی

1. ابتدا داده‌ها بهینه‌سازی می‌شوند (`_optimizeWhiteBoard`)
2. سپس به Protobuf تبدیل می‌شوند (`ProtobufSerializer.serializeWhiteBoard`)
3. داده‌ها با GZIP فشرده می‌شوند (`_compressData`)
4. داده‌های فشرده در فایل ذخیره می‌شوند

#### بارگیری

1. داده‌ها از فایل خوانده می‌شوند
2. در صورت فشرده بودن، فشرده‌گشایی می‌شوند (`_tryDecompressData`)
3. داده‌ها از Protobuf به مدل داخلی تبدیل می‌شوند (`ProtobufSerializer.deserializeWhiteBoard`)
4. مدل داخلی به Provider برگردانده می‌شود

## مدیریت وضعیت (State Management)

برنامه از `ChangeNotifier` برای مدیریت وضعیت استفاده می‌کند:

```dart
class ProtobufWhiteBoardProvider extends ChangeNotifier {
  // مدیریت وضعیت و متدهای اصلی
  WhiteBoard? _whiteBoard;
  Stroke? _currentStroke;
  bool _isLoading = false;
  bool _isSaving = false;
  
  // متدها برای ایجاد، ذخیره و مدیریت خطوط
  void startStroke(Offset position) { ... }
  void updateStroke(Offset position) { ... }
  void endStroke() { ... }
  Future<bool> saveWhiteBoard() { ... }
  Future<void> loadWhiteBoard(String id) { ... }
}
```

## رسم روی کنوس (Canvas)

برای رسم خطوط از کلاس `CustomPainter` استفاده شده است:

```dart
class WhiteBoardPainter extends CustomPainter {
  final WhiteBoardProvider provider;

  @override
  void paint(Canvas canvas, Size size) {
    // رسم خطوط قبلی
    for (final stroke in whiteBoard.strokes) {
      _drawStroke(canvas, stroke);
    }

    // رسم خط در حال ترسیم
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!);
    }
  }

  void _drawStroke(Canvas canvas, Stroke stroke) {
    final paint = Paint()
      ..color = stroke.style.color
      ..strokeWidth = stroke.style.thickness
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // ایجاد مسیر
    final path = Path();
    // رسم مسیر براساس نقاط
    // ...
    canvas.drawPath(path, paint);
  }
}
```

## بهینه‌سازی نقاط

برای بهینه‌سازی نقاط خطوط از الگوریتم ساده‌شده Douglas-Peucker استفاده می‌شود:

```dart
List<Point> _simplifyPoints(List<Point> points) {
  if (points.length <= 2) return List.from(points);
  
  final result = <Point>[points.first];
  Point prevPoint = points.first;
  
  for (int i = 1; i < points.length - 1; i++) {
    final currentPoint = points[i];
    final distance = _getDistanceBetweenPoints(prevPoint, currentPoint);
    
    if (distance >= _optimizationDistance) {
      result.add(currentPoint);
      prevPoint = currentPoint;
    }
  }
  
  result.add(points.last);
  return result;
}
```

## راهنمای اضافه کردن قابلیت‌های جدید

### افزودن یک نوع استایل جدید

1. `StrokeType` را در `stroke_style.dart` گسترش دهید
2. سپس UI مربوطه در `stroke_settings_panel.dart` را به‌روزرسانی کنید
3. منطق رسم را در `drawing_canvas_protobuf.dart` اضافه کنید

### افزودن قابلیت ذخیره در ابر

1. یک کلاس سرویس جدید در دایرکتوری `services/` ایجاد کنید
2. متدهای ذخیره و بارگیری را پیاده‌سازی کنید
3. provider را گسترش دهید تا از سرویس جدید استفاده کند

### افزودن یک ابزار جدید

1. منطق ابزار را در provider مربوطه اضافه کنید
2. UI مربوط به ابزار را در `protobuf_whiteboard_screen.dart` اضافه کنید
3. منطق رسم ابزار را در `drawing_canvas_protobuf.dart` پیاده‌سازی کنید

## مشکلات متداول و رفع آنها

### تداخل مدل‌های داده

به دلیل وجود دو نوع مدل داده، ممکن است دچار تداخل شوید. برای جلوگیری از این مشکل:

```dart
// استفاده از پیشوند برای مدل‌های JSON
import '../models/drawing_model.dart' as drawing;

// استفاده از مدل با پیشوند
drawing.StrokeStyle style = drawing.StrokeStyle.defaultStyle();
```

### مشکلات مسیر فایل در پلتفرم‌های مختلف

برای اطمینان از سازگاری با همه سیستم‌عامل‌ها:

```dart
// استفاده از جداکننده مسیر مناسب سیستم‌عامل
final file = File('${dir.path}${Platform.pathSeparator}$id$extension');

// استخراج نام فایل بدون وابستگی به پلتفرم
final fileName = file.path.split(Platform.pathSeparator).last;
```

## چک‌لیست توسعه قبل از ارسال کد

- [ ] آیا کد شما با نسخه‌های قبلی سازگار است؟
- [ ] آیا مستندات لازم را به README.md اضافه کرده‌اید؟
- [ ] آیا تست‌های مناسب برای قابلیت جدید نوشته‌اید؟
- [ ] آیا هشدارهای لینتر را برطرف کرده‌اید؟
- [ ] آیا از نشت حافظه جلوگیری کرده‌اید؟
- [ ] آیا کد شما روی همه پلتفرم‌های هدف تست شده است؟

## افزودن زبان‌های جدید

برای افزودن پشتیبانی زبان جدید:

1. فایل‌های ترجمه را در `assets/i18n/` اضافه کنید
2. کلاس `AppLocalizations` را به‌روزرسانی کنید
3. زبان جدید را به لیست `supportedLocales` در `main.dart` اضافه کنید 