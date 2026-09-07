import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/usecases/profile_usecases.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetUserProfileUseCase getUserProfileUseCase;
  final SaveUserProfileUseCase saveUserProfileUseCase;
  final UpdateUserProfileUseCase updateUserProfileUseCase;

  ProfileBloc({
    required this.getUserProfileUseCase,
    required this.saveUserProfileUseCase,
    required this.updateUserProfileUseCase,
  }) : super(const ProfileState()) {
    on<LoadProfileEvent>(_onLoadProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
  }

  Future<void> _onLoadProfile(
    LoadProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      UserProfileEntity? profile = await getUserProfileUseCase(event.userId);

      if (profile == null) {
        // First-time initialization in Firestore
        profile = UserProfileEntity(
          userId: event.userId,
          name: event.fallbackName ?? (event.fallbackEmail?.split('@').first ?? 'User'),
          email: event.fallbackEmail ?? '',
          createdAt: DateTime.now(),
          themeMode: 'system',
        );
        await saveUserProfileUseCase(profile);
      }

      emit(state.copyWith(
        status: ProfileStatus.success,
        profile: profile,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.failure,
        errorMessage: 'Failed to load user profile: $e',
      ));
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      await updateUserProfileUseCase(
        userId: event.userId,
        name: event.name,
        themeMode: event.themeMode,
      );

      final current = state.profile;
      final updated = current?.copyWith(
        name: event.name,
        themeMode: event.themeMode,
      );

      emit(state.copyWith(
        status: ProfileStatus.success,
        profile: updated,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.failure,
        errorMessage: 'Failed to update user profile: $e',
      ));
    }
  }
}
