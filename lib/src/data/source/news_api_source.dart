import 'package:dio/dio.dart';

class NewsApiSource {
  final Dio dio;
  NewsApiSource(this.dio);

  Future<List<Map<String, dynamic>>> fetchNewsList({int page = 1, int pageSize = 10}) async {
    final response = await dio.get(
      'https://getnewslistapi-z54jot6a5a-uc.a.run.app',
      queryParameters: {'page': page, 'pageSize': pageSize},
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
}
