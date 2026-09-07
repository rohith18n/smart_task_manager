import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ProfileThemePreferenceCard extends StatelessWidget {
  final String selectedTheme;
  final ValueChanged<String> onThemeChanged;

  const ProfileThemePreferenceCard({
    super.key,
    required this.selectedTheme,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.palette_outlined,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Theme Preference (Saved in Firestore)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'system',
                label: Text('System'),
                icon: Icon(Icons.brightness_auto, size: 16),
              ),
              ButtonSegment(
                value: 'light',
                label: Text('Light'),
                icon: Icon(Icons.light_mode, size: 16),
              ),
              ButtonSegment(
                value: 'dark',
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode, size: 16),
              ),
            ],
            selected: {selectedTheme},
            onSelectionChanged: (newSelection) {
              onThemeChanged(newSelection.first);
            },
          ),
        ],
      ),
    );
  }
}
