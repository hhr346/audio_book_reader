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
  int currentProgress; // 阅读进度百分比（按总页数计算）

  @HiveField(8)
  DateTime addedAt;

  @HiveField(9)
  DateTime? lastReadAt;

  @HiveField(10)
  int totalPages; // 全书总页数（用于进度计算）

  @HiveField(11)
  int currentPageIndex; // 当前页索引（在章节内的位置）

  @HiveField(12)
  int cumulativePagesRead; // 累计已读页数（用于全书进度）

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
    this.totalPages = 0,
    this.currentPageIndex = 0,
    this.cumulativePagesRead = 0,
  });

  /// 格式化阅读进度
  String get progressText => '$currentProgress%';

  /// 是否已读完
  bool get isFinished => currentProgress >= 100;

  /// 详细进度信息（用于显示）
  String get detailedProgressText {
    if (totalPages > 0) {
      return '第$cumulativePagesRead/$totalPages 页 ($currentProgress%)';
    }
    return '第$currentChapterIndex+1/${totalChapters}章 ($currentProgress%)';
  }
}
