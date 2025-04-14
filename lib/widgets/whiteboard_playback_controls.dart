import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/whiteboard_playback_controller.dart';

/// ویجت نمایش کنترل‌های بازپخش وایت‌بورد
class WhiteBoardPlaybackControls extends StatelessWidget {
  const WhiteBoardPlaybackControls({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<WhiteBoardPlaybackController>(
      builder: (context, controller, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // نوار پیشرفت
            _buildProgressSlider(controller),

            const SizedBox(height: 8),

            // کنترل‌های بازپخش
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // زمان فعلی
                _buildTimeDisplay(controller.currentTimeMs),

                const SizedBox(width: 16),

                // دکمه‌های کنترل
                _buildControlButtons(controller),

                const SizedBox(width: 16),

                // زمان کل
                _buildTimeDisplay(controller.totalDurationMs),

                const SizedBox(width: 16),

                // کنترل سرعت
                _buildSpeedControl(controller),
              ],
            ),
          ],
        );
      },
    );
  }

  /// ساخت نوار پیشرفت
  Widget _buildProgressSlider(WhiteBoardPlaybackController controller) {
    return SliderTheme(
      data: const SliderThemeData(
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
        trackHeight: 4,
      ),
      child: Slider(
        value: controller.progress,
        onChanged: (value) => controller.seekToPosition(value),
        activeColor: Colors.blue,
        inactiveColor: Colors.grey.shade300,
      ),
    );
  }

  /// ساخت نمایش زمان
  Widget _buildTimeDisplay(int milliseconds) {
    final seconds = (milliseconds / 1000).floor();
    final minutes = (seconds / 60).floor();

    final minutesStr = minutes.toString().padLeft(2, '0');
    final secondsStr = (seconds % 60).toString().padLeft(2, '0');

    return Text(
      '$minutesStr:$secondsStr',
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    );
  }

  /// ساخت دکمه‌های کنترل
  Widget _buildControlButtons(WhiteBoardPlaybackController controller) {
    return Row(
      children: [
        // دکمه برگشت به عقب
        IconButton(
          icon: const Icon(Icons.replay_10),
          onPressed:
              () => controller.seekToTime(
                (controller.currentTimeMs - 10000).clamp(
                  0,
                  controller.totalDurationMs,
                ),
              ),
          iconSize: 28,
          padding: const EdgeInsets.all(8),
        ),

        // دکمه پخش/توقف
        IconButton(
          icon: Icon(controller.isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: controller.isPlaying ? controller.pause : controller.play,
          iconSize: 36,
          padding: const EdgeInsets.all(8),
        ),

        // دکمه جلو بردن
        IconButton(
          icon: const Icon(Icons.forward_10),
          onPressed:
              () => controller.seekToTime(
                (controller.currentTimeMs + 10000).clamp(
                  0,
                  controller.totalDurationMs,
                ),
              ),
          iconSize: 28,
          padding: const EdgeInsets.all(8),
        ),
      ],
    );
  }

  /// ساخت کنترل سرعت
  Widget _buildSpeedControl(WhiteBoardPlaybackController controller) {
    return Row(
      children: [
        // دکمه کاهش سرعت
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: controller.decreaseSpeed,
          iconSize: 20,
          padding: const EdgeInsets.all(4),
        ),

        // نمایش سرعت فعلی
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${controller.playbackSpeed}x',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),

        // دکمه افزایش سرعت
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: controller.increaseSpeed,
          iconSize: 20,
          padding: const EdgeInsets.all(4),
        ),
      ],
    );
  }
}
