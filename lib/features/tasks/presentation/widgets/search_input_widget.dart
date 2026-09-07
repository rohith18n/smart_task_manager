import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';

class SearchInputWidget extends StatelessWidget {
  final TextEditingController? controller;

  const SearchInputWidget({super.key, this.controller});

  @override
  Widget build(BuildContext context) {
    final searchController = controller ??
        TextEditingController(
          text: context.read<TaskBloc>().state.searchQuery,
        );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 48,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: searchController,
        builder: (context, value, _) {
          return TextField(
            controller: searchController,
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
              fontSize: 15,
            ),
            onChanged: (query) {
              context.read<TaskBloc>().add(SearchTasksEvent(query.trim()));
            },
            decoration: InputDecoration(
              hintText: 'Search tasks by title...',
              hintStyle: TextStyle(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 22,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              suffixIcon: value.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      onPressed: () {
                        searchController.clear();
                        context
                            .read<TaskBloc>()
                            .add(const SearchTasksEvent(''));
                      },
                    )
                  : null,
              filled: true,
              fillColor:
                  isDark ? AppColors.darkInputFill : AppColors.lightInputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(
                  color: isDark ? AppColors.primary : AppColors.primaryDark,
                  width: 1.5,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            ),
          );
        },
      ),
    );
  }
}
