# audio_book_reader 问题修复报告

**日期**: 2026-03-11  
**状态**: 部分修复完成

---

## 问题汇总

### ✅ 问题 1: EPUB 打开后显示 0 页 - 已修复

**原因**: `_loadCurrentChapter()` 从未被调用
- `initState()` 中只调用了 `_loadSettings()`
- `didChangeDependencies()` 中的条件 `_pages.isEmpty && !_isLoading` 永远不满足（因为 `_isLoading` 初始为 `true`）

**修复方案**:
```dart
@override
void initState() {
  super.initState();
  _chaptersFuture = EpubService().getChapters(widget.book.filePath);
  _loadSettings();
  // 延迟加载，确保屏幕尺寸已获取
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _calculatePageCapacity();
    _loadCurrentChapter();
  });
}
```

**文件**: `lib/screens/reader_screen.dart`

---

### ✅ 问题 2: 书架封面不显示 - 已修复

**原因**: 封面提取代码被注释掉了
```dart
// 暂时跳过封面处理，避免 API 兼容性问题
// 封面功能后续完善
```

**修复方案**: 启用封面提取逻辑
```dart
try {
  // 尝试提取封面
  final coverImage = epubBook.cover;
  if (coverImage != null && coverImage.isNotEmpty) {
    coverPath = await _saveCoverImage(coverImage, filePath);
    print('✓ 封面已保存：$coverPath');
  } else {
    print('⚠️ 未找到封面图片');
  }
} catch (e) {
  print('⚠️ 封面提取失败：$e');
}
```

**文件**: `lib/services/epub_service.dart`

---

### ⚠️ 问题 3: 需要下滑才能看完整内容 - 待优化

**原因**: 内容区域使用了 `SingleChildScrollView` + `SelectableText`，导致可以滚动

**当前设计**:
```dart
child: SingleChildScrollView(
  child: SelectableText(
    _pages[_currentPageIndex],
    style: TextStyle(...),
  ),
)
```

**建议方案**: 移除 `SingleChildScrollView`，让分页逻辑完全控制内容显示
```dart
child: Center(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: SelectableText(
      _pages[_currentPageIndex],
      style: TextStyle(...),
    ),
  ),
)
```

**注意**: 这可能导致长段落超出屏幕，需要改进分页算法确保每页内容适配屏幕

---

### 🔧 问题 4: TTS 方案更换为端侧模型 - 调研完成

**当前方案**: `flutter_tts` (依赖系统 TTS 引擎，需要联网或系统语音包)

**调研的端侧 TTS 方案**:

| 方案 | 优点 | 缺点 | 推荐度 |
|------|------|------|--------|
| **stts** | 成熟 (32⭐), 离线优先，使用系统引擎，跨平台 | 本质上还是封装系统 TTS | ⭐⭐⭐⭐ |
| **kokoro_tts_flutter** | 真正端侧 AI 模型，ONNX Runtime，多语言 | 需要下载模型文件 (~100MB), 较新 | ⭐⭐⭐⭐ |
| **piper_tts_plugin** | 高质量，快速，真正离线 | GitHub 项目，文档较少 | ⭐⭐⭐ |
| **outetts** | 神经网络端侧推理，无需联网 | 已 discontinued | ⭐⭐ |

**推荐方案**: 

### 方案 A: 使用 `stts` (保守方案)
```yaml
dependencies:
  stts: ^1.2.6
```

**优点**:
- 成熟稳定，32 个点赞
- API 简单，迁移成本低
- 离线优先，使用系统引擎
- 支持 pause/resume, 语言选择，音调调节

**缺点**:
- 本质上还是依赖系统 TTS 引擎
- 音质取决于系统语音包

### 方案 B: 使用 `kokoro_tts_flutter` (先进方案)
```yaml
dependencies:
  kokoro_tts_flutter: ^0.2.0+1
```

**优点**:
- 真正端侧 AI 模型，不依赖系统
- 音质更好，更自然
- 支持多语言
- ONNX Runtime 加速

**缺点**:
- 需要下载模型文件 (~100MB)
- 需要配置 assets
- 较新的库，可能存在 bug

**实施建议**:
1. **短期**: 先用 `stts` 替换 `flutter_tts`，确保基本功能可用
2. **长期**: 评估 `kokoro_tts_flutter`，如果需要更高质量语音再迁移

---

## 下一步行动

### 立即可测试
1. 重新编译应用，测试 EPUB 打开是否正常显示页数
2. 导入新书，检查封面是否显示
3. 测试阅读体验，确认是否需要移除滚动

### TTS 迁移 (可选)
1. 添加 `stts` 依赖
2. 修改 `tts_service.dart` 使用 `stts.Tts` 替代 `FlutterTts`
3. 测试播放、暂停、继续功能
4. 测试定时关闭功能

---

## 文件修改清单

| 文件 | 修改内容 | 状态 |
|------|----------|------|
| `lib/screens/reader_screen.dart` | 修复 `_loadCurrentChapter()` 调用时机 | ✅ 完成 |
| `lib/services/epub_service.dart` | 启用封面提取逻辑 | ✅ 完成 |
| `lib/services/tts_service.dart` | 待迁移到 stts | ⏳ 待实施 |
| `pubspec.yaml` | 待添加 stts 依赖 | ⏳ 待实施 |

---

## 测试建议

1. **EPUB 解析测试**:
   - 导入不同来源的 EPUB 文件
   - 检查章节列表是否正确
   - 检查页数计算是否准确

2. **封面测试**:
   - 导入有封面的 EPUB
   - 导入无封面的 EPUB
   - 检查书架显示

3. **阅读体验测试**:
   - 测试翻页是否流畅
   - 测试字体大小调整
   - 测试暗黑模式

4. **TTS 测试** (迁移后):
   - 测试播放/暂停/继续
   - 测试语速调节
   - 测试定时关闭
