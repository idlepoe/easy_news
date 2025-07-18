import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class LoggingInterceptor extends Interceptor {
  final Logger logger = Logger();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.queryParameters.isNotEmpty) {
      logger.d(
        '🌐 REQUEST[${options.method}] => PATH: ${options.path}\n Query Parameters:\n${options.queryParameters.entries.map((e) => '  ${e.key}: ${e.value}').join('\n')}',
      );
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final duration = DateTime.now().difference(
      response.requestOptions.extra['startTime'] as DateTime,
    );

    // 뉴스 데이터인 경우 타이틀만 추출
    String responseData = '';
    if (response.data != null &&
        response.data['data'] != null &&
        response.data['data']['news'] != null) {
      final newsList = response.data['data']['news'] as List;
      if (newsList.isNotEmpty) {
        final titles = newsList
            .map((news) => news['title'] ?? '제목 없음')
            .toList();
        responseData =
            '뉴스 타이틀: ${titles.join(', ')}${newsList.length > 3 ? '...' : ''}';
      }
    } else {
      responseData = '${response.data}';
    }

    logger.d(
      '✅ RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}\n⏱️ 걸린 시간: ${duration.inMilliseconds}ms\n📊 Response Data: $responseData',
    );
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final duration = DateTime.now().difference(
      err.requestOptions.extra['startTime'] as DateTime,
    );
    logger.e(
      '❌ ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}\n⏱️ 걸린 시간: ${duration.inMilliseconds}ms\n🔍 Error Message: ${err.message}\n📊 Error Response: ${err.response?.data}',
    );
    super.onError(err, handler);
  }
}
