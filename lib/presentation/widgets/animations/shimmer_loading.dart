import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lifeos/config/theme/app_theme.dart';

class ShimmerLoading extends StatelessWidget {
  final int count;
  final double height;

  const ShimmerLoading({super.key, this.count = 3, this.height = 80});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (i) => Shimmer.fromColors(
        baseColor: AppColors.darkCard,
        highlightColor: AppColors.darkCardElevated,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: height,
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      )),
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBox({super.key, required this.width, required this.height, this.radius = 8});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.darkCard,
      highlightColor: AppColors.darkCardElevated,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(radius)),
      ),
    );
  }
}
