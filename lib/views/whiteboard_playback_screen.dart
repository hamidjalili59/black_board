import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import '../controllers/whiteboard_playback_controller.dart';
import '../models/white_board.dart';
import '../models/stroke.dart';
import '../services/protobuf_storage.dart';
import '../widgets/playback_whiteboard_canvas.dart';

/// صفحه بازپخش وایت‌بورد
class WhiteBoardPlaybackScreen extends StatefulWidget {
  /// شناسه وایت‌بورد برای بازپخش
  final String whiteBoardId;

  const WhiteBoardPlaybackScreen({super.key, required this.whiteBoardId});

  @override
  State<WhiteBoardPlaybackScreen> createState() =>
      _WhiteBoardPlaybackScreenState();
}

class _WhiteBoardPlaybackScreenState extends State<WhiteBoardPlaybackScreen> {
  /// کنترل‌کننده بازپخش
  WhiteBoardPlaybackController? _controller;

  /// وایت‌بورد بارگذاری شده
  WhiteBoard? _loadedWhiteBoard;

  /// وضعیت بارگذاری
  bool _isLoading = true;

  /// خطای بارگذاری
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWhiteBoard();
  }

  /// بارگذاری وایت‌بورد
  Future<void> _loadWhiteBoard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final whiteBoard = await ProtobufStorage.loadWhiteBoard(
        widget.whiteBoardId,
      );

      if (whiteBoard == null) {
        setState(() {
          _isLoading = false;
          _error = 'وایت‌بورد یافت نشد';
        });
        return;
      }

      setState(() {
        _loadedWhiteBoard = whiteBoard;
        _controller = WhiteBoardPlaybackController(
          originalWhiteBoard: whiteBoard,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'خطا در بارگذاری وایت‌بورد: $e';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_loadedWhiteBoard?.name ?? 'بازپخش وایت‌بورد'),
        actions: [
          // دکمه بازگشت به مبدا
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  /// ساخت محتوای اصلی صفحه
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadWhiteBoard,
              child: const Text('تلاش مجدد'),
            ),
          ],
        ),
      );
    }

    if (_controller == null) {
      return const Center(child: Text('کنترل‌کننده بازپخش ایجاد نشده است'));
    }

    return ChangeNotifierProvider.value(
      value: _controller,
      child: Column(
        children: [
          // کنوس وایت‌بورد (بخش اصلی)
          Expanded(
            child: Consumer<WhiteBoardPlaybackController>(
              builder: (context, controller, child) {
                return PlaybackWhiteBoardCanvas(
                  backgroundColor: Colors.white,
                  whiteBoard: controller.currentWhiteBoard,
                );
              },
            ),
          ),

          // کنترل‌های بازپخش
          _buildPlaybackControls(),
        ],
      ),
    );
  }

  /// ساخت کنترل‌های بازپخش
  Widget _buildPlaybackControls() {
    return Consumer<WhiteBoardPlaybackController>(
      builder: (context, controller, child) {
        final isPlaying = controller.state == PlaybackState.playing;
        final currentTime = _formatDuration(controller.currentTime);
        final totalTime = _formatDuration(controller.duration);

        return Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // نوار پیشرفت
              Slider(
                value: controller.currentTime.toDouble(),
                min: 0,
                max: controller.duration.toDouble(),
                onChanged: (value) {
                  controller.seekTo(value.toInt());
                },
              ),

              // زمان و مدت
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text(currentTime), Text(totalTime)],
                ),
              ),

              const SizedBox(height: 8),

              // دکمه‌های کنترل
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // دکمه عقب جهش 5 ثانیه
                  IconButton(
                    icon: const Icon(Icons.replay_5),
                    onPressed: () {
                      int newTime = controller.currentTime - 5000;
                      controller.seekTo(newTime < 0 ? 0 : newTime);
                    },
                  ),

                  // دکمه پخش/توقف
                  FloatingActionButton(
                    heroTag: 'playPause',
                    onPressed: () {
                      if (isPlaying) {
                        controller.pause();
                      } else {
                        controller.play();
                      }
                    },
                    child: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                  ),

                  // دکمه جلو جهش 5 ثانیه
                  IconButton(
                    icon: const Icon(Icons.forward_5),
                    onPressed: () {
                      int newTime = controller.currentTime + 5000;
                      controller.seekTo(
                        newTime > controller.duration
                            ? controller.duration
                            : newTime,
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // انتخاب سرعت
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('سرعت:'),
                  const SizedBox(width: 8),
                  DropdownButton<double>(
                    value: controller.playbackSpeed,
                    items:
                        [0.5, 1.0, 1.5, 2.0].map((speed) {
                          return DropdownMenuItem(
                            value: speed,
                            child: Text('${speed}x'),
                          );
                        }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        controller.playbackSpeed = value;
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// فرمت‌بندی زمان
  String _formatDuration(int milliseconds) {
    final seconds = (milliseconds / 1000).floor();
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
