import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();

  bool _isSpeaking = false;
  bool _isPaused = false;
  bool _isInitialized = false;
  double _speechRate = 0.5; // 默认语速
  double _pitch = 1.0;
  String? _language = 'zh-CN';
  
  // 后台播放支持
  Timer? _sleepTimer;
  bool _sleepTimerActive = false;
  Function(bool)? onSleepTimerComplete;
  
  // 当前正在朗读的文本
  String? _currentText;

  /// 初始化 TTS
  Future<void> init() async {
    if (_isInitialized) {
      print('✅ TTS 已初始化，跳过');
      return;
    }
    
    try {
      await _flutterTts.setLanguage(_language!);
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setPitch(_pitch);
      await _flutterTts.setVolume(1.0);

      // 监听状态
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        _isPaused = false;
        print('🔊 TTS 开始播放');
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        _isPaused = false;
        print('✅ TTS 播放完成');
      });

      _flutterTts.setCancelHandler(() {
        _isSpeaking = false;
        _isPaused = false;
        print('⏹️ TTS 已取消');
      });

      _flutterTts.setPauseHandler(() {
        _isPaused = true;
        print('⏸️ TTS 已暂停');
      });

      _flutterTts.setContinueHandler(() {
        _isPaused = false;
        print('▶️ TTS 继续播放');
      });

      _flutterTts.setErrorHandler((message) {
        print('❌ TTS Error: $message');
        _isSpeaking = false;
      });
      
      _isInitialized = true;
      print('✅ TTS 初始化完成');
    } catch (e) {
      print('❌ TTS 初始化失败：$e');
      rethrow;
    }
  }

  /// 朗读文本
  Future<void> speak(String text) async {
    try {
      if (text.isEmpty) {
        print('⚠️ 文本为空，跳过播放');
        return;
      }
      
      // 确保已初始化
      if (!_isInitialized) {
        print('⚠️ TTS 未初始化，正在初始化...');
        await init();
      }
      
      // 如果正在说话，先停止
      if (_isSpeaking && !_isPaused) {
        await stop();
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      _currentText = text;
      final result = await _flutterTts.speak(text);
      print('📖 开始朗读：${text.substring(0, text.length > 50 ? 50 : text.length)}... 结果：$result');
    } catch (e) {
      print('❌ TTS 朗读失败：$e');
      _isSpeaking = false;
      rethrow;
    }
  }

  /// 暂停
  Future<void> pause() async {
    if (_isSpeaking && !_isPaused) {
      await _flutterTts.pause();
      print('⏸️ 暂停播放');
    }
  }

  /// 继续
  Future<void> resume() async {
    if (_isPaused) {
      await _flutterTts.stop();
      // 重新朗读当前文本
      if (_currentText != null && _currentText!.isNotEmpty) {
        await speak(_currentText!);
      }
      print('▶️ 继续播放');
    }
  }

  /// 停止
  Future<void> stop() async {
    await _flutterTts.stop();
    _isSpeaking = false;
    _isPaused = false;
    _currentText = null;
    print('⏹️ 停止播放');
  }

  /// 设置语速 (0.0 - 1.0)
  Future<void> setRate(double rate) async {
    try {
      _speechRate = rate;
      await _flutterTts.setSpeechRate(rate);
      print('⚡ 语速设置为：${(rate * 100).round()}%');
    } catch (e) {
      print('❌ 设置语速失败：$e');
      rethrow;
    }
  }

  /// 设置音调 (0.5 - 2.0)
  Future<void> setPitch(double pitch) async {
    try {
      _pitch = pitch;
      await _flutterTts.setPitch(pitch);
      print('🎵 音调设置为：$pitch');
    } catch (e) {
      print('❌ 设置音调失败：$e');
      rethrow;
    }
  }

  /// 设置语言
  Future<void> setLanguage(String language) async {
    _language = language;
    await _flutterTts.setLanguage(language);
    print('🌐 语言设置为：$language');
  }

  /// 获取可用语言列表
  Future<List<String>> getAvailableLanguages() async {
    // 注意：flutter_tts 没有直接获取可用语言的方法
    // 这里返回常用语言列表
    return [
      'zh-CN', // 中文（简体）
      'zh-TW', // 中文（繁体）
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

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 获取当前语速
  double get speechRate => _speechRate;

  /// 获取当前音调
  double get pitch => _pitch;

  /// 获取当前语言
  String? get language => _language;

  /// 释放资源
  Future<void> dispose() async {
    await stop();
    _sleepTimer?.cancel();
  }

  // ========== 定时关闭功能 ==========
  
  /// 设置定时关闭（分钟）
  void setSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    _sleepTimerActive = true;
    
    print('⏰ 定时关闭已设置：$minutes 分钟');
    
    _sleepTimer = Timer(Duration(minutes: minutes), () {
      _sleepTimerActive = false;
      stop();
      onSleepTimerComplete?.call(true);
      print('⏰ 定时关闭已触发，停止播放');
    });
  }
  
  /// 取消定时关闭
  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimerActive = false;
    print('❌ 定时关闭已取消');
  }
  
  /// 获取定时关闭剩余时间（秒）
  int? getSleepTimerRemaining() {
    if (!_sleepTimerActive || _sleepTimer == null) return null;
    // 注意：Timer 没有直接获取剩余时间的方法，这里简化处理
    return 0;
  }
  
  /// 是否在定时关闭状态
  bool get isSleepTimerActive => _sleepTimerActive;
}
