class Chapter {
  final String title;
  final String content;
  final int index;

  Chapter({
    required this.title,
    required this.content,
    required this.index,
  });

  /// 获取纯文本内容（去除 HTML 标签）
  String get plainText {
    return content
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// 估算阅读时长（分钟）
  int get estimatedReadTime {
    final wordCount = plainText.split(RegExp(r'\s+')).length;
    return (wordCount / 300).ceil(); // 假设每分钟 300 字
  }

  /// 估算听书时长（分钟）
  int get estimatedListenTime {
    final wordCount = plainText.split(RegExp(r'\s+')).length;
    return (wordCount / 200).ceil(); // 假设每分钟 200 字（TTS 语速）
  }
}
