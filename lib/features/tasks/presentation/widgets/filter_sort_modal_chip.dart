import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class FilterSortModalChip extends StatelessWidget {
  final String label;
  final Color? dotColor;
  final IconData? icon;
  final Color? iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterSortModalChip({
    super.key,
    required this.label,
    this.dotColor,
    this.icon,
    this.iconColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isSelected
        ? (isDark ? AppColors.chipSelectedBg : AppColors.lightChipSelectedBg)
        : (isDark
            ? AppColors.chipUnselectedBg
            : AppColors.lightChipUnselectedBg);

    final textColor = isSelected
        ? (isDark ? AppColors.chipSelectedText : AppColors.lightChipSelectedText)
        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    final borderColor = isSelected
        ? (isDark ? Colors.transparent : AppColors.lightChipSelectedBorder)
        : (isDark ? Colors.transparent : AppColors.lightChipUnselectedBorder);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            if (icon != null) ...[
              Icon(icon, size: 14, color: iconColor ?? AppColors.primary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
