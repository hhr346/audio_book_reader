import 'package:hive_flutter/hive_flutter.dart';
import '../models/book.dart';

class StorageService extends ChangeNotifier {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late Box<Book> _books;

  /// 初始化存储
  Future<void> init() async {
    _books = await Hive.openBox<Book>('books');
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
}
