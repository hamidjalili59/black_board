import 'package:flutter/material.dart';
import '../controllers/whiteboard_playback_controller.dart';

/// ویجت نمایش‌دهنده کنترل‌های بازپخش وایت‌بورد
class PlaybackControls extends StatelessWidget {
  final WhiteBoardPlaybackController controller;
  final bool showSpeedControl;

  const PlaybackControls({
    Key? key,
    required this.controller,
    this.showSpeedControl = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // نمایش زمان و پیشرفت بازپخش
              _buildProgressSlider(),
              const SizedBox(height: 8),

              // ردیف کنترل‌های اصلی
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // دکمه توقف
                  IconButton(
                    icon: const Icon(Icons.stop),
                    onPressed: controller.stop,
                    tooltip: 'توقف',
                  ),

                  // دکمه پخش/مکث
                  IconButton(
                    icon: Icon(
                      controller.state == PlaybackState.playing
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    onPressed:
                        controller.state == PlaybackState.playing
                            ? controller.pause
                            : controller.play,
                    tooltip:
                        controller.state == PlaybackState.playing
                            ? 'مکث'
                            : 'پخش',
                    iconSize: 40,
                  ),
                ],
              ),

              // کنترل سرعت بازپخش (اختیاری)
              if (showSpeedControl) _buildSpeedControl(),
            ],
          ),
        );
      },
    );
  }

  /// ایجاد اسلایدر پیشرفت پخش
  Widget _buildProgressSlider() {
    // تبدیل زمان به فرمت دقیقه:ثانیه
    final currentFormatted = _formatDuration(
      Duration(milliseconds: controller.currentTime),
    );
    final totalFormatted = _formatDuration(
      Duration(milliseconds: controller.duration),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // نمایش زمان فعلی و کل
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(currentFormatted), Text(totalFormatted)],
        ),

        // اسلایدر پیشرفت
        Slider(
          value: controller.currentTime.toDouble(),
          min: 0,
          max: controller.duration.toDouble().clamp(1, double.infinity),
          onChanged: (value) => controller.seekTo(value.toInt()),
        ),
      ],
    );
  }

  /// ایجاد کنترل‌های سرعت پخش
  Widget _buildSpeedControl() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('سرعت: '),

        // دکمه‌های تنظیم سرعت
        _buildSpeedButton(0.5, controller.playbackSpeed == 0.5),
        _buildSpeedButton(1.0, controller.playbackSpeed == 1.0),
        _buildSpeedButton(1.5, controller.playbackSpeed == 1.5),
        _buildSpeedButton(2.0, controller.playbackSpeed == 2.0),
      ],
    );
  }

  /// ایجاد دکمه انتخاب سرعت
  Widget _buildSpeedButton(double speed, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: () => controller.playbackSpeed = speed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected ? Colors.blue.shade700 : Colors.blue.shade200,
          foregroundColor: isSelected ? Colors.white : Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text('${speed}x'),
      ),
    );
  }

  /// فرمت زمان به صورت دقیقه:ثانیه
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
