import 'dart:io';

void main() async {
  // ایجاد دایرکتوری‌های خروجی اگر وجود ندارند
  final generatedDir = Directory('lib/generated');
  if (!await generatedDir.exists()) {
    await generatedDir.create(recursive: true);
  }

  print('شروع تولید کدهای Protobuf...');

  // اجرای دستور protoc برای تولید کدهای دارت
  final result = await Process.run('protoc', [
    '--dart_out=grpc:lib/generated',
    '-Ilib/proto',
    'lib/proto/drawing.proto',
  ]);

  if (result.exitCode != 0) {
    print('خطا در تولید کدهای Protobuf:');
    print(result.stderr);
    exit(1);
  }

  print('کدهای Protobuf با موفقیت تولید شدند!');
  print('خروجی: ${result.stdout}');
}

/*
برای استفاده از این اسکریپت، باید ابتدا ابزارهای protoc و protoc-plugin دارت را نصب کنید:

1. نصب protoc از https://github.com/protocolbuffers/protobuf/releases
2. نصب پلاگین دارت با دستور:
   dart pub global activate protoc_plugin

سپس می‌توانید این اسکریپت را با دستور زیر اجرا کنید:
   dart run scripts/generate_protos.dart
*/
