import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  static const String _prefKey = 'saved_theme_mode';
  final ProfileRepository? profileRepository;
  String? _currentUserId;

  ThemeCubit({this.profileRepository}) : super(ThemeMode.system) {
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null) {
        setThemeFromString(saved, persist: false);
      }
    } catch (_) {}
  }

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

  void setThemeFromString(String? modeStr, {bool persist = true}) {
    ThemeMode mode;
    switch (modeStr?.toLowerCase()) {
      case 'light':
        mode = ThemeMode.light;
        break;
      case 'dark':
        mode = ThemeMode.dark;
        break;
      case 'system':
      default:
        mode = ThemeMode.system;
        break;
    }
    emit(mode);
    if (persist) {
      _persistTheme(mode);
    }
  }

  void _persistTheme(ThemeMode mode) async {
    final modeStr = mode == ThemeMode.dark
        ? 'dark'
        : (mode == ThemeMode.light ? 'light' : 'system');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, modeStr);
    } catch (_) {}

    if (_currentUserId != null &&
        _currentUserId!.isNotEmpty &&
        _currentUserId != 'guest_user') {
      profileRepository?.updateUserProfile(
        userId: _currentUserId!,
        themeMode: modeStr,
      );
    }
  }
}
