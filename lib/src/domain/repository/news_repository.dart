import '../entity/news.dart';

abstract class NewsRepository {
  Future<List<News>> getNewsList({
    int page = 1,
    int pageSize = 10,
    String? category,
  });
  Future<News> getNewsDetail(String id);
  Future<void> updateViewCount(String id);
}
