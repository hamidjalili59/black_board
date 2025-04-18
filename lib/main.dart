import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/protobuf_whiteboard_provider.dart';
import 'views/protobuf_whiteboard_screen.dart';
import 'views/protobuf_test_screen.dart';
import 'views/whiteboard_playback_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // تنظیم جهت برنامه بر اساس زبان
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => ProtobufWhiteBoardProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'وایت‌بورد هوشمند',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          fontFamily: 'Vazir',
          textTheme: const TextTheme(
            // تنظیم فونت‌ها برای پشتیبانی از زبان فارسی
            bodyLarge: TextStyle(fontSize: 16),
            bodyMedium: TextStyle(fontSize: 14),
            titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        // تنظیمات localization
        locale: const Locale('fa', 'IR'),
        supportedLocales: const [Locale('fa', 'IR'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routes: {
          '/': (context) => const ProtobufWhiteBoardScreen(),
          '/protobuf_test': (context) => const ProtobufTestScreen(),
          '/playback': (context) {
            final args =
                ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
            final whiteBoard = args?['whiteBoard'];
            if (whiteBoard != null) {
              return WhiteBoardPlaybackView(whiteBoard: whiteBoard);
            }
            // برگشت به صفحه اصلی در صورت نبود داده
            return const ProtobufWhiteBoardScreen();
          },
        },
      ),
    );
  }
}
