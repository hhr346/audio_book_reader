import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:epub_plus/epub_plus.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import '../models/book.dart';
import '../models/chapter.dart';

/// NCX 导航点数据结构
class NcxNavPoint {
  final String id;
  final String title;
  final String src;
  final String? anchor; // 锚点（#filepos109）

  NcxNavPoint({
    required this.id,
    required this.title,
    required this.src,
    this.anchor,
  });
}

class EpubService {
  static final EpubService _instance = EpubService._internal();
  factory EpubService() => _instance;
  EpubService._internal();

  /// 解析 epub 文件
  Future<EpubBook> parseEpub(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    return await EpubReader.readBook(bytes);
  }

  /// 从 EPUB 中提取 NCX 文件内容
  Future<String?> _extractNcxContent(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // 查找 toc.ncx 文件
      for (var file in archive.files) {
        if (file.name.endsWith('toc.ncx')) {
          final content = utf8.decode(file.content as List<int>);
          return content;
        }
      }
    } catch (e) {
      print('⚠️ 提取 NCX 失败：$e');
    }
    return null;
  }

  /// 解析 NCX 文件，提取章节信息
  Future<List<NcxNavPoint>> _parseNcx(String ncxContent) async {
    final navPoints = <NcxNavPoint>[];

    try {
      // 使用简单的正则表达式解析 NCX（避免引入 XML 解析库）
      final navPointRegex = RegExp(
        r'<navPoint[^>]*id="([^"]*)"[^>]*>.*?<navLabel>\s*<text>([^<]*)</text>.*?</navLabel>\s*<content[^>]*src="([^"]*)"',
        multiLine: true,
        dotAll: true,
      );

      for (final match in navPointRegex.allMatches(ncxContent)) {
        final id = match.group(1)!;
        final title = match.group(2)!;
        final src = match.group(3)!;

        // 提取锚点（如果有）
        String? anchor;
        if (src.contains('#')) {
          anchor = src.split('#').last;
        }

        navPoints.add(NcxNavPoint(
          id: id,
          title: title,
          src: src,
          anchor: anchor,
        ));
      }

      print('📑 NCX 解析完成：${navPoints.length} 个导航点');
    } catch (e) {
      print('❌ 解析 NCX 失败：$e');
    }

    return navPoints;
  }

  /// 从 HTML 内容中提取锚点对应的章节内容
  String _extractContentByAnchor(String html, String anchor, String title) {
    try {
      // 查找锚点位置
      final anchorPattern = 'id="$anchor"';
      final anchorIndex = html.indexOf(anchorPattern);

      if (anchorIndex == -1) {
        // 找不到锚点，返回空字符串
        return '';
      }

      // 从锚点位置开始，找到下一个锚点或文件结束
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
      final wrappedContent = '<h1>$title</h1>\n$content';
      
      return wrappedContent;
    } catch (e) {
      print('⚠️ 提取锚点内容失败：$e');
      return '';
    }
  }

  /// 从单个 HTML 文件中按锚点分割章节
  Future<List<Chapter>> _splitHtmlByAnchors(
    String filePath,
    String htmlFile,
    List<NcxNavPoint> navPoints,
  ) async {
    final chapters = <Chapter>[];

    try {
      // 读取 HTML 文件内容
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // 查找并读取 HTML 文件
      String? htmlContent;
      for (var archiveFile in archive.files) {
        if (archiveFile.name.endsWith(htmlFile)) {
          htmlContent = utf8.decode(archiveFile.content as List<int>);
          break;
        }
      }

      if (htmlContent == null) {
        print('⚠️ 未找到 HTML 文件：$htmlFile');
        return chapters;
      }

      print('📄 HTML 文件内容长度：${htmlContent.length}');

      // 按 NCX 导航点提取章节
      for (final navPoint in navPoints) {
        if (navPoint.anchor != null) {
          final content = _extractContentByAnchor(
            htmlContent,
            navPoint.anchor!,
            navPoint.title,
          );

          if (content.isNotEmpty) {
            chapters.add(Chapter(
              title: navPoint.title,
              content: content,
              index: chapters.length,
            ));
            print('✅ 提取章节：${navPoint.title} (${content.length} 字符)');
          } else {
            print('⚠️ 章节内容为空：${navPoint.title}');
          }
        }
      }
    } catch (e) {
      print('❌ 分割 HTML 失败：$e');
    }

    return chapters;
  }

  /// 从 epub 提取图书信息
  Future<Book> extractBookInfo(String filePath) async {
    final epubBook = await parseEpub(filePath);
    
    // 保存封面到本地
    String coverPath = '';
    try {
      // epub_plus 5.1.0 使用 coverImage 属性 (Image 类型)
      final coverImage = epubBook.coverImage;
      if (coverImage != null) {
        // 使用 encodeJpg 将 Image 转换为字节
        final jpgBytes = img.encodeJpg(coverImage);
        if (jpgBytes != null && jpgBytes.isNotEmpty) {
          coverPath = await _saveCoverImage(jpgBytes, filePath);
          print('✓ 封面已保存：$coverPath');
        } else {
          print('⚠️ 封面编码失败');
        }
      } else {
        print('⚠️ 未找到封面图片');
      }
    } catch (e) {
      print('⚠️ 封面提取失败：$e');
    }

    // 计算章节数
    final chapters = epubBook.chapters?.length ?? 0;

    return Book(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: epubBook.title ?? '未知标题',
      author: epubBook.author ?? '未知作者',
      coverPath: coverPath,
      filePath: filePath,
      totalChapters: chapters,
      addedAt: DateTime.now(),
    );
  }

  /// 保存封面图片
  Future<String> _saveCoverImage(List<int> coverData, String sourcePath) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final bookDir = Directory('${dir.path}/books');
      if (!await bookDir.exists()) {
        await bookDir.create(recursive: true);
      }

      // 生成唯一文件名
      final fileName = 'cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final coverFile = File('${bookDir.path}/$fileName');
      
      await coverFile.writeAsBytes(coverData);
      return coverFile.path;
    } catch (e) {
      return '';
    }
  }

  /// 获取章节列表（支持 NCX 锚点分章）
  Future<List<Chapter>> getChapters(String filePath) async {
    print('📚 开始解析章节：$filePath');
    
    // 1. 尝试解析 NCX 文件
    final ncxContent = await _extractNcxContent(filePath);
    if (ncxContent != null) {
      final navPoints = await _parseNcx(ncxContent);
      
      if (navPoints.isNotEmpty) {
        print('📑 NCX 解析到 ${navPoints.length} 个导航点');
        
        // 检查是否所有导航点都指向同一个文件（白老虎情况）
        final srcFiles = navPoints.map((np) => np.src.split('#').first).toSet();
        
        if (srcFiles.length == 1) {
          // 所有章节都在一个文件里，需要按锚点分割
          print('📝 检测到单文件多章节结构，使用锚点分割');
          final htmlFile = srcFiles.first;
          final chapters = await _splitHtmlByAnchors(filePath, htmlFile, navPoints);
          
          if (chapters.isNotEmpty) {
            print('✅ NCX 锚点分章成功：${chapters.length} 章');
            return chapters;
          }
        }
      }
    }
    
    // 2. NCX 解析失败，使用标准的 epub_plus 分章
    print('📖 使用标准 epub_plus 分章');
    final epubBook = await parseEpub(filePath);
    final chapters = <Chapter>[];

    if (epubBook.chapters != null) {
      for (int i = 0; i < epubBook.chapters!.length; i++) {
        final chapter = epubBook.chapters![i];
        final title = chapter.title ?? '第${i + 1}章';
        final content = chapter.htmlContent ?? '';
        
        chapters.add(Chapter(
          title: title,
          content: content,
          index: i,
        ));
      }
    }
    
    print('✅ 标准分章完成：${chapters.length} 章');
    return chapters;
  }

  /// 获取指定章节内容
  Future<Chapter?> getChapter(String filePath, int index) async {
    final chapters = await getChapters(filePath);
    if (index >= 0 && index < chapters.length) {
      return chapters[index];
    }
    return null;
  }

  /// 获取所有文本内容（用于 TTS）
  Future<String> getAllText(String filePath) async {
    final epubBook = await parseEpub(filePath);
    final buffer = StringBuffer();

    if (epubBook.chapters != null) {
      for (final chapter in epubBook.chapters!) {
        final htmlContent = chapter.htmlContent;
        if (htmlContent != null && htmlContent.isNotEmpty) {
          final text = htmlContent
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          if (text.isNotEmpty) {
            buffer.writeln(text);
          }
        }
      }
    }

    return buffer.toString();
  }

  /// 计算全书总页数（基于屏幕容量估算）
  /// 注意：这是近似值，实际页数会根据字体大小和屏幕尺寸变化
  Future<int> calculateTotalPages(String filePath, {
    double fontSize = 18.0,
    double lineHeight = 1.6,
    int screenWidth = 400,  // 默认手机宽度
    int screenHeight = 800, // 默认手机高度
  }) async {
    final allText = await getAllText(filePath);
    
    if (allText.isEmpty) return 0;
    
    // 计算每页容量
    final availableHeight = screenHeight - 280; // 减去 UI 元素
    final availableWidth = screenWidth - 64;
    final lineHeightInPixels = fontSize * (lineHeight + 0.2);
    final linesPerPage = ((availableHeight / lineHeightInPixels).floor() - 2).clamp(5, 100);
    final charWidth = fontSize * 0.7;
    final charsPerLine = ((availableWidth / charWidth).floor() - 2).clamp(10, 50);
    final maxCharsPerPage = linesPerPage * charsPerLine;
    
    // 计算总页数
    final totalPages = (allText.length / maxCharsPerPage).ceil();
    
    print('📊 计算总页数：${allText.length} 字符 ÷ $maxCharsPerPage 字/页 = $totalPages 页');
    
    return totalPages;
  }

  /// 获取章节的页数
  Future<int> getChapterPageCount(String filePath, int chapterIndex, {
    double fontSize = 18.0,
    double lineHeight = 1.6,
    int screenWidth = 400,
    int screenHeight = 800,
  }) async {
    final chapter = await getChapter(filePath, chapterIndex);
    if (chapter == null) return 0;
    
    final text = chapter.content
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    
    if (text.isEmpty) return 0;
    
    // 计算每页容量
    final availableHeight = screenHeight - 280;
    final availableWidth = screenWidth - 64;
    final lineHeightInPixels = fontSize * (lineHeight + 0.2);
    final linesPerPage = ((availableHeight / lineHeightInPixels).floor() - 2).clamp(5, 100);
    final charWidth = fontSize * 0.7;
    final charsPerLine = ((availableWidth / charWidth).floor() - 2).clamp(10, 50);
    final maxCharsPerPage = linesPerPage * charsPerLine;
    
    return (text.length / maxCharsPerPage).ceil();
  }
}
