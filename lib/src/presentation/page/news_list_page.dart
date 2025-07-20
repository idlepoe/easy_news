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
import '../controller/news_controller.dart'; // Added import for popularNewsProvider
import 'package:marquee/marquee.dart';

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

  Widget _buildPopularNewsSection(BuildContext context, double fontSize) {
    return Consumer(
      builder: (context, ref, child) {
        final popularNewsAsync = ref.watch(popularNewsProvider);

        return popularNewsAsync.when(
          data: (popularNews) {
            if (popularNews.isEmpty) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.fromLTRB(0, 0, 0, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 섹션 헤더
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '이번 주 인기뉴스',
                        style: TextStyle(
                          fontSize: fontSize + 1,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'TOP 10',
                        style: TextStyle(
                          fontSize: fontSize - 2,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 인기뉴스 그리드
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 4.0,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 6,
                        ),
                    itemCount: popularNews.length,
                    itemBuilder: (context, index) {
                      final news = popularNews[index];
                      return _buildPopularNewsCard(
                        context,
                        news,
                        index + 1,
                        fontSize,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
          loading: () => Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '이번 주 인기뉴스',
                      style: TextStyle(
                        fontSize: fontSize + 2,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Center(child: RoundedCircularProgress()),
                const SizedBox(height: 24),
              ],
            ),
          ),
          error: (error, stack) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildPopularNewsCard(
    BuildContext context,
    News news,
    int rank,
    double fontSize,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        return GestureDetector(
          onTap: () {
            // 상세 화면으로 이동
            context.push('/news/${news.id}', extra: news);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // 순위 표시
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: rank <= 3 ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          fontSize: fontSize - 3,
                          fontWeight: FontWeight.w700,
                          color: rank <= 3
                              ? AppColors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 뉴스 제목 (Marquee)
                  Expanded(
                    child: Marquee(
                      text: news.title,
                      style: TextStyle(
                        fontSize: fontSize - 1,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.titleMedium?.color,
                        height: 1.2,
                      ),
                      scrollAxis: Axis.horizontal,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      blankSpace: 20.0,
                      velocity: 30.0,
                      pauseAfterRound: const Duration(seconds: 1),
                      startPadding: 10.0,
                      accelerationDuration: const Duration(seconds: 1),
                      accelerationCurve: Curves.linear,
                      decelerationDuration: const Duration(milliseconds: 500),
                      decelerationCurve: Curves.easeOut,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNewsTab(
    BuildContext context,
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
        data: (newsList) => newsList.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RoundedCircularProgress(),
                    const SizedBox(height: 24),
                    Text(
                      '최신 뉴스 목록을 가져오고 있습니다.\n곧 새로운 소식을 전해드릴게요.',
                      style: TextStyle(
                        fontSize: fontSize,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
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
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 갱신 상태 카드 표시
                    if (newsListNotifier.isRefreshing)
                      RefreshStatusCard(
                        message: '데이터를 갱신하고 있습니다...',
                        onDismiss: () {},
                      ),
                    // 인기뉴스 섹션
                    _buildPopularNewsSection(context, fontSize),
                    // 뉴스 목록
                    ...newsList.map((news) {
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
                          subtitle = Text(
                            news.summary!,
                            style: TextStyle(fontSize: fontSize),
                          );
                          break;
                        case NewsBodyDisplayType.summary3lines:
                          subtitle = Text(
                            (news.summary3lines ?? '').trim(),
                            style: TextStyle(fontSize: fontSize),
                          );
                          break;
                        case NewsBodyDisplayType.easySummary:
                          subtitle = Text(
                            (news.easySummary ?? '').trim(),
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
                    }).toList(),
                    // 로딩 인디케이터
                    if (newsListNotifier.hasMore)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: RoundedCircularProgress()),
                      ),
                  ],
                ),
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
          '뉴스 한입',
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
        context,
        ref.watch(allNewsListProvider),
        ref.read(allNewsListProvider.notifier),
        fontSize,
        bodyType,
      ),
    );
  }
}
