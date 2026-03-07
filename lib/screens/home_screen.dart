import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../models/book.dart';
import '../services/epub_service.dart';
import '../services/storage_service.dart';
import 'reader_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const _BookshelfScreen(),
    const SettingsScreen(),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books),
            label: '书架',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}

class _BookshelfScreen extends StatefulWidget {
  const _BookshelfScreen();
  
  @override
  State<_BookshelfScreen> createState() => _BookshelfScreenState();
}

class _BookshelfScreenState extends State<_BookshelfScreen> {
  String _sortBy = 'date'; // date, title, progress
  bool _ascending = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 有声书架'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: '排序',
            onSelected: (value) {
              if (value == 'toggle') {
                setState(() => _ascending = !_ascending);
              } else {
                setState(() => _sortBy = value);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'date',
                child: Row(
                  children: [
                    _sortBy == 'date' ? const Icon(Icons.check) : const SizedBox(),
                    const SizedBox(width: 8),
                    const Text('按时间'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'title',
                child: Row(
                  children: [
                    _sortBy == 'title' ? const Icon(Icons.check) : const SizedBox(),
                    const SizedBox(width: 8),
                    const Text('按书名'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'progress',
                child: Row(
                  children: [
                    _sortBy == 'progress' ? const Icon(Icons.check) : const SizedBox(),
                    const SizedBox(width: 8),
                    const Text('按进度'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(Icons.swap_vert),
                    SizedBox(width: 8),
                    Text('切换顺序'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.import_export),
            onPressed: _importBook,
            tooltip: '导入图书',
          ),
        ],
      ),
      body: Consumer<StorageService>(
        builder: (context, storage, child) {
          var books = storage.getAllBooks();
          
          // 排序
          books = _sortBooks(books);
          
          if (books.isEmpty) {
            return _buildEmptyState();
          }
          
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: books.length,
            itemBuilder: (context, index) {
              return _BookCard(
                book: books[index],
                onTap: () => _openBook(books[index]),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.library_books_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 24),
          const Text(
            '书架空空如也',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            '点击右上角导入 epub 图书',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _importBook,
            icon: const Icon(Icons.add),
            label: const Text('导入第一本书'),
          ),
        ],
      ),
    );
  }

  Future<void> _importBook() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub'],
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.single.path;
      if (filePath == null) return;

      // 显示加载动画
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // 解析 epub
      final book = await EpubService().extractBookInfo(filePath);
      
      // 保存到存储
      await StorageService().addBook(book);

      // 关闭加载动画
      if (mounted) Navigator.pop(context);

      // 显示成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ 《${book.title}》已添加到书架'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // 关闭加载动画
      if (mounted) Navigator.pop(context);

      // 显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 导入失败：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openBook(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReaderScreen(book: book),
      ),
    );
  }
  
  List<Book> _sortBooks(List<Book> books) {
    final sorted = List<Book>.from(books);
    
    switch (_sortBy) {
      case 'date':
        sorted.sort((a, b) => a.addedAt.compareTo(b.addedAt));
        break;
      case 'title':
        sorted.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'progress':
        sorted.sort((a, b) => a.currentProgress.compareTo(b.currentProgress));
        break;
    }
    
    return _ascending ? sorted : sorted.reversed.toList();
  }
}

  @override
  State<_BookshelfScreen> createState() => _BookshelfScreenState();
}

class _BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const _BookCard({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 封面
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.grey.shade300,
                child: book.coverPath.isNotEmpty && File(book.coverPath).existsSync()
                    ? Image.file(
                        File(book.coverPath),
                        fit: BoxFit.cover,
                      )
                    : const Center(
                        child: Icon(
                          Icons.menu_book,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
            // 信息
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (book.currentProgress > 0) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: book.currentProgress / 100,
                      backgroundColor: Colors.grey.shade200,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${book.progressText} 已读',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
