import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_task_manager/core/theme/theme_cubit.dart';
import 'package:smart_task_manager/features/auth/domain/entities/user_entity.dart';
import 'package:smart_task_manager/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smart_task_manager/features/auth/presentation/bloc/auth_state.dart';
import 'package:smart_task_manager/features/profile/domain/entities/user_profile_entity.dart';
import 'package:smart_task_manager/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:smart_task_manager/features/profile/presentation/bloc/profile_state.dart';
import 'package:smart_task_manager/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:smart_task_manager/features/tasks/presentation/bloc/task_state.dart';
import 'package:smart_task_manager/features/tasks/presentation/widgets/task_list_app_bar.dart';

class MockAuthBloc extends Mock implements AuthBloc {}
class MockProfileBloc extends Mock implements ProfileBloc {}
class MockThemeCubit extends Mock implements ThemeCubit {}
class MockTaskBloc extends Mock implements TaskBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockProfileBloc mockProfileBloc;
  late MockThemeCubit mockThemeCubit;
  late MockTaskBloc mockTaskBloc;

  final now = DateTime(2025, 1, 1);
  final testProfile = UserProfileEntity(
    userId: 'user_123',
    name: 'asdfasdf',
    email: 'test@gmail.com',
    createdAt: now,
    themeMode: 'dark',
  );

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockProfileBloc = MockProfileBloc();
    mockThemeCubit = MockThemeCubit();
    mockTaskBloc = MockTaskBloc();

    when(() => mockAuthBloc.state).thenReturn(const AuthState(
      status: AuthStatus.authenticated,
      user: UserEntity(
        id: 'user_123',
        email: 'test@gmail.com',
        displayName: 'Test',
      ),
    ));
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockProfileBloc.state).thenReturn(ProfileState(
      status: ProfileStatus.success,
      profile: testProfile,
    ));
    when(() => mockProfileBloc.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockThemeCubit.state).thenReturn(ThemeMode.dark);
    when(() => mockThemeCubit.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockTaskBloc.state).thenReturn(const TaskState(isOnline: true));
    when(() => mockTaskBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<ProfileBloc>.value(value: mockProfileBloc),
        BlocProvider<ThemeCubit>.value(value: mockThemeCubit),
        BlocProvider<TaskBloc>.value(value: mockTaskBloc),
      ],
      child: const MaterialApp(
        home: Scaffold(
          appBar: TaskListAppBar(),
        ),
      ),
    );
  }

  testWidgets('TaskListAppBar displays updated ProfileBloc name over auth fallback in popup menu',
      (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Smart Tasks'), findsOneWidget);

    // Open popup menu
    final accountButton = find.byType(PopupMenuButton<String>);
    expect(accountButton, findsOneWidget);
    await tester.tap(accountButton);
    await tester.pumpAndSettle();

    // Verify popup menu displays updated Firestore profile name "asdfasdf" instead of stale "Test"
    expect(find.text('asdfasdf'), findsOneWidget);
    expect(find.text('test@gmail.com'), findsOneWidget);
    expect(find.text('User Profile'), findsOneWidget);
    expect(find.text('Sign Out'), findsOneWidget);
  });
}
