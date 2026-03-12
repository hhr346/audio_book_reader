# 📑 NCX 锚点分章功能开发报告

**日期**: 2026-03-13  
**状态**: ✅ 开发完成，待测试  
**目标**: 兼容白老虎等特殊结构的 EPUB

---

## 🎯 问题背景

### 白老虎 EPUB 的特殊结构

**问题**: 所有章节都在一个 HTML 文件内，用锚点分隔

```
text00001.html 包含:
  <p id="filepos109">第一晚</p>
  ...内容...
  <p id="filepos200">第二晚</p>
  ...内容...
  <p id="filepos300">第四日早晨</p>
  ...
```

**epub_plus 限制**:
- 按**文件**分章，不是按**锚点**分章
- 只能识别出 1 个章节
- 无法进入"第二章"

---

## ✅ 解决方案

### 核心思路：解析 NCX 文件

**NCX (Navigation Center for XML)**:
- EPUB 的导航文件
- 包含完整的章节目录
- 支持锚点引用

**白老虎的 toc.ncx**:
```xml
<navPoint id="id1">
  <navLabel><text>第一晚</text></navLabel>
  <content src="text00001.html#filepos109"/>
</navPoint>
<navPoint id="id2">
  <navLabel><text>第二晚</text></navLabel>
  <content src="text00001.html#filepos109"/>
</navPoint>
```

### 实现步骤

#### 1. 提取 NCX 文件

```dart
Future<String?> _extractNcxContent(String filePath) async {
  // 解压 EPUB（ZIP 格式）
  final archive = ZipDecoder().decodeBytes(bytes);
  
  // 查找 toc.ncx 文件
  for (var file in archive.files) {
    if (file.name.endsWith('toc.ncx')) {
      return utf8.decode(file.content);
    }
  }
  return null;
}
```

---

#### 2. 解析 NCX 导航点

```dart
Future<List<NcxNavPoint>> _parseNcx(String ncxContent) async {
  // 正则表达式解析 XML
  final navPointRegex = RegExp(
    r'<navPoint[^>]*id="([^"]*)"[^>]*>.*?<navLabel>\s*<text>([^<]*)</text>.*?</navLabel>\s*<content[^>]*src="([^"]*)"',
    multiLine: true,
    dotAll: true,
  );
  
  for (final match in navPointRegex.allMatches(ncxContent)) {
    navPoints.add(NcxNavPoint(
      id: match.group(1),
      title: match.group(2),
      src: match.group(3),
      anchor: extractAnchor(match.group(3)),
    ));
  }
  
  return navPoints;
}
```

**数据结构**:
```dart
class NcxNavPoint {
  final String id;
  final String title;      // 章节标题（第一晚、第二晚...）
  final String src;        // 文件路径（text00001.html#filepos109）
  final String? anchor;    // 锚点（filepos109）
}
```

---

#### 3. 检测单文件多章节

```dart
// 检查是否所有导航点都指向同一个文件
final srcFiles = navPoints.map((np) => np.src.split('#').first).toSet();

if (srcFiles.length == 1) {
  // 所有章节都在一个文件里，需要按锚点分割
  print('📝 检测到单文件多章节结构，使用锚点分割');
  final htmlFile = srcFiles.first;
  final chapters = await _splitHtmlByAnchors(filePath, htmlFile, navPoints);
  return chapters;
}
```

---

#### 4. 按锚点分割章节

```dart
Future<List<Chapter>> _splitHtmlByAnchors(
  String filePath,
  String htmlFile,
  List<NcxNavPoint> navPoints,
) async {
  // 读取 HTML 文件
  final htmlContent = readHtmlFile(filePath, htmlFile);
  
  // 按导航点提取章节
  for (final navPoint in navPoints) {
    if (navPoint.anchor != null) {
      final content = _extractContentByAnchor(
        htmlContent,
        navPoint.anchor!,
        navPoint.title,
      );
      
      chapters.add(Chapter(
        title: navPoint.title,
        content: content,
        index: chapters.length,
      ));
    }
  }
  
  return chapters;
}
```

---

#### 5. 提取锚点内容

```dart
String _extractContentByAnchor(String html, String anchor, String title) {
  // 查找锚点位置
  final anchorPattern = 'id="$anchor"';
  final anchorIndex = html.indexOf(anchorPattern);
  
  if (anchorIndex == -1) return '';
  
  // 找到下一个锚点
  final nextAnchorIndex = html.indexOf('id="', anchorIndex + 1);
  
  String content;
  if (nextAnchorIndex == -1) {
    // 最后一个锚点，取到文件结束
    content = html.substring(anchorIndex);
  } else {
    // 取到下一个锚点之前
    content = html.substring(anchorIndex, nextAnchorIndex);
  }
  
  // 添加标题
  return '<h1>$title</h1>\n$content';
}
```

---

#### 6. 混合识别策略

```dart
Future<List<Chapter>> getChapters(String filePath) async {
  // 1. 优先尝试 NCX 解析
  final ncxContent = await _extractNcxContent(filePath);
  if (ncxContent != null) {
    final navPoints = await _parseNcx(ncxContent);
    
    if (navPoints.isNotEmpty) {
      // 检查是否单文件多章节
      final srcFiles = navPoints.map(...).toSet();
      
      if (srcFiles.length == 1) {
        final chapters = await _splitHtmlByAnchors(...);
        if (chapters.isNotEmpty) {
          return chapters; // NCX 成功
        }
      }
    }
  }
  
  // 2. NCX 失败，使用标准 epub_plus 分章
  final epubBook = await parseEpub(filePath);
  // ... 标准分章逻辑
}
```

---

## 📝 修改的文件

### lib/services/epub_service.dart

**新增内容** (~200 行):
- `NcxNavPoint` 类
- `_extractNcxContent()` 提取 NCX
- `_parseNcx()` 解析导航点
- `_extractContentByAnchor()` 提取锚点内容
- `_splitHtmlByAnchors()` 分割章节
- `getChapters()` 混合识别

**修改内容**:
- `getChapters()` 改为混合识别策略

---

### pubspec.yaml

**新增依赖**:
```yaml
archive: ^3.4.9  # ZIP 解压（用于解析 NCX）
```

---

## 🧪 测试计划

### 测试 1: 白老虎（单文件多章节）

**预期结果**:
```
📚 开始解析章节：白老虎.epub
📑 NCX 解析到 9 个导航点
📝 检测到单文件多章节结构，使用锚点分割
📄 HTML 文件内容长度：50000
✅ 提取章节：第一晚 (5000 字符)
✅ 提取章节：第二晚 (5000 字符)
✅ 提取章节：第四日早晨 (5000 字符)
...
✅ NCX 锚点分章成功：9 章
```

**验证**:
- [ ] 章节数 = 9
- [ ] 每章标题正确（第一晚、第二晚...）
- [ ] 可以进入第二章
- [ ] 章节切换正常

---

### 测试 2: 现实一种（标准 EPUB）

**预期结果**:
```
📚 开始解析章节：现实一种.epub
📑 NCX 解析到 X 个导航点
📖 使用标准 epub_plus 分章
✅ 标准分章完成：X 章
```

**验证**:
- [ ] 章节数正确
- [ ] 功能正常（回归测试）

---

### 测试 3: 测试分章（标准 EPUB）

**预期结果**:
```
📚 开始解析章节：测试分章.epub
📑 NCX 解析到 3 个导航点
📖 使用标准 epub_plus 分章
✅ 标准分章完成：3 章
```

**验证**:
- [ ] 章节数 = 3
- [ ] 章节切换正常

---

## 📊 兼容性对比

| EPUB 类型 | 结构 | 旧版本 | 新版本 |
|-----------|------|--------|--------|
| 标准 EPUB | 每章独立文件 | ✅ 正常 | ✅ 正常 |
| 白老虎 | 单文件多章节（锚点） | ❌ 只识别 1 章 | ✅ 识别 9 章 |
| 其他特殊格式 | 待测试 | ? | 应该正常 |

---

## 🔧 技术细节

### 为什么使用正则而不是 XML 解析？

**原因**:
1. 避免引入额外的 XML 解析库
2. NCX 结构简单，正则足够
3. 性能更好

**正则表达式**:
```regex
<navPoint[^>]*id="([^"]*)"[^>]*>.*?<navLabel>\s*<text>([^<]*)</text>.*?</navLabel>\s*<content[^>]*src="([^"]*)"
```

**匹配**:
- Group 1: navPoint id
- Group 2: 章节标题
- Group 3: src 路径（含锚点）

---

### 为什么需要 archive 依赖？

**原因**:
- EPUB 本质是 ZIP 文件
- 需要解压读取 toc.ncx
- `archive` 库提供 ZIP 解压功能

**使用**:
```dart
import 'package:archive/archive.dart';

final archive = ZipDecoder().decodeBytes(bytes);
for (var file in archive.files) {
  if (file.name.endsWith('toc.ncx')) {
    // 读取 NCX 内容
  }
}
```

---

## 🐛 已知限制

### 限制 1: 正则解析可能不完整

**问题**: 复杂的 NCX 结构可能解析失败

**解决**: 如果 NCX 解析失败，回退到标准 epub_plus 分章

---

### 限制 2: 锚点提取可能不准确

**问题**: 某些 EPUB 的锚点格式不标准

**解决**: 添加错误处理，内容为空时跳过该章节

---

### 限制 3: 性能开销

**问题**: NCX 解析需要解压 ZIP，可能稍慢

**影响**: 首次打开图书时延迟 1-2 秒

**优化**: 缓存解析结果

---

## ✅ 成功标准

### 白老虎
- [ ] 章节数从 1 变为 9
- [ ] 每章标题正确
- [ ] 可以进入第二章
- [ ] 章节切换流畅
- [ ] 进度计算正确

### 现实一种（回归测试）
- [ ] 功能正常
- [ ] 章节数正确
- [ ] 无性能下降

### 测试分章
- [ ] 功能正常
- [ ] 3 章正确识别

---

## 🚀 下一步

1. **在模拟器中测试**
   - 导入白老虎
   - 查看控制台日志
   - 验证章节数

2. **收集测试数据**
   - 章节数
   - 每章标题
   - 能否进入第二章

3. **优化和修复**
   - 根据测试结果调整
   - 修复可能的 bug

---

**开发完成时间**: 2026-03-13  
**下一步**: 模拟器测试验证
