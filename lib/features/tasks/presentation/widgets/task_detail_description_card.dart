import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class TaskDetailDescriptionCard extends StatelessWidget {
  final String? description;

  const TaskDetailDescriptionCard({super.key, this.description});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasDesc = description != null && description!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkInputFill : AppColors.lightInputFill,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            hasDesc ? description! : 'No description provided for this task.',
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              fontStyle: hasDesc ? FontStyle.normal : FontStyle.italic,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
