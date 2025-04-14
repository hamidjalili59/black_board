import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/whiteboard_provider.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/stroke_settings_panel.dart';

/// صفحه اصلی وایت‌بورد
class WhiteBoardScreen extends StatefulWidget {
  const WhiteBoardScreen({Key? key}) : super(key: key);

  @override
  State<WhiteBoardScreen> createState() => _WhiteBoardScreenState();
}

class _WhiteBoardScreenState extends State<WhiteBoardScreen> {
  bool _showSettings = false;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WhiteBoardProvider>(context);
    final whiteBoard = provider.whiteBoard;

    return Scaffold(
      appBar: AppBar(
        title: const Text('وایت‌بورد'),
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
                      final result = await provider.saveCurrentWhiteBoard();
                      if (result && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
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
    final provider = Provider.of<WhiteBoardProvider>(context, listen: false);

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
    final provider = Provider.of<WhiteBoardProvider>(context, listen: false);
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

  /// دیالوگ بارگیری وایت‌بورد
  Future<void> _showLoadWhiteBoardDialog(BuildContext context) async {
    final provider = Provider.of<WhiteBoardProvider>(context, listen: false);

    // بارگیری لیست وایت‌بوردها
    await provider.loadSavedWhiteBoardIds();

    if (!mounted) return;

    if (provider.savedWhiteBoardIds.isEmpty) {
      // اگر وایت‌بوردی وجود نداشت
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('هیچ وایت‌بورد ذخیره شده‌ای وجود ندارد')),
      );
      return;
    }

    // نمایش دیالوگ انتخاب وایت‌بورد
    final selectedId = await showDialog<String>(
      context: context,
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
                    onTap: () => Navigator.of(context).pop(id),
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

    if (selectedId != null && mounted) {
      await provider.loadWhiteBoard(selectedId);

      // نمایش پیام متناسب با نتیجه بارگذاری
      if (provider.whiteBoard != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'وایت‌بورد با شناسه $selectedId با موفقیت بارگذاری شد',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بارگذاری وایت‌بورد با شناسه $selectedId'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
