# Audio Book Reader - 测试指南

## 快速测试

### 1. 获取测试书籍
可以从以下来源获取 epub 格式书籍：
- [Project Gutenberg](https://www.gutenberg.org/) - 公版书
- [Z-Library](https://z-library.se/) - 需要注册
- 本地已有的 epub 文件

### 2. 测试步骤

#### macOS
```bash
cd /Users/hhr/Desktop/audio_book_reader
flutter pub get
flutter run -d macos
```

#### iOS (需要真机或模拟器)
```bash
cd /Users/hhr/Desktop/audio_book_reader
flutter pub get
flutter run
```

#### Android
```bash
cd /Users/hhr/Desktop/audio_book_reader
flutter pub get
flutter run
```

### 3. 测试功能清单

#### 基础功能 ✅
- [ ] 应用启动正常
- [ ] 书架页面显示正常
- [ ] 空状态提示显示

#### 核心功能 🎯
- [ ] 导入 epub 文件
- [ ] 图书封面显示
- [ ] 图书信息正确（书名、作者）
- [ ] 打开图书进入阅读页面
- [ ] 章节内容显示正常
- [ ] 上一章/下一章切换
- [ ] 章节列表选择
- [ ] 阅读进度保存

#### TTS 功能 🔊
- [ ] 点击播放按钮开始朗读
- [ ] 点击暂停按钮停止朗读
- [ ] 语速调节有效
- [ ] 切换章节后 TTS 停止

#### 性能测试 ⚡
- [ ] 小文件 (<10MB) 加载速度
- [ ] 大文件 (>50MB) 加载速度
- [ ] 多本书（10+）书架滚动流畅度

---

## 已知问题排查

### 问题 1: 导入失败
**症状**: 点击导入按钮无反应或报错

**排查**:
1. 检查文件权限设置
2. 确认选择的是 epub 格式
3. 查看控制台错误日志

### 问题 2: TTS 无声
**症状**: 点击播放按钮但没声音

**排查**:
1. 检查设备音量
2. 检查系统 TTS 设置
3. 确认 TTS 语言包已安装

### 问题 3: 章节显示异常
**症状**: 章节内容为空或乱码

**排查**:
1. epub 文件编码问题（尝试 UTF-8）
2. epub 文件损坏
3. 复杂排版不支持

---

## 反馈模板

```
【问题描述】
简要描述遇到的问题

【重现步骤】
1. 打开应用
2. 点击...
3. 出现...

【期望行为】
应该发生什么

【实际行为】
实际发生了什么

【设备信息】
- 设备：iPhone 15 / MacBook Pro M1 / ...
- 系统：iOS 17 / macOS 14 / ...
- 应用版本：0.1.0

【日志】
```
（粘贴控制台日志）
```

【截图/录屏】
（如有）
```

---

*测试版本：0.1.0*
*更新日期：2026-03-07*
