import '../entity/news.dart';
import '../usecase/get_news_list_usecase.dart';

abstract class NewsRepository {
  Future<NewsListResult> getNewsList({
    int page = 1,
    int pageSize = 10,
    String? category,
    String? cursor,
  });
  Future<News> getNewsDetail(String id);
  Future<void> updateViewCount(String id);
}
