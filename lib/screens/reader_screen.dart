import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../models/chapter.dart';
import '../models/bookmark.dart';
import '../services/epub_service.dart';
import '../services/tts_service.dart';
import '../services/storage_service.dart';
import 'bookmarks_screen.dart';

class ReaderScreen extends StatefulWidget {
  final Book book;

  const ReaderScreen({super.key, required this.book});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late Future<List<Chapter>> _chaptersFuture;
  int _currentChapterIndex = 0;
  String _currentContent = '';
  bool _isLoading = true;
  bool _isTtsPlaying = false;
  
  @override
  void initState() {
    super.initState();
    _chaptersFuture = EpubService().getChapters(widget.book.filePath);
    _loadCurrentChapter();
  }

  Future<void> _loadCurrentChapter() async {
    setState(() => _isLoading = true);
    
    try {
      final chapter = await EpubService().getChapter(
        widget.book.filePath,
        _currentChapterIndex,
      );
      
      if (chapter != null) {
        // 移除 HTML 标签，提取纯文本
        final text = chapter.content
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        
        setState(() {
          _currentContent = text;
          _isLoading = false;
        });
        
        // 更新阅读进度
        final progress = ((_currentChapterIndex + 1) / widget.book.totalChapters * 100).round();
        widget.book.currentChapterIndex = _currentChapterIndex;
        widget.book.currentProgress = progress;
        widget.book.lastReadAt = DateTime.now();
        await StorageService().updateBook(widget.book);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载章节失败：$e')),
        );
      }
    }
  }

  Future<void> _toggleTts() async {
    final ttsService = TtsService();
    
    if (_isTtsPlaying) {
      await ttsService.pause();
      setState(() => _isTtsPlaying = false);
    } else {
      if (_currentContent.isNotEmpty) {
        await ttsService.speak(_currentContent);
        setState(() => _isTtsPlaying = true);
      }
    }
  }

  void _nextChapter() {
    if (_currentChapterIndex < widget.book.totalChapters - 1) {
      setState(() => _currentChapterIndex++);
      _loadCurrentChapter();
    }
  }

  void _previousChapter() {
    if (_currentChapterIndex > 0) {
      setState(() => _currentChapterIndex--);
      _loadCurrentChapter();
    }
  }

  void _showChapterList() async {
    final chapters = await _chaptersFuture;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '选择章节',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: chapters.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(
                    chapters[index].title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: index == _currentChapterIndex
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    setState(() => _currentChapterIndex = index);
                    _loadCurrentChapter();
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addBookmark() {
    final bookmark = Bookmark(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bookId: widget.book.id,
      chapterIndex: _currentChapterIndex,
      chapterTitle: '第${_currentChapterIndex + 1}章',
      position: 0,
      createdAt: DateTime.now(),
    );
    
    StorageService().addBookmark(bookmark);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ 书签已添加'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showBookmarks() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookmarksScreen(
          bookId: widget.book.id,
          bookTitle: widget.book.title,
          filePath: widget.book.filePath,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: _addBookmark,
            tooltip: '添加书签',
          ),
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: _showBookmarks,
            tooltip: '书签列表',
          ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _showChapterList,
            tooltip: '章节列表',
          ),
        ],
      ),
      body: Column(
        children: [
          // 进度条
          LinearProgressIndicator(
            value: widget.book.currentProgress / 100,
            backgroundColor: Colors.grey.shade200,
          ),
          
          // 内容区域
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      _currentContent,
                      style: const TextStyle(fontSize: 16, height: 1.6),
                    ),
                  ),
          ),
          
          // 底部控制栏
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 上一章
                ElevatedButton.icon(
                  onPressed: _currentChapterIndex > 0 ? _previousChapter : null,
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('上一章'),
                ),
                
                // TTS 播放
                FloatingActionButton(
                  heroTag: 'tts',
                  mini: true,
                  onPressed: _toggleTts,
                  child: Icon(
                    _isTtsPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                ),
                
                // 下一章
                ElevatedButton.icon(
                  onPressed: _currentChapterIndex < widget.book.totalChapters - 1
                      ? _nextChapter
                      : null,
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('下一章'),
                  style: ElevatedButton.styleFrom(
                    iconColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    TtsService().stop();
    super.dispose();
  }
}
