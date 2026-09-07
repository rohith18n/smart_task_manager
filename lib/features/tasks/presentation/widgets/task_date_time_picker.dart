import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';

class TaskDateTimePicker extends StatelessWidget {
  final DateTime selectedDueDate;
  final String? dueDateError;
  final bool isEditing;
  final ValueChanged<DateTime> onDateSelected;

  const TaskDateTimePicker({
    super.key,
    required this.selectedDueDate,
    required this.dueDateError,
    required this.isEditing,
    required this.onDateSelected,
  });

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDueDate.isBefore(now) ? now : selectedDueDate,
      firstDate:
          isEditing ? DateTime(2020) : DateTime(now.year, now.month, now.day),
      lastDate: DateTime(2040),
    );

    if (pickedDate == null || !context.mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedDueDate),
    );

    if (pickedTime == null || !context.mounted) return;

    final result = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    onDateSelected(result);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Due Date & Time',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _pickDate(context),
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkInputFill : AppColors.lightInputFill,
              borderRadius: BorderRadius.circular(28),
              border: dueDateError != null
                  ? Border.all(color: AppColors.error, width: 1.5)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: dueDateError != null
                      ? AppColors.error
                      : AppColors.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  DateFormatter.formatDateTime(selectedDueDate),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  'Change',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: dueDateError != null
                        ? AppColors.error
                        : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (dueDateError != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 18),
            child: Text(
              dueDateError!,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
