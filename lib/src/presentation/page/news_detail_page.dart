import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../controller/news_controller.dart';
import '../../domain/entity/news.dart';

class NewsDetailPage extends ConsumerWidget {
  final String newsId;

  const NewsDetailPage({super.key, required this.newsId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsDetailProvider(newsId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('뉴스 상세'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: newsAsync.when(
        data: (news) {
          // 뉴스 모델의 모든 내용을 로그로 출력
          final logger = Logger();
          logger.i('📰 뉴스 상세 데이터 로드 완료');
          logger.i('ID: ${news.id}');
          logger.i('제목: ${news.title}');
          logger.i('카테고리: ${news.category}');
          logger.i('발행일: ${news.pubDate}');
          logger.i('설명: ${news.description}');
          logger.i('요약: ${news.summary}');
          logger.i('3줄 요약: ${news.summary3lines}');
          logger.i('쉬운 요약: ${news.easySummary}');
          logger.i('링크: ${news.link}');
          logger.i('미디어 URL: ${news.mediaUrl}');
          if (news.entities != null) {
            logger.i('엔터티 개수: ${news.entities!.length}');
            for (int i = 0; i < news.entities!.length; i++) {
              final entity = news.entities![i];
              logger.i(
                '  엔터티 ${i + 1}: ${entity.text} (${entity.type}) - ${entity.description}',
              );
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (news.mediaUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      news.mediaUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 200,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image,
                            size: 64,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  news.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  news.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),

                // 3가지 요약 표시
                if (news.summary != null && news.summary!.isNotEmpty) ...[
                  _buildSummarySection('📝 일반 요약', news.summary!),
                  const SizedBox(height: 16),
                ],

                if (news.summary3lines != null &&
                    news.summary3lines!.isNotEmpty) ...[
                  _buildSummarySection('📋 3줄 요약', news.summary3lines!),
                  const SizedBox(height: 16),
                ],

                if (news.easySummary != null &&
                    news.easySummary!.isNotEmpty) ...[
                  _buildSummarySection('🎯 쉬운 요약', news.easySummary!),
                  const SizedBox(height: 16),
                ],

                // 엔터티 정보 표시
                if (news.entities != null && news.entities!.isNotEmpty) ...[
                  _buildEntitiesSection(news.entities!),
                  const SizedBox(height: 16),
                ],
                if (news.link.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: 원본 링크로 이동 구현
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('원본 기사 링크: ${news.link}')),
                        );
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('원본 기사 보기'),
                    ),
                  ),
              ],
            ),
          );
        },
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
                onPressed: () => ref.refresh(newsDetailProvider(newsId)),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection(String title, String content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(content, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildEntitiesSection(List<NewsEntity> entities) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🏷️ 주요 인물/기관/장소',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            ...entities.map(
              (entity) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getEntityColor(entity.type),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        entity.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entity.description,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
}
