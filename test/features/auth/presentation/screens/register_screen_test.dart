import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_task_manager/core/theme/theme_cubit.dart';
import 'package:smart_task_manager/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smart_task_manager/features/auth/presentation/bloc/auth_event.dart';
import 'package:smart_task_manager/features/auth/presentation/bloc/auth_state.dart';
import 'package:smart_task_manager/features/auth/presentation/screens/register_screen.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late ThemeCubit themeCubit;

  setUpAll(() {
    registerFallbackValue(
      const SignUpWithEmailEvent(
        email: 'test@gmail.com',
        password: 'password123',
        displayName: 'Test User',
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
        home: RegisterScreen(),
      ),
    );
  }

  testWidgets('RegisterScreen allows tapping and entering all registration fields',
      (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final textFields = find.byType(TextFormField);
    expect(textFields, findsNWidgets(4));

    final nameField = textFields.at(0);
    final emailField = textFields.at(1);
    final passwordField = textFields.at(2);
    final confirmPasswordField = textFields.at(3);

    await tester.enterText(nameField, 'Test User');
    await tester.enterText(emailField, 'test@gmail.com');
    await tester.enterText(passwordField, 'test@123');
    await tester.enterText(confirmPasswordField, 'test@123');
    await tester.pump();

    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('test@gmail.com'), findsOneWidget);
    expect(find.text('test@123'), findsNWidgets(2));

    final signUpButton = find.widgetWithText(ElevatedButton, 'Create Account');
    expect(signUpButton, findsOneWidget);
    await tester.ensureVisible(signUpButton);
    await tester.pumpAndSettle();
    await tester.tap(signUpButton);
    await tester.pump();

    verify(
      () => mockAuthBloc.add(
        const SignUpWithEmailEvent(
          email: 'test@gmail.com',
          password: 'test@123',
          displayName: 'Test User',
        ),
      ),
    ).called(1);
  });
}
