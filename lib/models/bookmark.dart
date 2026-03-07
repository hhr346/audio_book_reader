import 'package:hive/hive.dart';

part 'bookmark.g.dart';

@HiveType(typeId: 1)
class Bookmark extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String bookId;

  @HiveField(2)
  int chapterIndex;

  @HiveField(3)
  String chapterTitle;

  @HiveField(4)
  int position; // 在章节中的位置（字符索引）

  @HiveField(5)
  String note; // 可选的笔记内容

  @HiveField(6)
  DateTime createdAt;

  Bookmark({
    required this.id,
    required this.bookId,
    required this.chapterIndex,
    required this.chapterTitle,
    this.position = 0,
    this.note = '',
    required this.createdAt,
  });

  /// 格式化创建时间
  String get formattedDate {
    return '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')} '
        '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  /// 是否有笔记
  bool get hasNote => note.isNotEmpty;
}
