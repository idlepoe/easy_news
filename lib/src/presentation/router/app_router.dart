import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../page/news_list_page.dart';
import '../page/news_detail_page.dart';
import '../page/settings_screen.dart';
import '../services/notification_service.dart';
import '../../domain/entity/news.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    navigatorKey: NotificationService.navigatorKey,
    routes: [
      GoRoute(
        path: '/',
        name: 'news_list',
        builder: (context, state) => const NewsListPage(),
      ),
      GoRoute(
        path: '/news/:newsId',
        name: 'news_detail',
        builder: (context, state) {
          final newsId = state.pathParameters['newsId']!;
          final initialNews = state.extra as News?;
          return NewsDetailPage(newsId: newsId, initialNews: initialNews);
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '페이지를 찾을 수 없습니다',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '경로: ${state.uri}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('홈으로 돌아가기'),
            ),
          ],
        ),
      ),
    ),
  );
}
