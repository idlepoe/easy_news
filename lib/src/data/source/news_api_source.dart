import 'package:dio/dio.dart';

class NewsApiSource {
  final Dio dio;
  NewsApiSource(this.dio);

  Future<List<Map<String, dynamic>>> fetchNewsList({
    int page = 1,
    int pageSize = 10,
    String? category,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (category != null) {
      queryParams['category'] = category;
    }

    final response = await dio.get(
      'https://getnewslistapi-z54jot6a5a-uc.a.run.app',
      queryParameters: queryParams,
    );
    final data = response.data['data']['news'] as List;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> fetchNewsDetail(String id) async {
    final response = await dio.get(
      'https://getnewsdetailapi-z54jot6a5a-uc.a.run.app/',
      queryParameters: {'docId': id},
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  // 조회수 업데이트 메서드 추가
  Future<void> updateViewCount(String id) async {
    try {
      await dio.post(
        'https://updatenewsviewcountapi-z54jot6a5a-uc.a.run.app/',
        queryParameters: {'docId': id},
      );
    } catch (e) {
      // 조회수 업데이트 실패는 무시 (사용자 경험에 영향 없음)
      print('조회수 업데이트 실패: $e');
    }
  }
}
