import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_task_manager/core/theme/theme_cubit.dart';
import 'package:smart_task_manager/features/profile/domain/repositories/profile_repository.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockProfileRepository mockProfileRepository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockProfileRepository = MockProfileRepository();
    when(() => mockProfileRepository.updateUserProfile(
          userId: any(named: 'userId'),
          themeMode: any(named: 'themeMode'),
        )).thenAnswer((_) async {});
  });

  test('ThemeCubit persists theme to Firestore when userId is set and theme is toggled',
      () async {
    final cubit = ThemeCubit(profileRepository: mockProfileRepository);
    cubit.setUserId('user-456');

    // Toggle theme from default/light to dark
    cubit.toggleTheme();
    expect(cubit.state, ThemeMode.dark);
    await pumpEventQueue();

    verify(() => mockProfileRepository.updateUserProfile(
          userId: 'user-456',
          themeMode: 'dark',
        )).called(1);

    // Toggle theme from dark to light
    cubit.toggleTheme();
    expect(cubit.state, ThemeMode.light);
    await pumpEventQueue();

    verify(() => mockProfileRepository.updateUserProfile(
          userId: 'user-456',
          themeMode: 'light',
        )).called(1);
  });

  test('ThemeCubit setThemeFromString updates Firestore when persist is true',
      () async {
    final cubit = ThemeCubit(profileRepository: mockProfileRepository);
    cubit.setUserId('user-789');

    cubit.setThemeFromString('dark', persist: true);
    expect(cubit.state, ThemeMode.dark);
    await pumpEventQueue();

    verify(() => mockProfileRepository.updateUserProfile(
          userId: 'user-789',
          themeMode: 'dark',
        )).called(1);

    // When persist is false (e.g. initial load from Firestore)
    cubit.setThemeFromString('light', persist: false);
    expect(cubit.state, ThemeMode.light);
    await pumpEventQueue();

    // Should NOT call updateUserProfile again
    verifyNever(() => mockProfileRepository.updateUserProfile(
          userId: 'user-789',
          themeMode: 'light',
        ));
  });
}
