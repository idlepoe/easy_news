import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entity/news.dart';
import '../../domain/usecase/get_news_list_usecase.dart';
import 'news_controller.dart';

class NewsListNotifier extends StateNotifier<AsyncValue<List<News>>> {
  final Ref ref;
  final List<News> _allNews = [];
  int _currentPage = 1;
  bool _hasMore = true;
  String? _currentCategory;
  bool _isRefreshing = false;

  NewsListNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadInitialNews();
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
      _hasMore = news.length == 10; // 10개면 더 있을 가능성
      state = AsyncValue.data(_allNews);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshWithStatus() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    state = AsyncValue.data(_allNews); // 현재 상태 유지하면서 갱신 상태 표시

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
