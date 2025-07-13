import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../controller/news_controller.dart';
import '../../domain/entity/news.dart';
import 'news_detail_page.dart';

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
        return Colors.blue;
      case 'ORGANIZATION':
        return Colors.green;
      case 'LOCATION':
        return Colors.orange;
      case 'COMPANY':
        return Colors.purple;
      case 'COUNTRY':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildHighlightedText(String text, List<NewsEntity> entities) {
    if (entities.isEmpty) {
      return Text(
        text,
        style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.4),
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
              color: Colors.grey[600],
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
          style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.4),
        ),
      );
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsListAsync = ref.watch(allNewsListProvider);
    final newsListNotifier = ref.read(allNewsListProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Easy News'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: RefreshIndicator(
        onRefresh: () => newsListNotifier.refresh(),
        child: newsListAsync.when(
          data: (newsList) => NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels ==
                  scrollInfo.metrics.maxScrollExtent) {
                if (newsListNotifier.hasMore && !newsListNotifier.isLoading) {
                  newsListNotifier.loadMoreNews();
                }
              }
              return false;
            },
            child: ListView.builder(
              itemCount: newsList.length + (newsListNotifier.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                // 로딩 인디케이터
                if (index == newsList.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final news = newsList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  elevation: 4,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NewsDetailPage(newsId: news.id),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 이미지 섹션
                        if (news.mediaUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.network(
                                news.mediaUrl,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: double.infinity,
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.image,
                                      color: Colors.grey,
                                      size: 48,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                        // 콘텐츠 섹션
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 제목
                              Text(
                                news.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  height: 1.3,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const SizedBox(height: 12),

                              // 요약 (있는 경우) - entities 하이라이트 적용
                              if (news.summary != null &&
                                  news.summary!.isNotEmpty)
                                _buildHighlightedText(
                                  news.summary!,
                                  news.entities ?? [],
                                ),

                              const SizedBox(height: 12),

                              // 날짜/시간
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatKoreanDateTime(news.pubDate),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  const Spacer(),
                                  // 카테고리 (있는 경우)
                                  if (news.category.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        news.category,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('에러가 발생했습니다: $e'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => newsListNotifier.refresh(),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
