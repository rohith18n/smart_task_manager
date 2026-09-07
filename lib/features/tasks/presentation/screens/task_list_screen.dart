import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';
import '../widgets/empty_tasks_widget.dart';
import '../widgets/error_view_widget.dart';
import '../widgets/filter_sort_bar.dart';
import '../widgets/search_input_widget.dart';
import '../widgets/task_card_widget.dart';
import '../widgets/task_list_app_bar.dart';
import '../widgets/task_list_offline_banner.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<TaskBloc, TaskState>(
      listener: (context, state) {
        if (state.status == TaskStatus.failure &&
            state.errorMessage != null &&
            state.allTasks.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: const TaskListAppBar(),
        body: Column(
          children: [
            const TaskListOfflineBanner(),
            const SearchInputWidget(),
            const FilterSortBar(),
            const SizedBox(height: 4),
            Expanded(
              child: BlocBuilder<TaskBloc, TaskState>(
                builder: (context, state) {
                  if (state.status == TaskStatus.loading &&
                      state.allTasks.isEmpty) {
                    return const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    );
                  }

                  if (state.status == TaskStatus.failure &&
                      state.allTasks.isEmpty) {
                    return ErrorViewWidget(
                      error: state.error,
                      message: state.errorMessage ??
                          'An error occurred while loading tasks.',
                      onRetry: () {
                        context.read<TaskBloc>().add(const LoadTasksEvent());
                      },
                    );
                  }

                  if (state.filteredTasks.isEmpty) {
                    return EmptyTasksWidget(
                      filter: state.filter,
                      searchQuery: state.searchQuery,
                    );
                  }

                  final itemCount = state.filteredTasks.length +
                      (state.isLoadingMore ? 1 : 0);

                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async {
                      context.read<TaskBloc>().add(const SyncTasksEvent());
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification.metrics.pixels >=
                            notification.metrics.maxScrollExtent - 200) {
                          final taskBloc = context.read<TaskBloc>();
                          if (!taskBloc.state.hasReachedMax &&
                              !taskBloc.state.isLoadingMore) {
                            taskBloc.add(const LoadMoreTasksEvent());
                          }
                        }
                        return false;
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80, top: 4),
                        itemCount: itemCount,
                        itemBuilder: (context, index) {
                          if (index >= state.filteredTasks.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            );
                          }
                          final task = state.filteredTasks[index];
                          return TaskCardWidget(task: task);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/add'),
          backgroundColor: AppColors.primary,
          elevation: 4,
          child: const Icon(Icons.add, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}
