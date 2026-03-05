import 'dart:io';
import 'package:epub/epub.dart';
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
    if (epubBook.CoverImage != null) {
      coverPath = await _saveCoverImage(epubBook.CoverImage!, filePath);
    }

    // 计算章节数
    final chapters = epubBook.Chapters?.length ?? 0;

    return Book(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: epubBook.Title ?? '未知标题',
      author: epubBook.Author ?? '未知作者',
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

    if (epubBook.Chapters != null) {
      for (int i = 0; i < epubBook.Chapters!.length; i++) {
        final chapter = epubBook.Chapters![i];
        chapters.add(Chapter(
          title: chapter.Title ?? '第${i + 1}章',
          content: chapter.HtmlContent ?? '',
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

    if (epubBook.Chapters != null) {
      for (final chapter in epubBook.Chapters!) {
        final htmlContent = chapter.HtmlContent;
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
}
