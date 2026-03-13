# 🎙️ TTS 翻页问题和定时关闭功能修复报告

**日期**: 2026-03-13  
**状态**: ✅ 修复完成，编译成功  
**Commit**: `9808982`

---

## 🐛 问题描述

### 问题 1: 听书按钮开启后手动翻页，书籍多跳转一页

**现象**:
- 开启听书后，手动点击"下一页"
- 音频跳转到下一页是正确的
- 但书籍显示跳到了下下页（多跳了一页）

**根本原因**:
- `_currentTtsPageIndex` 变量导致状态不同步
- 翻页时只更新了 `_currentPageIndex`
- 但 TTS 播放逻辑中使用了 `_currentTtsPageIndex`，导致双页跳转

---

### 问题 2: 关闭听书后翻页，再开启听书从上次页面继续

**现象**:
- 开启听书 → 播放第 5 页
- 关闭听书 → 手动翻到第 8 页
- 再次开启听书 → 从第 5 页开始播放（应该从第 8 页）

**根本原因**:
- `_currentTtsPageIndex` 缓存了上次 TTS 播放的页码
- 开启 TTS 时使用了缓存值，而不是当前页面索引

---

### 问题 3: 定时关闭功能不完善

**现象**:
- 定时关闭没有明确的开启/关闭状态
- 设置时间后立即启动，无法预设时间
- 没有倒计时显示，用户不知道剩余时间

---

## ✅ 解决方案

### 方案 1: 移除 `_currentTtsPageIndex` 变量

**修改文件**: `lib/screens/reader_screen.dart`

**修改内容**:
```dart
// 删除这个变量
- int _currentTtsPageIndex = 0;

// _toggleTts 方法中
- _currentTtsPageIndex = _currentPageIndex;
+ // 直接使用 _currentPageIndex

// _nextPageForAutoRead 方法中
- _currentTtsPageIndex = nextPageIndex;
+ // 直接使用 _currentPageIndex
```

**效果**: TTS 始终跟随当前页面索引，不再有不同的状态。

---

### 方案 2: 翻页时先停止 TTS 再朗读新页面

**修改文件**: `lib/screens/reader_screen.dart`

**修改内容**:
```dart
// _nextPage 方法
if (_isTtsPlaying) {
-  TtsService().speak(_pages[_currentPageIndex]);
+  final ttsService = TtsService();
+  await ttsService.stop(); // 先停止当前播放
+  await ttsService.speak(_pages[_currentPageIndex]); // 再朗读新页面
}

// _previousPage 方法（同样的修改）
```

**效果**: 确保翻页时 TTS 立即切换到新页面，不会继续播放旧内容。

---

### 方案 3: 定时关闭功能改进

**修改文件**: `lib/services/tts_service.dart`, `lib/screens/settings_screen.dart`

#### 3.1 TTS 服务层改进

```dart
// 添加结束时间记录
DateTime? _sleepTimerEndTime;

// 设置定时关闭
void setSleepTimer(int minutes) {
  _sleepTimerEndTime = DateTime.now().add(Duration(minutes: minutes));
  // ...
}

// 获取剩余时间（秒）
int? getSleepTimerRemaining() {
  if (!_sleepTimerActive || _sleepTimerEndTime == null) return null;
  final remaining = _sleepTimerEndTime!.difference(DateTime.now());
  return remaining.inSeconds.clamp(0, remaining.inSeconds);
}
```

#### 3.2 设置界面改进

```dart
// 添加状态变量
bool _sleepTimerEnabled = false;
int _remainingSeconds = 0;
Timer? _countdownTimer;

// 每秒更新倒计时
void _startCountdownUpdate() {
  _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
    if (mounted && _sleepTimerEnabled) {
      final remaining = TtsService().getSleepTimerRemaining();
      if (remaining != null && remaining > 0) {
        setState(() => _remainingSeconds = remaining);
      }
    }
  });
}

// SwitchListTile 控制开启/关闭
SwitchListTile(
  title: const Text('定时关闭'),
  subtitle: _sleepTimerEnabled
      ? Text('⏰ 剩余：${_formatTime(_remainingSeconds)}')
      : Text('$_sleepTimerMinutes 分钟后停止播放'),
  value: _sleepTimerEnabled,
  onChanged: (value) {
    if (value) {
      TtsService().setSleepTimer(_sleepTimerMinutes);
    } else {
      TtsService().cancelSleepTimer();
    }
  },
)
```

**效果**:
- 默认为关闭状态
- 开启后显示实时倒计时（MM:SS 格式）
- 可以随时关闭定时
- 时间设置和开启分离（先设置时间，再开启）

---

## 📝 修改的文件

| 文件 | 修改内容 | 行数变化 |
|------|----------|----------|
| `lib/services/tts_service.dart` | 添加 `_sleepTimerEndTime`，改进定时关闭逻辑 | +15, -5 |
| `lib/screens/reader_screen.dart` | 移除 `_currentTtsPageIndex`，改进翻页逻辑 | +5, -10 |
| `lib/screens/settings_screen.dart` | 添加倒计时显示和开关控制 | +63, -4 |

**总计**: +83 行，-19 行

---

## 🧪 测试计划

### 测试 1: TTS 翻页问题修复

**步骤**:
1. 打开任意书籍
2. 点击听书按钮（开启 TTS）
3. 点击"下一页"按钮
4. 观察书籍显示和音频播放

**预期结果**:
- ✅ 书籍显示第 N+1 页
- ✅ 音频朗读第 N+1 页
- ✅ 没有多跳转一页

---

### 测试 2: 关闭听书后翻页

**步骤**:
1. 开启听书 → 播放第 5 页
2. 关闭听书
3. 手动翻到第 8 页
4. 再次开启听书

**预期结果**:
- ✅ 从第 8 页开始播放
- ✅ 不是从第 5 页继续

---

### 测试 3: 定时关闭功能

**步骤**:
1. 进入设置界面
2. 点击"定时关闭" → 设置 30 分钟
3. 观察定时关闭开关状态
4. 开启定时关闭开关
5. 观察倒计时显示

**预期结果**:
- ✅ 默认为关闭状态
- ✅ 设置时间后不立即启动
- ✅ 开启后显示倒计时（如 29:59）
- ✅ 每秒更新倒计时
- ✅ 关闭开关后定时取消

---

### 测试 4: 定时关闭触发

**步骤**:
1. 开启听书
2. 开启定时关闭（设置 1 分钟）
3. 等待 1 分钟
4. 观察 TTS 状态

**预期结果**:
- ✅ 1 分钟后 TTS 自动停止
- ✅ 倒计时显示消失
- ✅ 开关自动关闭

---

## 📊 对比

| 功能 | 修复前 | 修复后 |
|------|--------|--------|
| TTS 翻页 | ❌ 多跳一页 | ✅ 正常翻页 |
| 关闭后重开 | ❌ 从旧页面继续 | ✅ 从当前页面开始 |
| 定时关闭默认 | ❌ 设置即启动 | ✅ 默认关闭 |
| 倒计时显示 | ❌ 无 | ✅ 实时显示（MM:SS） |
| 随时关闭 | ❌ 不支持 | ✅ 支持 |

---

## 🚀 下一步

1. **在真机上测试**
   - 导入书籍
   - 测试 TTS 翻页
   - 测试定时关闭

2. **收集反馈**
   - 翻页是否流畅
   - 倒计时是否准确
   - 有无其他问题

3. **准备发布**
   - 版本号：0.2.1
   - 更新 CHANGELOG.md
   - 打包发布

---

**修复完成时间**: 2026-03-13 11:30  
**编译状态**: ✅ 成功  
**测试状态**: ⏳ 待测试
