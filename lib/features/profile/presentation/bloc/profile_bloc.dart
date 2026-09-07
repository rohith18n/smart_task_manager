import 'package:firebase_auth/firebase_auth.dart';
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
    on<ThemePreferenceChangedEvent>(_onThemePreferenceChanged);
  }

  void _onThemePreferenceChanged(
    ThemePreferenceChangedEvent event,
    Emitter<ProfileState> emit,
  ) {
    if (state.profile != null) {
      emit(state.copyWith(
        profile: state.profile!.copyWith(themeMode: event.themeMode),
      ));
    }
  }

  Future<void> _onLoadProfile(
    LoadProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      if (event.userId == 'guest_user') {
        emit(state.copyWith(
          status: ProfileStatus.success,
          profile: UserProfileEntity(
            userId: 'guest_user',
            name: event.fallbackName ?? 'Guest User',
            email: event.fallbackEmail ?? '',
            createdAt: DateTime.now(),
            themeMode: 'system',
          ),
        ));
        return;
      }

      UserProfileEntity? profile;
      try {
        profile = await getUserProfileUseCase(event.userId);
      } catch (_) {}

      if (profile != null) {
        // Use existing Firestore profile, filling any missing field with fallback
        final resolvedName = (profile.name.isNotEmpty && profile.name != 'User')
            ? profile.name
            : (event.fallbackName != null && event.fallbackName!.isNotEmpty
                ? event.fallbackName!
                : profile.name);
        final resolvedEmail = profile.email.isNotEmpty
            ? profile.email
            : (event.fallbackEmail ?? '');
        profile = profile.copyWith(
          name: resolvedName,
          email: resolvedEmail,
        );
      } else {
        // First-time initialization in Firestore
        final name = (event.fallbackName != null && event.fallbackName!.isNotEmpty)
            ? event.fallbackName!
            : (event.fallbackEmail != null && event.fallbackEmail!.isNotEmpty
                ? event.fallbackEmail!.split('@').first
                : 'User');
        profile = UserProfileEntity(
          userId: event.userId,
          name: name,
          email: event.fallbackEmail ?? '',
          createdAt: DateTime.now(),
          themeMode: 'system',
        );
        try {
          await saveUserProfileUseCase(profile);
        } catch (_) {}
      }

      emit(state.copyWith(
        status: ProfileStatus.success,
        profile: profile,
      ));
    } catch (e) {
      // Graceful fallback to guarantee UI always has active user details
      final fallbackProfile = UserProfileEntity(
        userId: event.userId,
        name: event.fallbackName ??
            (event.fallbackEmail?.split('@').first ?? 'User'),
        email: event.fallbackEmail ?? '',
        createdAt: DateTime.now(),
        themeMode: 'system',
      );
      emit(state.copyWith(
        status: ProfileStatus.success,
        profile: fallbackProfile,
      ));
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      if (event.userId != 'guest_user') {
        try {
          await updateUserProfileUseCase(
            userId: event.userId,
            name: event.name,
            themeMode: event.themeMode,
            photoUrl: event.photoUrl,
            removePhoto: event.removePhoto,
          );
        } catch (_) {}

        try {
          final firebaseUser = FirebaseAuth.instance.currentUser;
          if (firebaseUser != null && firebaseUser.uid == event.userId) {
            if (event.name != null && event.name!.isNotEmpty) {
              await firebaseUser.updateDisplayName(event.name);
            }
            if (event.removePhoto) {
              await firebaseUser.updatePhotoURL(null);
            } else if (event.photoUrl != null) {
              await firebaseUser.updatePhotoURL(event.photoUrl);
            }
          }
        } catch (_) {}
      }

      final current = state.profile ??
          UserProfileEntity(
            userId: event.userId,
            name: event.name ?? 'User',
            email: '',
            createdAt: DateTime.now(),
            themeMode: event.themeMode ?? 'system',
          );
      final updated = current.copyWith(
        name: event.name,
        themeMode: event.themeMode,
        photoUrl: () =>
            event.removePhoto ? null : (event.photoUrl ?? current.photoUrl),
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
