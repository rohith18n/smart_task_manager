import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/task_entity.dart';
import 'task_bloc.dart';
import 'task_event.dart';
import 'task_filter_sorter.dart';
import 'task_state.dart';

class TaskMutationHandlers {
  static void _emitRollback(
    TaskBloc bloc,
    Emitter<TaskState> emit,
    List<TaskEntity> previousTasks,
    Object error,
    String prefix,
  ) {
    final appEx = error is AppException ? error : ServerException(error.toString());
    emit(bloc.state.copyWith(
      status: TaskStatus.failure,
      error: () => appEx,
      allTasks: previousTasks,
      filteredTasks: TaskFilterSorter.filterAndSort(
        tasks: previousTasks,
        query: bloc.state.searchQuery,
        filter: bloc.state.filter,
        priority: bloc.state.priorityFilter,
        category: bloc.state.categoryFilter,
        sortBy: bloc.state.sortBy,
      ),
      errorMessage: '$prefix: $error',
    ));
  }

  static Future<void> onCreateTask(
    TaskBloc bloc,
    CreateTaskEvent event,
    Emitter<TaskState> emit,
  ) async {
    final previousTasks = bloc.state.allTasks;
    final optimisticTask = event.task.id != 0
        ? event.task
        : event.task.copyWith(
            id: -(DateTime.now().millisecondsSinceEpoch % 1000000000),
          );

    final optimisticList = [optimisticTask, ...previousTasks];
    final optimisticFiltered = TaskFilterSorter.filterAndSort(
      tasks: optimisticList,
      query: bloc.state.searchQuery,
      filter: bloc.state.filter,
      priority: bloc.state.priorityFilter,
      category: bloc.state.categoryFilter,
      sortBy: bloc.state.sortBy,
    );

    emit(bloc.state.copyWith(
      status: TaskStatus.success,
      allTasks: optimisticList,
      filteredTasks: optimisticFiltered,
    ));

    try {
      final created = await bloc.createTaskUseCase(optimisticTask);
      final finalizedList = bloc.state.allTasks.map((t) {
        return (t.id == optimisticTask.id) ? created : t;
      }).toList();

      emit(bloc.state.copyWith(
        status: TaskStatus.success,
        allTasks: finalizedList,
        filteredTasks: TaskFilterSorter.filterAndSort(
          tasks: finalizedList,
          query: bloc.state.searchQuery,
          filter: bloc.state.filter,
          priority: bloc.state.priorityFilter,
          category: bloc.state.categoryFilter,
          sortBy: bloc.state.sortBy,
        ),
      ));
    } catch (e) {
      _emitRollback(bloc, emit, previousTasks, e, 'Failed to create task');
    }
  }

  static Future<void> onUpdateTask(
    TaskBloc bloc,
    UpdateTaskEvent event,
    Emitter<TaskState> emit,
  ) async {
    final previousTasks = bloc.state.allTasks;
    final optimisticList = bloc.state.allTasks.map((t) {
      return (t.id == event.task.id) ? event.task : t;
    }).toList();

    emit(bloc.state.copyWith(
      status: TaskStatus.success,
      allTasks: optimisticList,
      filteredTasks: TaskFilterSorter.filterAndSort(
        tasks: optimisticList,
        query: bloc.state.searchQuery,
        filter: bloc.state.filter,
        priority: bloc.state.priorityFilter,
        category: bloc.state.categoryFilter,
        sortBy: bloc.state.sortBy,
      ),
    ));

    try {
      final updated = await bloc.updateTaskUseCase(event.task);
      final finalizedList = bloc.state.allTasks.map((t) {
        return (t.id == event.task.id) ? updated : t;
      }).toList();

      emit(bloc.state.copyWith(
        status: TaskStatus.success,
        allTasks: finalizedList,
        filteredTasks: TaskFilterSorter.filterAndSort(
          tasks: finalizedList,
          query: bloc.state.searchQuery,
          filter: bloc.state.filter,
          priority: bloc.state.priorityFilter,
          category: bloc.state.categoryFilter,
          sortBy: bloc.state.sortBy,
        ),
      ));
    } catch (e) {
      _emitRollback(bloc, emit, previousTasks, e, 'Failed to update task');
    }
  }

  static Future<void> onDeleteTask(
    TaskBloc bloc,
    DeleteTaskEvent event,
    Emitter<TaskState> emit,
  ) async {
    final previousTasks = bloc.state.allTasks;
    final optimisticList =
        bloc.state.allTasks.where((t) => t.id != event.id).toList();

    emit(bloc.state.copyWith(
      status: TaskStatus.success,
      allTasks: optimisticList,
      filteredTasks: TaskFilterSorter.filterAndSort(
        tasks: optimisticList,
        query: bloc.state.searchQuery,
        filter: bloc.state.filter,
        priority: bloc.state.priorityFilter,
        category: bloc.state.categoryFilter,
        sortBy: bloc.state.sortBy,
      ),
    ));

    try {
      await bloc.deleteTaskUseCase(event.id, userId: bloc.currentUserId);
    } catch (e) {
      _emitRollback(bloc, emit, previousTasks, e, 'Failed to delete task');
    }
  }

  static Future<void> onToggleCompletion(
    TaskBloc bloc,
    ToggleTaskCompletionEvent event,
    Emitter<TaskState> emit,
  ) async {
    final previousTasks = bloc.state.allTasks;
    final optimisticList = bloc.state.allTasks.map((t) {
      if (t.id == event.id) {
        return t.copyWith(
          isCompleted: !t.isCompleted,
          updatedAt: DateTime.now(),
        );
      }
      return t;
    }).toList();

    emit(bloc.state.copyWith(
      status: TaskStatus.success,
      allTasks: optimisticList,
      filteredTasks: TaskFilterSorter.filterAndSort(
        tasks: optimisticList,
        query: bloc.state.searchQuery,
        filter: bloc.state.filter,
        priority: bloc.state.priorityFilter,
        category: bloc.state.categoryFilter,
        sortBy: bloc.state.sortBy,
      ),
    ));

    try {
      final toggled = await bloc.toggleTaskCompletionUseCase(
        event.id,
        userId: bloc.currentUserId,
      );
      if (toggled != null) {
        final finalizedList = bloc.state.allTasks.map((t) {
          return (t.id == event.id) ? toggled : t;
        }).toList();

        emit(bloc.state.copyWith(
          status: TaskStatus.success,
          allTasks: finalizedList,
          filteredTasks: TaskFilterSorter.filterAndSort(
            tasks: finalizedList,
            query: bloc.state.searchQuery,
            filter: bloc.state.filter,
            priority: bloc.state.priorityFilter,
            category: bloc.state.categoryFilter,
            sortBy: bloc.state.sortBy,
          ),
        ));
      }
    } catch (e) {
      _emitRollback(bloc, emit, previousTasks, e, 'Failed to update task status');
    }
  }
}
