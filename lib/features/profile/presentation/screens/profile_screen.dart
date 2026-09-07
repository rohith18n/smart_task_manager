import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../widgets/profile_avatar_header.dart';
import '../widgets/profile_theme_preference_card.dart';

class ProfileScreen extends StatelessWidget {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final ValueNotifier<String> _themeNotifier = ValueNotifier<String>('system');
  final ValueNotifier<bool> _isInitialized = ValueNotifier<bool>(false);

  ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully!'),
                backgroundColor: AppColors.primary,
                duration: Duration(seconds: 2),
              ),
            );
          } else if (state.status == ProfileStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Update failed.'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final profile = state.profile;

          if (profile != null && !_isInitialized.value) {
            _nameController.text = profile.name;
            _themeNotifier.value = profile.themeMode;
            _isInitialized.value = true;
          }

          if (state.status == ProfileStatus.loading && profile == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  ProfileAvatarHeader(profile: profile),
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
                  ValueListenableBuilder<String>(
                    valueListenable: _themeNotifier,
                    builder: (context, currentTheme, _) {
                      return ProfileThemePreferenceCard(
                        selectedTheme: currentTheme,
                        onThemeChanged: (chosen) {
                          _themeNotifier.value = chosen;
                          context
                              .read<ThemeCubit>()
                              .setThemeFromString(chosen);
                        },
                      );
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
                      onPressed: state.status == ProfileStatus.loading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate() &&
                                  profile != null) {
                                context.read<ProfileBloc>().add(
                                      UpdateProfileEvent(
                                        userId: profile.userId,
                                        name: _nameController.text.trim(),
                                        themeMode: _themeNotifier.value,
                                      ),
                                    );
                                context
                                    .read<ThemeCubit>()
                                    .setThemeFromString(_themeNotifier.value);
                              }
                            },
                      child: state.status == ProfileStatus.loading
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
