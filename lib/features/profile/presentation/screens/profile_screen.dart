import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../widgets/profile_avatar_header.dart';
import '../widgets/profile_picture_picker_sheet.dart';
import '../widgets/profile_theme_preference_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  String _selectedTheme = 'system';
  String? _selectedPhotoUrl;
  bool _isPhotoModified = false;
  bool _hasPopulatedFromState = false;
  bool _isSubmitting = false;

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();

    final currentThemeMode = context.read<ThemeCubit>().state;
    _selectedTheme = _themeModeToString(currentThemeMode);

    final authUser = context.read<AuthBloc>().state.user;
    final firebaseUser = () {
      try {
        return FirebaseAuth.instance.currentUser;
      } catch (_) {
        return null;
      }
    }();

    final userId = authUser?.id ?? firebaseUser?.uid;
    final fallbackEmail = authUser?.email ?? firebaseUser?.email ?? '';
    final fallbackName = authUser?.displayName ??
        firebaseUser?.displayName ??
        (fallbackEmail.isNotEmpty ? fallbackEmail.split('@').first : '');

    final currentProfile = context.read<ProfileBloc>().state.profile;

    if (currentProfile != null) {
      _nameController.text = currentProfile.name;
      _selectedTheme = currentProfile.themeMode;
      _selectedPhotoUrl = currentProfile.photoUrl;
      _hasPopulatedFromState = true;
    } else {
      if (fallbackName.isNotEmpty) {
        _nameController.text = fallbackName;
      }
      if (userId != null && userId.isNotEmpty) {
        context.read<ProfileBloc>().add(
              LoadProfileEvent(
                userId,
                fallbackEmail: fallbackEmail,
                fallbackName: fallbackName,
              ),
            );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _openPhotoPicker(BuildContext context, String? currentPhotoUrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProfilePicturePickerSheet(
        currentPhotoUrl: _selectedPhotoUrl ?? currentPhotoUrl,
        onPhotoSelected: (newUrl) {
          setState(() {
            _selectedPhotoUrl = newUrl;
            _isPhotoModified = true;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authUser = context.watch<AuthBloc>().state.user;
    final firebaseUser = () {
      try {
        return FirebaseAuth.instance.currentUser;
      } catch (_) {
        return null;
      }
    }();

    final fallbackEmail = authUser?.email ?? firebaseUser?.email;
    final fallbackName = authUser?.displayName ??
        firebaseUser?.displayName ??
        (fallbackEmail != null && fallbackEmail.isNotEmpty
            ? fallbackEmail.split('@').first
            : '');

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        scrolledUnderElevation: 0,
        title: Text(
          'User Profile',
          style: TextStyle(
            color:
                isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state.status == ProfileStatus.success) {
            if (_isSubmitting) {
              _isSubmitting = false;
              AppFeedback.showSuccess(
                context,
                title: 'Profile Saved',
                message:
                    'Your profile details and theme preferences have been synced with Firestore.',
              );
            }
            if (state.profile != null) {
              if (!_hasPopulatedFromState) {
                _nameController.text = state.profile!.name;
                if (!_isPhotoModified) {
                  _selectedPhotoUrl = state.profile!.photoUrl;
                }
                _hasPopulatedFromState = true;
              }
              _selectedTheme = state.profile!.themeMode;
            }
          } else if (state.status == ProfileStatus.failure) {
            _isSubmitting = false;
            AppFeedback.showError(
              context,
              title: 'Update Notice',
              message: state.errorMessage ??
                  'Could not sync with Firestore. Saved locally.',
            );
          }
        },
        builder: (context, state) {
          final profile = state.profile;

          if (profile != null && !_hasPopulatedFromState) {
            _nameController.text = profile.name;
            _selectedTheme = profile.themeMode;
            if (!_isPhotoModified) {
              _selectedPhotoUrl = profile.photoUrl;
            }
            _hasPopulatedFromState = true;
          }

          if (state.status == ProfileStatus.loading &&
              profile == null &&
              _nameController.text.isEmpty &&
              (fallbackEmail == null || fallbackEmail.isEmpty)) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final isLoading = state.status == ProfileStatus.loading;
          final activePhotoUrl = _isPhotoModified
              ? _selectedPhotoUrl
              : (profile?.photoUrl ?? _selectedPhotoUrl);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  ProfileAvatarHeader(
                    profile: profile,
                    customPhotoUrl: activePhotoUrl,
                    fallbackName: fallbackName.isNotEmpty
                        ? fallbackName
                        : _nameController.text,
                    fallbackEmail: fallbackEmail,
                    onEditPhoto: () =>
                        _openPhotoPicker(context, profile?.photoUrl),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Full Name',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter your name',
                            prefixIcon:
                                const Icon(Icons.person_outline, size: 20),
                            filled: true,
                            fillColor: isDark
                                ? AppColors.darkInputFill
                                : AppColors.lightInputFill,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ProfileThemePreferenceCard(
                    selectedTheme: _selectedTheme,
                    onThemeChanged: (chosen) {
                      setState(() {
                        _selectedTheme = chosen;
                      });
                      context.read<ThemeCubit>().setThemeFromString(chosen);
                      final effectiveUserId = profile?.userId ??
                          authUser?.id ??
                          firebaseUser?.uid;
                      if (effectiveUserId != null &&
                          effectiveUserId != 'guest_user') {
                        context.read<ProfileBloc>().add(
                              UpdateProfileEvent(
                                userId: effectiveUserId,
                                themeMode: chosen,
                              ),
                            );
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      onPressed: isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                FocusScope.of(context).unfocus();
                                setState(() {
                                  _isSubmitting = true;
                                });
                                final effectiveUserId = profile?.userId ??
                                    authUser?.id ??
                                    firebaseUser?.uid ??
                                    'guest_user';

                                context.read<ProfileBloc>().add(
                                      UpdateProfileEvent(
                                        userId: effectiveUserId,
                                        name: _nameController.text.trim(),
                                        themeMode: _selectedTheme,
                                        photoUrl: _selectedPhotoUrl,
                                        removePhoto: _isPhotoModified &&
                                            _selectedPhotoUrl == null,
                                      ),
                                    );
                                context
                                    .read<ThemeCubit>()
                                    .setThemeFromString(_selectedTheme);
                              }
                            },
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
