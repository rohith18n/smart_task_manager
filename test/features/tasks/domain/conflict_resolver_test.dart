import 'package:flutter_test/flutter_test.dart';
import 'package:smart_task_manager/features/tasks/domain/entities/task_entity.dart';
import 'package:smart_task_manager/features/tasks/domain/enums/task_category.dart';
import 'package:smart_task_manager/features/tasks/domain/enums/task_priority.dart';
import 'package:smart_task_manager/features/tasks/domain/services/conflict_resolver.dart';

void main() {
  late ConflictResolver conflictResolver;

  setUp(() {
    conflictResolver = const ConflictResolver();
  });

  final baseTime = DateTime(2026, 8, 19, 10, 0, 0);

  final localTask = TaskEntity(
    id: 1,
    userId: 'user-1',
    title: 'Local Version Title',
    description: 'Edited locally',
    priority: TaskPriority.high,
    category: TaskCategory.work,
    dueDate: baseTime.add(const Duration(days: 1)),
    isCompleted: false,
    createdAt: baseTime,
    updatedAt: baseTime.add(const Duration(hours: 2)), // 12:00
    isSynced: false,
  );

  final olderRemoteTask = TaskEntity(
    id: 1,
    userId: 'user-1',
    title: 'Remote Old Title',
    description: 'Remote description',
    priority: TaskPriority.medium,
    category: TaskCategory.work,
    dueDate: baseTime.add(const Duration(days: 1)),
    isCompleted: false,
    createdAt: baseTime,
    updatedAt: baseTime.add(const Duration(hours: 1)), // 11:00
    isSynced: true,
  );

  final newerRemoteTask = TaskEntity(
    id: 1,
    userId: 'user-1',
    title: 'Remote Newer Title',
    description: 'Remote newer description',
    priority: TaskPriority.high,
    category: TaskCategory.work,
    dueDate: baseTime.add(const Duration(days: 1)),
    isCompleted: true,
    createdAt: baseTime,
    updatedAt: baseTime.add(const Duration(hours: 3)), // 13:00
    isSynced: true,
  );

  test('Last-Write-Wins: Local wins when local updatedAt is newer', () {
    final result = conflictResolver.resolve(
      localTask: localTask,
      remoteTask: olderRemoteTask,
    );

    expect(result.winner, 'LOCAL');
    expect(result.wasConflict, true);
    expect(result.resolvedTask.title, 'Local Version Title');
  });

  test('Last-Write-Wins: Remote wins when remote updatedAt is newer', () {
    final result = conflictResolver.resolve(
      localTask: localTask,
      remoteTask: newerRemoteTask,
    );

    expect(result.winner, 'REMOTE');
    expect(result.wasConflict, true);
    expect(result.resolvedTask.title, 'Remote Newer Title');
    expect(result.resolvedTask.isSynced, true);
  });
}
