import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
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

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final authUser = context.read<AuthBloc>().state.user;
    final firebaseUid = () {
      try {
        return FirebaseAuth.instance.currentUser?.uid;
      } catch (_) {
        return null;
      }
    }();
    final uid = authUser?.id ?? firebaseUid;
    final taskBloc = context.read<TaskBloc>();
    if (taskBloc.state.status == TaskStatus.initial ||
        taskBloc.state.allTasks.isEmpty) {
      taskBloc.add(LoadTasksEvent(uid));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh(BuildContext context) async {
    final authUser = context.read<AuthBloc>().state.user;
    final firebaseUid = () {
      try {
        return FirebaseAuth.instance.currentUser?.uid;
      } catch (_) {
        return null;
      }
    }();
    final uid = authUser?.id ?? firebaseUid;
    final taskBloc = context.read<TaskBloc>();
    taskBloc.add(SyncTasksEvent(uid));
    try {
      await taskBloc.stream
          .firstWhere((state) => !state.isSyncing)
          .timeout(const Duration(seconds: 4));
    } catch (_) {
      // Stream timeout fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, authState) {
            if (authState.isAuthenticated && authState.user != null) {
              context.read<TaskBloc>().add(LoadTasksEvent(authState.user!.id));
            }
          },
        ),
        BlocListener<TaskBloc, TaskState>(
          listener: (context, state) {
            if (state.status == TaskStatus.failure &&
                state.errorMessage != null &&
                state.allTasks.isNotEmpty) {
              AppFeedback.showError(
                context,
                title: 'Task Error',
                message: state.errorMessage!,
                actionLabel: 'Retry',
                onAction: () {
                  final authUser = context.read<AuthBloc>().state.user;
                  context.read<TaskBloc>().add(
                        LoadTasksEvent(
                          authUser?.id ?? state.allTasks.firstOrNull?.userId,
                        ),
                      );
                },
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: const TaskListAppBar(),
        body: Column(
          children: [
            const TaskListOfflineBanner(),
            SearchInputWidget(controller: _searchController),
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
                    return RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => _handleRefresh(context),
                      child: LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: ErrorViewWidget(
                              error: state.error,
                              message: state.errorMessage ??
                                  'An error occurred while loading tasks.',
                              onRetry: () {
                                final authUser =
                                    context.read<AuthBloc>().state.user;
                                context.read<TaskBloc>().add(
                                      LoadTasksEvent(authUser?.id),
                                    );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  if (state.filteredTasks.isEmpty) {
                    return RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => _handleRefresh(context),
                      child: LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: EmptyTasksWidget(
                              filter: state.filter,
                              searchQuery: state.searchQuery,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  final itemCount = state.filteredTasks.length +
                      (state.isLoadingMore ? 1 : 0);

                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () => _handleRefresh(context),
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
