import 'package:hive/hive.dart';

part 'book.g.dart';

@HiveType(typeId: 0)
class Book extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String author;

  @HiveField(3)
  String coverPath;

  @HiveField(4)
  String filePath;

  @HiveField(5)
  int totalChapters;

  @HiveField(6)
  int currentChapterIndex;

  @HiveField(7)
  int currentProgress; // 阅读进度百分比

  @HiveField(8)
  DateTime addedAt;

  @HiveField(9)
  DateTime? lastReadAt;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.coverPath,
    required this.filePath,
    required this.totalChapters,
    this.currentChapterIndex = 0,
    this.currentProgress = 0,
    required this.addedAt,
    this.lastReadAt,
  });

  /// 格式化阅读进度
  String get progressText => '$currentProgress%';

  /// 是否已读完
  bool get isFinished => currentProgress >= 100;
}
