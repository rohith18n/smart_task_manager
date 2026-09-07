import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_task_manager/core/di/injection_container.dart';
import 'package:smart_task_manager/core/services/notification_service.dart';
import 'package:smart_task_manager/core/error/exceptions.dart';
import 'package:smart_task_manager/core/theme/theme_cubit.dart';
import 'package:smart_task_manager/features/auth/domain/entities/user_entity.dart';
import 'package:smart_task_manager/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smart_task_manager/features/auth/presentation/bloc/auth_state.dart';
import 'package:smart_task_manager/features/tasks/domain/entities/task_entity.dart';
import 'package:smart_task_manager/features/tasks/domain/enums/task_category.dart';
import 'package:smart_task_manager/features/tasks/domain/enums/task_priority.dart';
import 'package:smart_task_manager/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:smart_task_manager/features/tasks/presentation/bloc/task_state.dart';
import 'package:smart_task_manager/features/tasks/presentation/screens/task_form_screen.dart';
import 'package:smart_task_manager/features/tasks/presentation/widgets/error_view_widget.dart';
import 'package:smart_task_manager/features/tasks/presentation/widgets/priority_badge_widget.dart';
import 'package:smart_task_manager/features/tasks/presentation/widgets/task_card_widget.dart';

class MockTaskBloc extends Mock implements TaskBloc {}
class MockAuthBloc extends Mock implements AuthBloc {}
class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockTaskBloc mockTaskBloc;
  late MockAuthBloc mockAuthBloc;
  late MockNotificationService mockNotificationService;

  setUpAll(() {
    mockNotificationService = MockNotificationService();
    if (!sl.isRegistered<NotificationService>()) {
      sl.registerLazySingleton<NotificationService>(() => mockNotificationService);
    }
  });

  setUp(() {
    mockTaskBloc = MockTaskBloc();
    mockAuthBloc = MockAuthBloc();

    when(() => mockTaskBloc.state).thenReturn(const TaskState());
    when(() => mockTaskBloc.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockAuthBloc.state).thenReturn(const AuthState(
      status: AuthStatus.authenticated,
      user: UserEntity(id: 'test-user-1', email: 'test@example.com', displayName: 'Test User'),
    ));
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  final testTask = TaskEntity(
    id: 1,
    userId: 'test-user-1',
    title: 'Financial Risk Assessment',
    description: 'Complete Q3 risk breakdown',
    priority: TaskPriority.high,
    category: TaskCategory.finance,
    dueDate: DateTime.now().add(const Duration(days: 2)),
    isCompleted: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    isSynced: true,
  );

  testWidgets('PriorityBadgeWidget renders priority label correctly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PriorityBadgeWidget(priority: TaskPriority.high),
        ),
      ),
    );

    expect(find.text('High'), findsOneWidget);
  });

  testWidgets('TaskCardWidget renders title and description', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<TaskBloc>.value(
          value: mockTaskBloc,
          child: Scaffold(
            body: TaskCardWidget(task: testTask),
          ),
        ),
      ),
    );

    expect(find.text('Financial Risk Assessment'), findsOneWidget);
    expect(find.text('Complete Q3 risk breakdown'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
    expect(find.text('Finance'), findsOneWidget);
    expect(find.byIcon(Icons.assignment_outlined), findsOneWidget);
  });

  testWidgets('TaskFormScreen shows validation error when title is empty', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<TaskBloc>.value(value: mockTaskBloc),
          ],
          child: const TaskFormScreen(),
        ),
      ),
    );

    final saveButton = find.widgetWithText(ElevatedButton, 'Create Task');
    expect(saveButton, findsOneWidget);

    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Please enter a task title'), findsOneWidget);
  });

  testWidgets('ErrorViewWidget renders NetworkException correctly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorViewWidget(
            error: const NetworkException(),
            message: 'No internet',
            onRetry: () {},
          ),
        ),
      ),
    );

    expect(find.text('No Internet Connection'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    expect(find.text('Retry Connection'), findsOneWidget);
  });

  testWidgets('ErrorViewWidget renders ServerException correctly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorViewWidget(
            error: const ServerException('Database unavailable', 500),
            message: 'Database unavailable',
            onRetry: () {},
          ),
        ),
      ),
    );

    expect(find.text('Server Error'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    expect(find.text('Database unavailable'), findsOneWidget);
  });

  testWidgets('ErrorViewWidget renders AuthException correctly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorViewWidget(
            error: const AuthException('Session expired', 'expired'),
            message: 'Session expired',
            onRetry: () {},
          ),
        ),
      ),
    );

    expect(find.text('Authentication Error'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
