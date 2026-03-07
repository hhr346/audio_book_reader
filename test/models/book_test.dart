import 'package:flutter_test/flutter_test.dart';
import 'package:audio_book_reader/models/book.dart';

void main() {
  group('Book Model Tests', () {
    test('Book creation with required fields', () {
      final book = Book(
        id: 'test-1',
        title: 'Test Book',
        author: 'Test Author',
        coverPath: '',
        filePath: '/path/to/book.epub',
        totalChapters: 10,
        addedAt: DateTime.now(),
      );

      expect(book.id, 'test-1');
      expect(book.title, 'Test Book');
      expect(book.author, 'Test Author');
      expect(book.totalChapters, 10);
      expect(book.currentChapterIndex, 0);
      expect(book.currentProgress, 0);
    });

    test('Book progress text formatting', () {
      final book = Book(
        id: 'test-2',
        title: 'Test',
        author: 'Author',
        coverPath: '',
        filePath: '/path.epub',
        totalChapters: 10,
        addedAt: DateTime.now(),
      );

      book.currentProgress = 50;
      expect(book.progressText, '50%');

      book.currentProgress = 100;
      expect(book.progressText, '100%');
    });

    test('Book isFinished flag', () {
      final book = Book(
        id: 'test-3',
        title: 'Test',
        author: 'Author',
        coverPath: '',
        filePath: '/path.epub',
        totalChapters: 10,
        addedAt: DateTime.now(),
      );

      expect(book.isFinished, false);

      book.currentProgress = 100;
      expect(book.isFinished, true);
    });
  });
}
