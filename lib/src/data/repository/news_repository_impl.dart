import '../../domain/entity/news.dart';
import '../../domain/repository/news_repository.dart';
import '../source/news_api_source.dart';

class NewsRepositoryImpl implements NewsRepository {
  final NewsApiSource apiSource;
  NewsRepositoryImpl(this.apiSource);

  @override
  Future<List<News>> getNewsList({int page = 1, int pageSize = 10}) async {
    final list = await apiSource.fetchNewsList(page: page, pageSize: pageSize);
    return list
        .map(
          (e) => News(
            id: e['id'] ?? '',
            title: e['title'] ?? '',
            description: e['description'] ?? '',
            link: e['link'] ?? '',
            mediaUrl: e['mediaUrl'] ?? '',
            category: e['category'] ?? '',
            pubDate: e['pubDate'] != null
                ? DateTime.fromMillisecondsSinceEpoch(
                    e['pubDate']['_seconds'] * 1000,
                  )
                : DateTime.now(),
            summary: e['summary'],
            summary3lines: e['summary3lines'],
            easySummary: e['easySummary'],
            entities: e['entities'] != null
                ? (e['entities'] as List)
                      .map(
                        (entity) => NewsEntity(
                          text: entity['text'] ?? '',
                          type: entity['type'] ?? '',
                          description: entity['description'] ?? '',
                        ),
                      )
                      .toList()
                : null,
          ),
        )
        .toList();
  }

  @override
  Future<News> getNewsDetail(String id) async {
    final e = await apiSource.fetchNewsDetail(id);
    return News(
      id: e['id'] ?? '',
      title: e['title'] ?? '',
      description: e['description'] ?? '',
      link: e['link'] ?? '',
      mediaUrl: e['mediaUrl'] ?? '',
      category: e['category'] ?? '',
      pubDate: e['pubDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(e['pubDate']['_seconds'] * 1000)
          : DateTime.now(),
      summary: e['summary'],
      summary3lines: e['summary3lines'],
      easySummary: e['easySummary'],
      entities: e['entities'] != null
          ? (e['entities'] as List)
                .map(
                  (entity) => NewsEntity(
                    text: entity['text'] ?? '',
                    type: entity['type'] ?? '',
                    description: entity['description'] ?? '',
                  ),
                )
                .toList()
          : null,
    );
  }
}
