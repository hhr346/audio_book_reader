# Kokoro TTS 模型文件

本目录需要放置以下模型文件：

## 必需文件

| 文件名 | 大小 | 下载地址 |
|--------|------|----------|
| `kokoro-v1.0.int8.onnx` | ~80 MB | [下载](https://huggingface.co/onnx-community/Kokoro-82M-v1.0-ONNX/resolve/main/kokoro-v1.0.int8.onnx) |
| `voices-v1.0.bin` | ~5 MB | [下载](https://huggingface.co/onnx-community/Kokoro-82M-v1.0-ONNX/resolve/main/voices-v1.0.bin) |

## 下载方法

### 方法 1: 使用下载脚本（推荐）

```bash
cd /Users/hhr/Desktop/audio_book_reader/assets
bash download_models.sh
```

### 方法 2: 手动下载

1. **使用浏览器下载**:
   - 打开 [HuggingFace 模型页面](https://huggingface.co/onnx-community/Kokoro-82M-v1.0-ONNX)
   - 点击 "Files and versions" 标签
   - 下载 `kokoro-v1.0.int8.onnx` 和 `voices-v1.0.bin`
   - 将文件放入本目录

### 方法 3: 使用 Python 下载

```bash
pip install huggingface_hub
cd /Users/hhr/Desktop/audio_book_reader/assets
huggingface-cli download onnx-community/Kokoro-82M-v1.0-ONNX kokoro-v1.0.int8.onnx voices-v1.0.bin --local-dir .
```

## 验证文件

下载完成后，运行：
```bash
ls -lh *.onnx *.bin
```

应该看到：
```
-rw-r--r--  kokoro-v1.0.int8.onnx  (~80M)
-rw-r--r--  voices-v1.0.bin  (~5M)
```

## 可选：额外语音文件

如果你有 `~/Documents/OpenIdea/kokoro/kokoro.js/voices/` 目录，可以复制额外的语音文件到本目录：

```bash
cp ~/Documents/OpenIdea/kokoro/kokoro.js/voices/*.bin ./voices/
```

可用语音包括：
- **af_heart** - 女声，高质量（推荐）
- **af_bella** - 女声，自然
- **am_michael** - 男声
- **af_nicole** - 女声，清晰
- **zm_yunxi** - 中文男声
- **zf_xiaoni** - 中文女声

## 模型信息

- **模型名称**: Kokoro-82M v1.0
- **参数量**: 82M
- **量化版本**: INT8（体积减少 75%，音质损失很小）
- **授权**: Apache 2.0
- **支持语言**: 英语、日语等（中文支持有限）

## 注意事项

⚠️ **中文支持**: Kokoro 主要支持英语和日语，中文合成效果可能不如专门的中文 TTS。
建议保留系统 TTS 作为中文内容的备选方案。

## 启用 Kokoro TTS

在 `lib/main.dart` 中：

```dart
// 注释掉系统 TTS
// import 'services/tts_service.dart';
// await TtsService().init();

// 启用 Kokoro TTS
import 'services/tts_service_kokoro.dart';
await TtsServiceKokoro().init();
```
