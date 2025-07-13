import '../entity/news.dart';

abstract class NewsRepository {
  Future<List<News>> getNewsList({int page = 1, int pageSize = 10});
  Future<News> getNewsDetail(String id);
}
