import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/usecases/create_task_usecase.dart';
import '../../domain/usecases/delete_task_usecase.dart';
import '../../domain/usecases/get_tasks_usecase.dart';
import '../../domain/usecases/sync_tasks_usecase.dart';
import '../../domain/usecases/toggle_task_completion_usecase.dart';
import '../../domain/usecases/update_task_usecase.dart';
import 'task_event.dart';
import 'task_filter_sorter.dart';
import 'task_mutation_handlers.dart';
import 'task_query_handlers.dart';
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
  String? currentUserId;

  TaskBloc({
    required this.getTasksUseCase,
    required this.createTaskUseCase,
    required this.updateTaskUseCase,
    required this.deleteTaskUseCase,
    required this.toggleTaskCompletionUseCase,
    required this.syncTasksUseCase,
    required this.networkInfo,
  }) : super(const TaskState()) {
    on<LoadTasksEvent>(
        (e, emit) => TaskQueryHandlers.onLoadTasks(this, e, emit));
    on<LoadMoreTasksEvent>(
        (e, emit) => TaskQueryHandlers.onLoadMoreTasks(this, e, emit));
    on<CreateTaskEvent>(
        (e, emit) => TaskMutationHandlers.onCreateTask(this, e, emit));
    on<UpdateTaskEvent>(
        (e, emit) => TaskMutationHandlers.onUpdateTask(this, e, emit));
    on<DeleteTaskEvent>(
        (e, emit) => TaskMutationHandlers.onDeleteTask(this, e, emit));
    on<ToggleTaskCompletionEvent>(
        (e, emit) => TaskMutationHandlers.onToggleCompletion(this, e, emit));
    on<SearchTasksEvent>(_onSearchTasks);
    on<ChangeFilterEvent>(_onChangeFilter);
    on<ChangePriorityFilterEvent>(_onChangePriorityFilter);
    on<ChangeCategoryFilterEvent>(_onChangeCategoryFilter);
    on<ChangeSortEvent>(_onChangeSort);
    on<SyncTasksEvent>(
        (e, emit) => TaskQueryHandlers.onSyncTasks(this, e, emit));
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

    _connectivitySubscription =
        networkInfo.onConnectivityChanged.listen((connected) {
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

  void _onSearchTasks(SearchTasksEvent event, Emitter<TaskState> emit) {
    emit(state.copyWith(
      searchQuery: event.query,
      filteredTasks: TaskFilterSorter.filterAndSort(
        tasks: state.allTasks,
        query: event.query,
        filter: state.filter,
        priority: state.priorityFilter,
        category: state.categoryFilter,
        sortBy: state.sortBy,
      ),
    ));
  }

  void _onChangeFilter(ChangeFilterEvent event, Emitter<TaskState> emit) {
    emit(state.copyWith(
      filter: event.filter,
      filteredTasks: TaskFilterSorter.filterAndSort(
        tasks: state.allTasks,
        query: state.searchQuery,
        filter: event.filter,
        priority: state.priorityFilter,
        category: state.categoryFilter,
        sortBy: state.sortBy,
      ),
    ));
  }

  void _onChangePriorityFilter(
      ChangePriorityFilterEvent event, Emitter<TaskState> emit) {
    emit(state.copyWith(
      priorityFilter: () => event.priority,
      filteredTasks: TaskFilterSorter.filterAndSort(
        tasks: state.allTasks,
        query: state.searchQuery,
        filter: state.filter,
        priority: event.priority,
        category: state.categoryFilter,
        sortBy: state.sortBy,
      ),
    ));
  }

  void _onChangeCategoryFilter(
      ChangeCategoryFilterEvent event, Emitter<TaskState> emit) {
    emit(state.copyWith(
      categoryFilter: () => event.category,
      filteredTasks: TaskFilterSorter.filterAndSort(
        tasks: state.allTasks,
        query: state.searchQuery,
        filter: state.filter,
        priority: state.priorityFilter,
        category: event.category,
        sortBy: state.sortBy,
      ),
    ));
  }

  void _onChangeSort(ChangeSortEvent event, Emitter<TaskState> emit) {
    emit(state.copyWith(
      sortBy: event.sortBy,
      filteredTasks: TaskFilterSorter.filterAndSort(
        tasks: state.allTasks,
        query: state.searchQuery,
        filter: state.filter,
        priority: state.priorityFilter,
        category: state.categoryFilter,
        sortBy: event.sortBy,
      ),
    ));
  }

  void _onNetworkStatusChanged(
      NetworkStatusChangedEvent event, Emitter<TaskState> emit) {
    final wasOffline = !state.isOnline;
    if (state.isOnline != event.isConnected) {
      emit(state.copyWith(isOnline: event.isConnected));
    }
    if (wasOffline && event.isConnected) {
      add(SyncTasksEvent(currentUserId));
    }
  }
}
