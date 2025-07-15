import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../controller/news_controller.dart';
import '../controller/news_list_notifier.dart';
import '../../domain/entity/news.dart';
import '../../domain/entity/news_entity.dart';
import '../../data/constants/app_colors.dart';
import 'news_detail_page.dart';
import '../widgets/news_card.dart';
import '../widgets/rounded_circular_progress.dart';
import '../widgets/font_size_menu.dart';
import '../widgets/refresh_status_card.dart';
import '../controller/font_size_provider.dart';
import '../page/settings_screen.dart'; // Added import for SettingsScreen
import '../controller/theme_mode_provider.dart'; // Added import for ThemeModeProvider

class NewsListPage extends ConsumerWidget {
  const NewsListPage({super.key});

  String _formatKoreanDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return DateFormat('M월 d일 H시 m분', 'ko_KR').format(dateTime);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  Color _getEntityColor(String type) {
    switch (type) {
      case 'PERSON':
        return AppColors.entityPerson;
      case 'ORGANIZATION':
        return AppColors.entityOrganization;
      case 'LOCATION':
        return AppColors.entityLocation;
      case 'COMPANY':
        return AppColors.entityCompany;
      case 'COUNTRY':
        return AppColors.entityCountry;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildHighlightedText(String text, List<NewsEntity> entities) {
    if (entities.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          height: 1.4,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      );
    }

    // entities를 텍스트 위치 순으로 정렬
    final sortedEntities = List<NewsEntity>.from(entities);
    sortedEntities.sort((a, b) {
      final aIndex = text.toLowerCase().indexOf(a.text.toLowerCase());
      final bIndex = text.toLowerCase().indexOf(b.text.toLowerCase());
      return aIndex.compareTo(bIndex);
    });

    final List<TextSpan> spans = [];
    int currentIndex = 0;

    for (final entity in sortedEntities) {
      final entityText = entity.text;
      final entityIndex = text.toLowerCase().indexOf(
        entityText.toLowerCase(),
        currentIndex,
      );

      if (entityIndex == -1) continue; // 텍스트에서 찾을 수 없는 경우

      // entity 이전 텍스트 추가
      if (entityIndex > currentIndex) {
        spans.add(
          TextSpan(
            text: text.substring(currentIndex, entityIndex),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        );
      }

      // entity 텍스트 추가 (색상 적용)
      spans.add(
        TextSpan(
          text: text.substring(entityIndex, entityIndex + entityText.length),
          style: TextStyle(
            fontSize: 14,
            color: _getEntityColor(entity.type),
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
      );

      currentIndex = entityIndex + entityText.length;
    }

    // 남은 텍스트 추가
    if (currentIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(currentIndex),
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      );
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildNewsTab(
    AsyncValue<List<News>> newsListAsync,
    NewsListNotifier newsListNotifier,
    double fontSize,
    NewsBodyDisplayType bodyType,
  ) {
    return RefreshIndicator(
      onRefresh: () => newsListNotifier.refreshWithStatus(),
      color: AppColors.primary,
      backgroundColor: AppColors.white,
      child: newsListAsync.when(
        data: (newsList) => Column(
          children: [
            // 갱신 상태 카드 표시
            if (newsListNotifier.isRefreshing)
              RefreshStatusCard(message: '데이터를 갱신하고 있습니다...', onDismiss: () {}),
            // 뉴스 목록
            Expanded(
              child: newsList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.article_outlined,
                            size: 64,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '뉴스가 없습니다',
                            style: TextStyle(
                              fontSize: fontSize,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification scrollInfo) {
                        if (scrollInfo.metrics.pixels ==
                            scrollInfo.metrics.maxScrollExtent) {
                          if (newsListNotifier.hasMore &&
                              !newsListNotifier.isLoading) {
                            newsListNotifier.loadMoreNews();
                          }
                        }
                        return false;
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount:
                            newsList.length +
                            (newsListNotifier.hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == newsList.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: RoundedCircularProgress()),
                            );
                          }
                          final news = newsList[index];
                          Widget? subtitle;
                          switch (bodyType) {
                            case NewsBodyDisplayType.description:
                              subtitle = Text(
                                news.description,
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: fontSize),
                              );
                              break;
                            case NewsBodyDisplayType.summary:
                              final summary = (news.summary ?? '').trim();
                              if (summary.isEmpty) {
                                subtitle = Text(
                                  news.description,
                                  maxLines: 5,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: fontSize),
                                );
                              } else {
                                subtitle = Text(
                                  summary,
                                  maxLines: 5,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: fontSize),
                                );
                              }
                              break;
                            case NewsBodyDisplayType.summary3lines:
                              subtitle = Text(
                                (news.summary3lines ?? '').trim(),
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: fontSize),
                              );
                              break;
                            case NewsBodyDisplayType.easySummary:
                              subtitle = Text(
                                (news.easySummary ?? '').trim(),
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: fontSize),
                              );
                              break;
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: NewsCard(
                              news: news,
                              subtitle: subtitle,
                              onTap: () {
                                context.push('/news/${news.id}', extra: news);
                              },
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
        loading: () => const Center(child: RoundedCircularProgress()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                '에러가 발생했습니다: $e',
                style: TextStyle(
                  fontSize: fontSize,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => newsListNotifier.refresh(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = ref.watch(fontSizeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final bodyType = ref.watch(newsBodyDisplayProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Easy News',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).textTheme.titleLarge?.color,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push('/settings');
            },
          ),
        ],
      ),
      body: _buildNewsTab(
        ref.watch(allNewsListProvider),
        ref.read(allNewsListProvider.notifier),
        fontSize,
        bodyType,
      ),
    );
  }
}
