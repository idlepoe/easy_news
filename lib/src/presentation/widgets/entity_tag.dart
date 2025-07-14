import 'package:flutter/material.dart';
import '../../domain/entity/news_entity.dart';
import '../../data/constants/app_colors.dart';

class EntityTag extends StatelessWidget {
  final NewsEntity entity;
  final Color color;
  final VoidCallback? onTap;

  const EntityTag({
    super.key,
    required this.entity,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Text(
          entity.text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
