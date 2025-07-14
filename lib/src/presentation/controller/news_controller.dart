import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/source/news_api_source.dart';
import '../../data/source/dio_interceptor.dart';
import '../../data/source/request_timing_interceptor.dart';
import '../../data/repository/news_repository_impl.dart';
import '../../domain/usecase/get_news_list_usecase.dart';
import '../../domain/usecase/get_news_detail_usecase.dart';
import '../../domain/entity/news.dart';
import 'package:dio/dio.dart';
import 'news_list_notifier.dart';

// Provider for Dio
final dioProvider = Provider((ref) {
  final dio = Dio();
  dio.interceptors.addAll([RequestTimingInterceptor(), LoggingInterceptor()]);
  return dio;
});

// Provider for NewsApiSource
final newsApiSourceProvider = Provider(
  (ref) => NewsApiSource(ref.watch(dioProvider)),
);

// Provider for NewsRepository
final newsRepositoryProvider = Provider(
  (ref) => NewsRepositoryImpl(ref.watch(newsApiSourceProvider)),
);

// Provider for GetNewsListUseCase
final getNewsListUseCaseProvider = Provider(
  (ref) => GetNewsListUseCase(ref.watch(newsRepositoryProvider)),
);

// Provider for GetNewsDetailUseCase
final getNewsDetailUseCaseProvider = Provider(
  (ref) => GetNewsDetailUseCase(ref.watch(newsRepositoryProvider)),
);

// 뉴스 목록 상태 (페이지네이션)
final newsListProvider = FutureProvider.family<List<News>, int>((
  ref,
  page,
) async {
  return ref.watch(getNewsListUseCaseProvider)(page: page, pageSize: 10);
});

// 현재 페이지 상태
final currentPageProvider = StateProvider<int>((ref) => 1);

// 뉴스 목록 상태 (모든 페이지 누적)
final allNewsListProvider =
    StateNotifierProvider<NewsListNotifier, AsyncValue<List<News>>>((ref) {
      return NewsListNotifier(ref);
    });

// 뉴스 상세 상태
final newsDetailProvider = FutureProvider.family<News, String>((ref, id) async {
  final useCase = ref.watch(getNewsDetailUseCaseProvider);
  return useCase(id);
});

// 조회수 업데이트 프로바이더
final updateViewCountProvider = FutureProvider.family<void, String>((
  ref,
  id,
) async {
  final repository = ref.watch(newsRepositoryProvider);
  return repository.updateViewCount(id);
});
