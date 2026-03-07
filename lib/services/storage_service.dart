import 'package:hive_flutter/hive_flutter.dart';
import '../models/book.dart';
import '../models/bookmark.dart';

class StorageService extends ChangeNotifier {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late Box<Book> _books;
  late Box<Bookmark> _bookmarks;

  /// 初始化存储
  Future<void> init() async {
    _books = await Hive.openBox<Book>('books');
    _bookmarks = await Hive.openBox<Bookmark>('bookmarks');
  }

  /// 添加图书
  Future<void> addBook(Book book) async {
    await _books.put(book.id, book);
    notifyListeners();
  }

  /// 获取所有图书
  List<Book> getAllBooks() {
    final books = _books.values.toList();
    // 按添加时间倒序排列
    books.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return books;
  }

  /// 更新图书
  Future<void> updateBook(Book book) async {
    await _books.put(book.id, book);
    notifyListeners();
  }

  /// 删除图书
  Future<void> removeBook(String id) async {
    await _books.delete(id);
    notifyListeners();
  }

  /// 获取图书
  Book? getBook(String id) {
    return _books.get(id);
  }

  /// 清除所有图书
  Future<void> clearAll() async {
    await _books.clear();
    notifyListeners();
  }

  /// 获取图书数量
  int get bookCount => _books.length;

  // ========== 书签管理 ==========

  /// 添加书签
  Future<void> addBookmark(Bookmark bookmark) async {
    await _bookmarks.put(bookmark.id, bookmark);
    notifyListeners();
  }

  /// 获取某本书的所有书签
  List<Bookmark> getBookmarks(String bookId) {
    final bookmarks = _bookmarks.values
        .where((b) => b.bookId == bookId)
        .toList();
    // 按创建时间排序
    bookmarks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return bookmarks;
  }

  /// 删除书签
  Future<void> removeBookmark(String id) async {
    await _bookmarks.delete(id);
    notifyListeners();
  }

  /// 获取书签
  Bookmark? getBookmark(String id) {
    return _bookmarks.get(id);
  }

  /// 清除某本书的所有书签
  Future<void> clearBookmarks(String bookId) async {
    final bookmarks = getBookmarks(bookId);
    for (final bookmark in bookmarks) {
      await _bookmarks.delete(bookmark.id);
    }
    notifyListeners();
  }

  /// 获取书签数量
  int get bookmarkCount => _bookmarks.length;
}
