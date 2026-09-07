import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/enums/task_filter.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';
import 'active_filter_tags.dart';
import 'filter_sort_bottom_sheet.dart';

class FilterSortBar extends StatelessWidget {
  const FilterSortBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPillChip(
                      context,
                      label: 'All',
                      count: state.totalTasksCount,
                      isSelected: state.filter == TaskFilter.all,
                      onTap: () {
                        context
                            .read<TaskBloc>()
                            .add(const ChangeFilterEvent(TaskFilter.all));
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildPillChip(
                      context,
                      label: 'Pending',
                      count: state.pendingTasksCount,
                      isSelected: state.filter == TaskFilter.pending,
                      onTap: () {
                        context
                            .read<TaskBloc>()
                            .add(const ChangeFilterEvent(TaskFilter.pending));
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildPillChip(
                      context,
                      label: 'Completed',
                      count: state.completedTasksCount,
                      isSelected: state.filter == TaskFilter.completed,
                      onTap: () {
                        context
                            .read<TaskBloc>()
                            .add(const ChangeFilterEvent(TaskFilter.completed));
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildSortPill(context),
                  ],
                ),
              ),
              ActiveFilterTags(
                priorityFilter: state.priorityFilter,
                categoryFilter: state.categoryFilter,
                onClearPriority: () => context
                    .read<TaskBloc>()
                    .add(const ChangePriorityFilterEvent(null)),
                onClearCategory: () => context
                    .read<TaskBloc>()
                    .add(const ChangeCategoryFilterEvent(null)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPillChip(
    BuildContext context, {
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isSelected
        ? (isDark ? AppColors.chipSelectedBg : AppColors.lightChipSelectedBg)
        : (isDark
            ? AppColors.chipUnselectedBg
            : AppColors.lightChipUnselectedBg);

    final textColor = isSelected
        ? (isDark ? AppColors.chipSelectedText : AppColors.lightChipSelectedText)
        : (isDark
            ? AppColors.chipUnselectedText
            : AppColors.lightChipUnselectedText);

    final borderColor = isSelected
        ? (isDark ? Colors.transparent : AppColors.lightChipSelectedBorder)
        : (isDark ? Colors.transparent : AppColors.lightChipUnselectedBorder);

    final displayText = count > 0 && isSelected ? '$label $count' : label;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Text(
          displayText,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }

  Widget _buildSortPill(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark
        ? AppColors.chipUnselectedBg
        : AppColors.lightChipUnselectedBg;
    final textColor = isDark
        ? AppColors.chipUnselectedText
        : AppColors.lightChipUnselectedText;
    final borderColor =
        isDark ? Colors.transparent : AppColors.lightChipUnselectedBorder;

    return InkWell(
      onTap: () => FilterSortBottomSheet.show(context),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune_rounded, size: 16, color: textColor),
            const SizedBox(width: 6),
            Text(
              'Filter & Sort',
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
