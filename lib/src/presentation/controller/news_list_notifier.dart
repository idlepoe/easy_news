import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entity/news.dart';
import '../../domain/usecase/get_news_list_usecase.dart';
import 'news_controller.dart';

class NewsListNotifier extends StateNotifier<AsyncValue<List<News>>> {
  final Ref ref;
  final List<News> _allNews = [];
  int _currentPage = 1;
  bool _hasMore = true;

  NewsListNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadInitialNews();
  }

  Future<void> loadInitialNews() async {
    state = const AsyncValue.loading();
    try {
      final useCase = ref.read(getNewsListUseCaseProvider);
      final news = await useCase(page: 1, pageSize: 10);
      _allNews.clear();
      _allNews.addAll(news);
      _currentPage = 1;
      _hasMore = news.length == 10; // 10개면 더 있을 가능성
      state = AsyncValue.data(_allNews);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadMoreNews() async {
    if (!_hasMore || state.isLoading) return;

    try {
      final useCase = ref.read(getNewsListUseCaseProvider);
      final nextPage = _currentPage + 1;
      final news = await useCase(page: nextPage, pageSize: 10);

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

  bool get hasMore => _hasMore;
  bool get isLoading => state.isLoading;
}
