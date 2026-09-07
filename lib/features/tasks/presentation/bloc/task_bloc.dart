import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/enums/task_category.dart';
import '../../domain/enums/task_filter.dart';
import '../../domain/enums/task_priority.dart';
import '../../domain/enums/task_sort.dart';
import '../../domain/usecases/create_task_usecase.dart';
import '../../domain/usecases/delete_task_usecase.dart';
import '../../domain/usecases/get_tasks_usecase.dart';
import '../../domain/usecases/sync_tasks_usecase.dart';
import '../../domain/usecases/toggle_task_completion_usecase.dart';
import '../../domain/usecases/update_task_usecase.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final GetTasksUseCase getTasksUseCase;
  final CreateTaskUseCase createTaskUseCase;
  final UpdateTaskUseCase updateTaskUseCase;
  final DeleteTaskUseCase deleteTaskUseCase;
  final ToggleTaskCompletionUseCase toggleTaskCompletionUseCase;
  final SyncTasksUseCase syncTasksUseCase;
  final NetworkInfo networkInfo;

  StreamSubscription<bool>? _connectivitySubscription;
  String? _currentUserId;

  TaskBloc({
    required this.getTasksUseCase,
    required this.createTaskUseCase,
    required this.updateTaskUseCase,
    required this.deleteTaskUseCase,
    required this.toggleTaskCompletionUseCase,
    required this.syncTasksUseCase,
    required this.networkInfo,
  }) : super(const TaskState()) {
    on<LoadTasksEvent>(_onLoadTasks);
    on<LoadMoreTasksEvent>(_onLoadMoreTasks);
    on<CreateTaskEvent>(_onCreateTask);
    on<UpdateTaskEvent>(_onUpdateTask);
    on<DeleteTaskEvent>(_onDeleteTask);
    on<ToggleTaskCompletionEvent>(_onToggleTaskCompletion);
    on<SearchTasksEvent>(_onSearchTasks);
    on<ChangeFilterEvent>(_onChangeFilter);
    on<ChangePriorityFilterEvent>(_onChangePriorityFilter);
    on<ChangeCategoryFilterEvent>(_onChangeCategoryFilter);
    on<ChangeSortEvent>(_onChangeSort);
    on<SyncTasksEvent>(_onSyncTasks);
    on<NetworkStatusChangedEvent>(_onNetworkStatusChanged);

    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    networkInfo.isConnected.then((connected) {
      if (!isClosed) {
        try {
          add(NetworkStatusChangedEvent(connected));
        } catch (_) {}
      }
    }).catchError((_) {});

    _connectivitySubscription = networkInfo.onConnectivityChanged.listen((connected) {
      if (!isClosed) {
        try {
          add(NetworkStatusChangedEvent(connected));
        } catch (_) {}
      }
    });
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadTasks(LoadTasksEvent event, Emitter<TaskState> emit) async {
    _currentUserId = event.userId;
    emit(state.copyWith(status: TaskStatus.loading, errorMessage: null, hasReachedMax: false));
    try {
      final tasks = await getTasksUseCase(userId: _currentUserId, skip: 0, limit: 10);
      final filtered = _filterAndSort(
        tasks: tasks,
        query: state.searchQuery,
        filter: state.filter,
        priority: state.priorityFilter,
        category: state.categoryFilter,
        sortBy: state.sortBy,
      );
      emit(state.copyWith(
        status: TaskStatus.success,
        allTasks: tasks,
        filteredTasks: filtered,
        hasReachedMax: tasks.length < 10,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TaskStatus.failure,
        errorMessage: 'Failed to load tasks: $e',
      ));
    }
  }

  Future<void> _onLoadMoreTasks(LoadMoreTasksEvent event, Emitter<TaskState> emit) async {
    if (state.hasReachedMax || state.isLoadingMore) return;

    emit(state.copyWith(isLoadingMore: true));
    try {
      final newTasks = await getTasksUseCase(
        userId: _currentUserId,
        skip: state.allTasks.length,
        limit: event.limit,
      );

      if (newTasks.isEmpty) {
        emit(state.copyWith(isLoadingMore: false, hasReachedMax: true));
        return;
      }

      final existingIds = state.allTasks.map((t) => t.id).toSet();
      final uniqueNew = newTasks.where((t) => !existingIds.contains(t.id)).toList();

      final updatedAll = [...state.allTasks, ...uniqueNew];
      final filtered = _filterAndSort(
        tasks: updatedAll,
        query: state.searchQuery,
        filter: state.filter,
        priority: state.priorityFilter,
        category: state.categoryFilter,
        sortBy: state.sortBy,
      );

      emit(state.copyWith(
        isLoadingMore: false,
        allTasks: updatedAll,
        filteredTasks: filtered,
        hasReachedMax: newTasks.length < event.limit,
      ));
    } catch (e) {
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  // --- Optimistic UI Updates ---

  Future<void> _onCreateTask(CreateTaskEvent event, Emitter<TaskState> emit) async {
    final previousTasks = state.allTasks;
    // Optimistic item
    final optimisticTask = event.task.id != 0
        ? event.task
        : event.task.copyWith(id: -(DateTime.now().millisecondsSinceEpoch % 1000000000));

    final optimisticList = [optimisticTask, ...previousTasks];
    final optimisticFiltered = _filterAndSort(
      tasks: optimisticList,
      query: state.searchQuery,
      filter: state.filter,
      priority: state.priorityFilter,
      category: state.categoryFilter,
      sortBy: state.sortBy,
    );

    emit(state.copyWith(
      status: TaskStatus.success,
      allTasks: optimisticList,
      filteredTasks: optimisticFiltered,
    ));

    try {
      final created = await createTaskUseCase(event.task);
      // Replace optimistic temp item with real synced item
      final finalizedList = state.allTasks.map((t) {
        return (t.id == optimisticTask.id) ? created : t;
      }).toList();

      final finalizedFiltered = _filterAndSort(
        tasks: finalizedList,
        query: state.searchQuery,
        filter: state.filter,
        priority: state.priorityFilter,
        category: state.categoryFilter,
        sortBy: state.sortBy,
      );

      emit(state.copyWith(
        status: TaskStatus.success,
        allTasks: finalizedList,
        filteredTasks: finalizedFiltered,
      ));
    } catch (e) {
      // Revert on failure
      emit(state.copyWith(
        status: TaskStatus.failure,
        allTasks: previousTasks,
        filteredTasks: _filterAndSort(
          tasks: previousTasks,
          query: state.searchQuery,
          filter: state.filter,
          priority: state.priorityFilter,
          category: state.categoryFilter,
          sortBy: state.sortBy,
        ),
        errorMessage: 'Failed to create task: $e',
      ));
    }
  }

  Future<void> _onUpdateTask(UpdateTaskEvent event, Emitter<TaskState> emit) async {
    final previousTasks = state.allTasks;

    // Optimistic update
    final optimisticList = state.allTasks.map((t) {
      return (t.id == event.task.id) ? event.task : t;
    }).toList();

    emit(state.copyWith(
      status: TaskStatus.success,
      allTasks: optimisticList,
      filteredTasks: _filterAndSort(
        tasks: optimisticList,
        query: state.searchQuery,
        filter: state.filter,
        priority: state.priorityFilter,
        category: state.categoryFilter,
        sortBy: state.sortBy,
      ),
    ));

    try {
      final updated = await updateTaskUseCase(event.task);
      final finalizedList = state.allTasks.map((t) {
        return (t.id == event.task.id) ? updated : t;
      }).toList();

      emit(state.copyWith(
        status: TaskStatus.success,
        allTasks: finalizedList,
        filteredTasks: _filterAndSort(
          tasks: finalizedList,
          query: state.searchQuery,
          filter: state.filter,
          priority: state.priorityFilter,
          category: state.categoryFilter,
          sortBy: state.sortBy,
        ),
      ));
    } catch (e) {
      // Revert on failure
      emit(state.copyWith(
        status: TaskStatus.failure,
        allTasks: previousTasks,
        filteredTasks: _filterAndSort(
          tasks: previousTasks,
          query: state.searchQuery,
          filter: state.filter,
          priority: state.priorityFilter,
          category: state.categoryFilter,
          sortBy: state.sortBy,
        ),
        errorMessage: 'Failed to update task: $e',
      ));
    }
  }

  Future<void> _onDeleteTask(DeleteTaskEvent event, Emitter<TaskState> emit) async {
    final previousTasks = state.allTasks;

    // Optimistic deletion
    final optimisticList = state.allTasks.where((t) => t.id != event.id).toList();

    emit(state.copyWith(
      status: TaskStatus.success,
      allTasks: optimisticList,
      filteredTasks: _filterAndSort(
        tasks: optimisticList,
        query: state.searchQuery,
        filter: state.filter,
        priority: state.priorityFilter,
        category: state.categoryFilter,
        sortBy: state.sortBy,
      ),
    ));

    try {
      await deleteTaskUseCase(event.id, userId: _currentUserId);
    } catch (e) {
      // Revert on failure
      emit(state.copyWith(
        status: TaskStatus.failure,
        allTasks: previousTasks,
        filteredTasks: _filterAndSort(
          tasks: previousTasks,
          query: state.searchQuery,
          filter: state.filter,
          priority: state.priorityFilter,
          category: state.categoryFilter,
          sortBy: state.sortBy,
        ),
        errorMessage: 'Failed to delete task: $e',
      ));
    }
  }

  Future<void> _onToggleTaskCompletion(
    ToggleTaskCompletionEvent event,
    Emitter<TaskState> emit,
  ) async {
    final previousTasks = state.allTasks;

    // Optimistic toggle
    final optimisticList = state.allTasks.map((t) {
      if (t.id == event.id) {
        return t.copyWith(
          isCompleted: !t.isCompleted,
          updatedAt: DateTime.now(),
        );
      }
      return t;
    }).toList();

    emit(state.copyWith(
      status: TaskStatus.success,
      allTasks: optimisticList,
      filteredTasks: _filterAndSort(
        tasks: optimisticList,
        query: state.searchQuery,
        filter: state.filter,
        priority: state.priorityFilter,
        category: state.categoryFilter,
        sortBy: state.sortBy,
      ),
    ));

    try {
      final toggled = await toggleTaskCompletionUseCase(event.id, userId: _currentUserId);
      if (toggled != null) {
        final finalizedList = state.allTasks.map((t) {
          return (t.id == event.id) ? toggled : t;
        }).toList();

        emit(state.copyWith(
          status: TaskStatus.success,
          allTasks: finalizedList,
          filteredTasks: _filterAndSort(
            tasks: finalizedList,
            query: state.searchQuery,
            filter: state.filter,
            priority: state.priorityFilter,
            category: state.categoryFilter,
            sortBy: state.sortBy,
          ),
        ));
      }
    } catch (e) {
      // Revert on failure
      emit(state.copyWith(
        status: TaskStatus.failure,
        allTasks: previousTasks,
        filteredTasks: _filterAndSort(
          tasks: previousTasks,
          query: state.searchQuery,
          filter: state.filter,
          priority: state.priorityFilter,
          category: state.categoryFilter,
          sortBy: state.sortBy,
        ),
        errorMessage: 'Failed to update task status: $e',
      ));
    }
  }

  // --- Filtering, Searching & Sorting ---

  void _onSearchTasks(SearchTasksEvent event, Emitter<TaskState> emit) {
    final filtered = _filterAndSort(
      tasks: state.allTasks,
      query: event.query,
      filter: state.filter,
      priority: state.priorityFilter,
      category: state.categoryFilter,
      sortBy: state.sortBy,
    );
    emit(state.copyWith(
      searchQuery: event.query,
      filteredTasks: filtered,
    ));
  }

  void _onChangeFilter(ChangeFilterEvent event, Emitter<TaskState> emit) {
    final filtered = _filterAndSort(
      tasks: state.allTasks,
      query: state.searchQuery,
      filter: event.filter,
      priority: state.priorityFilter,
      category: state.categoryFilter,
      sortBy: state.sortBy,
    );
    emit(state.copyWith(
      filter: event.filter,
      filteredTasks: filtered,
    ));
  }

  void _onChangePriorityFilter(ChangePriorityFilterEvent event, Emitter<TaskState> emit) {
    final filtered = _filterAndSort(
      tasks: state.allTasks,
      query: state.searchQuery,
      filter: state.filter,
      priority: event.priority,
      category: state.categoryFilter,
      sortBy: state.sortBy,
    );
    emit(state.copyWith(
      priorityFilter: () => event.priority,
      filteredTasks: filtered,
    ));
  }

  void _onChangeCategoryFilter(ChangeCategoryFilterEvent event, Emitter<TaskState> emit) {
    final filtered = _filterAndSort(
      tasks: state.allTasks,
      query: state.searchQuery,
      filter: state.filter,
      priority: state.priorityFilter,
      category: event.category,
      sortBy: state.sortBy,
    );
    emit(state.copyWith(
      categoryFilter: () => event.category,
      filteredTasks: filtered,
    ));
  }

  void _onChangeSort(ChangeSortEvent event, Emitter<TaskState> emit) {
    final filtered = _filterAndSort(
      tasks: state.allTasks,
      query: state.searchQuery,
      filter: state.filter,
      priority: state.priorityFilter,
      category: state.categoryFilter,
      sortBy: event.sortBy,
    );
    emit(state.copyWith(
      sortBy: event.sortBy,
      filteredTasks: filtered,
    ));
  }

  Future<void> _onSyncTasks(SyncTasksEvent event, Emitter<TaskState> emit) async {
    emit(state.copyWith(isSyncing: true));
    try {
      final uid = event.userId ?? _currentUserId;
      await syncTasksUseCase(userId: uid);
      final tasks = await getTasksUseCase(userId: uid, skip: 0, limit: 20);
      final filtered = _filterAndSort(
        tasks: tasks,
        query: state.searchQuery,
        filter: state.filter,
        priority: state.priorityFilter,
        category: state.categoryFilter,
        sortBy: state.sortBy,
      );
      emit(state.copyWith(
        isSyncing: false,
        allTasks: tasks,
        filteredTasks: filtered,
        lastSyncedAt: DateTime.now(),
      ));
    } catch (_) {
      emit(state.copyWith(isSyncing: false));
    }
  }

  void _onNetworkStatusChanged(NetworkStatusChangedEvent event, Emitter<TaskState> emit) {
    final wasOffline = !state.isOnline;
    if (state.isOnline != event.isConnected) {
      emit(state.copyWith(isOnline: event.isConnected));
    }
    if (wasOffline && event.isConnected) {
      add(SyncTasksEvent(_currentUserId));
    }
  }

  List<TaskEntity> _filterAndSort({
    required List<TaskEntity> tasks,
    required String query,
    required TaskFilter filter,
    required TaskPriority? priority,
    required TaskCategory? category,
    required TaskSortBy sortBy,
  }) {
    var result = List<TaskEntity>.from(tasks);

    // Search query (Title and description)
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      result = result.where((t) {
        final titleMatches = t.title.toLowerCase().contains(q);
        final descMatches = t.description?.toLowerCase().contains(q) ?? false;
        return titleMatches || descMatches;
      }).toList();
    }

    // Status filter
    switch (filter) {
      case TaskFilter.pending:
        result = result.where((t) => !t.isCompleted).toList();
        break;
      case TaskFilter.completed:
        result = result.where((t) => t.isCompleted).toList();
        break;
      case TaskFilter.all:
        break;
    }

    // Priority filter
    if (priority != null) {
      result = result.where((t) => t.priority == priority).toList();
    }

    // Category filter
    if (category != null) {
      result = result.where((t) => t.category == category).toList();
    }

    // Sorting
    switch (sortBy) {
      case TaskSortBy.dueDateAsc:
        result.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case TaskSortBy.dueDateDesc:
        result.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return b.dueDate!.compareTo(a.dueDate!);
        });
        break;
      case TaskSortBy.priorityHighToLow:
        result.sort((a, b) => b.priority.rank.compareTo(a.priority.rank));
        break;
      case TaskSortBy.priorityLowToHigh:
        result.sort((a, b) => a.priority.rank.compareTo(b.priority.rank));
        break;
      case TaskSortBy.createdDateDesc:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return result;
  }
}
