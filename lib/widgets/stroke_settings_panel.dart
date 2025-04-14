import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/whiteboard_provider.dart';

/// پنل تنظیمات خط با قابلیت تنظیم نرمی، رنگ و ضخامت
class StrokeSettingsPanel extends StatelessWidget {
  const StrokeSettingsPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WhiteBoardProvider>(context);
    final style = provider.currentStyle;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('تنظیمات قلم', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),

          // رنگ قلم
          Row(
            children: [
              const Text('رنگ:'),
              const SizedBox(width: 16),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _buildColorPalette(context, style.color),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ضخامت قلم
          Row(
            children: [
              const Text('ضخامت:'),
              const SizedBox(width: 16),
              Expanded(
                child: Slider(
                  value: style.width,
                  min: 1,
                  max: 20,
                  divisions: 19,
                  label: style.width.toStringAsFixed(1),
                  onChanged: (value) {
                    provider.setStrokeStyle(width: value);
                  },
                ),
              ),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(style.width.toStringAsFixed(1)),
              ),
            ],
          ),

          // نرمی قلم
          Row(
            children: [
              const Text('نرمی:'),
              const SizedBox(width: 16),
              Expanded(
                child: Slider(
                  value: style.smoothness,
                  min: 0,
                  max: 1,
                  divisions: 10,
                  label: style.smoothness.toStringAsFixed(1),
                  onChanged: (value) {
                    provider.setStrokeStyle(smoothness: value);
                  },
                ),
              ),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(style.smoothness.toStringAsFixed(1)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ساخت پالت رنگ‌ها
  List<Widget> _buildColorPalette(BuildContext context, int selectedColor) {
    final colors = [
      Colors.black,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.brown,
      Colors.grey,
    ];

    return colors.map((color) {
      final isSelected = color.value == selectedColor;

      return GestureDetector(
        onTap: () {
          final provider = Provider.of<WhiteBoardProvider>(
            context,
            listen: false,
          );
          provider.setStrokeStyle(color: color.value);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey,
              width: isSelected ? 3 : 1,
            ),
          ),
        ),
      );
    }).toList();
  }
}
