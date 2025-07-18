import '../../domain/entity/news.dart';
import '../../domain/entity/news_entity.dart';
import '../../domain/repository/news_repository.dart';
import '../../domain/usecase/get_news_list_usecase.dart';
import '../source/news_api_source.dart';
import '../services/local_cache_service.dart';

class NewsRepositoryImpl implements NewsRepository {
  final NewsApiSource apiSource;
  final LocalCacheService cacheService;

  NewsRepositoryImpl(this.apiSource) : cacheService = LocalCacheService();

  @override
  Future<NewsListResult> getNewsList({
    int page = 1,
    int pageSize = 10,
    String? category,
    String? cursor,
  }) async {
    // 첫 페이지인 경우에만 캐시 확인
    if (page == 1) {
      final cachedNews = await cacheService.getCachedNewsList(
        category ?? 'all',
      );
      if (cachedNews != null && cachedNews.isNotEmpty) {
        // 캐시된 데이터가 있으면 먼저 반환하고 백그라운드에서 갱신
        _refreshNewsListInBackground(category);
        return NewsListResult(
          news: cachedNews,
          totalSize: 100, // 캐시된 데이터는 충분히 큰 값으로 설정하여 다음 페이지 로드 가능하게 함
          hasMore: true,
          nextCursor: null,
        );
      }
    }

    // 캐시가 없거나 첫 페이지가 아닌 경우 API 호출
    final response = await apiSource.fetchNewsList(
      page: page,
      pageSize: pageSize,
      category: category,
      cursor: cursor,
    );

    final list = response['news'] as List;
    final newsList = list.map((e) {
      final viewCount = e['viewCount'] ?? 0;
      print('📊 뉴스 매핑 - ID: ${e['id']}, viewCount: $viewCount');
      return News(
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
        viewCount: viewCount,
      );
    }).toList();

    // 첫 페이지인 경우 캐시에 저장
    if (page == 1) {
      await cacheService.cacheNewsList(newsList, category ?? 'all');
    }

    return NewsListResult(
      news: newsList,
      totalSize: response['totalSize'],
      hasMore: response['hasMore'] ?? false,
      nextCursor: response['nextCursor'],
    );
  }

  // 백그라운드에서 뉴스 목록 갱신
  Future<void> _refreshNewsListInBackground(String? category) async {
    try {
      final response = await apiSource.fetchNewsList(
        page: 1,
        pageSize: 10,
        category: category,
      );
      final list = response['news'] as List;
      final newsList = list
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
              viewCount: e['viewCount'] ?? 0,
            ),
          )
          .toList();

      await cacheService.cacheNewsList(newsList, category ?? 'all');
    } catch (e) {
      // 백그라운드 갱신 실패는 무시
    }
  }

  @override
  Future<News> getNewsDetail(String id) async {
    // 캐시된 상세 데이터 확인
    final cachedNews = await cacheService.getCachedNewsDetail(id);
    if (cachedNews != null) {
      // 캐시된 데이터가 있으면 먼저 반환하고 백그라운드에서 갱신
      _refreshNewsDetailInBackground(id);
      return cachedNews;
    }

    // 캐시가 없는 경우 API 호출
    final e = await apiSource.fetchNewsDetail(id);
    final news = News(
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
      viewCount: e['viewCount'] ?? 0,
    );

    // 캐시에 저장
    await cacheService.cacheNewsDetail(news);

    return news;
  }

  // 백그라운드에서 뉴스 상세 갱신
  Future<void> _refreshNewsDetailInBackground(String id) async {
    try {
      final e = await apiSource.fetchNewsDetail(id);
      final news = News(
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
        viewCount: e['viewCount'] ?? 0,
      );

      await cacheService.cacheNewsDetail(news);
    } catch (e) {
      // 백그라운드 갱신 실패는 무시
    }
  }

  @override
  Future<void> updateViewCount(String id) async {
    await apiSource.updateViewCount(id);
  }
}
