import '../entity/news.dart';
import '../repository/news_repository.dart';

class GetNewsListUseCase {
  final NewsRepository repository;
  GetNewsListUseCase(this.repository);

  Future<List<News>> call({
    int page = 1,
    int pageSize = 10,
    String? category,
  }) => repository.getNewsList(
    page: page,
    pageSize: pageSize,
    category: category,
  );
}
