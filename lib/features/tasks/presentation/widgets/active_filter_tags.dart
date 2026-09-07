import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/enums/task_category.dart';
import '../../domain/enums/task_priority.dart';

class ActiveFilterTags extends StatelessWidget {
  final TaskPriority? priorityFilter;
  final TaskCategory? categoryFilter;
  final VoidCallback onClearPriority;
  final VoidCallback onClearCategory;

  const ActiveFilterTags({
    super.key,
    required this.priorityFilter,
    required this.categoryFilter,
    required this.onClearPriority,
    required this.onClearCategory,
  });

  @override
  Widget build(BuildContext context) {
    if (priorityFilter == null && categoryFilter == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          if (priorityFilter != null)
            _buildTag(
              context,
              label: 'Priority: ${priorityFilter!.displayName}',
              dotColor: priorityFilter!.color,
              onClear: onClearPriority,
            ),
          if (categoryFilter != null)
            _buildTag(
              context,
              label: 'Category: ${categoryFilter!.displayName}',
              icon: categoryFilter!.icon,
              iconColor: categoryFilter!.color,
              onClear: onClearCategory,
            ),
        ],
      ),
    );
  }

  Widget _buildTag(
    BuildContext context, {
    required String label,
    Color? dotColor,
    IconData? icon,
    Color? iconColor,
    required VoidCallback onClear,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:
            isDark ? AppColors.chipSelectedBg : AppColors.lightChipSelectedBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.transparent : AppColors.lightChipSelectedBorder,
          width: 1,
        ),
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
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.chipSelectedText
                  : AppColors.lightChipSelectedText,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onClear,
            child: Icon(
              Icons.close_rounded,
              size: 14,
              color: isDark
                  ? AppColors.chipSelectedText
                  : AppColors.lightChipSelectedText,
            ),
          ),
        ],
      ),
    );
  }
}
