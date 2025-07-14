import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class LoggingInterceptor extends Interceptor {
  final Logger logger = Logger();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // logger.i('🌐 REQUEST[${options.method}] => PATH: ${options.path}');
    // logger.i('Query Parameters: ${options.queryParameters}');
    // logger.i('Headers: ${options.headers}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final duration = DateTime.now().difference(
      response.requestOptions.extra['startTime'] as DateTime,
    );
    logger.d(
      '✅ RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}\n⏱️ 걸린 시간: ${duration.inMilliseconds}ms\n📊 Response Data: ${response.data}',
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
