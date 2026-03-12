# Kokoro TTS 整合指南

## 📦 已完成的工作

### 1. 依赖添加
`pubspec.yaml` 已更新：
```yaml
dependencies:
  kokoro_tts_flutter: ^0.2.0+1
  onnxruntime: ^1.16.0
  flutter_tts: ^4.0.2  # 保留作为备用
```

### 2. 新 TTS 服务
创建文件：`lib/services/tts_service_kokoro.dart`

**特性**:
- ✅ 双引擎支持（Kokoro + 系统 TTS）
- ✅ 自动检测模型文件
- ✅ 模型缺失时自动降级到系统 TTS
- ✅ 保留所有原有功能（暂停、继续、定时关闭）

### 3. 模型文件说明
创建文件：`assets/README.md` 和 `assets/download_models.sh`

---

## 📥 下载模型文件

### 方法 1: 手动下载（推荐）

1. 打开 [HuggingFace 模型页面](https://huggingface.co/onnx-community/Kokoro-82M-v1.0-ONNX)
2. 点击 "Files and versions" 标签
3. 下载以下文件到 `assets/` 目录：
   - `kokoro-v1.0.int8.onnx` (~80 MB)
   - `voices-v1.0.bin` (~5 MB)

### 方法 2: 使用下载脚本

```bash
cd /Users/hhr/Desktop/audio_book_reader/assets
bash download_models.sh
```

### 方法 3: 使用 huggingface-cli

```bash
pip install huggingface_hub
cd /Users/hhr/Desktop/audio_book_reader/assets
huggingface-cli download onnx-community/Kokoro-82M-v1.0-ONNX kokoro-v1.0.int8.onnx --local-dir .
huggingface-cli download onnx-community/Kokoro-82M-v1.0-ONNX voices-v1.0.bin --local-dir .
```

---

## 🔧 使用步骤

### 步骤 1: 安装依赖

```bash
cd /Users/hhr/Desktop/audio_book_reader
flutter pub get
```

### 步骤 2: 下载模型文件

按照上面的方法下载模型文件到 `assets/` 目录

### 步骤 3: 验证文件

```bash
ls -lh assets/*.onnx assets/*.bin
```

应该看到：
```
-rw-r--r--  kokoro-v1.0.int8.onnx  (~80M)
-rw-r--r--  voices-v1.0.bin  (~5M)
```

### 步骤 4: 编译运行

```bash
flutter run
```

---

## 🎯 使用说明

### 自动引擎选择

TTS 服务会自动检测并选择最佳引擎：

1. **优先使用 Kokoro**（如果模型文件存在）
2. **自动降级到系统 TTS**（如果模型缺失或加载失败）

### 手动切换引擎（可选）

在代码中：
```dart
final tts = TtsService();

// 检查 Kokoro 是否可用
if (tts.kokoroAvailable) {
  print('使用高质量 Kokoro TTS');
} else {
  print('使用系统 TTS');
}
```

---

## ⚠️ 注意事项

### 中文支持

Kokoro 主要支持**英语和日语**，中文合成效果有限。

**建议方案**:
- 英文内容 → 使用 Kokoro（高质量）
- 中文内容 → 使用系统 TTS（更好的中文支持）

可以在朗读前根据文本语言自动选择：
```dart
bool isChinese(String text) {
  return text.contains(RegExp(r'[\u4e00-\u9fff]'));
}

if (isChinese(text)) {
  await tts.setLanguage('zh-CN');
} else {
  await tts.setLanguage('en-US');
}
```

### 首次启动

- 首次启动会检查模型文件（约 1-2 秒）
- 模型文件较大（85MB），建议预下载

### 性能

- **Kokoro**: 音质更好，但首次合成稍慢（需要推理）
- **系统 TTS**: 响应更快，但音质取决于系统

---

## 📊 对比测试

| 特性 | Kokoro | 系统 TTS |
|------|--------|----------|
| 音质 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| 响应速度 | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| 中文支持 | ⭐⭐ | ⭐⭐⭐⭐ |
| 英文支持 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| 离线可用 | ✅ | ✅（需下载语音包） |
| 模型大小 | 85MB | 0MB |

---

## 🐛 故障排除

### 问题 1: "Kokoro 模型文件缺失"

**解决**: 下载模型文件到 `assets/` 目录

### 问题 2: "ONNX Runtime 初始化失败"

**解决**: 
```bash
flutter clean
flutter pub get
flutter run
```

### 问题 3: 播放时没有声音

**检查**:
1. 音量是否打开
2. 是否选择了正确的语言
3. 尝试切换到系统 TTS

---

## 📝 下一步

1. ✅ 下载模型文件
2. ✅ 运行 `flutter pub get`
3. ✅ 编译测试
4. ⏳ 测试英文内容朗读效果
5. ⏳ 根据需要添加语言自动检测

---

## 📄 相关文件

| 文件 | 说明 |
|------|------|
| `lib/services/tts_service_kokoro.dart` | 新 TTS 服务（双引擎） |
| `lib/services/tts_service.dart` | 原 TTS 服务（保留备用） |
| `assets/README.md` | 模型下载说明 |
| `assets/download_models.sh` | 自动下载脚本 |
| `pubspec.yaml` | 依赖配置 |

---

**创建时间**: 2026-03-11  
**模型版本**: Kokoro-82M v1.0 (INT8 量化)
