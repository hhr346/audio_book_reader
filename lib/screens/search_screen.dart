import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../services/storage_service.dart';
import 'reader_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Book> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
      _performSearch();
    });
  }

  void _performSearch() {
    if (_searchQuery.isEmpty) {
      _searchResults = [];
      return;
    }

    final allBooks = StorageService().getAllBooks();
    setState(() {
      _searchResults = allBooks.where((book) {
        final title = book.title.toLowerCase();
        final author = book.author.toLowerCase();
        final query = _searchQuery.toLowerCase();
        return title.contains(query) || author.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '搜索书名或作者...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            border: InputBorder.none,
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
          ),
        ),
      ),
      body: _searchQuery.isEmpty ? _buildRecentSearch() : _buildSearchResults(),
    );
  }

  Widget _buildRecentSearch() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 24),
          const Text(
            '搜索图书',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            '输入书名或作者进行搜索',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          _buildSearchTips(),
        ],
      ),
    );
  }

  Widget _buildSearchTips() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '搜索提示：',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          const Text('• 支持模糊搜索'),
          const Text('• 支持书名和作者搜索'),
          const Text('• 不区分大小写'),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            const Text(
              '未找到相关图书',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              '尝试搜索 "$_searchQuery"',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final book = _searchResults[index];
        return _BookResultCard(
          book: book,
          onTap: () => _openBook(book),
        );
      },
    );
  }

  void _openBook(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReaderScreen(book: book),
      ),
    );
  }
}

class _BookResultCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const _BookResultCard({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 封面
              Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.menu_book, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              // 信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    if (book.currentProgress > 0)
                      LinearProgressIndicator(
                        value: book.currentProgress / 100,
                        backgroundColor: Colors.grey.shade200,
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
