import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_task_manager/core/network/network_info.dart';
import 'package:smart_task_manager/features/tasks/domain/entities/task_entity.dart';
import 'package:smart_task_manager/features/tasks/domain/enums/task_category.dart';
import 'package:smart_task_manager/features/tasks/domain/enums/task_filter.dart';
import 'package:smart_task_manager/features/tasks/domain/enums/task_priority.dart';
import 'package:smart_task_manager/features/tasks/domain/enums/task_sort.dart';
import 'package:smart_task_manager/features/tasks/domain/usecases/create_task_usecase.dart';
import 'package:smart_task_manager/features/tasks/domain/usecases/delete_task_usecase.dart';
import 'package:smart_task_manager/features/tasks/domain/usecases/get_tasks_usecase.dart';
import 'package:smart_task_manager/features/tasks/domain/usecases/sync_tasks_usecase.dart';
import 'package:smart_task_manager/features/tasks/domain/usecases/toggle_task_completion_usecase.dart';
import 'package:smart_task_manager/features/tasks/domain/usecases/update_task_usecase.dart';
import 'package:smart_task_manager/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:smart_task_manager/features/tasks/presentation/bloc/task_event.dart';
import 'package:smart_task_manager/features/tasks/presentation/bloc/task_state.dart';

class MockGetTasksUseCase extends Mock implements GetTasksUseCase {}
class MockCreateTaskUseCase extends Mock implements CreateTaskUseCase {}
class MockUpdateTaskUseCase extends Mock implements UpdateTaskUseCase {}
class MockDeleteTaskUseCase extends Mock implements DeleteTaskUseCase {}
class MockToggleTaskCompletionUseCase extends Mock implements ToggleTaskCompletionUseCase {}
class MockSyncTasksUseCase extends Mock implements SyncTasksUseCase {}
class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late MockGetTasksUseCase mockGetTasksUseCase;
  late MockCreateTaskUseCase mockCreateTaskUseCase;
  late MockUpdateTaskUseCase mockUpdateTaskUseCase;
  late MockDeleteTaskUseCase mockDeleteTaskUseCase;
  late MockToggleTaskCompletionUseCase mockToggleTaskCompletionUseCase;
  late MockSyncTasksUseCase mockSyncTasksUseCase;
  late MockNetworkInfo mockNetworkInfo;
  late StreamController<bool> connectivityController;

  final task1 = TaskEntity(
    id: 1,
    userId: 'user-1',
    title: 'Alpha Task',
    description: 'First test task description',
    priority: TaskPriority.low,
    category: TaskCategory.work,
    dueDate: DateTime(2026, 8, 25),
    isCompleted: false,
    createdAt: DateTime(2026, 8, 18, 10),
    updatedAt: DateTime(2026, 8, 18, 10),
  );

  final task2 = TaskEntity(
    id: 2,
    userId: 'user-1',
    title: 'Beta Task',
    description: 'Second test task',
    priority: TaskPriority.high,
    category: TaskCategory.personal,
    dueDate: DateTime(2026, 8, 21),
    isCompleted: true,
    createdAt: DateTime(2026, 8, 19, 10),
    updatedAt: DateTime(2026, 8, 19, 10),
  );

  final taskList = [task1, task2];

  setUp(() {
    mockGetTasksUseCase = MockGetTasksUseCase();
    mockCreateTaskUseCase = MockCreateTaskUseCase();
    mockUpdateTaskUseCase = MockUpdateTaskUseCase();
    mockDeleteTaskUseCase = MockDeleteTaskUseCase();
    mockToggleTaskCompletionUseCase = MockToggleTaskCompletionUseCase();
    mockSyncTasksUseCase = MockSyncTasksUseCase();
    mockNetworkInfo = MockNetworkInfo();
    connectivityController = StreamController<bool>.broadcast();

    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
    when(() => mockNetworkInfo.onConnectivityChanged)
        .thenAnswer((_) => connectivityController.stream);
  });

  tearDown(() {
    connectivityController.close();
  });

  TaskBloc buildBloc() {
    return TaskBloc(
      getTasksUseCase: mockGetTasksUseCase,
      createTaskUseCase: mockCreateTaskUseCase,
      updateTaskUseCase: mockUpdateTaskUseCase,
      deleteTaskUseCase: mockDeleteTaskUseCase,
      toggleTaskCompletionUseCase: mockToggleTaskCompletionUseCase,
      syncTasksUseCase: mockSyncTasksUseCase,
      networkInfo: mockNetworkInfo,
    );
  }

  group('TaskBloc Tests', () {
    test('initial state has empty lists and initial status', () {
      final bloc = buildBloc();
      expect(bloc.state.status, TaskStatus.initial);
      expect(bloc.state.allTasks, isEmpty);
      bloc.close();
    });

    blocTest<TaskBloc, TaskState>(
      'emits [loading, success] with tasks sorted by createdDateDesc on LoadTasksEvent',
      setUp: () {
        when(() => mockGetTasksUseCase(userId: any(named: 'userId'), skip: any(named: 'skip'), limit: any(named: 'limit')))
            .thenAnswer((_) async => taskList);
      },
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const LoadTasksEvent()),
      expect: () => [
        const TaskState(status: TaskStatus.loading),
        TaskState(
          status: TaskStatus.success,
          allTasks: taskList,
          filteredTasks: [task2, task1], // sorted by createdDateDesc
          hasReachedMax: true,
        ),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'filters tasks locally without network call on SearchTasksEvent',
      build: () => buildBloc(),
      seed: () => TaskState(
        status: TaskStatus.success,
        allTasks: taskList,
        filteredTasks: [task2, task1],
      ),
      act: (bloc) => bloc.add(const SearchTasksEvent('Alpha')),
      expect: () => [
        TaskState(
          status: TaskStatus.success,
          allTasks: taskList,
          filteredTasks: [task1],
          searchQuery: 'Alpha',
        ),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'filters pending tasks on ChangeFilterEvent(TaskFilter.pending)',
      build: () => buildBloc(),
      seed: () => TaskState(
        status: TaskStatus.success,
        allTasks: taskList,
        filteredTasks: [task2, task1],
      ),
      act: (bloc) => bloc.add(const ChangeFilterEvent(TaskFilter.pending)),
      expect: () => [
        TaskState(
          status: TaskStatus.success,
          allTasks: taskList,
          filteredTasks: [task1],
          filter: TaskFilter.pending,
        ),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'sorts tasks by priority on ChangeSortEvent(TaskSortBy.priorityHighToLow)',
      build: () => buildBloc(),
      seed: () => TaskState(
        status: TaskStatus.success,
        allTasks: taskList,
        filteredTasks: [task1, task2],
      ),
      act: (bloc) => bloc.add(const ChangeSortEvent(TaskSortBy.priorityHighToLow)),
      expect: () => [
        TaskState(
          status: TaskStatus.success,
          allTasks: taskList,
          filteredTasks: [task2, task1], // high (task2) first, then low (task1)
          sortBy: TaskSortBy.priorityHighToLow,
        ),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'toggles task completion status when ToggleTaskCompletionEvent is added',
      setUp: () {
        when(() => mockToggleTaskCompletionUseCase(1, userId: any(named: 'userId')))
            .thenAnswer((_) async => task1.copyWith(isCompleted: true));
      },
      build: () => buildBloc(),
      seed: () => TaskState(
        status: TaskStatus.success,
        allTasks: [task1, task2],
        filteredTasks: [task2, task1],
      ),
      act: (bloc) => bloc.add(const ToggleTaskCompletionEvent(1)),
      verify: (_) {
        verify(() => mockToggleTaskCompletionUseCase(1, userId: any(named: 'userId'))).called(1);
      },
    );
  });
}
