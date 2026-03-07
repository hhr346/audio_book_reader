import 'package:flutter/material.dart';

/// 搜索防抖工具类
class SearchDebounce {
  Timer? _timer;
  final Duration delay;
  final Function(String query) onSearch;

  SearchDebounce({this.delay = const Duration(milliseconds: 500), required this.onSearch});

  void query(String text) {
    _timer?.cancel();
    _timer = Timer(delay, () => onSearch(text));
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// 搜索结果缓存
class SearchCache {
  final Map<String, List<dynamic>> _cache = {};
  final int maxCacheSize = 100;

  List<dynamic>? get(String key) => _cache[key];

  void put(String key, List<dynamic> value) {
    if (_cache.length >= maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
  }

  void clear() => _cache.clear();

  bool containsKey(String key) => _cache.containsKey(key);
}

/// 搜索优化服务
class SearchOptimizationService {
  static final SearchOptimizationService _instance = SearchOptimizationService._internal();
  factory SearchOptimizationService() => _instance;
  SearchOptimizationService._internal();

  final SearchCache _cache = SearchCache();

  /// 防抖搜索
  SearchDebounce createDebounce(Function(String) onSearch) {
    return SearchDebounce(onSearch: onSearch);
  }

  /// 带缓存的搜索
  Future<List<T>> searchWithCache<T>({
    required String query,
    required Future<List<T>> Function() searchFunc,
    Duration cacheDuration = const Duration(minutes: 5),
  }) async {
    // 检查缓存
    final cached = _cache.get(query);
    if (cached != null) {
      return List<T>.from(cached);
    }

    // 执行搜索
    final results = await searchFunc();
    
    // 缓存结果
    _cache.put(query, results);
    
    return results;
  }

  /// 清除缓存
  void clearCache() => _cache.clear();

  /// 获取缓存大小
  int get cacheSize => _cache._cache.length;
}
