import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_task_manager/core/constants/app_constants.dart';
import 'package:smart_task_manager/core/network/network_info.dart';
import 'package:smart_task_manager/features/tasks/data/datasources/task_local_data_source.dart';
import 'package:smart_task_manager/features/tasks/data/datasources/task_remote_data_source.dart';
import 'package:smart_task_manager/features/tasks/data/models/task_model.dart';
import 'package:smart_task_manager/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:smart_task_manager/features/tasks/domain/enums/task_category.dart';
import 'package:smart_task_manager/features/tasks/domain/enums/task_priority.dart';
import 'package:smart_task_manager/features/tasks/domain/services/conflict_resolver.dart';

class MockTaskLocalDataSource extends Mock implements TaskLocalDataSource {}
class MockTaskRemoteDataSource extends Mock implements TaskRemoteDataSource {}
class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late MockTaskLocalDataSource mockLocalDataSource;
  late MockTaskRemoteDataSource mockRemoteDataSource;
  late MockNetworkInfo mockNetworkInfo;
  late TaskRepositoryImpl repository;

  final testDate = DateTime(2026, 8, 20);
  final tTaskModel = TaskModel(
    id: 1,
    userId: 'user-1',
    title: 'Repo Test Task',
    description: 'Testing repository sync',
    priority: TaskPriority.medium,
    category: TaskCategory.work,
    dueDate: testDate,
    isCompleted: false,
    createdAt: testDate,
    updatedAt: testDate,
    isSynced: true,
    syncAction: 'NONE',
  );

  setUpAll(() {
    registerFallbackValue(tTaskModel);
  });

  setUp(() {
    mockLocalDataSource = MockTaskLocalDataSource();
    mockRemoteDataSource = MockTaskRemoteDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = TaskRepositoryImpl(
      localDataSource: mockLocalDataSource,
      remoteDataSource: mockRemoteDataSource,
      networkInfo: mockNetworkInfo,
      conflictResolver: const ConflictResolver(),
    );
  });

  group('getTasks', () {
    test('returns local tasks and checks connectivity', () async {
      when(() => mockLocalDataSource.getTasks(userId: any(named: 'userId')))
          .thenAnswer((_) async => [tTaskModel]);
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.getTasks(userId: 'user-1');

      expect(result, [tTaskModel]);
      verify(() => mockLocalDataSource.getTasks(userId: 'user-1')).called(1);
    });
  });

  group('createTask', () {
    test('saves with isSynced=true to remote and local when online', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.createTask(any())).thenAnswer((_) async => tTaskModel);
      when(() => mockLocalDataSource.insertTask(any())).thenAnswer((_) async {});

      final result = await repository.createTask(tTaskModel);

      expect(result.isSynced, true);
      verify(() => mockRemoteDataSource.createTask(any())).called(1);
      verify(() => mockLocalDataSource.insertTask(any(that: isA<TaskModel>().having(
            (m) => m.isSynced,
            'isSynced',
            true,
          )))).called(1);
    });

    test('saves with isSynced=false to local when offline', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(() => mockLocalDataSource.insertTask(any())).thenAnswer((_) async {});

      final result = await repository.createTask(tTaskModel);

      expect(result.isSynced, false);
      verifyZeroInteractions(mockRemoteDataSource);
      verify(() => mockLocalDataSource.insertTask(any(that: isA<TaskModel>()
          .having((m) => m.isSynced, 'isSynced', false)
          .having((m) => m.syncAction, 'syncAction', AppConstants.syncActionInsert)))).called(1);
    });
  });

  group('syncPendingTasks', () {
    test('syncs pending creations and pulls remote tasks when online', () async {
      final pendingTask = tTaskModel.copyWith(
        id: -99,
        isSynced: false,
        syncAction: AppConstants.syncActionInsert,
      );

      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockLocalDataSource.getPendingSyncTasks(userId: any(named: 'userId')))
          .thenAnswer((_) async => [pendingTask]);
      when(() => mockRemoteDataSource.createTask(any())).thenAnswer((_) async => tTaskModel);
      when(() => mockLocalDataSource.replaceTemporaryId(any(), any())).thenAnswer((_) async {});
      when(() => mockRemoteDataSource.getTasks(userId: any(named: 'userId'), skip: any(named: 'skip'), limit: any(named: 'limit')))
          .thenAnswer((_) async => [tTaskModel]);
      when(() => mockLocalDataSource.getTasks(userId: any(named: 'userId')))
          .thenAnswer((_) async => [tTaskModel]);
      when(() => mockLocalDataSource.saveFromRemote(any())).thenAnswer((_) async {});

      await repository.syncPendingTasks(userId: 'user-1');

      verify(() => mockRemoteDataSource.createTask(any())).called(1);
      verify(() => mockLocalDataSource.replaceTemporaryId(-99, any())).called(1);
      verify(() => mockRemoteDataSource.getTasks(userId: 'user-1', skip: 0, limit: 50)).called(1);
    });
  });
}
