import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../domain/entities/task_entity.dart';

class TaskDetailMetadataSection extends StatelessWidget {
  final TaskEntity task;
  final bool isOverdue;

  const TaskDetailMetadataSection({
    super.key,
    required this.task,
    required this.isOverdue,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Task Metadata',
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkInputFill : AppColors.lightInputFill,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              if (task.dueDate != null) ...[
                _buildRow(
                  context: context,
                  icon: Icons.calendar_today_rounded,
                  label: 'Due Date',
                  trailing: Text(
                    DateFormatter.formatRelative(task.dueDate),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isOverdue ? AppColors.error : AppColors.primary,
                    ),
                  ),
                ),
                Divider(
                  height: 18,
                  color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                ),
              ],
              _buildRow(
                context: context,
                icon: Icons.add_circle_outline_rounded,
                label: 'Created Date',
                value: DateFormatter.formatDateTime(task.createdAt),
              ),
              Divider(
                height: 18,
                color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
              ),
              _buildRow(
                context: context,
                icon: Icons.update_rounded,
                label: 'Last Updated',
                value: DateFormatter.formatDateTime(task.updatedAt),
              ),
              Divider(
                height: 18,
                color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
              ),
              _buildRow(
                context: context,
                icon: Icons.cloud_sync_rounded,
                label: 'Sync Status',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      task.isSynced && task.syncAction == 'NONE'
                          ? 'Synced'
                          : 'Pending sync',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: task.isSynced && task.syncAction == 'NONE'
                            ? AppColors.synced
                            : AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      task.isSynced && task.syncAction == 'NONE'
                          ? Icons.check_circle_rounded
                          : Icons.cloud_upload_outlined,
                      size: 16,
                      color: task.isSynced && task.syncAction == 'NONE'
                          ? AppColors.synced
                          : AppColors.warning,
                    ),
                  ],
                ),
              ),
              Divider(
                height: 18,
                color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.fingerprint_rounded,
                      size: 18,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Task ID',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '#${task.id}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: task.id.toString()));
                        AppFeedback.showInfo(
                          context,
                          title: 'Copied to Clipboard',
                          message: 'Task ID #${task.id} has been copied.',
                          icon: Icons.content_copy_rounded,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    String? value,
    Widget? trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        if (trailing != null)
          trailing
        else if (value != null)
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
      ],
    );
  }
}
