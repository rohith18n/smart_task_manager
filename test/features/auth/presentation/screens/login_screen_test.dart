import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_task_manager/core/theme/theme_cubit.dart';
import 'package:smart_task_manager/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smart_task_manager/features/auth/presentation/bloc/auth_event.dart';
import 'package:smart_task_manager/features/auth/presentation/bloc/auth_state.dart';
import 'package:smart_task_manager/features/auth/presentation/screens/login_screen.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late ThemeCubit themeCubit;

  setUpAll(() {
    registerFallbackValue(
      const SignInWithEmailEvent(
        email: 'test@gmail.com',
        password: 'password123',
      ),
    );
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    themeCubit = ThemeCubit();

    when(() => mockAuthBloc.state).thenReturn(
      const AuthState(status: AuthStatus.unauthenticated),
    );
  });

  tearDown(() {
    themeCubit.close();
  });

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<ThemeCubit>.value(value: themeCubit),
      ],
      child: MaterialApp(
        home: LoginScreen(),
      ),
    );
  }

  testWidgets('LoginScreen allows tapping and entering email and password',
      (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Find email and password fields
    final emailField = find.byType(TextFormField).first;
    final passwordField = find.byType(TextFormField).last;

    // Verify fields are present
    expect(emailField, findsOneWidget);
    expect(passwordField, findsOneWidget);

    // Tap and enter text into email field
    await tester.tap(emailField);
    await tester.enterText(emailField, 'test@gmail.com');
    await tester.pump();

    // Tap and enter text into password field
    await tester.tap(passwordField);
    await tester.enterText(passwordField, 'test@123');
    await tester.pump();

    // Verify text remains present after keyboard simulation
    expect(find.text('test@gmail.com'), findsOneWidget);
    expect(find.text('test@123'), findsOneWidget);

    // Tap the Sign In button
    final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
    expect(signInButton, findsOneWidget);
    await tester.tap(signInButton);
    await tester.pump();

    // Verify SignInWithEmailEvent was dispatched with the credentials
    verify(
      () => mockAuthBloc.add(
        const SignInWithEmailEvent(
          email: 'test@gmail.com',
          password: 'test@123',
        ),
      ),
    ).called(1);
  });
}
