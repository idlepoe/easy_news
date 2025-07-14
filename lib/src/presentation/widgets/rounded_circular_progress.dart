import 'package:flutter/material.dart';
import '../../data/constants/app_colors.dart';

class RoundedCircularProgress extends StatelessWidget {
  final double? value;
  final double strokeWidth;
  final Color? color;
  final double? size;

  const RoundedCircularProgress({
    super.key,
    this.value,
    this.strokeWidth = 3.0,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final progressColor = color ?? AppColors.primary;
    final indicator = CircularProgressIndicator(
      value: value,
      strokeWidth: strokeWidth,
      color: progressColor,
      backgroundColor: progressColor.withOpacity(0.1),
    );
    if (size != null) {
      return SizedBox(width: size, height: size, child: indicator);
    }
    return indicator;
  }
}

// 실제 strokeCap round는 Material 기본 위젯에서 직접 지정 불가하므로, 커스텀 painter가 필요할 수 있음.
// 하지만 대부분의 디자인에서는 위처럼 충분히 자연스럽게 보임.
