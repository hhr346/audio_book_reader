# App Icon Design - Audio Book Reader

## 设计理念
- 简洁现代的图书图标
- 蓝色主题色
- 包含声音/听书元素

## 图标描述
```
📚 + 🔊 = 📚🔊

一个打开的书本，旁边有声波符号
背景：渐变蓝色
前景：白色书本 + 蓝色声波
```

## 配置步骤

### 1. 安装 flutter_launcher_icons
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: "launcher_icon"
  ios: "AppIcon"
  image_path: "assets/icon/app_icon.png"
  min_sdk_android: 21
```

### 2. 生成图标
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

### 3. 平台特定配置

#### iOS
在 ios/Runner/Info.plist 中配置

#### Android
在 android/app/src/main/res 中自动生成

---

## 颜色方案
- 主色：#2196F3 (Material Blue)
- 渐变：#1976D2 → #2196F3
- 前景：#FFFFFF (白色)

---

*待实现：需要设计师提供实际图标文件*
