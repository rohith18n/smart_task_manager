import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UserProfileEntity?> getUserProfile(String userId) async {
    return await remoteDataSource.getUserProfile(userId);
  }

  @override
  Future<void> saveUserProfile(UserProfileEntity profile) async {
    await remoteDataSource.saveUserProfile(profile);
  }

  @override
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? themeMode,
    String? photoUrl,
    bool removePhoto = false,
  }) async {
    await remoteDataSource.updateUserProfile(
      userId: userId,
      name: name,
      themeMode: themeMode,
      photoUrl: photoUrl,
      removePhoto: removePhoto,
    );
  }
}
