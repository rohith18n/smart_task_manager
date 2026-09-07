import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/user_profile_entity.dart';

abstract class ProfileRemoteDataSource {
  Future<UserProfileEntity?> getUserProfile(String userId);
  Future<void> saveUserProfile(UserProfileEntity profile);
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? themeMode,
  });
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final FirebaseFirestore? firestore;

  ProfileRemoteDataSourceImpl({this.firestore});

  FirebaseFirestore get _firestore {
    try {
      return firestore ?? FirebaseFirestore.instance;
    } catch (e) {
      throw ServerException('Firebase is not initialized: $e');
    }
  }

  DocumentReference<Map<String, dynamic>> _userDoc(String userId) {
    return _firestore
        .collection(AppConstants.firestoreUsersCollection)
        .doc(userId);
  }

  @override
  Future<UserProfileEntity?> getUserProfile(String userId) async {
    try {
      final doc = await _userDoc(userId).get();
      if (doc.exists && doc.data() != null) {
        return UserProfileEntity.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw ServerException('Failed to fetch user profile: $e');
    }
  }

  @override
  Future<void> saveUserProfile(UserProfileEntity profile) async {
    try {
      await _userDoc(profile.userId).set(
        profile.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      throw ServerException('Failed to save user profile: $e');
    }
  }

  @override
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? themeMode,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (themeMode != null) updates['themeMode'] = themeMode;

      if (updates.isNotEmpty) {
        await _userDoc(userId).set(updates, SetOptions(merge: true));
      }
    } catch (e) {
      throw ServerException('Failed to update user profile: $e');
    }
  }
}
