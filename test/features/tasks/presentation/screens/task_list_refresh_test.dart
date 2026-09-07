import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_task_manager/core/network/network_info.dart';
import 'package:smart_task_manager/core/theme/theme_cubit.dart';
import 'package:smart_task_manager/features/auth/domain/entities/user_entity.dart';
import 'package:smart_task_manager/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smart_task_manager/features/auth/presentation/bloc/auth_state.dart';
import 'package:smart_task_manager/features/tasks/domain/entities/task_entity.dart';
import 'package:smart_task_manager/features/tasks/domain/enums/task_category.dart';
import 'package:smart_task_manager/features/tasks/domain/enums/task_priority.dart';
import 'package:smart_task_manager/features/tasks/domain/usecases/create_task_usecase.dart';
import 'package:smart_task_manager/features/tasks/domain/usecases/delete_task_usecase.dart';
import 'package:smart_task_manager/features/tasks/domain/usecases/get_tasks_usecase.dart';
import 'package:smart_task_manager/features/tasks/domain/usecases/sync_tasks_usecase.dart';
import 'package:smart_task_manager/features/tasks/domain/usecases/toggle_task_completion_usecase.dart';
import 'package:smart_task_manager/features/tasks/domain/usecases/update_task_usecase.dart';
import 'package:smart_task_manager/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:smart_task_manager/features/tasks/presentation/bloc/task_event.dart';
import 'package:smart_task_manager/features/tasks/presentation/screens/task_list_screen.dart';

class MockGetTasksUseCase extends Mock implements GetTasksUseCase {}
class MockCreateTaskUseCase extends Mock implements CreateTaskUseCase {}
class MockUpdateTaskUseCase extends Mock implements UpdateTaskUseCase {}
class MockDeleteTaskUseCase extends Mock implements DeleteTaskUseCase {}
class MockToggleTaskCompletionUseCase extends Mock implements ToggleTaskCompletionUseCase {}
class MockSyncTasksUseCase extends Mock implements SyncTasksUseCase {}
class MockNetworkInfo extends Mock implements NetworkInfo {}
class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockGetTasksUseCase mockGetTasksUseCase;
  late MockSyncTasksUseCase mockSyncTasksUseCase;
  late MockNetworkInfo mockNetworkInfo;
  late MockAuthBloc mockAuthBloc;

  final sampleTask = TaskEntity(
    id: 1,
    title: 'Sample Task',
    description: 'Sample Description',
    userId: 'user-123',
    priority: TaskPriority.high,
    category: TaskCategory.work,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    mockGetTasksUseCase = MockGetTasksUseCase();
    mockSyncTasksUseCase = MockSyncTasksUseCase();
    mockNetworkInfo = MockNetworkInfo();
    mockAuthBloc = MockAuthBloc();

    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
    when(() => mockNetworkInfo.onConnectivityChanged)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockGetTasksUseCase(
          userId: any(named: 'userId'),
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
        )).thenAnswer((_) async => [sampleTask]);
    when(() => mockSyncTasksUseCase(userId: any(named: 'userId')))
        .thenAnswer((_) async {});
    when(() => mockAuthBloc.state).thenReturn(const AuthState(
      status: AuthStatus.authenticated,
      user: UserEntity(
        id: 'user-123',
        email: 'user@example.com',
        displayName: 'Test User',
      ),
    ));
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  testWidgets('RefreshIndicator and sync calls get tasks API with userId',
      (WidgetTester tester) async {
    final taskBloc = TaskBloc(
      getTasksUseCase: mockGetTasksUseCase,
      createTaskUseCase: MockCreateTaskUseCase(),
      updateTaskUseCase: MockUpdateTaskUseCase(),
      deleteTaskUseCase: MockDeleteTaskUseCase(),
      toggleTaskCompletionUseCase: MockToggleTaskCompletionUseCase(),
      syncTasksUseCase: mockSyncTasksUseCase,
      networkInfo: mockNetworkInfo,
    );

    taskBloc.add(const LoadTasksEvent('user-123'));

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<TaskBloc>.value(value: taskBloc),
        ],
        child: MaterialApp(
          home: TaskListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sample Task'), findsOneWidget);

    // Trigger pull to refresh gesture
    await tester.fling(
      find.text('Sample Task'),
      const Offset(0, 300),
      1000,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Verify sync & get tasks was executed with user-123
    verify(() => mockSyncTasksUseCase(userId: 'user-123')).called(greaterThanOrEqualTo(1));
    verify(() => mockGetTasksUseCase(
          userId: 'user-123',
          skip: 0,
          limit: any(named: 'limit'),
        )).called(greaterThanOrEqualTo(1));
  });
}
