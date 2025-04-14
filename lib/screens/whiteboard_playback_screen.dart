import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/white_board.dart';
import '../controllers/whiteboard_playback_controller.dart';
import '../widgets/whiteboard_view.dart';
import '../widgets/playback_controls.dart';

class WhiteBoardPlaybackScreen extends StatelessWidget {
  final WhiteBoard whiteBoard;

  const WhiteBoardPlaybackScreen({Key? key, required this.whiteBoard})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (context) =>
              WhiteBoardPlaybackController(originalWhiteBoard: whiteBoard),
      child: Scaffold(
        appBar: AppBar(
          title: Text('بازپخش: ${whiteBoard.name}'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Column(
          children: [
            // نمایش وایت‌بورد
            Expanded(
              child: Consumer<WhiteBoardPlaybackController>(
                builder: (context, controller, child) {
                  return WhiteBoardView(
                    whiteBoard: controller.currentWhiteBoard,
                    readOnly: true,
                  );
                },
              ),
            ),

            // کنترل‌های بازپخش
            Consumer<WhiteBoardPlaybackController>(
              builder: (context, controller, child) {
                return PlaybackControls(controller: controller);
              },
            ),
          ],
        ),
      ),
    );
  }
}
