import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/task_entity.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../cubit/task_form_cubit.dart';
import '../widgets/task_category_selector.dart';
import '../widgets/task_date_time_picker.dart';
import '../widgets/task_form_submit_button.dart';
import '../widgets/task_form_text_fields.dart';
import '../widgets/task_priority_selector.dart';

class TaskFormScreen extends StatelessWidget {
  final TaskEntity? task;

  const TaskFormScreen({super.key, this.task});

  bool get isEditing => task != null;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TaskFormCubit(initialTask: task),
      child: _TaskFormContent(task: task, isEditing: isEditing),
    );
  }
}

class _TaskFormContent extends StatelessWidget {
  final TaskEntity? task;
  final bool isEditing;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  _TaskFormContent({required this.task, required this.isEditing});

  void _saveTask(
    BuildContext context,
    TextEditingController titleController,
    TextEditingController descController,
  ) {
    final formCubit = context.read<TaskFormCubit>();
    if (!_formKey.currentState!.validate() ||
        !formCubit.validateDueDate(isEditing)) {
      return;
    }

    formCubit.setSaving(true);
    final state = formCubit.state;
    final now = DateTime.now();
    final currentUserId =
        context.read<AuthBloc>().state.user?.id ?? 'guest_user';

    if (isEditing) {
      final updatedTask = task!.copyWith(
        title: titleController.text.trim(),
        description: descController.text.trim().isEmpty
            ? null
            : descController.text.trim(),
        priority: state.priority,
        category: state.category,
        dueDate: state.dueDate,
        isCompleted: state.isCompleted,
        updatedAt: now,
      );
      context.read<TaskBloc>().add(UpdateTaskEvent(updatedTask));
      sl<NotificationService>().scheduleTaskDueReminder(updatedTask);
    } else {
      final newTask = TaskEntity(
        id: 0,
        title: titleController.text.trim(),
        description: descController.text.trim().isEmpty
            ? null
            : descController.text.trim(),
        priority: state.priority,
        category: state.category,
        dueDate: state.dueDate,
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
        userId: currentUserId,
      );
      context.read<TaskBloc>().add(CreateTaskEvent(newTask));
      sl<NotificationService>().scheduleTaskDueReminder(newTask);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEditing
              ? 'Task updated successfully'
              : 'Task created successfully',
        ),
      ),
    );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleController = TextEditingController(text: task?.title ?? '');
    final descController =
        TextEditingController(text: task?.description ?? '');

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        title: Text(
          isEditing ? 'Edit Task' : 'New Task',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color:
                isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        actions: [
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, _) => IconButton(
              icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
              onPressed: () => context.read<ThemeCubit>().toggleTheme(),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<TaskFormCubit, TaskFormState>(
        builder: (context, formState) {
          final cubit = context.read<TaskFormCubit>();

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TaskFormTextFields(
                      titleController: titleController,
                      descriptionController: descController,
                    ),
                    const SizedBox(height: 24),
                    TaskCategorySelector(
                      selectedCategory: formState.category,
                      onCategoryChanged: cubit.setCategory,
                    ),
                    const SizedBox(height: 24),
                    TaskPrioritySelector(
                      selectedPriority: formState.priority,
                      onPriorityChanged: cubit.setPriority,
                    ),
                    const SizedBox(height: 24),
                    TaskDateTimePicker(
                      selectedDueDate: formState.dueDate,
                      dueDateError: formState.dueDateError,
                      isEditing: isEditing,
                      onDateSelected: cubit.setDueDate,
                    ),
                    const SizedBox(height: 24),
                    if (isEditing) ...[
                      _CompletedToggle(
                        isCompleted: formState.isCompleted,
                        onChanged: cubit.setIsCompleted,
                      ),
                      const SizedBox(height: 24),
                    ],
                    TaskFormSubmitButton(
                      isEditing: isEditing,
                      isSaving: formState.isSaving,
                      onPressed: () =>
                          _saveTask(context, titleController, descController),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CompletedToggle extends StatelessWidget {
  final bool isCompleted;
  final ValueChanged<bool> onChanged;

  const _CompletedToggle({
    required this.isCompleted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkInputFill : AppColors.lightInputFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Mark as Completed',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          Switch(
            value: isCompleted,
            activeThumbColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
