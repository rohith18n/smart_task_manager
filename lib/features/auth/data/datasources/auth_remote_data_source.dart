import 'dart:async';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthRemoteDataSource {
  Stream<UserEntity?> get authStateChanges;
  Future<UserEntity?> getCurrentUser();
  Future<UserEntity> signInWithEmail(String email, String password);
  Future<UserEntity> signUpWithEmail(String email, String password, {String? displayName});
  Future<UserEntity> signInAnonymously();
  Future<void> signOut();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  static const String _guestModeKey = 'is_guest_session';
  final StreamController<UserEntity?> _authController =
      StreamController<UserEntity?>.broadcast();

  AuthRemoteDataSourceImpl({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance {
    _initAuthStream();
  }

  void _initAuthStream() {
    _firebaseAuth.authStateChanges().listen(
      (user) async {
        if (user != null) {
          _authController.add(_mapFirebaseUser(user));
        } else {
          try {
            final prefs = await SharedPreferences.getInstance();
            final isGuest = prefs.getBool(_guestModeKey) ?? false;
            if (isGuest) {
              _authController.add(const UserEntity(
                id: 'guest_user',
                displayName: 'Guest User',
                isAnonymous: true,
              ));
              return;
            }
          } catch (_) {}
          _authController.add(null);
        }
      },
      onError: (_) => _authController.add(null),
    );
  }

  @override
  Stream<UserEntity?> get authStateChanges => _authController.stream;

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isGuest = prefs.getBool(_guestModeKey) ?? false;
      if (isGuest) {
        return const UserEntity(
          id: 'guest_user',
          displayName: 'Guest User',
          isAnonymous: true,
        );
      }
    } catch (_) {}

    final user = _firebaseAuth.currentUser;
    if (user != null) {
      return _mapFirebaseUser(user);
    }
    return null;
  }

  @override
  Future<UserEntity> signInWithEmail(String email, String password) async {
    developer.log('🔑 [AUTH] Attempting sign in as $email', name: 'Auth');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_guestModeKey, false);

      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException('Authentication failed. No user returned.');
      }
      developer.log(
        '✅ [AUTH SUCCESS] Logged in: ${user.email} (UID: ${user.uid})',
        name: 'Auth',
      );
      return _mapFirebaseUser(user)!;
    } on FirebaseAuthException catch (e) {
      developer.log(
        '❌ [AUTH ERROR] ${e.code}: ${e.message}',
        name: 'Auth',
        error: e,
      );
      throw AuthException(_mapFirebaseAuthError(e), e.code);
    } catch (e) {
      developer.log('❌ [AUTH ERROR] $e', name: 'Auth', error: e);
      if (e is AppException) rethrow;
      throw AuthException('Failed to sign in: $e');
    }
  }

  @override
  Future<UserEntity> signUpWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async {
    developer.log('📝 [AUTH] Attempting registration for $email', name: 'Auth');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_guestModeKey, false);

      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException('Registration failed. No user returned.');
      }
      if (displayName != null && displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
        await user.reload();
      }
      developer.log(
        '✅ [AUTH SUCCESS] Registered: ${user.email} (UID: ${user.uid})',
        name: 'Auth',
      );
      return _mapFirebaseUser(_firebaseAuth.currentUser ?? user)!;
    } on FirebaseAuthException catch (e) {
      developer.log(
        '❌ [AUTH ERROR] ${e.code}: ${e.message}',
        name: 'Auth',
        error: e,
      );
      throw AuthException(_mapFirebaseAuthError(e), e.code);
    } catch (e) {
      developer.log('❌ [AUTH ERROR] $e', name: 'Auth', error: e);
      if (e is AppException) rethrow;
      throw AuthException('Failed to create account: $e');
    }
  }

  @override
  Future<UserEntity> signInAnonymously() async {
    const guestUser = UserEntity(
      id: 'guest_user',
      displayName: 'Guest User',
      isAnonymous: true,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_guestModeKey, true);
    } catch (_) {}
    _authController.add(guestUser);
    return guestUser;
  }

  @override
  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_guestModeKey, false);
      _authController.add(null);
      await _firebaseAuth.signOut().catchError((_) {});
    } catch (e) {
      _authController.add(null);
      throw ServerException('Failed to sign out: $e');
    }
  }

  UserEntity? _mapFirebaseUser(User? user) {
    if (user == null) return null;
    return UserEntity(
      id: user.uid,
      email: user.email,
      displayName: user.displayName ?? (user.isAnonymous ? 'Guest User' : user.email?.split('@').first),
      isAnonymous: user.isAnonymous,
      createdAt: user.metadata.creationTime,
    );
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    final code = e.code.toLowerCase();
    final message = (e.message ?? '').toLowerCase();

    if (code == 'user-not-found' || message.contains('user not found') || message.contains('no user record')) {
      return 'No account found with this email. Please sign up.';
    } else if (code == 'wrong-password') {
      return 'Incorrect password. Please try again.';
    } else if (code == 'invalid-credential' ||
        code == 'invalid_login_credentials' ||
        message.contains('auth credential') ||
        message.contains('credential is incorrect')) {
      return 'Incorrect email or password. Please check your credentials or sign up.';
    } else if (code == 'email-already-in-use' || message.contains('already in use')) {
      return 'An account already exists for this email. Please sign in instead.';
    } else if (code == 'invalid-email') {
      return 'Please enter a valid email address.';
    } else if (code == 'weak-password') {
      return 'Password is too weak. Please use at least 6 characters.';
    } else if (code == 'operation-not-allowed') {
      return 'Email/Password sign-in is not enabled in Firebase Console.';
    } else if (code == 'user-disabled') {
      return 'This account has been disabled. Please contact support.';
    } else if (code == 'too-many-requests') {
      return 'Too many attempts. Please wait a moment and try again.';
    } else if (code == 'network-request-failed' || message.contains('network')) {
      return 'Network error. Please check your internet connection.';
    }
    return e.message ?? 'Authentication error ($code).';
  }
}
