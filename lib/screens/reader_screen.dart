import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';
import '../models/chapter.dart';
import '../models/bookmark.dart';
import '../services/epub_service.dart';
import '../services/tts_service.dart';
import '../services/storage_service.dart';
import 'bookmarks_screen.dart';
import 'settings_screen.dart';

class ReaderScreen extends StatefulWidget {
  final Book book;
  final int? initialChapterIndex;
  final int? initialPageIndex;

  const ReaderScreen({
    super.key,
    required this.book,
    this.initialChapterIndex,
    this.initialPageIndex,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late Future<List<Chapter>> _chaptersFuture;
  late int _currentChapterIndex; // 初始化为上次阅读的章节
  
  // 分页相关
  List<String> _pages = [];
  int _currentPageIndex = 0;
  int _totalPages = 0; // 全书总页数
  int _cumulativePagesRead = 0; // 累计已读页数
  bool _isLoading = true;
  
  // 主题和字体
  double _fontSize = 18.0;
  bool _isDarkMode = false;
  
  // TTS 相关
  bool _isTtsPlaying = false;
  int _currentTtsPageIndex = 0;
  
  // 屏幕尺寸相关
  double _lineHeight = 1.6;
  int _linesPerPage = 0;
  int _charsPerLine = 0;
  
  // 章节页数缓存
  final Map<int, int> _chapterPageCounts = {};

  @override
  void initState() {
    super.initState();
    _chaptersFuture = EpubService().getChapters(widget.book.filePath);
    _loadSettings();
    // 初始化章节索引：书签位置 > 上次阅读位置 > 第一章
    if (widget.initialChapterIndex != null) {
      _currentChapterIndex = widget.initialChapterIndex!;
      print('📑 从书签打开：第${_currentChapterIndex + 1}章');
    } else {
      _currentChapterIndex = widget.book.currentChapterIndex;
      print('📖 打开图书，上次位置：第${_currentChapterIndex + 1}章，第${widget.book.currentPageIndex + 1}页');
    }
    // 延迟加载，确保屏幕尺寸已获取
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _calculatePageCapacity();
      await _calculateTotalPages();
      await _loadCurrentChapter(); // 会恢复上次位置或书签位置
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _fontSize = prefs.getDouble('font_size') ?? 18.0;
      _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    });
  }
  
  /// 重新加载设置（主题变化时调用）
  Future<void> _reloadSettings() async {
    await _loadSettings();
  }

  /// 计算全书总页数（逐章累加，确保准确性）
  Future<void> _calculateTotalPages() async {
    try {
      final chapters = await EpubService().getChapters(widget.book.filePath);
      
      _chapterPageCounts.clear();
      _totalPages = 0;
      
      for (int i = 0; i < chapters.length; i++) {
        final pageCount = await EpubService().getChapterPageCount(
          widget.book.filePath,
          i,
          fontSize: _fontSize,
          lineHeight: _lineHeight,
        );
        _chapterPageCounts[i] = pageCount;
        _totalPages += pageCount;
      }
      
      // 更新图书模型的总页数
      widget.book.totalPages = _totalPages;
      await StorageService().updateBook(widget.book);
      
      print('📊 全书总页数：$_totalPages (共${chapters.length}章)');
      print('📊 各章页数：${_chapterPageCounts.values.join(", ")}');
    } catch (e) {
      print('❌ 计算总页数失败：$e');
      _totalPages = widget.book.totalChapters * 10; // 估算值
    }
  }

  /// 计算累计页数（前面所有章节的页数 + 当前章节的页索引）
  Future<int> _calculateCumulativePages(int chapterIndex, int pageIndex) async {
    int cumulative = 0;
    
    // 计算前面所有章节的页数
    for (int i = 0; i < chapterIndex; i++) {
      if (!_chapterPageCounts.containsKey(i)) {
        _chapterPageCounts[i] = await EpubService().getChapterPageCount(
          widget.book.filePath,
          i,
          fontSize: _fontSize,
          lineHeight: _lineHeight,
        );
      }
      cumulative += _chapterPageCounts[i]!;
    }
    
    // 加上当前章节的页索引
    cumulative += pageIndex;
    
    return cumulative;
  }

  /// 计算屏幕容量（根据字体大小和屏幕尺寸）
  Future<void> _calculatePageCapacity() async {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // 减去 AppBar、底部控制栏、状态栏、padding 等（更保守的估算）
    final availableHeight = screenHeight - 280; // 增加预留空间
    final availableWidth = screenWidth - 64; // 增加左右 padding
    
    // 计算行高（像素）- 使用更大的行高系数
    final lineHeightInPixels = _fontSize * (_lineHeight + 0.2);
    
    // 每页行数（减少 2 行作为安全余量）
    _linesPerPage = ((availableHeight / lineHeightInPixels).floor() - 2).clamp(5, 100);
    
    // 每行字符数（假设每个汉字约 0.7 倍字体宽度，更保守）
    final charWidth = _fontSize * 0.7;
    _charsPerLine = ((availableWidth / charWidth).floor() - 2).clamp(10, 50);
    
    print('📐 分页计算：${_linesPerPage}行 × ${_charsPerLine}字 = ${_linesPerPage * _charsPerLine}字/页');
  }

  Future<void> _loadCurrentChapter({bool forceFirstPage = false}) async {
    if (!mounted) return;
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
        
        // 重新计算容量（确保已获取屏幕尺寸）
        if (_linesPerPage == 0 || _charsPerLine == 0) {
          await _calculatePageCapacity();
        }
        
        // 分页处理
        final pages = _paginateText(text);
        
        if (mounted) {
          // 恢复页面位置：书签位置 > 强制第一页 > 第一页
          int restorePageIndex = 0;
          
          if (widget.initialPageIndex != null && widget.initialPageIndex! < pages.length) {
            // 从书签打开
            restorePageIndex = widget.initialPageIndex!;
            print('📑 从书签恢复：第${_currentChapterIndex + 1}章 第${restorePageIndex + 1}页');
          } else if (forceFirstPage) {
            // 强制跳转到第一页（章节切换时）
            restorePageIndex = 0;
            print('📖 跳转到新章节：第${_currentChapterIndex + 1}章 第 1 页');
          }
          
          // 如果不是强制第一页，且累计页数未设置，则计算累计页数
          if (!forceFirstPage && _cumulativePagesRead == 0) {
            _cumulativePagesRead = await _calculateCumulativePages(_currentChapterIndex, restorePageIndex);
          }
          
          setState(() {
            _pages = pages;
            _currentPageIndex = restorePageIndex;
            _isLoading = false;
          });
          
          // 更新阅读进度（按总页数计算）
          final progress = _totalPages > 0 
              ? ((_cumulativePagesRead + 1) / _totalPages * 100).round()
              : 0;
          
          widget.book.currentChapterIndex = _currentChapterIndex;
          widget.book.currentPageIndex = restorePageIndex;
          widget.book.cumulativePagesRead = _cumulativePagesRead;
          widget.book.currentProgress = progress.clamp(0, 100);
          widget.book.lastReadAt = DateTime.now();
          await StorageService().updateBook(widget.book);
          
          print('📊 加载完成：第${_currentChapterIndex + 1}章 第${restorePageIndex + 1}页，累计${_cumulativePagesRead + 1}/$_totalPages 页 ($progress%)');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载章节失败：$e')),
        );
      }
    }
  }

  /// 改进的分页算法 - 按屏幕容量分页
  List<String> _paginateText(String text) {
    if (text.isEmpty) return [''];
    
    final pages = <String>[];
    final maxCharsPerPage = _linesPerPage * _charsPerLine;
    
    // 如果计算失败，使用默认值
    if (maxCharsPerPage <= 0) {
      return [text];
    }
    
    // 按段落分割
    final paragraphs = text.split('\n');
    StringBuffer currentPage = StringBuffer();
    int currentLength = 0;
    
    for (final paragraph in paragraphs) {
      final words = paragraph.split(' ');
      
      for (final word in words) {
        // 如果当前页 + 这个词会超限
        if (currentLength + word.length + 1 > maxCharsPerPage) {
          // 保存当前页
          if (currentPage.isNotEmpty) {
            pages.add(currentPage.toString().trim());
            currentPage.clear();
            currentLength = 0;
          }
        }
        
        // 添加词到当前页
        if (currentPage.isNotEmpty) {
          currentPage.write(' ');
          currentLength++;
        }
        currentPage.write(word);
        currentLength += word.length;
      }
      
      // 段落结束，添加换行
      if (paragraphs.length > 1) {
        currentPage.write('\n\n');
        currentLength += 2;
      }
    }
    
    // 保存最后一页
    if (currentPage.isNotEmpty) {
      pages.add(currentPage.toString().trim());
    }
    
    // 确保至少有一页
    if (pages.isEmpty) {
      pages.add(text);
    }
    
    return pages;
  }

  Future<void> _toggleTts() async {
    print('🎙️ _toggleTts() 被调用');
    final ttsService = TtsService();
    
    print('  - TTS 已初始化：${ttsService.isInitialized}');
    print('  - 当前是否播放：$_isTtsPlaying');
    print('  - 页数：${_pages.length}');
    print('  - 当前页索引：$_currentPageIndex');
    
    // 首次使用时初始化
    if (!ttsService.isInitialized) {
      print('⚠️ TTS 未初始化，开始初始化...');
      await ttsService.init();
    }
    
    // 设置自动连读回调
    ttsService.setAutoContinue(true);
    ttsService.setOnPageChanged((text) {
      // 播放完成后自动翻页并继续朗读
      print('🔄 自动连读回调触发');
      if (_isTtsPlaying && mounted) {
        _nextPageForAutoRead();
      }
    });
    
    if (_isTtsPlaying) {
      print('⏸️ 暂停播放');
      await ttsService.pause();
      setState(() => _isTtsPlaying = false);
    } else {
      if (_pages.isNotEmpty && _currentPageIndex < _pages.length) {
        final textToSpeak = _pages[_currentPageIndex];
        print('▶️ 开始播放第${_currentPageIndex + 1}页');
        print('  - 文本长度：${textToSpeak.length}');
        
        try {
          await ttsService.speak(textToSpeak);
          setState(() {
            _isTtsPlaying = true;
            _currentTtsPageIndex = _currentPageIndex;
          });
          print('✅ TTS 播放状态已更新');
        } catch (e) {
          print('❌ TTS 播放失败：$e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ TTS 播放失败：$e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        print('⚠️ 无法播放：页数=${_pages.length}, 索引=$_currentPageIndex');
      }
    }
  }
  
  /// 自动连读时的翻页（不触发 TTS，因为回调会自动处理）
  Future<void> _nextPageForAutoRead() async {
    if (_currentPageIndex < _pages.length - 1) {
      final nextPageIndex = _currentPageIndex + 1;
      
      // 更新累计页数
      _cumulativePagesRead++;
      
      setState(() {
        _currentPageIndex = nextPageIndex;
        _currentTtsPageIndex = nextPageIndex; // 更新 TTS 页码
      });
      
      // 更新进度
      await _updateProgress();
      
      print('🔄 自动连读：第${_currentChapterIndex + 1}章 第${nextPageIndex + 1}页，累计${_cumulativePagesRead + 1}/$_totalPages 页');
      
      // 朗读新页面
      final ttsService = TtsService();
      await ttsService.speak(_pages[nextPageIndex]);
    } else {
      // 已经是最后一页，进入下一章
      print('🔄 当前章结束，进入下一章');
      await _nextChapter();
      // 下一章第一页自动开始朗读
      final ttsService = TtsService();
      if (_pages.isNotEmpty) {
        await ttsService.speak(_pages[0]);
      }
    }
  }

  Future<void> _nextPage() async {
    if (_currentPageIndex < _pages.length - 1) {
      final nextPageIndex = _currentPageIndex + 1;
      
      // 更新累计页数（在当前章节内，只需 +1）
      _cumulativePagesRead++;
      
      setState(() {
        _currentPageIndex = nextPageIndex;
      });
      
      // 更新进度
      await _updateProgress();
      
      print('📖 下一页：第${_currentChapterIndex + 1}章 第${nextPageIndex + 1}页，累计${_cumulativePagesRead + 1}/$_totalPages 页');
      
      // 如果 TTS 正在播放，朗读新页面
      if (_isTtsPlaying) {
        TtsService().speak(_pages[_currentPageIndex]);
      }
    } else {
      // 已经是最后一页，进入下一章
      await _nextChapter();
    }
  }

  Future<void> _previousPage() async {
    if (_currentPageIndex > 0) {
      final prevPageIndex = _currentPageIndex - 1;
      
      // 更新累计页数（在当前章节内，只需 -1）
      _cumulativePagesRead--;
      
      setState(() {
        _currentPageIndex = prevPageIndex;
      });
      
      // 更新进度
      await _updateProgress();
      
      print('📖 上一页：第${_currentChapterIndex + 1}章 第${prevPageIndex + 1}页，累计${_cumulativePagesRead + 1}/$_totalPages 页');
      
      if (_isTtsPlaying) {
        TtsService().speak(_pages[_currentPageIndex]);
      }
    } else {
      // 已经是第一页，返回上一章的最后一页
      await _previousChapter();
    }
  }

  /// 更新阅读进度
  Future<void> _updateProgress() async {
    final progress = _totalPages > 0 
        ? ((_cumulativePagesRead + 1) / _totalPages * 100).round()
        : 0;
    
    widget.book.currentChapterIndex = _currentChapterIndex;
    widget.book.currentPageIndex = _currentPageIndex;
    widget.book.cumulativePagesRead = _cumulativePagesRead;
    widget.book.currentProgress = progress.clamp(0, 100);
    widget.book.lastReadAt = DateTime.now();
    
    await StorageService().updateBook(widget.book);
  }

  Future<void> _nextChapter() async {
    if (_currentChapterIndex < widget.book.totalChapters - 1) {
      final nextChapterIndex = _currentChapterIndex + 1;
      
      // 提前计算累计页数（避免 UI 突变）
      final cumulativePages = await _calculateCumulativePages(nextChapterIndex, 0);
      
      setState(() {
        _currentChapterIndex = nextChapterIndex;
        _currentPageIndex = 0;
        _cumulativePagesRead = cumulativePages; // 同时更新累计页数
      });
      
      print('📖 切换到下一章：第${nextChapterIndex + 1}章，累计第${cumulativePages + 1}页');
      
      await _loadCurrentChapter(forceFirstPage: true);
    }
  }

  Future<void> _previousChapter() async {
    if (_currentChapterIndex > 0) {
      final prevChapterIndex = _currentChapterIndex - 1;
      
      // 获取上一章的页数
      final prevChapterPageCount = _chapterPageCounts[prevChapterIndex] ?? 
          await EpubService().getChapterPageCount(
            widget.book.filePath,
            prevChapterIndex,
            fontSize: _fontSize,
            lineHeight: _lineHeight,
          );
      
      final lastPageIndex = prevChapterPageCount - 1;
      
      // 提前计算累计页数
      final cumulativePages = await _calculateCumulativePages(prevChapterIndex, lastPageIndex);
      
      setState(() {
        _currentChapterIndex = prevChapterIndex;
        _currentPageIndex = lastPageIndex;
        _cumulativePagesRead = cumulativePages; // 同时更新累计页数
      });
      
      print('📖 切换到上一章：第${prevChapterIndex + 1}章 第${lastPageIndex + 1}页，累计第${cumulativePages + 1}页');
      
      await _loadCurrentChapter(forceFirstPage: false);
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
                    setState(() {
                      _currentChapterIndex = index;
                      _currentPageIndex = 0; // 新章节从第一页开始
                    });
                    _loadCurrentChapter(forceFirstPage: true); // 强制跳转到第一页
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
      position: _currentPageIndex,
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

  void _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          onFontSizeChanged: (size) {
            setState(() {
              _fontSize = size;
              _calculatePageCapacity();
              _loadCurrentChapter(); // 重新分页
            });
          },
          onThemeChanged: (isDark) async {
            // 立即更新本地状态
            setState(() => _isDarkMode = isDark);
            // 保存到 SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('is_dark_mode', isDark);
          },
          currentFontSize: _fontSize,
          currentIsDarkMode: _isDarkMode,
        ),
      ),
    );
    // 返回后重新加载设置（确保同步）
    await _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _isDarkMode ? Colors.white : Colors.black;
    final backgroundColor = _isDarkMode ? Colors.black : Colors.white;
    final scaffoldBackgroundColor = _isDarkMode ? Colors.grey[900]! : Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.book.title),
        backgroundColor: _isDarkMode ? Colors.grey[850] : null,
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
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: '设置',
          ),
        ],
      ),
      body: Column(
        children: [
          // 进度条
          LinearProgressIndicator(
            value: widget.book.currentProgress / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              _isDarkMode ? Colors.blue[300]! : Colors.blue,
            ),
          ),
          
          // 章节和页码信息
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '第${_currentChapterIndex + 1}/${widget.book.totalChapters}章',
                  style: TextStyle(
                    color: textColor.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${_cumulativePagesRead + 1}/$_totalPages 页 (${_currentPageIndex + 1}/${_pages.length})',
                  style: TextStyle(
                    color: textColor.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // 内容区域（分页显示）
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _pages.isEmpty
                    ? const Center(child: Text('本章无内容'))
                    : GestureDetector(
                        onTap: () {
                          // 点击屏幕中间显示/隐藏控制栏
                        },
                        onHorizontalDragEnd: (details) {
                          if (details.primaryVelocity! < -50) {
                            _nextPage();
                          } else if (details.primaryVelocity! > 50) {
                            _previousPage();
                          }
                        },
                        child: Container(
                          color: backgroundColor,
                          padding: const EdgeInsets.all(16),
                          child: SingleChildScrollView(
                            child: SelectableText(
                              _pages[_currentPageIndex],
                              style: TextStyle(
                                fontSize: _fontSize,
                                height: _lineHeight,
                                color: textColor,
                              ),
                            ),
                          ),
                        ),
                      ),
          ),
          
          // 底部控制栏
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[850] : Colors.white,
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
                // 上一页
                ElevatedButton.icon(
                  onPressed: _currentPageIndex > 0 || _currentChapterIndex > 0
                      ? _previousPage
                      : null,
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('上一页'),
                ),
                
                // TTS 播放
                FloatingActionButton(
                  heroTag: 'tts',
                  mini: true,
                  onPressed: _pages.isNotEmpty ? _toggleTts : null,
                  child: Icon(
                    _isTtsPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                ),
                
                // 下一页
                ElevatedButton.icon(
                  onPressed: _currentPageIndex < _pages.length - 1 || _currentChapterIndex < widget.book.totalChapters - 1
                      ? _nextPage
                      : null,
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('下一页'),
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
