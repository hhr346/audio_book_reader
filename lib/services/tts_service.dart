import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();

  bool _isSpeaking = false;
  bool _isPaused = false;
  double _speechRate = 0.5; // 默认语速
  double _pitch = 1.0;
  String? _language = 'zh-CN';

  /// 初始化 TTS
  Future<void> init() async {
    await _flutterTts.setLanguage(_language!);
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setPitch(_pitch);
    await _flutterTts.setVolume(1.0);

    // 监听状态
    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
      _isPaused = false;
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      _isPaused = false;
    });

    _flutterTts.setCancelHandler(() {
      _isSpeaking = false;
      _isPaused = false;
    });

    _flutterTts.setPauseHandler(() {
      _isPaused = true;
    });

    _flutterTts.setContinueHandler(() {
      _isPaused = false;
    });

    _flutterTts.setErrorHandler((message) {
      print('TTS Error: $message');
      _isSpeaking = false;
    });
  }

  /// 朗读文本
  Future<void> speak(String text) async {
    if (_isSpeaking && !_isPaused) {
      await stop();
    }
    await _flutterTts.speak(text);
  }

  /// 暂停
  Future<void> pause() async {
    if (_isSpeaking && !_isPaused) {
      await _flutterTts.pause();
    }
  }

  /// 继续
  Future<void> resume() async {
    if (_isPaused) {
      await _flutterTts.stop();
      // 需要重新调用 speak 来继续
    }
  }

  /// 停止
  Future<void> stop() async {
    await _flutterTts.stop();
    _isSpeaking = false;
    _isPaused = false;
  }

  /// 设置语速 (0.0 - 1.0)
  Future<void> setRate(double rate) async {
    _speechRate = rate;
    await _flutterTts.setSpeechRate(rate);
  }

  /// 设置音调 (0.5 - 2.0)
  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
    await _flutterTts.setPitch(pitch);
  }

  /// 设置语言
  Future<void> setLanguage(String language) async {
    _language = language;
    await _flutterTts.setLanguage(language);
  }

  /// 获取可用语言列表
  Future<List<String>> getAvailableLanguages() async {
    // 注意：flutter_tts 没有直接获取可用语言的方法
    // 这里返回常用语言列表
    return [
      'zh-CN', // 中文
      'zh-TW', // 繁体中文
      'en-US', // 英文（美）
      'en-GB', // 英文（英）
      'ja-JP', // 日文
      'ko-KR', // 韩文
    ];
  }

  /// 当前是否在说话
  bool get isSpeaking => _isSpeaking;

  /// 当前是否暂停
  bool get isPaused => _isPaused;

  /// 获取当前语速
  double get speechRate => _speechRate;

  /// 获取当前音调
  double get pitch => _pitch;

  /// 获取当前语言
  String? get language => _language;

  /// 释放资源
  Future<void> dispose() async {
    await stop();
  }
}
