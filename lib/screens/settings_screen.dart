import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../services/tts_service.dart';

class SettingsScreen extends StatefulWidget {
  final Function(double) onFontSizeChanged;
  final Function(bool) onThemeChanged;
  final double currentFontSize;
  final bool currentIsDarkMode;

  const SettingsScreen({
    super.key,
    required this.onFontSizeChanged,
    required this.onThemeChanged,
    required this.currentFontSize,
    required this.currentIsDarkMode,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _fontSize;
  late bool _isDarkMode;
  int _sleepTimerMinutes = 30;
  bool _sleepTimerEnabled = false;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  
  @override
  void initState() {
    super.initState();
    _fontSize = widget.currentFontSize;
    _isDarkMode = widget.currentIsDarkMode;
    _loadSettings();
    _startCountdownUpdate();
  }
  
  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
  
  /// 每秒更新倒计时显示
  void _startCountdownUpdate() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _sleepTimerEnabled) {
        final remaining = TtsService().getSleepTimerRemaining();
        if (remaining != null && remaining > 0) {
          setState(() => _remainingSeconds = remaining);
        } else if (remaining == 0 || remaining == null) {
          setState(() {
            _sleepTimerEnabled = false;
            _remainingSeconds = 0;
          });
        }
      }
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('font_size') ?? widget.currentFontSize;
      _isDarkMode = prefs.getBool('is_dark_mode') ?? widget.currentIsDarkMode;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_size', _fontSize);
    await prefs.setBool('is_dark_mode', _isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 阅读设置
          _buildSectionTitle('阅读设置'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.text_fields),
                  title: const Text('字体大小'),
                  subtitle: Text('${_fontSize.round()}磅'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showFontSizeDialog(),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode),
                  title: const Text('夜间模式'),
                  subtitle: const Text('深色主题更护眼'),
                  value: _isDarkMode,
                  onChanged: (value) {
                    setState(() {
                      _isDarkMode = value;
                      widget.onThemeChanged(value);
                      _saveSettings();
                    });
                    _showThemeChangeSnackbar();
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 听书设置
          _buildSectionTitle('听书设置'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.timer),
                  title: const Text('定时关闭'),
                  subtitle: _sleepTimerEnabled
                      ? Text('⏰ 剩余：${_formatTime(_remainingSeconds)}')
                      : Text('$_sleepTimerMinutes 分钟后停止播放'),
                  value: _sleepTimerEnabled,
                  onChanged: (value) {
                    setState(() {
                      _sleepTimerEnabled = value;
                    });
                    if (value) {
                      // 开启定时关闭
                      TtsService().setSleepTimer(_sleepTimerMinutes);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('✅ 定时关闭已开启：$_sleepTimerMinutes 分钟')),
                      );
                    } else {
                      // 关闭定时关闭
                      TtsService().cancelSleepTimer();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('❌ 定时关闭已取消')),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.speed),
                  title: const Text('语速设置'),
                  subtitle: const Text('调整 TTS 播放速度'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showSpeechRateDialog(),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 关于
          _buildSectionTitle('关于'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('应用信息'),
                  subtitle: const Text('版本 0.2.0 - 支持分页阅读'),
                  onTap: () => _showAboutDialog(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  /// 格式化时间为 MM:SS
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showFontSizeDialog() {
    double tempFontSize = _fontSize;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('字体大小'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: tempFontSize,
                min: 16,
                max: 40,
                divisions: 24,
                label: '${tempFontSize.round()}磅',
                onChanged: (value) {
                  setDialogState(() => tempFontSize = value);
                },
              ),
              const SizedBox(height: 16),
              Text(
                '预览效果',
                style: TextStyle(fontSize: tempFontSize),
              ),
              const SizedBox(height: 8),
              Text(
                '这是预览文本，字体大小会实时变化',
                style: TextStyle(fontSize: tempFontSize),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _fontSize = tempFontSize;
                widget.onFontSizeChanged(_fontSize);
                _saveSettings();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ 字体大小已保存')),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showSleepTimerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('定时关闭时间'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('选择定时时间'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TimerChip(minutes: 15, selected: _sleepTimerMinutes == 15),
                _TimerChip(minutes: 30, selected: _sleepTimerMinutes == 30),
                _TimerChip(minutes: 60, selected: _sleepTimerMinutes == 60),
                _TimerChip(minutes: 90, selected: _sleepTimerMinutes == 90),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              // 只设置时间，不立即启动
              setState(() {
                _sleepTimerMinutes = _sleepTimerMinutes;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('⏰ 定时时间已设置为 $_sleepTimerMinutes 分钟，请在设置界面开启')),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Widget _TimerChip({required int minutes, required bool selected}) {
    return ChoiceChip(
      label: Text('$minutes 分钟'),
      selected: selected,
      onSelected: (value) {
        if (value) {
          setState(() => _sleepTimerMinutes = minutes);
        }
      },
    );
  }

  void _showSpeechRateDialog() {
    final ttsService = TtsService();
    double rate = ttsService.speechRate;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('语速设置'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: rate,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label: '${(rate * 100).round()}%',
                onChanged: (value) {
                  setDialogState(() => rate = value);
                },
              ),
              Text('当前语速：${(rate * 100).round()}%'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ttsService.setRate(rate);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ 语速已保存')),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showThemeChangeSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isDarkMode ? '🌙 已切换到夜间模式' : '☀️ 已切换到日间模式'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: '有声图书阅读器',
      applicationVersion: '0.2.0',
      applicationIcon: const Icon(Icons.menu_book, size: 48),
      children: [
        const Text('一款支持 epub 格式的图书阅读器，配备 TTS 听书功能。'),
        const SizedBox(height: 16),
        const Text('功能特性：'),
        const Text('• epub 格式支持'),
        const Text('• TTS 文本转语音（端侧模型）'),
        const Text('• 分页阅读体验'),
        const Text('• 阅读进度追踪'),
        const Text('• 定时关闭功能'),
        const Text('• 字体大小调节'),
        const Text('• 夜间模式'),
      ],
    );
  }
}
