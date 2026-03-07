# Audio Book Reader 应用图标设计

## 设计理念
- 简洁现代的图书图标
- 蓝色主题色 (Material Blue #2196F3)
- 包含声音/听书元素
- 适合多平台 (iOS/Android/macOS)

## AI 生图工具推荐

### 1. AI Gen Max (推荐)
- **网址**: https://aigenmax.art/ai-icon-generator
- **特点**: 免费、无需注册、无水印、无限使用
- **支持**: 图标生成、Logo 设计

### 2. 其他工具
- **Bing Image Creator**: 需要 Microsoft 账号
- **Leonardo.ai**: 每日免费额度
- **Playground AI**: 免费额度充足

## 图标提示词 (Prompt)

### 英文 Prompt (推荐)
```
A modern minimalist app icon for an audiobook reader application. 
The icon features an open book with sound waves emerging from the pages, 
symbolizing text-to-speech functionality. 
Clean vector style, flat design, gradient blue color scheme (#2196F3 to #1976D2). 
White background, rounded corners, professional and elegant. 
Suitable for iOS App Store and Google Play Store. 
High quality, 1024x1024 pixels.
```

### 中文 Prompt
```
一个现代简约的有声书阅读器应用图标。
图标展示一本打开的书，书页中传出声波，象征文本转语音功能。
简洁的矢量风格，扁平化设计，渐变蓝色配色 (#2196F3 到 #1976D2)。
白色背景，圆角，专业优雅。
适合 iOS App Store 和 Google Play Store。
高质量，1024x1024 像素。
```

### 简化版 Prompt
```
audiobook app icon, open book with sound waves, blue gradient, 
minimalist, flat design, 1024x1024
```

## 生成步骤

### 使用 AI Gen Max
1. 访问 https://aigenmax.art/ai-icon-generator
2. 选择 "App Icon" 或 "Logo" 模式
3. 输入上述 Prompt
4. 选择风格：Flat/Minimalist
5. 生成并下载 (1024x1024 PNG)
6. 保存到项目：`assets/icon/app_icon.png`

### 使用其他工具
1. 选择工具并注册 (如需)
2. 输入 Prompt
3. 调整参数：
   - 尺寸：1024x1024
   - 风格：Flat/Minimalist
   - 配色：蓝色系
4. 生成并下载

## 图标规格要求

### iOS
- **尺寸**: 1024x1024 (App Store), 多种尺寸 (应用内)
- **格式**: PNG
- **特点**: 无圆角 (系统自动添加)

### Android
- **尺寸**: 512x512 (Play Store), 多种尺寸 (应用内)
- **格式**: PNG
- **特点**: 无圆角

### macOS
- **尺寸**: 1024x1024
- **格式**: PNG/ICNS
- **特点**: 可带圆角

## 配色方案

| 用途 | 颜色 | Hex |
|------|------|-----|
| 主色 | Material Blue | #2196F3 |
| 渐变 | Dark Blue | #1976D2 |
| 前景 | White | #FFFFFF |
| 背景 | Transparent | 透明 |

## 设计元素

### 核心元素
- 📖 打开的书本 (主体)
- 🔊 声波/音量符号 (听书功能)
- 🎧 可选：耳机元素

### 风格要求
- ✅ 扁平化设计
- ✅ 简洁明了
- ✅ 高识别度
- ✅ 小尺寸清晰

### 避免元素
- ❌ 过于复杂的细节
- ❌ 渐变色过多
- ❌ 文字说明
- ❌ 照片素材

## 后续处理

### 生成后
1. 检查图标清晰度
2. 调整尺寸到 1024x1024
3. 保存为 PNG 格式
4. 放置到 `assets/icon/app_icon.png`

### Flutter 配置
```bash
flutter pub run flutter_launcher_icons
```

会自动生成各平台所需尺寸。

---

*待执行：使用 AI 工具生成图标*
