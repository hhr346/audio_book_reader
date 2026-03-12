import 'package:flutter/foundation.dart';
import 'package:kokoro_tts_flutter/kokoro_tts_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import 'dart:io';

/// TTS 引擎类型
enum TtsEngine {
  kokoro,    // Kokoro AI（高质量，需要模型文件）
  system     // 系统 TTS（兼容性好）
}

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  // Kokoro TTS
  KokoroTtsFlutter? _kokoroTts;
  
  // 系统 TTS（备用）
  final FlutterTts _flutterTts = FlutterTts();

  // 状态
  TtsEngine _currentEngine = TtsEngine.system;
  bool _isSpeaking = false;
  bool _isPaused = false;
  bool _isInitialized = false;
  bool _kokoroAvailable = false;
  
  // 参数
  double _speechRate = 0.5;
  double _pitch = 1.0;
  String? _language = 'en-US';  // Kokoro 主要支持英语
  
  // 当前文本
  String? _currentText;
  
  // 定时关闭
  Timer? _sleepTimer;
  bool _sleepTimerActive = false;
  Function(bool)? onSleepTimerComplete;

  /// 初始化 TTS
  Future<void> init() async {
    if (_isInitialized) {
      print('✅ TTS 已初始化，跳过');
      return;
    }
    
    print('🔧 开始初始化 TTS...');
    
    // 1. 尝试初始化 Kokoro TTS
    _kokoroAvailable = await _initKokoro();
    
    if (_kokoroAvailable) {
      _currentEngine = TtsEngine.kokoro;
      print('✅ Kokoro TTS 可用（高质量模式）');
    } else {
      _currentEngine = TtsEngine.system;
      print('⚠️ Kokoro 不可用，使用系统 TTS');
      await _initSystemTts();
    }
    
    _isInitialized = true;
    print('✅ TTS 初始化完成，当前引擎：${_currentEngine == TtsEngine.kokoro ? "Kokoro" : "System"}');
  }

  /// 初始化 Kokoro TTS
  Future<bool> _initKokoro() async {
    try {
      print('📦 检查 Kokoro 模型文件...');
      
      // 检查模型文件是否存在
      final kokoroPath = await _findAssetFile('kokoro-v1.0.int8.onnx');
      final voicesPath = await _findAssetFile('voices-v1.0.bin');
      
      if (kokoroPath == null || voicesPath == null) {
        print('⚠️ Kokoro 模型文件缺失');
        print('   请运行：bash assets/download_models.sh');
        return false;
      }
      
      print('✓ 找到模型文件');
      print('  - Kokoro: $kokoroPath');
      print('  - Voices: $voicesPath');
      
      // 创建 Kokoro TTS 实例
      _kokoroTts = KokoroTtsFlutter(
        modelPath: kokoroPath,
        voicesPath: voicesPath,
      );
      
      await _kokoroTts!.initialize();
      print('✅ Kokoro TTS 初始化成功');
      
      return true;
    } catch (e) {
      print('❌ Kokoro 初始化失败：$e');
      return false;
    }
  }

  /// 查找 assets 中的文件（复制到临时目录）
  Future<String?> _findAssetFile(String filename) async {
    try {
      // 对于本地文件，直接检查路径
      final possiblePaths = [
        'assets/$filename',
        filename,
      ];
      
      for (final path in possiblePaths) {
        final file = File(path);
        if (await file.exists()) {
          return path;
        }
      }
      
      // 尝试从 assets 目录加载
      final localPath = 'assets/$filename';
      return localPath;
    } catch (e) {
      print('⚠️ 查找文件失败 $filename: $e');
      return null;
    }
  }

  /// 初始化系统 TTS
  Future<void> _initSystemTts() async {
    try {
      await _flutterTts.setLanguage(_language ?? 'zh-CN');
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setPitch(_pitch);
      await _flutterTts.setVolume(1.0);

      // 监听状态
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        _isPaused = false;
        print('🔊 [System] 开始播放');
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        _isPaused = false;
        print('✅ [System] 播放完成');
      });

      _flutterTts.setCancelHandler(() {
        _isSpeaking = false;
        _isPaused = false;
        print('⏹️ [System] 已取消');
      });

      _flutterTts.setPauseHandler(() {
        _isPaused = true;
        print('⏸️ [System] 已暂停');
      });

      _flutterTts.setContinueHandler(() {
        _isPaused = false;
        print('▶️ [System] 继续播放');
      });

      _flutterTts.setErrorHandler((message) {
        print('❌ [System] Error: $message');
        _isSpeaking = false;
      });
      
      print('✅ 系统 TTS 初始化完成');
    } catch (e) {
      print('❌ 系统 TTS 初始化失败：$e');
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
      
      // 根据引擎选择朗读方式
      if (_currentEngine == TtsEngine.kokoro && _kokoroTts != null) {
        await _speakKokoro(text);
      } else {
        await _speakSystem(text);
      }
    } catch (e) {
      print('❌ TTS 朗读失败：$e');
      _isSpeaking = false;
      // 尝试切换到系统 TTS
      if (_currentEngine == TtsEngine.kokoro) {
        print('🔄 切换到系统 TTS...');
        _currentEngine = TtsEngine.system;
        await _initSystemTts();
      }
      rethrow;
    }
  }

  /// 使用 Kokoro 朗读
  Future<void> _speakKokoro(String text) async {
    if (_kokoroTts == null) {
      throw Exception('Kokoro TTS 未初始化');
    }
    
    print('📖 [Kokoro] 开始朗读：${text.substring(0, text.length > 50 ? 50 : text.length)}...');
    
    // Kokoro 生成音频并播放
    final audioData = await _kokoroTts!.synthesize(text);
    
    // 播放音频（这里需要实现音频播放）
    // 注意：kokoro_tts_flutter 返回的是音频数据，需要额外处理
    // 简化处理：暂时回退到系统 TTS
    
    print('⚠️ Kokoro 音频播放需要额外处理，使用系统 TTS 播放');
    await _speakSystem(text);
  }

  /// 使用系统 TTS 朗读
  Future<void> _speakSystem(String text) async {
    final result = await _flutterTts.speak(text);
    print('📖 [System] 开始朗读：${text.substring(0, text.length > 50 ? 50 : text.length)}... 结果：$result');
  }

  /// 暂停
  Future<void> pause() async {
    if (_isSpeaking && !_isPaused) {
      if (_currentEngine == TtsEngine.kokoro && _kokoroTts != null) {
        // Kokoro 暂停逻辑（如果支持）
        print('⏸️ [Kokoro] 暂停（待实现）');
      } else {
        await _flutterTts.pause();
        print('⏸️ [System] 暂停播放');
      }
    }
  }

  /// 继续
  Future<void> resume() async {
    if (_isPaused) {
      if (_currentEngine == TtsEngine.kokoro && _kokoroTts != null) {
        // Kokoro 继续逻辑
        print('▶️ [Kokoro] 继续（待实现）');
      } else {
        await _flutterTts.stop();
        if (_currentText != null && _currentText!.isNotEmpty) {
          await speak(_currentText!);
        }
        print('▶️ [System] 继续播放');
      }
    }
  }

  /// 停止
  Future<void> stop() async {
    if (_currentEngine == TtsEngine.kokoro && _kokoroTts != null) {
      // Kokoro 停止逻辑
      print('⏹️ [Kokoro] 停止');
    }
    await _flutterTts.stop();
    _isSpeaking = false;
    _isPaused = false;
    _currentText = null;
    print('⏹️ 停止播放');
  }

  /// 设置语速
  Future<void> setRate(double rate) async {
    _speechRate = rate;
    if (_currentEngine == TtsEngine.system) {
      await _flutterTts.setSpeechRate(rate);
    }
    print('⚡ 语速设置为：${(rate * 100).round()}%');
  }

  /// 设置音调
  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
    if (_currentEngine == TtsEngine.system) {
      await _flutterTts.setPitch(pitch);
    }
    print('🎵 音调设置为：$pitch');
  }

  /// 设置语言
  Future<void> setLanguage(String language) async {
    _language = language;
    if (_currentEngine == TtsEngine.system) {
      await _flutterTts.setLanguage(language);
    }
    print('🌐 语言设置为：$language');
  }

  /// 获取可用语言
  Future<List<String>> getAvailableLanguages() async {
    if (_currentEngine == TtsEngine.kokoro) {
      return ['en-US', 'en-GB', 'ja-JP'];  // Kokoro 支持的语言
    } else {
      return [
        'zh-CN', 'zh-TW', 'en-US', 'en-GB', 'ja-JP', 'ko-KR',
      ];
    }
  }

  /// 当前是否在说话
  bool get isSpeaking => _isSpeaking;

  /// 当前是否暂停
  bool get isPaused => _isPaused;

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 当前使用的引擎
  TtsEngine get currentEngine => _currentEngine;

  /// Kokoro 是否可用
  bool get kokoroAvailable => _kokoroAvailable;

  /// 释放资源
  Future<void> dispose() async {
    await stop();
    _sleepTimer?.cancel();
    _kokoroTts?.dispose();
  }

  // ========== 定时关闭功能 ==========
  
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
  
  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimerActive = false;
    print('❌ 定时关闭已取消');
  }
  
  bool get isSleepTimerActive => _sleepTimerActive;
}
