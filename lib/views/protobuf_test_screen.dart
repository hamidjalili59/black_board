import 'package:flutter/material.dart';
import '../tests/protobuf_test.dart';

/// صفحه تست برای بررسی عملکرد Protobuf
class ProtobufTestScreen extends StatefulWidget {
  const ProtobufTestScreen({super.key});

  @override
  State<ProtobufTestScreen> createState() => _ProtobufTestScreenState();
}

class _ProtobufTestScreenState extends State<ProtobufTestScreen> {
  List<String> _logs = [];
  bool _isTestRunning = false;

  @override
  void initState() {
    super.initState();
    _redirectLogOutput();
  }

  /// تغییر مسیر خروجی‌های لاگ به لیست داخلی
  void _redirectLogOutput() {
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        setState(() {
          _logs.add(message);
        });
      }
    };
  }

  /// اجرای تست Protobuf
  Future<void> _runTest() async {
    setState(() {
      _isTestRunning = true;
      _logs.clear();
    });

    try {
      await testProtobufConversion();
    } catch (e) {
      setState(() {
        _logs.add('خطا: $e');
      });
    } finally {
      setState(() {
        _isTestRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تست Protobuf')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isTestRunning ? null : _runTest,
              child:
                  _isTestRunning
                      ? const CircularProgressIndicator()
                      : const Text('اجرای تست Protobuf'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 4.0,
                  ),
                  child: Text(_logs[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
