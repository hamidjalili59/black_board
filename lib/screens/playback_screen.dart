import 'package:flutter/material.dart';
import '../models/white_board.dart';
import '../controllers/whiteboard_playback_controller.dart';
import '../widgets/playback_controls.dart';
import '../widgets/whiteboard_view.dart';

/// صفحه نمایش بازپخش وایت‌بورد
class PlaybackScreen extends StatefulWidget {
  final WhiteBoard whiteBoard;

  const PlaybackScreen({Key? key, required this.whiteBoard}) : super(key: key);

  @override
  State<PlaybackScreen> createState() => _PlaybackScreenState();
}

class _PlaybackScreenState extends State<PlaybackScreen> {
  late WhiteBoardPlaybackController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WhiteBoardPlaybackController(
      originalWhiteBoard: widget.whiteBoard,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بازپخش وایت‌بورد'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // منطق به اشتراک‌گذاری بازپخش در اینجا پیاده‌سازی شود
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('قابلیت به اشتراک‌گذاری در حال پیاده‌سازی است'),
                ),
              );
            },
            tooltip: 'اشتراک‌گذاری',
          ),
        ],
      ),
      body: Column(
        children: [
          // محیط نقاشی وایت‌بورد
          Expanded(
            child: Container(
              color: Colors.grey[200],
              width: double.infinity,
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  return WhiteBoardView(
                    whiteBoard: _controller.currentWhiteBoard,
                    readOnly: true,
                  );
                },
              ),
            ),
          ),

          // کنترل‌های بازپخش در پایین صفحه
          Padding(
            padding: const EdgeInsets.all(16),
            child: PlaybackControls(controller: _controller),
          ),
        ],
      ),
    );
  }
}
