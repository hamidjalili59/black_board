import 'dart:async';
import 'package:grpc/grpc.dart';
import 'package:flutter/foundation.dart';
import '../models/drawing_model.dart';

/// سرویس gRPC برای ارتباط با سرور
class GrpcService {
  static final GrpcService _instance = GrpcService._internal();
  late ClientChannel _channel;
  // کلاینت سرویس وایت‌بورد که با استفاده از فایل proto تولید می‌شود
  // WhiteBoardServiceClient? _client;
  bool _isInitialized = false;

  // سینگلتون پترن
  factory GrpcService() {
    return _instance;
  }

  GrpcService._internal();

  /// راه‌اندازی اتصال به سرور
  Future<void> initialize({
    required String host,
    required int port,
    bool secure = false,
  }) async {
    if (_isInitialized) return;

    _channel = ClientChannel(
      host,
      port: port,
      options: ChannelOptions(
        credentials:
            secure
                ? ChannelCredentials.secure()
                : ChannelCredentials.insecure(),
        codecRegistry: CodecRegistry(
          codecs: const [GzipCodec(), IdentityCodec()],
        ),
      ),
    );

    // _client = WhiteBoardServiceClient(_channel);
    _isInitialized = true;

    debugPrint(
      'gRPC Service initialized with host: $host, port: $port, secure: $secure',
    );
  }

  /// بستن کانال ارتباطی
  Future<void> shutdown() async {
    if (!_isInitialized) return;

    await _channel.shutdown();
    _isInitialized = false;

    debugPrint('gRPC Service shutdown');
  }

  /// بررسی اتصال به سرور
  Future<bool> checkConnection() async {
    if (!_isInitialized) return false;

    try {
      // یک درخواست ساده برای تست اتصال
      // await _client?.listWhiteBoards(ListRequest(pageSize: 1, pageNumber: 1));
      return true;
    } catch (e) {
      debugPrint('gRPC connection check failed: $e');
      return false;
    }
  }

  /// ذخیره وایت‌بورد در سرور
  Future<String?> saveWhiteBoard(WhiteBoard whiteBoard) async {
    if (!_isInitialized) return null;

    try {
      // تبدیل مدل به proto
      // final protoWhiteBoard = _convertToProto(whiteBoard);
      // final response = await _client?.saveWhiteBoard(protoWhiteBoard);

      // return response?.id;
      return whiteBoard.id; // فعلاً فقط آیدی را برمی‌گردانیم
    } catch (e) {
      debugPrint('Failed to save whiteboard: $e');
      return null;
    }
  }

  /// دریافت وایت‌بورد از سرور
  Future<WhiteBoard?> getWhiteBoard(String id) async {
    if (!_isInitialized) return null;

    try {
      // final response = await _client?.getWhiteBoard(GetRequest(id: id));
      // return _convertFromProto(response);
      return null; // فعلاً null برمی‌گردانیم
    } catch (e) {
      debugPrint('Failed to get whiteboard: $e');
      return null;
    }
  }

  // تبدیل مدل به proto و بالعکس
  // روش‌های تبدیل مدل به proto و بالعکس باید پیاده‌سازی شوند
}
