import 'package:flutter/material.dart';
import '../../data/constants/app_colors.dart';

class FontSizeMenu extends StatelessWidget {
  final double currentSize;
  final List<double> fontSizes;
  final ValueChanged<double> onSelected;

  const FontSizeMenu({
    super.key,
    required this.currentSize,
    required this.fontSizes,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double>(
      icon: Icon(Icons.font_download_outlined, color: AppColors.textPrimary),
      initialValue: currentSize,
      onSelected: onSelected,
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.divider),
      ),
      itemBuilder: (context) => fontSizes
          .map(
            (size) => PopupMenuItem<double>(
              value: size,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${size.toInt()} pt',
                      style: TextStyle(
                        fontSize: size,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (size == currentSize)
                      Icon(Icons.check, color: AppColors.primary, size: 16),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
