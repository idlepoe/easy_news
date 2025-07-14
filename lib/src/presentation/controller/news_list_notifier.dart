import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../domain/entity/news.dart';
import '../../domain/usecase/get_news_list_usecase.dart';
import 'news_controller.dart';

const _newsListCacheKey = 'news_list_cache';

class NewsListNotifier extends StateNotifier<AsyncValue<List<News>>> {
  final Ref ref;
  final List<News> _allNews = [];
  int _currentPage = 1;
  bool _hasMore = true;
  String? _currentCategory;
  bool _isRefreshing = false;

  NewsListNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadCachedNews();
    loadInitialNews();
  }

  Future<void> _loadCachedNews() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_newsListCacheKey);
    if (jsonStr != null) {
      try {
        final List<dynamic> jsonList = json.decode(jsonStr);
        final cachedNews = jsonList.map((e) => News.fromJson(e)).toList();
        _allNews.clear();
        _allNews.addAll(cachedNews);
        state = AsyncValue.data(_allNews);
      } catch (_) {}
    }
  }

  Future<void> _saveNewsCache(List<News> newsList) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(newsList.map((e) => e.toJson()).toList());
    await prefs.setString(_newsListCacheKey, jsonStr);
  }

  Future<void> loadInitialNews({String? category}) async {
    state = const AsyncValue.loading();
    try {
      final useCase = ref.read(getNewsListUseCaseProvider);
      final news = await useCase(page: 1, pageSize: 10, category: category);
      _allNews.clear();
      _allNews.addAll(news);
      _currentPage = 1;
      _currentCategory = category;
      _hasMore = news.length == 10;
      state = AsyncValue.data(_allNews);
      await _saveNewsCache(_allNews);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshWithStatus() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    state = AsyncValue.data(_allNews);

    try {
      final useCase = ref.read(getNewsListUseCaseProvider);
      final news = await useCase(
        page: 1,
        pageSize: 10,
        category: _currentCategory,
      );
      _allNews.clear();
      _allNews.addAll(news);
      _currentPage = 1;
      _hasMore = news.length == 10;
      _isRefreshing = false;
      state = AsyncValue.data(_allNews);
      await _saveNewsCache(_allNews);
    } catch (error, stackTrace) {
      _isRefreshing = false;
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadMoreNews() async {
    if (!_hasMore || state.isLoading) return;

    try {
      final useCase = ref.read(getNewsListUseCaseProvider);
      final nextPage = _currentPage + 1;
      final news = await useCase(
        page: nextPage,
        pageSize: 10,
        category: _currentCategory,
      );

      if (news.isNotEmpty) {
        _allNews.addAll(news);
        _currentPage = nextPage;
        _hasMore = news.length == 10;
        state = AsyncValue.data(_allNews);
        await _saveNewsCache(_allNews);
      } else {
        _hasMore = false;
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadInitialNews();
  }

  // 조회수 낙관적 업데이트
  void updateViewCountOptimistically(String newsId) {
    final currentNews = state.value;
    if (currentNews == null) return;

    final updatedNews = currentNews.map((news) {
      if (news.id == newsId) {
        return news.copyWith(viewCount: (news.viewCount ?? 0) + 1);
      }
      return news;
    }).toList();

    state = AsyncValue.data(updatedNews);
  }

  bool get hasMore => _hasMore;
  bool get isLoading => state.isLoading;
  bool get isRefreshing => _isRefreshing;
}
