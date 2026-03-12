import 'dart:io';
import 'dart:typed_data';
import 'package:epub_plus/epub_plus.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../models/book.dart';
import '../models/chapter.dart';

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

  /// 获取章节列表
  Future<List<Chapter>> getChapters(String filePath) async {
    final epubBook = await parseEpub(filePath);
    final chapters = <Chapter>[];

    if (epubBook.chapters != null) {
      for (int i = 0; i < epubBook.chapters!.length; i++) {
        final chapter = epubBook.chapters![i];
        chapters.add(Chapter(
          title: chapter.title ?? '第${i + 1}章',
          content: chapter.htmlContent ?? '',
          index: i,
        ));
      }
    }

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
