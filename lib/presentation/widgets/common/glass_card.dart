import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lifeos/config/theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final Color? borderColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final double blur;
  final List<BoxShadow>? shadows;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.borderColor,
    this.backgroundColor,
    this.onTap,
    this.blur = 10,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius ?? 20),
          boxShadow: shadows ?? [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius ?? 20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              padding: padding ?? const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: backgroundColor ?? (isDark ? AppColors.glassDark : AppColors.glassLight),
                borderRadius: BorderRadius.circular(borderRadius ?? 20),
                border: Border.all(
                  color: borderColor ?? AppColors.glassBorder,
                  width: 0.5,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class GradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final List<Color>? colors;
  final double? borderRadius;
  final VoidCallback? onTap;

  const GradientCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.colors,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius ?? 20),
          gradient: LinearGradient(
            colors: colors ?? [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: (colors?.first ?? AppColors.primary).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
