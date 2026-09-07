import '../entities/user_profile_entity.dart';
import '../repositories/profile_repository.dart';

class GetUserProfileUseCase {
  final ProfileRepository repository;
  GetUserProfileUseCase(this.repository);

  Future<UserProfileEntity?> call(String userId) async {
    return await repository.getUserProfile(userId);
  }
}

class SaveUserProfileUseCase {
  final ProfileRepository repository;
  SaveUserProfileUseCase(this.repository);

  Future<void> call(UserProfileEntity profile) async {
    await repository.saveUserProfile(profile);
  }
}

class UpdateUserProfileUseCase {
  final ProfileRepository repository;
  UpdateUserProfileUseCase(this.repository);

  Future<void> call({
    required String userId,
    String? name,
    String? themeMode,
    String? photoUrl,
    bool removePhoto = false,
  }) async {
    await repository.updateUserProfile(
      userId: userId,
      name: name,
      themeMode: themeMode,
      photoUrl: photoUrl,
      removePhoto: removePhoto,
    );
  }
}
