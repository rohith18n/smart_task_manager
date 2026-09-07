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
import 'package:smart_task_manager/features/profile/presentation/bloc/profile_event.dart';
import 'package:smart_task_manager/features/profile/presentation/bloc/profile_state.dart';
import 'package:smart_task_manager/features/profile/presentation/screens/profile_screen.dart';

class MockAuthBloc extends Mock implements AuthBloc {}
class MockProfileBloc extends Mock implements ProfileBloc {}
class MockThemeCubit extends Mock implements ThemeCubit {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockProfileBloc mockProfileBloc;
  late MockThemeCubit mockThemeCubit;

  final now = DateTime(2025, 1, 1);
  final testProfile = UserProfileEntity(
    userId: 'user_123',
    name: 'Rohith Test',
    email: 'rohith@example.com',
    createdAt: now,
    themeMode: 'dark',
  );

  setUpAll(() {
    registerFallbackValue(const UpdateProfileEvent(
      userId: 'user_123',
      name: 'Rohith Test',
      themeMode: 'dark',
    ));
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockProfileBloc = MockProfileBloc();
    mockThemeCubit = MockThemeCubit();

    when(() => mockAuthBloc.state).thenReturn(const AuthState(
      status: AuthStatus.authenticated,
      user: UserEntity(
        id: 'user_123',
        email: 'rohith@example.com',
        displayName: 'Rohith Test',
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
  });

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<ProfileBloc>.value(value: mockProfileBloc),
        BlocProvider<ThemeCubit>.value(value: mockThemeCubit),
      ],
      child: const MaterialApp(
        home: ProfileScreen(),
      ),
    );
  }

  group('ProfileScreen Widget Tests', () {
    testWidgets('renders user profile details from state without duplicate name',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('User Profile'), findsWidgets);
      // Name is shown only once in the Full Name input field
      expect(find.text('Rohith Test'), findsOneWidget);
      expect(find.text('rohith@example.com'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('tapping Save Changes dispatches UpdateProfileEvent',
        (tester) async {
      when(() => mockProfileBloc.add(any())).thenReturn(null);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final saveButton = find.text('Save Changes');
      expect(saveButton, findsOneWidget);

      await tester.tap(saveButton);
      await tester.pump();

      verify(() => mockProfileBloc.add(any(that: isA<UpdateProfileEvent>())))
          .called(1);
    });
  });
}
