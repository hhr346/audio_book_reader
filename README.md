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
- Flutter SDK >= 3.11.0
- iOS 12.0+ / Android 5.0+ / macOS 10.15+

### 安装步骤

```bash
# 进入项目目录
cd /Users/hhr/Desktop/audio_book_reader

# 安装依赖
flutter pub get

# 运行应用
flutter run

# 运行测试
flutter test
```

### 构建发布

```bash
# iOS
flutter build ios --release

# Android
flutter build apk --release

# macOS
flutter build macos --release
```

### 功能演示

#### 1. 导入图书
- 点击右上角导入按钮
- 选择 epub 文件
- 自动解析并添加到书架

#### 2. 阅读图书
- 点击图书卡片打开
- 章节切换
- 进度自动保存

#### 3. 听书功能
- 点击播放按钮
- 调节语速
- 设置定时关闭

#### 4. 书签管理
- 添加书签
- 查看书签列表
- 添加笔记

#### 5. 搜索图书
- 点击搜索图标
- 输入书名或作者
- 实时搜索结果

#### 6. 书架排序
- 点击排序菜单
- 选择排序方式
- 切换升序/降序

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

## ✅ 已完成功能

### 核心功能
- ✅ epub 格式导入和解析
- ✅ 书架管理（Grid 布局、封面展示）
- ✅ 阅读器（章节浏览、进度保存）
- ✅ TTS 听书（播放控制、语速调节）
- ✅ 定时关闭（15/30/60/90 分钟）
- ✅ 书签功能（添加、列表、笔记）
- ✅ 搜索功能（实时、书名/作者）
- ✅ 设置页面（字体、主题、语速）
- ✅ 书架排序（时间/书名/进度）
- ✅ 底部导航（书架/设置）

### 技术特性
- ✅ Hive 本地存储
- ✅ Provider 状态管理
- ✅ 错误处理和日志
- ✅ 单元测试

## 📋 开发计划

### Phase 2 - 增强 (下周)
- [ ] 应用图标和启动页
- [ ] 书签跳转功能完善
- [ ] TTS 后台播放
- [ ] 阅读界面优化（字体、主题）
- [ ] 批量删除图书

### Phase 3 - 高级功能 (下月)
- [ ] 多 TTS 引擎支持（讯飞、百度）
- [ ] 云端同步
- [ ] 离线下载
- [ ] 书架备份/导入
- [ ] 数据统计（听书时长、完成书籍）
- [ ] 成就系统

### Phase 4 - 发布准备
- [ ] 真机测试（iOS/Android）
- [ ] 性能优化
- [ ] Bug 修复
- [ ] 应用商店素材
- [ ] 隐私政策
- [ ] 提交审核

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
