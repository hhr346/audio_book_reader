# Audio Book Reader 📚

有声图书阅读器 - 让阅读更自由

## 📱 项目简介

一款支持 epub 格式的图书阅读器，配备文本转语音（TTS）功能，用户可以自由选择阅读或听书模式。

## ✨ 核心功能

### 📖 阅读功能
- **epub 格式支持**：导入主流 epub 格式图书
- **自定义排版**：字体大小、行距、主题可调节
- **书签管理**：支持添加和管理书签
- **阅读进度**：自动保存阅读进度

### 🔊 听书功能（TTS）
- **文本转语音**：将图书内容转换为语音播放
- **多语言支持**：支持中文、英文等多种语言
- **语速调节**：0.5x - 3.0x 语速可调
- **后台播放**：支持后台持续播放
- **定时关闭**：睡眠定时功能

### 📚 书架管理
- **图书导入**：从文件管理器导入 epub 文件
- **封面展示**：自动提取 epub 封面
- **分类管理**：支持自定义分类
- **搜索功能**：快速查找图书

## 🛠️ 技术栈

- **框架**: Flutter 3.x
- **语言**: Dart
- **epub 解析**: epub 库
- **TTS 引擎**: flutter_tts (系统 TTS)
- **状态管理**: Provider
- **本地存储**: Hive

## 📦 依赖说明

| 包名 | 用途 |
|------|------|
| epub | epub 格式解析 |
| flutter_tts | 文本转语音 |
| file_picker | 文件选择导入 |
| path_provider | 文件路径管理 |
| permission_handler | 权限管理 |
| hive | 本地数据存储 |
| just_audio | 音频播放（备用） |

## 🚀 快速开始

### 环境要求
- Flutter SDK >= 3.0.0
- iOS 12.0+ / Android 5.0+

### 安装步骤

```bash
# 进入项目目录
cd /Users/hhr/Desktop/audio_book_reader

# 安装依赖
flutter pub get

# 运行应用
flutter run
```

### 构建发布

```bash
# iOS
flutter build ios --release

# Android
flutter build apk --release
```

## 📁 项目结构

```
audio_book_reader/
├── lib/
│   ├── main.dart              # 应用入口
│   ├── models/                # 数据模型
│   │   ├── book.dart          # 图书模型
│   │   ├── chapter.dart       # 章节模型
│   │   └── bookmark.dart      # 书签模型
│   ├── screens/               # 页面
│   │   ├── home_screen.dart   # 首页（书架）
│   │   ├── reader_screen.dart # 阅读页面
│   │   ├── player_screen.dart # 听书页面
│   │   └── settings_screen.dart # 设置
│   ├── widgets/               # 自定义组件
│   │   ├── book_card.dart     # 图书卡片
│   │   ├── player_controls.dart # 播放控制
│   │   └── chapter_list.dart  # 章节列表
│   ├── services/              # 服务层
│   │   ├── epub_service.dart  # epub 解析服务
│   │   ├── tts_service.dart   # TTS 服务
│   │   └── storage_service.dart # 存储服务
│   └── providers/             # 状态管理
│       ├── book_provider.dart
│       └── player_provider.dart
├── assets/                    # 资源文件
│   └── fonts/
└── test/                      # 测试文件
```

## 🎯 开发计划

### Phase 1 - MVP (当前)
- [x] 项目初始化
- [ ] epub 解析和展示
- [ ] TTS 基础播放
- [ ] 书架管理

### Phase 2 - 增强
- [ ] 阅读界面优化
- [ ] TTS 语速/音调调节
- [ ] 书签和笔记
- [ ] 阅读进度同步

### Phase 3 - 高级功能
- [ ] 多 TTS 引擎支持
- [ ] 云端同步
- [ ] 离线下载
- [ ] 书架备份

## 🔊 TTS 语音说明

应用使用系统内置 TTS 引擎：

**iOS**: 使用 AVSpeechSynthesizer
- 中文：Siri  voices
- 英文：Samantha, Daniel 等

**Android**: 使用 Android TTS
- 中文：Google 中文语音
- 英文：Google US English

用户可以在系统设置中下载更多语音包。

## 📄 许可证

MIT License

---

**开发者**: Hongri  
**创建时间**: 2026-03-05  
**版本**: 0.1.0

## 💡 资源需求

如需测试图书资源，可以：
1. 使用公版书项目（Project Gutenberg）
2. 导入本地 epub 文件
3. 测试用样例图书
