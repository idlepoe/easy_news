import 'package:flutter/material.dart';
import '../../data/constants/app_colors.dart';

class NewsInfoBadge extends StatelessWidget {
  final String category;
  final int? viewCount;

  const NewsInfoBadge({super.key, required this.category, this.viewCount});

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 카테고리 배지
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getCategoryColor(category).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getCategoryColor(category).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            category,
            style: TextStyle(
              color: _getCategoryColor(category),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 조회수
        if (viewCount != null)
          Row(
            children: [
              Icon(
                Icons.visibility_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                _formatViewCount(viewCount!),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
      ],
    );
  }

  String _formatViewCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}만';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}천';
    } else {
      return count.toString();
    }
  }
}
