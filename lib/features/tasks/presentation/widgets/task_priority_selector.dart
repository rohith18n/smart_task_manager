import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/enums/task_priority.dart';

class TaskPrioritySelector extends StatelessWidget {
  final TaskPriority selectedPriority;
  final ValueChanged<TaskPriority> onPriorityChanged;

  const TaskPrioritySelector({
    super.key,
    required this.selectedPriority,
    required this.onPriorityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Priority Level *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: TaskPriority.values.map((priority) {
            final isSelected = selectedPriority == priority;

            Color pillBg;
            Color pillText;
            Color pillBorder;

            if (isSelected) {
              if (isDark) {
                pillBg = priority.backgroundColor;
                pillText = priority.color;
                pillBorder = priority.color;
              } else {
                pillBg = AppColors.lightChipSelectedBg;
                pillText = AppColors.lightChipSelectedText;
                pillBorder = AppColors.lightChipSelectedBorder;
              }
            } else {
              if (isDark) {
                pillBg = AppColors.darkInputFill;
                pillText = AppColors.darkTextSecondary;
                pillBorder = Colors.transparent;
              } else {
                pillBg = Colors.white;
                pillText = AppColors.lightChipUnselectedText;
                pillBorder = AppColors.lightChipUnselectedBorder;
              }
            }

            return Expanded(
              child: GestureDetector(
                onTap: () => onPriorityChanged(priority),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: pillBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: pillBorder,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: priority.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        priority.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: pillText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
