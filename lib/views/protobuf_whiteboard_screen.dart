import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/protobuf_whiteboard_provider.dart';
import '../widgets/drawing_canvas_protobuf.dart';
import '../widgets/stroke_settings_panel_protobuf.dart';
import '../models/white_board.dart';

/// صفحه اصلی وایت‌بورد با پروتوباف
class ProtobufWhiteBoardScreen extends StatefulWidget {
  const ProtobufWhiteBoardScreen({super.key});

  @override
  State<ProtobufWhiteBoardScreen> createState() =>
      _ProtobufWhiteBoardScreenState();
}

class _ProtobufWhiteBoardScreenState extends State<ProtobufWhiteBoardScreen> {
  bool _showSettings = false;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProtobufWhiteBoardProvider>(context);
    final whiteBoard = provider.whiteBoard;

    return Scaffold(
      appBar: AppBar(
        title: const Text('وایت‌بورد پروتوباف'),
        actions: [
          // دکمه ذخیره
          IconButton(
            icon:
                provider.isSaving
                    ? const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    )
                    : const Icon(Icons.save),
            onPressed:
                provider.isSaving
                    ? null
                    : () async {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      final result = await provider.saveCurrentWhiteBoard();
                      if (result && mounted) {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('وایت‌بورد با موفقیت ذخیره شد'),
                          ),
                        );
                      }
                    },
          ),

          // دکمه پاک کردن
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            onPressed: () {
              _showClearConfirmationDialog(context);
            },
          ),

          // دکمه بازگشت (Undo)
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed:
                whiteBoard == null || (whiteBoard.strokes.isEmpty)
                    ? null
                    : () {
                      provider.undoLastStroke();
                    },
          ),

          // دکمه بازپخش
          IconButton(
            icon: const Icon(Icons.slideshow),
            onPressed:
                whiteBoard == null
                    ? null
                    : () {
                      _navigateToPlayback(context, whiteBoard);
                    },
            tooltip: 'بازپخش وایت‌بورد',
          ),

          IconButton(
            icon: const Icon(Icons.data_object),
            onPressed: () {
              Navigator.pushNamed(context, '/protobuf_test');
            },
            tooltip: 'تست Protobuf',
          ),
        ],
      ),
      body: Column(
        children: [
          // کنوس وایت‌بورد (بخش اصلی)
          Expanded(
            child: Stack(
              children: [
                // کنوس
                whiteBoard == null
                    ? const Center(child: Text('وایت‌بورد جدید ایجاد کنید'))
                    : DrawingCanvasPanel(
                      strokes: whiteBoard.strokes,
                      currentStroke: provider.currentStroke,
                      onPanStart: provider.startStroke,
                      onPanUpdate: provider.updateStroke,
                      onPanEnd: provider.endStroke,
                    ),

                // نشانگر وضعیت بارگذاری
                if (provider.isLoading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),

          // پنل تنظیمات (اگر نمایش داده شود)
          if (_showSettings) const StrokeSettingsPanel(),
        ],
      ),

      // نوار پایین برای ابزارها
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // دکمه قلم
            IconButton(
              icon: const Icon(Icons.brush),
              onPressed: () {
                // اینجا می‌توانیم منطق انتخاب ابزار را پیاده‌سازی کنیم
              },
              color: Colors.blue,
              tooltip: 'قلم',
            ),

            // دکمه تنظیمات قلم
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                setState(() {
                  _showSettings = !_showSettings;
                });
              },
              color: _showSettings ? Colors.blue : null,
              tooltip: 'تنظیمات قلم',
            ),

            // دکمه باز کردن
            IconButton(
              icon: const Icon(Icons.folder_open),
              onPressed: () {
                _showLoadWhiteBoardDialog(context);
              },
              tooltip: 'باز کردن وایت‌بورد',
            ),

            // دکمه جدید
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                _showNewWhiteBoardDialog(context);
              },
              tooltip: 'وایت‌بورد جدید',
            ),
          ],
        ),
      ),
    );
  }

  /// دیالوگ تایید برای پاک کردن وایت‌بورد
  Future<void> _showClearConfirmationDialog(BuildContext context) async {
    final provider = Provider.of<ProtobufWhiteBoardProvider>(
      context,
      listen: false,
    );

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('پاک کردن وایت‌بورد'),
            content: const Text(
              'آیا مطمئن هستید که می‌خواهید تمام محتوای وایت‌بورد را پاک کنید؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('خیر'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('بله'),
              ),
            ],
          ),
    );

    if (result == true) {
      provider.clearWhiteBoard();
    }
  }

  /// دیالوگ ایجاد وایت‌بورد جدید
  Future<void> _showNewWhiteBoardDialog(BuildContext context) async {
    final provider = Provider.of<ProtobufWhiteBoardProvider>(
      context,
      listen: false,
    );
    final nameController = TextEditingController(text: 'وایت‌بورد جدید');

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('وایت‌بورد جدید'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'نام وایت‌بورد',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('لغو'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('ایجاد'),
              ),
            ],
          ),
    );

    if (result == true) {
      provider.createNewWhiteBoard(name: nameController.text);
    }
  }

  /// انتقال به صفحه بازپخش
  void _navigateToPlayback(BuildContext context, WhiteBoard whiteBoard) {
    Navigator.pushNamed(
      context,
      '/playback',
      arguments: {'whiteBoard': whiteBoard},
    );
  }

  /// دیالوگ بارگیری وایت‌بورد و اضافه کردن دکمه بازپخش
  Future<void> _showLoadWhiteBoardDialog(BuildContext contextOuter) async {
    final provider = Provider.of<ProtobufWhiteBoardProvider>(
      contextOuter,
      listen: false,
    );

    // بارگیری لیست وایت‌بوردها
    await provider.loadSavedWhiteBoardIds();

    if (!mounted) return;

    if (provider.savedWhiteBoardIds.isEmpty) {
      // اگر وایت‌بوردی وجود نداشت
      ScaffoldMessenger.of(contextOuter).showSnackBar(
        const SnackBar(content: Text('هیچ وایت‌بورد ذخیره شده‌ای وجود ندارد')),
      );
      return;
    }

    // نمایش دیالوگ انتخاب وایت‌بورد همراه با گزینه بازپخش
    final result = await showDialog<Map<String, dynamic>>(
      context: contextOuter,
      builder:
          (context) => AlertDialog(
            title: const Text('انتخاب وایت‌بورد'),
            content: SizedBox(
              width: double.maxFinite,
              height: 200,
              child: ListView.builder(
                itemCount: provider.savedWhiteBoardIds.length,
                itemBuilder: (context, index) {
                  final id = provider.savedWhiteBoardIds[index];
                  return ListTile(
                    title: Text('وایت‌بورد $id'),
                    onTap:
                        () => Navigator.of(
                          context,
                        ).pop({'id': id, 'action': 'load'}),
                    trailing: IconButton(
                      icon: const Icon(Icons.slideshow),
                      tooltip: 'بازپخش',
                      onPressed: () async {
                        // بارگیری وایت‌بورد برای بازپخش
                        Navigator.of(
                          context,
                        ).pop({'id': id, 'action': 'playback'});
                      },
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('لغو'),
              ),
            ],
          ),
    );

    if (result != null && mounted) {
      final String selectedId = result['id'];
      final String action = result['action'];

      // بارگیری وایت‌بورد
      await provider.loadWhiteBoard(selectedId);

      if (!mounted || provider.whiteBoard == null) {
        // در صورت خطا در بارگیری
        if (mounted) {
          ScaffoldMessenger.of(contextOuter).showSnackBar(
            SnackBar(
              content: Text('خطا در بارگیری وایت‌بورد با شناسه $selectedId'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // پیام موفقیت آمیز بودن بارگیری
      ScaffoldMessenger.of(contextOuter).showSnackBar(
        SnackBar(
          content: Text('وایت‌بورد با شناسه $selectedId با موفقیت بارگیری شد'),
          backgroundColor: Colors.green,
        ),
      );

      // اگر اکشن بازپخش بود، به صفحه بازپخش برویم
      if (action == 'playback') {
        _navigateToPlayback(contextOuter, provider.whiteBoard!);
      }
    }
  }
}
