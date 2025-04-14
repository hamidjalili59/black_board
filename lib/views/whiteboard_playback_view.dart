import 'package:flutter/material.dart';
import '../controllers/whiteboard_playback_controller.dart';
import '../models/white_board.dart';
import '../widgets/drawing_canvas_protobuf.dart';

/// صفحه نمایش بازپخش وایت‌بورد
class WhiteBoardPlaybackView extends StatefulWidget {
  final WhiteBoard whiteBoard;

  const WhiteBoardPlaybackView({super.key, required this.whiteBoard});

  @override
  State<WhiteBoardPlaybackView> createState() => _WhiteBoardPlaybackViewState();
}

class _WhiteBoardPlaybackViewState extends State<WhiteBoardPlaybackView> {
  late WhiteBoardPlaybackController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WhiteBoardPlaybackController(
      originalWhiteBoard: widget.whiteBoard,
    );
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('بازپخش: ${_controller.currentWhiteBoard.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'بستن',
          ),
        ],
      ),
      body: Column(
        children: [
          // محیط نمایش وایت‌بورد (فقط خواندنی)
          Expanded(
            child: DrawingCanvasPanel(
              strokes: _controller.currentWhiteBoard.strokes,
              currentStroke: null,
              onPanStart: (_) {}, // حالت فقط خواندنی
              onPanUpdate: (_) {}, // حالت فقط خواندنی
              onPanEnd: () {}, // حالت فقط خواندنی
            ),
          ),

          // کنترل‌های پخش
          _buildPlaybackControls(),
        ],
      ),
    );
  }

  Widget _buildPlaybackControls() {
    // محاسبه زمان فعلی و کل به فرمت دقیقه:ثانیه
    final currentTimeStr = _formatDuration(_controller.currentTime);
    final durationStr = _formatDuration(_controller.duration);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // نوار پیشرفت
          Slider(
            value: _controller.currentTime.toDouble(),
            max: _controller.duration.toDouble(),
            onChanged: (value) {
              _controller.seekTo(value.toInt());
            },
          ),

          // نمایش زمان
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text(currentTimeStr), Text(durationStr)],
            ),
          ),

          const SizedBox(height: 8),

          // دکمه‌های کنترل
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // دکمه برگشت به ابتدا
              IconButton(
                icon: const Icon(Icons.replay),
                onPressed: () => _controller.stop(),
                tooltip: 'برگشت به ابتدا',
              ),

              // دکمه پخش/مکث
              IconButton(
                icon: Icon(
                  _controller.state == PlaybackState.playing
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  size: 48,
                ),
                onPressed: () {
                  if (_controller.state == PlaybackState.playing) {
                    _controller.pause();
                  } else {
                    _controller.play();
                  }
                },
              ),

              // انتخاب سرعت پخش
              PopupMenuButton<double>(
                initialValue: _controller.playbackSpeed,
                tooltip: 'سرعت پخش',
                icon: const Icon(Icons.speed),
                onSelected: (value) {
                  _controller.playbackSpeed = value;
                },
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(value: 0.5, child: Text('0.5x')),
                      const PopupMenuItem(value: 1.0, child: Text('1.0x')),
                      const PopupMenuItem(value: 1.5, child: Text('1.5x')),
                      const PopupMenuItem(value: 2.0, child: Text('2.0x')),
                    ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// تبدیل میلی‌ثانیه به فرمت دقیقه:ثانیه
  String _formatDuration(int milliseconds) {
    final seconds = (milliseconds / 1000).floor();
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;

    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
