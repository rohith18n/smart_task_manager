import 'package:equatable/equatable.dart';

class UserProfileEntity extends Equatable {
  final String userId;
  final String name;
  final String email;
  final DateTime createdAt;
  final String themeMode; // 'light', 'dark', 'system'
  final String? photoUrl;

  const UserProfileEntity({
    required this.userId,
    required this.name,
    required this.email,
    required this.createdAt,
    this.themeMode = 'system',
    this.photoUrl,
  });

  UserProfileEntity copyWith({
    String? userId,
    String? name,
    String? email,
    DateTime? createdAt,
    String? themeMode,
    String? Function()? photoUrl,
  }) {
    return UserProfileEntity(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      themeMode: themeMode ?? this.themeMode,
      photoUrl: photoUrl != null ? photoUrl() : this.photoUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
      'themeMode': themeMode,
      'photoUrl': photoUrl,
    };
  }

  factory UserProfileEntity.fromMap(Map<String, dynamic> map, String id) {
    return UserProfileEntity(
      userId: id,
      name: map['name'] as String? ?? 'User',
      email: map['email'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      themeMode: map['themeMode'] as String? ?? 'system',
      photoUrl: map['photoUrl'] as String?,
    );
  }

  @override
  List<Object?> get props => [userId, name, email, createdAt, themeMode, photoUrl];
}
