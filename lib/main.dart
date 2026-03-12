import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/book.dart';
import 'services/storage_service.dart';
import 'services/tts_service.dart';
// import 'services/tts_service_kokoro.dart';  // 启用 Kokoro TTS 时取消注释
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化 Hive
  await Hive.initFlutter();
  
  // 注册适配器
  Hive.registerAdapter(BookAdapter());
  
  // 初始化存储服务
  await StorageService().init();
  
  // 初始化 TTS 服务
  // 使用 Kokoro TTS 时取消注释下面这行，并注释掉上面这行
  // await TtsServiceKokoro().init();
  await TtsService().init();
  
  runApp(const AudioBookApp());
}

class AudioBookApp extends StatefulWidget {
  const AudioBookApp({super.key});

  @override
  State<AudioBookApp> createState() => _AudioBookAppState();
}

class _AudioBookAppState extends State<AudioBookApp> {
  bool _isDarkMode = false;
  
  @override
  void initState() {
    super.initState();
    _loadTheme();
  }
  
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('is_dark_mode') ?? false;
    setState(() {
      _isDarkMode = isDark;
    });
  }
  
  void _toggleTheme(bool isDark) {
    setState(() {
      _isDarkMode = isDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StorageService(),
      child: MaterialApp(
        title: '有声图书阅读器',
        debugShowCheckedModeBanner: false,
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          scaffoldBackgroundColor: Colors.white,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          appBarTheme: AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.grey[850],
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            color: Colors.grey[850],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          scaffoldBackgroundColor: Colors.grey[900],
        ),
        home: HomeScreen(
          isDarkMode: _isDarkMode,
          onThemeChanged: _toggleTheme,
        ),
      ),
    );
  }
}
