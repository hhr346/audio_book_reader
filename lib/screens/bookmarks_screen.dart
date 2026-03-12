import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bookmark.dart';
import '../models/book.dart';
import '../services/storage_service.dart';
import 'reader_screen.dart';

class BookmarksScreen extends StatelessWidget {
  final String bookId;
  final String bookTitle;
  final String filePath;

  const BookmarksScreen({
    super.key,
    required this.bookId,
    required this.bookTitle,
    required this.filePath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📑 书签 - $bookTitle'),
      ),
      body: Consumer<StorageService>(
        builder: (context, storage, child) {
          final bookmarks = storage.getBookmarks(bookId);

          if (bookmarks.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookmarks.length,
            itemBuilder: (context, index) {
              return _BookmarkCard(
                bookmark: bookmarks[index],
                onTap: () => _jumpToBookmark(context, bookmarks[index]),
                onDelete: () => _deleteBookmark(context, storage, bookmarks[index].id),
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
            Icons.bookmark_border,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 24),
          const Text(
            '暂无书签',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            '阅读时点击书签按钮添加',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _jumpToBookmark(BuildContext context, Bookmark bookmark) {
    // 关闭书签页面
    Navigator.pop(context);
    
    // 打开阅读器并跳转到书签位置
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReaderScreen(
          book: Book(
            id: bookmark.bookId,
            title: bookTitle,
            author: '',
            coverPath: '',
            filePath: filePath,
            totalChapters: 0,
            addedAt: DateTime.now(),
          ),
          initialChapterIndex: bookmark.chapterIndex,
          initialPageIndex: bookmark.position,
        ),
      ),
    );
  }

  void _deleteBookmark(BuildContext context, StorageService storage, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除书签'),
        content: const Text('确定要删除这个书签吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              storage.removeBookmark(id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ 书签已删除')),
              );
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  final Bookmark bookmark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BookmarkCard({
    required this.bookmark,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bookmark, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      bookmark.chapterTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                    onPressed: onDelete,
                    tooltip: '删除书签',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                bookmark.formattedDate,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              if (bookmark.hasNote) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    bookmark.note,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
