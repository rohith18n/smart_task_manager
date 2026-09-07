import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_task_manager/features/tasks/domain/entities/task_entity.dart';
import 'package:smart_task_manager/features/tasks/domain/enums/task_category.dart';
import 'package:smart_task_manager/features/tasks/domain/enums/task_priority.dart';
import 'package:smart_task_manager/features/tasks/domain/repositories/task_repository.dart';
import 'package:smart_task_manager/features/tasks/domain/usecases/create_task_usecase.dart';
import 'package:smart_task_manager/features/tasks/domain/usecases/delete_task_usecase.dart';
import 'package:smart_task_manager/features/tasks/domain/usecases/get_tasks_usecase.dart';
import 'package:smart_task_manager/features/tasks/domain/usecases/sync_tasks_usecase.dart';
import 'package:smart_task_manager/features/tasks/domain/usecases/toggle_task_completion_usecase.dart';
import 'package:smart_task_manager/features/tasks/domain/usecases/update_task_usecase.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository mockRepository;
  final testDate = DateTime(2026, 8, 20);
  final tTask = TaskEntity(
    id: 1,
    userId: 'user-1',
    title: 'Test Task',
    description: 'Description',
    priority: TaskPriority.high,
    category: TaskCategory.work,
    dueDate: testDate,
    isCompleted: false,
    createdAt: testDate,
    updatedAt: testDate,
  );

  setUp(() {
    mockRepository = MockTaskRepository();
  });

  test('GetTasksUseCase calls repository.getTasks', () async {
    when(() => mockRepository.getTasks(userId: any(named: 'userId'), skip: any(named: 'skip'), limit: any(named: 'limit')))
        .thenAnswer((_) async => [tTask]);
    final useCase = GetTasksUseCase(mockRepository);

    final result = await useCase();

    expect(result, [tTask]);
    verify(() => mockRepository.getTasks(userId: null, skip: 0, limit: 10)).called(1);
  });

  test('CreateTaskUseCase calls repository.createTask', () async {
    when(() => mockRepository.createTask(tTask)).thenAnswer((_) async => tTask);
    final useCase = CreateTaskUseCase(mockRepository);

    final result = await useCase(tTask);

    expect(result, tTask);
    verify(() => mockRepository.createTask(tTask)).called(1);
  });

  test('UpdateTaskUseCase calls repository.updateTask', () async {
    when(() => mockRepository.updateTask(tTask)).thenAnswer((_) async => tTask);
    final useCase = UpdateTaskUseCase(mockRepository);

    final result = await useCase(tTask);

    expect(result, tTask);
    verify(() => mockRepository.updateTask(tTask)).called(1);
  });

  test('DeleteTaskUseCase calls repository.deleteTask', () async {
    when(() => mockRepository.deleteTask(1, userId: any(named: 'userId'))).thenAnswer((_) async {});
    final useCase = DeleteTaskUseCase(mockRepository);

    await useCase(1);

    verify(() => mockRepository.deleteTask(1)).called(1);
  });

  test('ToggleTaskCompletionUseCase calls repository.toggleTaskCompletion', () async {
    when(() => mockRepository.toggleTaskCompletion(1, userId: any(named: 'userId'))).thenAnswer((_) async => tTask);
    final useCase = ToggleTaskCompletionUseCase(mockRepository);

    final result = await useCase(1);

    expect(result, tTask);
    verify(() => mockRepository.toggleTaskCompletion(1)).called(1);
  });

  test('SyncTasksUseCase calls repository.syncPendingTasks', () async {
    when(() => mockRepository.syncPendingTasks(userId: any(named: 'userId'))).thenAnswer((_) async {});
    final useCase = SyncTasksUseCase(mockRepository);

    await useCase();

    verify(() => mockRepository.syncPendingTasks(userId: null)).called(1);
  });
}
