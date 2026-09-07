import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_task_manager/features/profile/domain/entities/user_profile_entity.dart';
import 'package:smart_task_manager/features/profile/domain/usecases/profile_usecases.dart';
import 'package:smart_task_manager/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:smart_task_manager/features/profile/presentation/bloc/profile_event.dart';
import 'package:smart_task_manager/features/profile/presentation/bloc/profile_state.dart';

class MockGetUserProfileUseCase extends Mock implements GetUserProfileUseCase {}
class MockSaveUserProfileUseCase extends Mock implements SaveUserProfileUseCase {}
class MockUpdateUserProfileUseCase extends Mock implements UpdateUserProfileUseCase {}

void main() {
  late MockGetUserProfileUseCase mockGetUserProfileUseCase;
  late MockSaveUserProfileUseCase mockSaveUserProfileUseCase;
  late MockUpdateUserProfileUseCase mockUpdateUserProfileUseCase;

  setUpAll(() {
    registerFallbackValue(UserProfileEntity(
      userId: 'fallback',
      name: 'Fallback',
      email: 'fallback@test.com',
      createdAt: DateTime.now(),
    ));
  });

  setUp(() {
    mockGetUserProfileUseCase = MockGetUserProfileUseCase();
    mockSaveUserProfileUseCase = MockSaveUserProfileUseCase();
    mockUpdateUserProfileUseCase = MockUpdateUserProfileUseCase();
  });

  ProfileBloc buildBloc() {
    return ProfileBloc(
      getUserProfileUseCase: mockGetUserProfileUseCase,
      saveUserProfileUseCase: mockSaveUserProfileUseCase,
      updateUserProfileUseCase: mockUpdateUserProfileUseCase,
    );
  }

  final testProfile = UserProfileEntity(
    userId: 'user_123',
    name: 'Rohith',
    email: 'rohith@example.com',
    createdAt: DateTime(2025, 1, 1),
    themeMode: 'dark',
    photoUrl: 'https://example.com/avatar.jpg',
  );

  group('ProfileBloc Tests', () {
    test('initial state has status ProfileStatus.initial', () {
      final bloc = buildBloc();
      expect(bloc.state.status, ProfileStatus.initial);
      expect(bloc.state.profile, isNull);
    });

    blocTest<ProfileBloc, ProfileState>(
      'emits [loading, success] when LoadProfileEvent fetches existing profile from Firestore',
      build: () {
        when(() => mockGetUserProfileUseCase('user_123'))
            .thenAnswer((_) async => testProfile);
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadProfileEvent('user_123')),
      expect: () => [
        const ProfileState(status: ProfileStatus.loading),
        ProfileState(status: ProfileStatus.success, profile: testProfile),
      ],
      verify: (_) {
        verify(() => mockGetUserProfileUseCase('user_123')).called(1);
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [loading, success] and creates initial profile if none exists in Firestore',
      build: () {
        when(() => mockGetUserProfileUseCase('user_new'))
            .thenAnswer((_) async => null);
        when(() => mockSaveUserProfileUseCase(any()))
            .thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadProfileEvent(
        'user_new',
        fallbackEmail: 'newuser@test.com',
        fallbackName: 'New User',
      )),
      expect: () => [
        const ProfileState(status: ProfileStatus.loading),
        predicate<ProfileState>((state) {
          return state.status == ProfileStatus.success &&
              state.profile?.userId == 'user_new' &&
              state.profile?.email == 'newuser@test.com' &&
              state.profile?.name == 'New User';
        }),
      ],
      verify: (_) {
        verify(() => mockGetUserProfileUseCase('user_new')).called(1);
        verify(() => mockSaveUserProfileUseCase(any())).called(1);
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [loading, success] when UpdateProfileEvent updates name, theme, and photo in Firestore',
      build: () {
        when(() => mockUpdateUserProfileUseCase(
              userId: 'user_123',
              name: 'Updated Name',
              themeMode: 'light',
              photoUrl: 'https://example.com/new_avatar.png',
              removePhoto: false,
            )).thenAnswer((_) async {});
        return buildBloc();
      },
      seed: () => ProfileState(status: ProfileStatus.success, profile: testProfile),
      act: (bloc) => bloc.add(const UpdateProfileEvent(
        userId: 'user_123',
        name: 'Updated Name',
        themeMode: 'light',
        photoUrl: 'https://example.com/new_avatar.png',
      )),
      expect: () => [
        ProfileState(
          status: ProfileStatus.loading,
          profile: testProfile,
        ),
        predicate<ProfileState>((state) {
          return state.status == ProfileStatus.success &&
              state.profile?.name == 'Updated Name' &&
              state.profile?.themeMode == 'light' &&
              state.profile?.photoUrl == 'https://example.com/new_avatar.png';
        }),
      ],
      verify: (_) {
        verify(() => mockUpdateUserProfileUseCase(
              userId: 'user_123',
              name: 'Updated Name',
              themeMode: 'light',
              photoUrl: 'https://example.com/new_avatar.png',
              removePhoto: false,
            )).called(1);
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [loading, success] when UpdateProfileEvent removes profile photo',
      build: () {
        when(() => mockUpdateUserProfileUseCase(
              userId: 'user_123',
              name: 'Rohith',
              themeMode: 'dark',
              photoUrl: null,
              removePhoto: true,
            )).thenAnswer((_) async {});
        return buildBloc();
      },
      seed: () => ProfileState(status: ProfileStatus.success, profile: testProfile),
      act: (bloc) => bloc.add(const UpdateProfileEvent(
        userId: 'user_123',
        name: 'Rohith',
        themeMode: 'dark',
        removePhoto: true,
      )),
      expect: () => [
        ProfileState(
          status: ProfileStatus.loading,
          profile: testProfile,
        ),
        predicate<ProfileState>((state) {
          return state.status == ProfileStatus.success &&
              state.profile?.name == 'Rohith' &&
              state.profile?.photoUrl == null;
        }),
      ],
      verify: (_) {
        verify(() => mockUpdateUserProfileUseCase(
              userId: 'user_123',
              name: 'Rohith',
              themeMode: 'dark',
              photoUrl: null,
              removePhoto: true,
            )).called(1);
      },
    );
  });
}
