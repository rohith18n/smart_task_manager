import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/exceptions.dart';
import 'task_bloc.dart';
import 'task_event.dart';
import 'task_filter_sorter.dart';
import 'task_state.dart';

class TaskQueryHandlers {
  static Future<void> onLoadTasks(
    TaskBloc bloc,
    LoadTasksEvent event,
    Emitter<TaskState> emit,
  ) async {
    bloc.currentUserId = event.userId;
    emit(bloc.state.copyWith(
      status: TaskStatus.loading,
      error: () => null,
      errorMessage: null,
      hasReachedMax: false,
    ));
    try {
      final tasks = await bloc.getTasksUseCase(
        userId: bloc.currentUserId,
        skip: 0,
        limit: 10,
      );
      final filtered = TaskFilterSorter.filterAndSort(
        tasks: tasks,
        query: bloc.state.searchQuery,
        filter: bloc.state.filter,
        priority: bloc.state.priorityFilter,
        category: bloc.state.categoryFilter,
        sortBy: bloc.state.sortBy,
      );
      emit(bloc.state.copyWith(
        status: TaskStatus.success,
        error: () => null,
        errorMessage: null,
        allTasks: tasks,
        filteredTasks: filtered,
        hasReachedMax: tasks.length < 10,
      ));
    } on AppException catch (e) {
      emit(bloc.state.copyWith(
        status: TaskStatus.failure,
        error: () => e,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(bloc.state.copyWith(
        status: TaskStatus.failure,
        error: () => ServerException(e.toString()),
        errorMessage: 'Failed to load tasks: $e',
      ));
    }
  }

  static Future<void> onLoadMoreTasks(
    TaskBloc bloc,
    LoadMoreTasksEvent event,
    Emitter<TaskState> emit,
  ) async {
    if (bloc.state.hasReachedMax || bloc.state.isLoadingMore) return;

    emit(bloc.state.copyWith(isLoadingMore: true));
    try {
      final newTasks = await bloc.getTasksUseCase(
        userId: bloc.currentUserId,
        skip: bloc.state.allTasks.length,
        limit: event.limit,
      );

      if (newTasks.isEmpty) {
        emit(bloc.state.copyWith(isLoadingMore: false, hasReachedMax: true));
        return;
      }

      final existingIds = bloc.state.allTasks.map((t) => t.id).toSet();
      final uniqueNew =
          newTasks.where((t) => !existingIds.contains(t.id)).toList();

      final updatedAll = [...bloc.state.allTasks, ...uniqueNew];
      final filtered = TaskFilterSorter.filterAndSort(
        tasks: updatedAll,
        query: bloc.state.searchQuery,
        filter: bloc.state.filter,
        priority: bloc.state.priorityFilter,
        category: bloc.state.categoryFilter,
        sortBy: bloc.state.sortBy,
      );

      emit(bloc.state.copyWith(
        isLoadingMore: false,
        allTasks: updatedAll,
        filteredTasks: filtered,
        hasReachedMax: newTasks.length < event.limit,
      ));
    } catch (e) {
      emit(bloc.state.copyWith(isLoadingMore: false));
    }
  }

  static Future<void> onSyncTasks(
    TaskBloc bloc,
    SyncTasksEvent event,
    Emitter<TaskState> emit,
  ) async {
    final uid = event.userId ?? bloc.currentUserId;
    if (uid != null && uid.isNotEmpty) {
      bloc.currentUserId = uid;
    }
    emit(bloc.state.copyWith(isSyncing: true));
    try {
      await bloc.syncTasksUseCase(userId: uid);
      final currentCount = bloc.state.allTasks.length;
      final limit = currentCount > 20 ? currentCount : 20;
      final tasks = await bloc.getTasksUseCase(userId: uid, skip: 0, limit: limit);
      final filtered = TaskFilterSorter.filterAndSort(
        tasks: tasks,
        query: bloc.state.searchQuery,
        filter: bloc.state.filter,
        priority: bloc.state.priorityFilter,
        category: bloc.state.categoryFilter,
        sortBy: bloc.state.sortBy,
      );
      emit(bloc.state.copyWith(
        isSyncing: false,
        allTasks: tasks,
        filteredTasks: filtered,
        lastSyncedAt: DateTime.now(),
      ));
    } catch (_) {
      emit(bloc.state.copyWith(isSyncing: false));
    }
  }
}
