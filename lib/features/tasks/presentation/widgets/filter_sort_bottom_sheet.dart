import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/enums/task_category.dart';
import '../../domain/enums/task_priority.dart';
import '../../domain/enums/task_sort.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';
import 'filter_sort_modal_chip.dart';

class FilterSortBottomSheet extends StatelessWidget {
  const FilterSortBottomSheet({super.key});

  static void show(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<TaskBloc>(),
        child: const FilterSortBottomSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        final bloc = context.read<TaskBloc>();

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkDivider
                          : AppColors.lightDivider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Sort & Filters',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'SORT BY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                ...TaskSortBy.values.map((sort) {
                  final isSelected = state.sortBy == sort;
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      sort.label,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? (isDark
                                ? AppColors.chipSelectedText
                                : AppColors.primaryDark)
                            : (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary),
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: isDark
                                ? AppColors.chipSelectedText
                                : AppColors.primaryDark,
                          )
                        : null,
                    onTap: () {
                      bloc.add(ChangeSortEvent(sort));
                      Navigator.pop(context);
                    },
                  );
                }),
                Divider(
                  height: 24,
                  color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                ),
                Text(
                  'FILTER BY CATEGORY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterSortModalChip(
                      label: 'All Categories',
                      isSelected: state.categoryFilter == null,
                      onTap: () {
                        bloc.add(const ChangeCategoryFilterEvent(null));
                        Navigator.pop(context);
                      },
                    ),
                    ...TaskCategory.values.map((cat) {
                      final isSelected = state.categoryFilter == cat;
                      return FilterSortModalChip(
                        label: cat.displayName,
                        icon: cat.icon,
                        iconColor: cat.color,
                        isSelected: isSelected,
                        onTap: () {
                          bloc.add(ChangeCategoryFilterEvent(
                            isSelected ? null : cat,
                          ));
                          Navigator.pop(context);
                        },
                      );
                    }),
                  ],
                ),
                Divider(
                  height: 24,
                  color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                ),
                Text(
                  'FILTER BY PRIORITY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterSortModalChip(
                      label: 'All Priorities',
                      isSelected: state.priorityFilter == null,
                      onTap: () {
                        bloc.add(const ChangePriorityFilterEvent(null));
                        Navigator.pop(context);
                      },
                    ),
                    ...TaskPriority.values.map((priority) {
                      final isSelected = state.priorityFilter == priority;
                      return FilterSortModalChip(
                        label: priority.displayName,
                        dotColor: priority.color,
                        isSelected: isSelected,
                        onTap: () {
                          bloc.add(ChangePriorityFilterEvent(
                            isSelected ? null : priority,
                          ));
                          Navigator.pop(context);
                        },
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
