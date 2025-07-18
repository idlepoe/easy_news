import '../entity/news.dart';
import '../repository/news_repository.dart';

class NewsListResult {
  final List<News> news;
  final int totalSize;
  final bool hasMore;
  final String? nextCursor;

  NewsListResult({
    required this.news,
    required this.totalSize,
    required this.hasMore,
    this.nextCursor,
  });
}

class GetNewsListUseCase {
  final NewsRepository repository;
  GetNewsListUseCase(this.repository);

  Future<NewsListResult> call({
    int page = 1,
    int pageSize = 10,
    String? category,
    String? cursor,
  }) => repository.getNewsList(
    page: page,
    pageSize: pageSize,
    category: category,
    cursor: cursor,
  );
}
