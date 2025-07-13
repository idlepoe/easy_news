import '../entity/news.dart';
import '../repository/news_repository.dart';

class GetNewsDetailUseCase {
  final NewsRepository repository;
  GetNewsDetailUseCase(this.repository);

  Future<News> call(String id) => repository.getNewsDetail(id);
}
