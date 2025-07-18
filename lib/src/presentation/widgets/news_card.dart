import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entity/news.dart';
import '../../data/constants/app_colors.dart';
import 'news_info_badge.dart';
import 'rounded_circular_progress.dart';

class NewsCard extends StatelessWidget {
  final News news;
  final VoidCallback? onTap;
  final Widget? subtitle;

  const NewsCard({super.key, required this.news, this.onTap, this.subtitle});

  String _formatDate(DateTime date) {
    return '${date.month}월 ${date.day}일 ${date.hour}시 ${date.minute}분';
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case '정치':
        return AppColors.entityPerson;
      case '경제':
        return AppColors.entityCompany;
      case '사회':
        return AppColors.entityOrganization;
      case '국제':
        return AppColors.entityLocation;
      case '문화':
        return AppColors.entityCountry;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatViewCount(int count) {
    if (count >= 10000) {
      final formatted = '${(count / 10000).toStringAsFixed(1)}만';
      return formatted;
    } else if (count >= 1000) {
      final formatted = '${(count / 1000).toStringAsFixed(1)}천';
      return formatted;
    } else {
      return count.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (news.mediaUrl.isNotEmpty)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: CachedNetworkImage(
                        imageUrl: news.mediaUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: double.infinity,
                          color: Theme.of(context).cardColor,
                          child: const Center(child: RoundedCircularProgress()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: double.infinity,
                          color: Theme.of(context).cardColor,
                          child: Icon(
                            Icons.image_outlined,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 카테고리 배지 (이미지 왼쪽 상단)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(
                          news.category,
                        ).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.overlay.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        news.category,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단: 제목
                  Text(
                    news.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // 중간: 요약
                  if (subtitle != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [subtitle!],
                    ),
                  const SizedBox(height: 12),
                  // 하단: 조회수와 날짜
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 왼쪽: 조회수
                      Row(
                        children: [
                          Icon(
                            Icons.visibility_outlined,
                            size: 14,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 4),
                          Builder(
                            builder: (context) {
                              final viewCount = news.viewCount ?? 0;
                              final formattedViewCount = _formatViewCount(
                                viewCount,
                              );
                              return Text(
                                formattedViewCount,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      // 오른쪽: 날짜
                      Text(
                        _formatDate(news.pubDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontWeight: FontWeight.w400,
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
  }
}
