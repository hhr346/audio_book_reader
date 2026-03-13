import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import 'dart:io' show Platform;

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();

  bool _isSpeaking = false;
  bool _isPaused = false;
  bool _isInitialized = false;
  double _speechRate = 0.5; // 默认语速（0.5 是正常速度，0.8 太快了）
  double _pitch = 1.0;
  String? _language = 'zh-CN';
  
  // 自动连读支持
  bool _autoContinue = true; // 是否自动继续阅读下一页
  Function(String)? onPageChanged; // 翻页回调
  
  // 后台播放支持
  Timer? _sleepTimer;
  bool _sleepTimerActive = false;
  DateTime? _sleepTimerEndTime;
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
      print('🔧 开始初始化 TTS...');
      print('  - 语言：$_language');
      print('  - 语速：$_speechRate');
      print('  - 音调：$_pitch');
      
      // 设置语言（带错误处理）
      try {
        final langResult = await _flutterTts.setLanguage(_language!);
        print('✓ 语言设置结果：$langResult');
      } catch (e) {
        print('⚠️ 语言设置失败：$e，尝试使用英语');
        _language = 'en-US';
        await _flutterTts.setLanguage('en-US');
      }
      
      await _flutterTts.setSpeechRate(_speechRate);
      print('✓ 语速设置完成');
      
      await _flutterTts.setPitch(_pitch);
      print('✓ 音调设置完成');
      
      await _flutterTts.setVolume(1.0);
      print('✓ 音量设置完成');

      // 🔑 关键：iOS 专用音频配置（支持后台播放）
      if (Platform.isIOS) {
        print('📱 配置 iOS 音频类别（支持后台播放）...');
        try {
          // 使用 playback 模式，支持后台播放
          // 这样锁屏或切换应用后 TTS 仍能继续播放
          await _flutterTts.setIosAudioCategory(
            IosTextToSpeechAudioCategory.playback,  // 播放模式
            [
              IosTextToSpeechAudioCategoryOptions.mixWithOthers,  // 允许与其他音频混合
              IosTextToSpeechAudioCategoryOptions.duckOthers,     // 降低其他音频音量
            ],
          );
          print('✓ iOS 音频类别设置成功（playback 模式 - 支持后台播放）');
        } catch (e) {
          print('⚠️ iOS 音频类别设置失败：$e');
          // 回退到 ambient 模式
          try {
            await _flutterTts.setIosAudioCategory(
              IosTextToSpeechAudioCategory.ambient,
              [IosTextToSpeechAudioCategoryOptions.mixWithOthers],
            );
            print('✓ 回退到 ambient 模式');
          } catch (e2) {
            print('⚠️ ambient 模式也失败：$e2');
          }
        }
      }

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
        
        // 自动连读：播放完成后自动继续下一页
        if (_autoContinue && _currentText != null) {
          print('🔄 触发自动连读回调...');
          onPageChanged?.call(_currentText!);
        }
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
      
      print('🔊 TTS speak() 被调用');
      print('  - 文本长度：${text.length}');
      print('  - 文本内容：${text.substring(0, text.length > 30 ? 30 : text.length)}...');
      
      // 确保已初始化
      if (!_isInitialized) {
        print('⚠️ TTS 未初始化，正在初始化...');
        await init();
      }
      
      // 如果正在说话，先停止
      if (_isSpeaking && !_isPaused) {
        print('⏹️ 正在播放，先停止');
        await stop();
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      _currentText = text;
      print('📞 调用 _flutterTts.speak()...');
      final result = await _flutterTts.speak(text);
      print('📖 speak() 返回结果：$result');
      print('📖 开始朗读：${text.substring(0, text.length > 50 ? 50 : text.length)}...');
    } catch (e) {
      print('❌ TTS 朗读失败：$e');
      print('❌ 错误类型：${e.runtimeType}');
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
      // iOS 直接调用 speak 即可继续
      if (_currentText != null && _currentText!.isNotEmpty) {
        await _flutterTts.speak(_currentText!);
      }
      _isPaused = false;
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
  /// 如果正在播放，会停止并用新语速重新朗读
  Future<void> setRate(double rate) async {
    try {
      final wasSpeaking = _isSpeaking;
      final currentText = _currentText;
      
      // 如果正在播放，先停止
      if (wasSpeaking && currentText != null) {
        print('🔄 语速调节中，重新朗读...');
        await _flutterTts.stop();
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      _speechRate = rate;
      await _flutterTts.setSpeechRate(rate);
      print('⚡ 语速设置为：${(rate * 100).round()}%');
      
      // 如果之前在播放，用新语速重新朗读
      if (wasSpeaking && currentText != null) {
        await _flutterTts.speak(currentText);
        print('🔊 用新语速重新朗读');
      }
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
    _sleepTimerEndTime = DateTime.now().add(Duration(minutes: minutes));
    
    print('⏰ 定时关闭已设置：$minutes 分钟，结束时间：$_sleepTimerEndTime');
    
    _sleepTimer = Timer(Duration(minutes: minutes), () {
      _sleepTimerActive = false;
      _sleepTimerEndTime = null;
      stop();
      onSleepTimerComplete?.call(true);
      print('⏰ 定时关闭已触发，停止播放');
    });
  }
  
  /// 取消定时关闭
  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimerActive = false;
    _sleepTimerEndTime = null;
    print('❌ 定时关闭已取消');
  }
  
  /// 获取定时关闭剩余时间（秒）
  int? getSleepTimerRemaining() {
    if (!_sleepTimerActive || _sleepTimerEndTime == null) return null;
    final remaining = _sleepTimerEndTime!.difference(DateTime.now());
    return remaining.inSeconds.clamp(0, remaining.inSeconds);
  }
  
  /// 是否在定时关闭状态
  bool get isSleepTimerActive => _sleepTimerActive;
  
  /// 设置自动连读
  void setAutoContinue(bool value) {
    _autoContinue = value;
    print('⏭️ 自动连读：${value ? "开启" : "关闭"}');
  }
  
  /// 设置翻页回调
  void setOnPageChanged(Function(String text) callback) {
    onPageChanged = callback;
    print('📖 翻页回调已设置');
  }
  
  /// 获取当前语速
  double get rate => _speechRate;
}
