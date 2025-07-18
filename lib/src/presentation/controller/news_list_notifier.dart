import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../domain/entity/news.dart';
import '../../domain/usecase/get_news_list_usecase.dart';
import 'news_controller.dart';

const _newsListCacheKey = 'news_list_cache';

class NewsListNotifier extends StateNotifier<AsyncValue<List<News>>>
    with WidgetsBindingObserver {
  final Ref ref;
  final List<News> _allNews = [];
  int _currentPage = 1;
  bool _hasMore = true;
  String? _currentCategory;
  bool _isRefreshing = false;
  String? _nextCursor; // 커서 기반 페이지네이션용

  NewsListNotifier(this.ref) : super(const AsyncValue.loading()) {
    WidgetsBinding.instance.addObserver(this);
    _loadCachedNews();
    loadInitialNews();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // 앱이 resume될 때 목록 갱신
    if (state == AppLifecycleState.resumed) {
      print('🔄 앱이 resume되어 목록을 갱신합니다.');
      refreshFromResume();
    }
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
      } catch (_) {
        // 캐시 파싱 실패 시 빈 리스트로 설정
        state = AsyncValue.data([]);
      }
    } else {
      // 캐시된 데이터가 없으면 빈 리스트로 설정
      state = AsyncValue.data([]);
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
      final result = await useCase(page: 1, pageSize: 10, category: category);
      _allNews.clear();
      _allNews.addAll(result.news);
      _currentPage = 1;
      _currentCategory = category;
      // totalSize 기반으로 hasMore 판단
      _hasMore = (1 * 10) < result.totalSize;
      _nextCursor = result.nextCursor;
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
      final result = await useCase(
        page: 1,
        pageSize: 10,
        category: _currentCategory,
      );
      _allNews.clear();
      _allNews.addAll(result.news);
      _currentPage = 1;
      // totalSize 기반으로 hasMore 판단
      _hasMore = (1 * 10) < result.totalSize;
      _nextCursor = result.nextCursor;
      _isRefreshing = false;
      state = AsyncValue.data(_allNews);
      await _saveNewsCache(_allNews);
    } catch (error, stackTrace) {
      _isRefreshing = false;
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // 앱 resume 시 백그라운드에서 갱신 (로딩 상태 표시 없음)
  Future<void> refreshFromResume() async {
    if (_isRefreshing) return;

    _isRefreshing = true;

    try {
      final useCase = ref.read(getNewsListUseCaseProvider);
      final result = await useCase(
        page: 1,
        pageSize: 10,
        category: _currentCategory,
      );

      // 새로운 데이터가 있는 경우에만 업데이트
      if (result.news.isNotEmpty) {
        final currentIds = _allNews.map((n) => n.id).toSet();
        final hasNewData = result.news.any((n) => !currentIds.contains(n.id));

        if (hasNewData) {
          _allNews.clear();
          _allNews.addAll(result.news);
          _currentPage = 1;
          _hasMore = (1 * 10) < result.totalSize;
          _nextCursor = result.nextCursor;
          state = AsyncValue.data(_allNews);
          await _saveNewsCache(_allNews);
          print('✅ 새로운 뉴스가 추가되어 목록이 갱신되었습니다.');
        } else {
          print('ℹ️ 새로운 뉴스가 없습니다.');
        }
      }

      _isRefreshing = false;
    } catch (error, stackTrace) {
      _isRefreshing = false;
      print('❌ 앱 resume 시 목록 갱신 실패: $error');
    }
  }

  Future<void> loadMoreNews() async {
    if (!_hasMore || state.isLoading) return;

    try {
      final useCase = ref.read(getNewsListUseCaseProvider);
      final nextPage = _currentPage + 1;
      final result = await useCase(
        page: nextPage,
        pageSize: 10,
        category: _currentCategory,
        cursor: _nextCursor,
      );

      if (result.news.isNotEmpty) {
        // 중복 데이터 방지를 위해 ID 기반으로 필터링
        final existingIds = _allNews.map((n) => n.id).toSet();
        final newNews = result.news
            .where((n) => !existingIds.contains(n.id))
            .toList();

        if (newNews.isNotEmpty) {
          _allNews.addAll(newNews);
          _currentPage = nextPage;
          // totalSize 기반으로 hasMore 판단
          _hasMore = (_currentPage * 10) < result.totalSize;
          _nextCursor = result.nextCursor;
          state = AsyncValue.data(_allNews);
          await _saveNewsCache(_allNews);
        } else {
          // 중복 데이터만 있는 경우에도 totalSize 기반으로 hasMore 판단
          _currentPage = nextPage;
          _hasMore = (_currentPage * 10) < result.totalSize;
          _nextCursor = result.nextCursor;
          // 상태 업데이트하여 로딩 종료
          state = AsyncValue.data(_allNews);
        }
      } else {
        _hasMore = false;
        // 상태 업데이트하여 로딩 종료
        state = AsyncValue.data(_allNews);
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
