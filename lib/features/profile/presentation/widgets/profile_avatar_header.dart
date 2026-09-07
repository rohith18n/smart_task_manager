import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/user_profile_entity.dart';

class ProfileAvatarHeader extends StatelessWidget {
  final UserProfileEntity? profile;
  final String? fallbackName;
  final String? fallbackEmail;
  final String? customPhotoUrl;
  final VoidCallback? onEditPhoto;

  const ProfileAvatarHeader({
    super.key,
    this.profile,
    this.fallbackName,
    this.fallbackEmail,
    this.customPhotoUrl,
    this.onEditPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final displayName = (profile != null && profile!.name.isNotEmpty)
        ? profile!.name
        : (fallbackName != null && fallbackName!.isNotEmpty)
            ? fallbackName!
            : (fallbackEmail != null && fallbackEmail!.isNotEmpty)
                ? fallbackEmail!.split('@').first
                : 'User';

    final displayEmail = (profile != null && profile!.email.isNotEmpty)
        ? profile!.email
        : (fallbackEmail ?? '');

    final initial = (displayName.isNotEmpty) ? displayName[0].toUpperCase() : 'U';
    final activePhotoUrl = customPhotoUrl ?? profile?.photoUrl;

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: onEditPhoto,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(50),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _buildAvatarContent(activePhotoUrl, initial),
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBackground
                            : AppColors.lightBackground,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(40),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (displayEmail.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCard
                    : AppColors.lightCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Text(
                displayEmail,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            'Member since ${DateFormat.yMMMd().format(profile?.createdAt ?? DateTime.now())}',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent(String? photoUrl, String initial) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      if (photoUrl.startsWith('data:image')) {
        try {
          final commaIndex = photoUrl.indexOf(',');
          final base64Data = commaIndex != -1 ? photoUrl.substring(commaIndex + 1) : photoUrl;
          final bytes = base64Decode(base64Data);
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildInitialAvatar(initial),
          );
        } catch (_) {
          return _buildInitialAvatar(initial);
        }
      } else if (photoUrl.startsWith('http')) {
        return Image.network(
          photoUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitialAvatar(initial),
        );
      }
    }
    return _buildInitialAvatar(initial);
  }

  Widget _buildInitialAvatar(String initial) {
    return Container(
      color: AppColors.primary,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 38,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}
