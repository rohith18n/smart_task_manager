import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final ProfileRepository? profileRepository;
  String? _currentUserId;

  ThemeCubit({this.profileRepository}) : super(ThemeMode.system);

  void setUserId(String? userId) {
    _currentUserId = userId;
  }

  void toggleTheme() {
    final nextMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setTheme(nextMode);
  }

  void setTheme(ThemeMode mode) {
    emit(mode);
    _persistTheme(mode);
  }

  void setThemeFromString(String? modeStr) {
    switch (modeStr?.toLowerCase()) {
      case 'light':
        emit(ThemeMode.light);
        break;
      case 'dark':
        emit(ThemeMode.dark);
        break;
      case 'system':
      default:
        emit(ThemeMode.system);
        break;
    }
  }

  void _persistTheme(ThemeMode mode) {
    if (_currentUserId != null && _currentUserId!.isNotEmpty && _currentUserId != 'guest_user') {
      final modeStr = mode == ThemeMode.dark
          ? 'dark'
          : (mode == ThemeMode.light ? 'light' : 'system');
      profileRepository?.updateUserProfile(
        userId: _currentUserId!,
        themeMode: modeStr,
      );
    }
  }
}
