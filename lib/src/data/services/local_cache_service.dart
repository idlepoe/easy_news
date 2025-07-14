import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entity/news.dart';

class LocalCacheService {
  static const String _newsListKey = 'cached_news_list';
  static const String _newsDetailPrefix = 'cached_news_detail_';
  static const String _lastUpdateKey = 'last_update_time';
  static const String _politicsNewsListKey = 'cached_politics_news_list';
  static const String _allNewsListKey = 'cached_all_news_list';

  // 뉴스 목록 캐싱 (전체)
  Future<void> cacheNewsList(List<News> newsList, String category) async {
    final prefs = await SharedPreferences.getInstance();
    final key = category == 'politics' ? _politicsNewsListKey : _allNewsListKey;
    final jsonList = newsList.map((news) => news.toJson()).toList();
    await prefs.setString(key, jsonEncode(jsonList));
    await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
  }

  // 뉴스 목록 조회 (전체)
  Future<List<News>?> getCachedNewsList(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final key = category == 'politics' ? _politicsNewsListKey : _allNewsListKey;
    final jsonString = prefs.getString(key);

    if (jsonString == null) return null;

    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => News.fromJson(json)).toList();
    } catch (e) {
      return null;
    }
  }

  // 뉴스 상세 캐싱
  Future<void> cacheNewsDetail(News news) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_newsDetailPrefix${news.id}';
    await prefs.setString(key, jsonEncode(news.toJson()));
  }

  // 뉴스 상세 조회
  Future<News?> getCachedNewsDetail(String newsId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_newsDetailPrefix$newsId';
    final jsonString = prefs.getString(key);

    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString);
      return News.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  // 마지막 업데이트 시간 조회
  Future<DateTime?> getLastUpdateTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString(_lastUpdateKey);
    if (timeString == null) return null;

    try {
      return DateTime.parse(timeString);
    } catch (e) {
      return null;
    }
  }

  // 캐시 삭제
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_newsListKey);
    await prefs.remove(_politicsNewsListKey);
    await prefs.remove(_allNewsListKey);
    await prefs.remove(_lastUpdateKey);

    // 모든 상세 캐시 삭제
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_newsDetailPrefix)) {
        await prefs.remove(key);
      }
    }
  }

  // 특정 뉴스 상세 캐시 삭제
  Future<void> clearNewsDetailCache(String newsId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_newsDetailPrefix$newsId';
    await prefs.remove(key);
  }
}
