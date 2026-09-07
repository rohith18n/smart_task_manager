import 'package:equatable/equatable.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/enums/task_category.dart';
import '../../domain/enums/task_filter.dart';
import '../../domain/enums/task_priority.dart';
import '../../domain/enums/task_sort.dart';

enum TaskStatus { initial, loading, success, failure }

class TaskState extends Equatable {
  final TaskStatus status;
  final List<TaskEntity> allTasks;
  final List<TaskEntity> filteredTasks;
  final String searchQuery;
  final TaskFilter filter;
  final TaskPriority? priorityFilter;
  final TaskCategory? categoryFilter;
  final TaskSortBy sortBy;
  final bool isOnline;
  final bool isSyncing;
  final bool isLoadingMore;
  final bool hasReachedMax;
  final AppException? error;
  final String? errorMessage;
  final DateTime? lastSyncedAt;

  const TaskState({
    this.status = TaskStatus.initial,
    this.allTasks = const [],
    this.filteredTasks = const [],
    this.searchQuery = '',
    this.filter = TaskFilter.all,
    this.priorityFilter,
    this.categoryFilter,
    this.sortBy = TaskSortBy.createdDateDesc,
    this.isOnline = true,
    this.isSyncing = false,
    this.isLoadingMore = false,
    this.hasReachedMax = false,
    this.error,
    this.errorMessage,
    this.lastSyncedAt,
  });

  TaskState copyWith({
    TaskStatus? status,
    List<TaskEntity>? allTasks,
    List<TaskEntity>? filteredTasks,
    String? searchQuery,
    TaskFilter? filter,
    TaskPriority? Function()? priorityFilter,
    TaskCategory? Function()? categoryFilter,
    TaskSortBy? sortBy,
    bool? isOnline,
    bool? isSyncing,
    bool? isLoadingMore,
    bool? hasReachedMax,
    AppException? Function()? error,
    String? errorMessage,
    DateTime? lastSyncedAt,
  }) {
    return TaskState(
      status: status ?? this.status,
      allTasks: allTasks ?? this.allTasks,
      filteredTasks: filteredTasks ?? this.filteredTasks,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
      priorityFilter: priorityFilter != null ? priorityFilter() : this.priorityFilter,
      categoryFilter: categoryFilter != null ? categoryFilter() : this.categoryFilter,
      sortBy: sortBy ?? this.sortBy,
      isOnline: isOnline ?? this.isOnline,
      isSyncing: isSyncing ?? this.isSyncing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      error: error != null ? error() : this.error,
      errorMessage: errorMessage ?? this.errorMessage,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  int get pendingSyncCount =>
      allTasks.where((task) => !task.isSynced || task.syncAction != 'NONE').length;

  int get totalTasksCount => allTasks.length;
  int get completedTasksCount => allTasks.where((t) => t.isCompleted).length;
  int get pendingTasksCount => allTasks.where((t) => !t.isCompleted).length;

  @override
  List<Object?> get props => [
        status,
        allTasks,
        filteredTasks,
        searchQuery,
        filter,
        priorityFilter,
        categoryFilter,
        sortBy,
        isOnline,
        isSyncing,
        isLoadingMore,
        hasReachedMax,
        error,
        errorMessage,
        lastSyncedAt,
      ];
}
