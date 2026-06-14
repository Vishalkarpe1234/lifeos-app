import 'package:flutter/material.dart';
import 'package:lifeos/config/theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final Color accentColor;
  final IconData icon;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    required this.accentColor,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.darkBorder, width: 0.5),
          gradient: LinearGradient(
            colors: [AppColors.darkCard, accentColor.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accentColor, size: 18),
                ),
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: accentColor),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontFamily: 'Inter',
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
            if (subtitle != null)
              Text(subtitle!, style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'Inter')),
          ],
        ),
      ),
    );
  }
}
