import '../entities/user_profile_entity.dart';

abstract class ProfileRepository {
  Future<UserProfileEntity?> getUserProfile(String userId);
  Future<void> saveUserProfile(UserProfileEntity profile);
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? themeMode,
    String? photoUrl,
    bool removePhoto = false,
  });
}
