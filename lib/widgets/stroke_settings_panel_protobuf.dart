import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/protobuf_whiteboard_provider.dart';
import '../models/stroke_style.dart';

/// پنل تنظیمات خط
class StrokeSettingsPanel extends StatelessWidget {
  const StrokeSettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProtobufWhiteBoardProvider>(context);
    final style = provider.strokeStyle;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        border: Border(top: BorderSide(color: Colors.grey.shade400)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // انتخاب رنگ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildColorButton(
                context,
                Colors.black,
                style.color == Colors.black,
              ),
              _buildColorButton(context, Colors.red, style.color == Colors.red),
              _buildColorButton(
                context,
                Colors.blue,
                style.color == Colors.blue,
              ),
              _buildColorButton(
                context,
                Colors.green,
                style.color == Colors.green,
              ),
              _buildColorButton(
                context,
                Colors.yellow,
                style.color == Colors.yellow,
              ),
              _buildColorButton(
                context,
                Colors.orange,
                style.color == Colors.orange,
              ),
              _buildColorButton(
                context,
                Colors.purple,
                style.color == Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // تنظیم ضخامت
          Row(
            children: [
              const Text('ضخامت:'),
              Expanded(
                child: Slider(
                  value: style.thickness,
                  min: 1.0,
                  max: 10.0,
                  onChanged: (value) => provider.setThickness(value),
                ),
              ),
              Text('${style.thickness.toStringAsFixed(1)}'),
            ],
          ),

          // انتخاب نوع خط
          Row(
            children: [
              const Text('نوع خط:'),
              const SizedBox(width: 16),
              ToggleButtons(
                isSelected: [
                  style.type == StrokeType.solid,
                  style.type == StrokeType.dotted,
                ],
                onPressed: (index) {
                  provider.setStrokeType(
                    index == 0 ? StrokeType.solid : StrokeType.dotted,
                  );
                },
                children: const [
                  Padding(padding: EdgeInsets.all(8.0), child: Text('ممتد')),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('نقطه‌چین'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// دکمه انتخاب رنگ
  Widget _buildColorButton(BuildContext context, Color color, bool isSelected) {
    return GestureDetector(
      onTap:
          () => Provider.of<ProtobufWhiteBoardProvider>(
            context,
            listen: false,
          ).setColor(color),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.grey,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }
}
