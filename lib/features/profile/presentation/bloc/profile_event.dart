import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfileEvent extends ProfileEvent {
  final String userId;
  final String? fallbackEmail;
  final String? fallbackName;

  const LoadProfileEvent(this.userId, {this.fallbackEmail, this.fallbackName});

  @override
  List<Object?> get props => [userId, fallbackEmail, fallbackName];
}

class UpdateProfileEvent extends ProfileEvent {
  final String userId;
  final String? name;
  final String? themeMode;
  final String? photoUrl;
  final bool removePhoto;

  const UpdateProfileEvent({
    required this.userId,
    this.name,
    this.themeMode,
    this.photoUrl,
    this.removePhoto = false,
  });

  @override
  List<Object?> get props => [userId, name, themeMode, photoUrl, removePhoto];
}

class ThemePreferenceChangedEvent extends ProfileEvent {
  final String themeMode;
  const ThemePreferenceChangedEvent(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}
