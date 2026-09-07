import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_task_manager/core/theme/theme_cubit.dart';
import 'package:smart_task_manager/features/profile/domain/entities/user_profile_entity.dart';
import 'package:smart_task_manager/features/profile/domain/repositories/profile_repository.dart';
import 'package:smart_task_manager/features/profile/domain/usecases/profile_usecases.dart';
import 'package:smart_task_manager/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:smart_task_manager/features/profile/presentation/bloc/profile_event.dart';
import 'package:smart_task_manager/features/profile/presentation/bloc/profile_state.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}
class MockGetUserProfileUseCase extends Mock implements GetUserProfileUseCase {}
class MockSaveUserProfileUseCase extends Mock implements SaveUserProfileUseCase {}
class MockUpdateUserProfileUseCase extends Mock implements UpdateUserProfileUseCase {}

void main() {
  late MockProfileRepository mockProfileRepository;
  late MockGetUserProfileUseCase mockGetUserProfileUseCase;
  late MockSaveUserProfileUseCase mockSaveUserProfileUseCase;
  late MockUpdateUserProfileUseCase mockUpdateUserProfileUseCase;
  late ProfileBloc profileBloc;

  final now = DateTime(2025, 1, 1);
  final testProfile = UserProfileEntity(
    userId: 'user_123',
    name: 'Rohith Test',
    email: 'rohith@example.com',
    createdAt: now,
    themeMode: 'system',
  );

  setUp(() {
    mockProfileRepository = MockProfileRepository();
    mockGetUserProfileUseCase = MockGetUserProfileUseCase();
    mockSaveUserProfileUseCase = MockSaveUserProfileUseCase();
    mockUpdateUserProfileUseCase = MockUpdateUserProfileUseCase();

    profileBloc = ProfileBloc(
      getUserProfileUseCase: mockGetUserProfileUseCase,
      saveUserProfileUseCase: mockSaveUserProfileUseCase,
      updateUserProfileUseCase: mockUpdateUserProfileUseCase,
    );
  });

  tearDown(() {
    profileBloc.close();
  });

  group('Theme Synchronization Tests', () {
    test('ThemePreferenceChangedEvent updates ProfileBloc state themeMode', () async {
      when(() => mockGetUserProfileUseCase('user_123'))
          .thenAnswer((_) async => testProfile);

      profileBloc.add(const LoadProfileEvent('user_123'));
      await expectLater(
        profileBloc.stream,
        emitsInOrder([
          const ProfileState(status: ProfileStatus.loading),
          ProfileState(status: ProfileStatus.success, profile: testProfile),
        ]),
      );

      // Now dispatch ThemePreferenceChangedEvent
      profileBloc.add(const ThemePreferenceChangedEvent('dark'));
      await expectLater(
        profileBloc.stream,
        emits(
          ProfileState(
            status: ProfileStatus.success,
            profile: testProfile.copyWith(themeMode: 'dark'),
          ),
        ),
      );
    });

    test('ThemeCubit updates SharedPreferences and calls ProfileRepository on toggle', () async {
      when(() => mockProfileRepository.updateUserProfile(
            userId: any(named: 'userId'),
            name: any(named: 'name'),
            themeMode: any(named: 'themeMode'),
            photoUrl: any(named: 'photoUrl'),
            removePhoto: any(named: 'removePhoto'),
          )).thenAnswer((_) async {});

      final themeCubit = ThemeCubit(profileRepository: mockProfileRepository);
      themeCubit.setUserId('user_123');

      themeCubit.setTheme(ThemeMode.dark);
      expect(themeCubit.state, ThemeMode.dark);

      themeCubit.toggleTheme();
      expect(themeCubit.state, ThemeMode.light);

      await themeCubit.close();
    });
  });
}
