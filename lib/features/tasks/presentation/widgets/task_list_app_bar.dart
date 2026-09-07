import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import 'sync_status_indicator.dart';

class TaskListAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TaskListAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      scrolledUnderElevation: 0,
      title: Text(
        'Smart Tasks',
        style: TextStyle(
          color:
              isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        const SyncStatusIndicator(),
        const SizedBox(width: 4),
        BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, _) => IconButton(
            tooltip:
                isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
            onPressed: () => context.read<ThemeCubit>().toggleTheme(),
          ),
        ),
        BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, profileState) {
            final authUser = context.watch<AuthBloc>().state.user;
            final profile = profileState.profile;

            final displayName = (profile != null &&
                    profile.name.isNotEmpty &&
                    profile.name != 'User')
                ? profile.name
                : (authUser?.displayName?.isNotEmpty == true
                    ? authUser!.displayName!
                    : (profile?.email.isNotEmpty == true
                        ? profile!.email.split('@').first
                        : (authUser?.email?.isNotEmpty == true
                            ? authUser!.email!.split('@').first
                            : 'User')));

            final email = (profile != null && profile.email.isNotEmpty)
                ? profile.email
                : (authUser?.email ?? '');

            final photoUrl = profile?.photoUrl;
            final initial =
                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

            return PopupMenuButton<String>(
              tooltip: 'Account',
              color:
                  isDark ? AppColors.darkSurface : AppColors.lightSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              offset: const Offset(0, 48),
              icon: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary,
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                    ? NetworkImage(photoUrl)
                    : null,
                child: (photoUrl != null && photoUrl.isNotEmpty)
                    ? null
                    : Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
              itemBuilder: (ctx) => [
                PopupMenuItem<String>(
                  enabled: false,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary,
                        backgroundImage:
                            (photoUrl != null && photoUrl.isNotEmpty)
                                ? NetworkImage(photoUrl)
                                : null,
                        child: (photoUrl != null && photoUrl.isNotEmpty)
                            ? null
                            : Text(
                                initial,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            if (email.isNotEmpty)
                              Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 18,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'User Profile',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded,
                          size: 18, color: AppColors.error),
                      SizedBox(width: 8),
                      Text(
                        'Sign Out',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'profile') {
                  context.push('/profile');
                } else if (value == 'logout') {
                  context.read<AuthBloc>().add(const SignOutEvent());
                }
              },
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
