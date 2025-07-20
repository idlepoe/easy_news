import 'package:dio/dio.dart';

class NewsApiSource {
  final Dio dio;
  NewsApiSource(this.dio);

  Future<Map<String, dynamic>> fetchNewsList({
    int page = 1,
    int pageSize = 10,
    String? category,
    String? cursor,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (category != null) {
      queryParams['category'] = category;
    }
    if (cursor != null) {
      queryParams['cursor'] = cursor;
    }

    final response = await dio.get(
      'https://getnewslistapi-z54jot6a5a-uc.a.run.app',
      queryParameters: queryParams,
    );
    final data = response.data['data'];
    return {
      'news': data['news'] as List,
      'totalSize': data['totalSize'],
      'hasMore': data['hasMore'],
      'nextCursor': data['nextCursor'],
    };
  }

  Future<Map<String, dynamic>> fetchNewsDetail(String id) async {
    final response = await dio.get(
      'https://getnewsdetailapi-z54jot6a5a-uc.a.run.app/',
      queryParameters: {'docId': id},
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  // 인기뉴스 조회 메서드 추가
  Future<Map<String, dynamic>> fetchPopularNews({
    int limit = 10,
    String period = 'all',
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'period': period,
    };

    final response = await dio.get(
      'https://getpopularnewsapi-z54jot6a5a-uc.a.run.app/',
      queryParameters: queryParams,
    );
    return response.data['data'] as Map<String, dynamic>;
  }
}
