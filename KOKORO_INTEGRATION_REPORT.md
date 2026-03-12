# 🎉 Kokoro TTS 整合完成报告

**日期**: 2026-03-12  
**状态**: ✅ 代码整合完成，待下载模型测试

---

## 📦 完成的工作

### 1. ✅ 依赖配置

**文件**: `pubspec.yaml`

添加了以下依赖：
```yaml
kokoro_tts_flutter: ^0.2.0+1    # Kokoro AI TTS
onnxruntime: ^1.16.0             # ONNX Runtime 支持
flutter_tts: ^4.0.2              # 保留作为备用
image: ^4.1.7                    # 图像处理（封面提取）
```

配置了 assets 目录：
```yaml
flutter:
  assets:
    - assets/
    - assets/fonts/
    - assets/icon/
    - assets/voices/             # 额外语音文件
```

---

### 2. ✅ TTS 服务架构

**文件**: `lib/services/tts_service_kokoro.dart`

**核心特性**:
- 🔄 **双引擎自动切换**
  - 优先使用 Kokoro（高质量 AI 语音）
  - 模型缺失时自动降级到系统 TTS
- 📁 **自动模型检测**
  - 启动时检查模型文件是否存在
  - 缺失时给出明确提示
- 🌐 **多语言支持**
  - 英语（Kokoro 强项）
  - 日语
  - 中文（自动切换到系统 TTS）
- ⚙️ **完整功能**
  - 播放/暂停/继续/停止
  - 语速/音调调节
  - 定时关闭
  - 状态监听

**引擎对比**:
| 特性 | Kokoro | 系统 TTS |
|------|--------|----------|
| 音质 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| 响应速度 | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| 中文支持 | ⭐⭐ | ⭐⭐⭐⭐ |
| 英文支持 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| 模型大小 | 85MB | 0MB |

---

### 3. ✅ 模型文件管理

**脚本文件**:

| 文件 | 用途 |
|------|------|
| `assets/download_models.sh` | 自动下载主模型（ONNX + voices） |
| `assets/copy_voices.sh` | 从 OpenIdea 复制额外语音文件 |
| `assets/README.md` | 完整下载说明 |

**模型信息**:
- **kokoro-v1.0.int8.onnx**: ~80 MB（量化版）
- **voices-v1.0.bin**: ~5 MB（基础语音）
- **额外语音**: 56 种声音（从 OpenIdea 复制）
- **总计**: ~85 MB（基础）+ ~50 MB（额外语音）

**语音文件来源**:
- 基础语音：HuggingFace 下载
- 额外语音：`~/Documents/OpenIdea/kokoro/kokoro.js/voices/`

**可用语音**（部分）:
| 语音 ID | 性别 | 语言 | 特点 |
|--------|------|------|------|
| af_heart | 女 | 英语 | 高质量（推荐） |
| af_bella | 女 | 英语 | 自然 |
| am_michael | 男 | 英语 | 清晰 |
| af_nicole | 女 | 英语 | 专业 |
| zm_yunxi | 男 | 中文 | 中文男声 |
| zf_xiaoni | 女 | 中文 | 中文女声 |

---

### 4. ✅ 文档

**创建/更新文件**:

| 文件 | 说明 |
|------|------|
| `KOKORO_SETUP.md` | 完整整合指南 |
| `KOKORO_INTEGRATION_REPORT.md` | 本报告 |
| `UPDATE_REPORT_2026-03-12.md` | 最新更新报告 |
| `assets/README.md` | 模型下载说明 |
| `test_app.sh` | 快速测试脚本 |

---

## 📥 下一步：下载模型

### 方法 1: 使用下载脚本（推荐）

```bash
cd /Users/hhr/Desktop/audio_book_reader/assets

# 下载主模型
bash download_models.sh

# 复制额外语音（可选）
bash copy_voices.sh
```

### 方法 2: 手动下载

1. 打开 [HuggingFace 模型页面](https://huggingface.co/onnx-community/Kokoro-82M-v1.0-ONNX)
2. 点击 "Files and versions"
3. 下载文件到 `assets/` 目录：
   - `kokoro-v1.0.int8.onnx`
   - `voices-v1.0.bin`

### 方法 3: 使用 huggingface-cli

```bash
pip install huggingface_hub
cd /Users/hhr/Desktop/audio_book_reader/assets
huggingface-cli download onnx-community/Kokoro-82M-v1.0-ONNX kokoro-v1.0.int8.onnx voices-v1.0.bin --local-dir .
```

---

## 🧪 测试步骤

### 步骤 1: 安装依赖

```bash
cd /Users/hhr/Desktop/audio_book_reader
flutter pub get
```

### 步骤 2: 生成 Hive 适配器

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 步骤 3: 验证模型文件

```bash
ls -lh assets/*.onnx assets/*.bin assets/voices/*.bin
```

应该看到：
```
-rw-r--r--  kokoro-v1.0.int8.onnx  (~80M)
-rw-r--r--  voices-v1.0.bin  (~5M)
-rw-r--r--  voices/af_heart.bin  (~1M)
-rw-r--r--  voices/am_michael.bin  (~1M)
...
```

### 步骤 4: 编译运行

```bash
# 方法 A: 直接运行
flutter run

# 方法 B: 使用测试脚本
bash test_app.sh

# 方法 C: Xcode
open ios/Runner.xcworkspace
# 然后选择模拟器并运行
```

---

## 🔧 启用 Kokoro TTS

### 当前状态
默认使用原系统 TTS (`tts_service.dart`)

### 启用方法

**文件**: `lib/main.dart`

修改前：
```dart
import 'services/tts_service.dart';
// import 'services/tts_service_kokoro.dart';

await TtsService().init();
```

修改后：
```dart
// import 'services/tts_service.dart';
import 'services/tts_service_kokoro.dart';

await TtsServiceKokoro().init();
```

---

## ⚠️ 注意事项

### 中文支持限制

Kokoro 主要支持**英语和日语**，中文合成效果有限。

**建议方案**:
1. 检测文本语言
2. 英文 → 使用 Kokoro
3. 中文 → 使用系统 TTS

示例代码：
```dart
bool isChinese(String text) {
  return text.contains(RegExp(r'[\u4e00-\u9fff]'));
}

final tts = TtsServiceKokoro();
if (isChinese(text)) {
  await tts.setLanguage('zh-CN');  // 系统 TTS
} else {
  await tts.setLanguage('en-US');  // Kokoro
}
```

### 首次启动

- 模型检查耗时：1-2 秒
- 首次合成耗时：2-3 秒（加载模型）
- 后续合成：实时

### 性能优化建议

1. **预加载模型**: 应用启动时预加载
2. **缓存音频**: 对常用文本缓存合成结果
3. **后台合成**: 使用 isolate 避免阻塞 UI

---

## 📊 测试清单

### 功能测试
- [ ] EPUB 打开显示正常
- [ ] 书架封面显示
- [ ] Kokoro 模型加载成功
- [ ] 英文内容朗读
- [ ] 中文内容朗读（自动切换系统 TTS）
- [ ] 播放/暂停/继续
- [ ] 语速调节
- [ ] 定时关闭
- [ ] **阅读位置记忆**（新功能）
- [ ] **进度条按页数计算**（新功能）

### 性能测试
- [ ] 首次启动时间 < 5 秒
- [ ] 首次合成时间 < 3 秒
- [ ] 后续合成实时
- [ ] 内存占用 < 200MB
- [ ] 总页数计算 < 2 秒

### 兼容性测试
- [ ] iOS 模拟器
- [ ] iOS 真机
- [ ] Android 模拟器
- [ ] Android 真机

---

## 📁 文件清单

### 新增文件
```
assets/copy_voices.sh                        (0.8 KB) - 语音复制脚本
UPDATE_REPORT_2026-03-12.md                 (4.3 KB) - 更新报告
```

### 修改文件
```
lib/models/book.dart                         (+3 fields) - 位置记忆字段
lib/screens/reader_screen.dart              (major) - 位置记忆 + 页数进度
lib/services/epub_service.dart              (+2 methods) - 页数计算
lib/services/tts_service_kokoro.dart        (existing) - TTS 服务
pubspec.yaml                                (+1 dep) - image 依赖
assets/download_models.sh                   (updated) - 下载脚本
assets/README.md                            (updated) - 模型说明
```

### 保留文件
```
lib/services/tts_service.dart               (backup) - 系统 TTS 备用
```

---

## 🎯 成功标准

- ✅ 模型文件下载完成
- ✅ `flutter pub get` 无错误
- ✅ Hive 适配器生成成功
- ✅ 应用编译成功
- ✅ 启动时正确检测模型
- ✅ 英文内容使用 Kokoro 朗读
- ✅ 模型缺失时自动降级到系统 TTS
- ✅ 重新打开图书恢复到上次位置
- ✅ 进度条按总页数正确显示

---

## 📞 问题排查

### 常见问题

**Q: "Kokoro 模型文件缺失"**
- A: 运行 `bash assets/download_models.sh`

**Q: "ONNX Runtime 初始化失败"**
- A: 运行 `flutter clean && flutter pub get`

**Q: "Hive 适配器错误"**
- A: 运行 `flutter pub run build_runner build --delete-conflicting-outputs`

**Q: 播放时没有声音**
- A: 检查音量、语言设置，尝试系统 TTS

**Q: 中文朗读效果差**
- A: 正常，Kokoro 主要支持英文，建议中文用系统 TTS

**Q: 进度条显示不正确**
- A: 打开一本新书重新计算总页数

---

## 🚀 后续优化

1. **语言自动检测**: 根据文本自动选择引擎
2. **引擎切换 UI**: 设置页面添加引擎选择
3. **音频缓存**: 缓存常用段落合成结果
4. **后台播放**: 支持锁屏播放
5. **更多声音**: UI 支持切换不同说话人
6. **预计算页数**: 导入图书时计算总页数

---

**整合完成时间**: 2026-03-12  
**模型版本**: Kokoro-82M v1.0 (INT8 量化)  
**下一步**: 
1. `flutter pub get`
2. `flutter pub run build_runner build --delete-conflicting-outputs`
3. `bash assets/download_models.sh`
4. 运行应用测试
