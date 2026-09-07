import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/enums/task_category.dart';
import '../../domain/enums/task_priority.dart';

class TaskFormState extends Equatable {
  final String title;
  final String description;
  final TaskPriority priority;
  final TaskCategory category;
  final DateTime dueDate;
  final bool isCompleted;
  final bool isSaving;
  final String? dueDateError;

  const TaskFormState({
    required this.title,
    required this.description,
    required this.priority,
    required this.category,
    required this.dueDate,
    required this.isCompleted,
    this.isSaving = false,
    this.dueDateError,
  });

  factory TaskFormState.initial(TaskEntity? task) {
    return TaskFormState(
      title: task?.title ?? '',
      description: task?.description ?? '',
      priority: task?.priority ?? TaskPriority.medium,
      category: task?.category ?? TaskCategory.work,
      dueDate: task?.dueDate ??
          DateTime.now().add(const Duration(days: 1, hours: 2)),
      isCompleted: task?.isCompleted ?? false,
    );
  }

  TaskFormState copyWith({
    String? title,
    String? description,
    TaskPriority? priority,
    TaskCategory? category,
    DateTime? dueDate,
    bool? isCompleted,
    bool? isSaving,
    String? Function()? dueDateError,
  }) {
    return TaskFormState(
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      isSaving: isSaving ?? this.isSaving,
      dueDateError: dueDateError != null ? dueDateError() : this.dueDateError,
    );
  }

  @override
  List<Object?> get props => [
        title,
        description,
        priority,
        category,
        dueDate,
        isCompleted,
        isSaving,
        dueDateError,
      ];
}

class TaskFormCubit extends Cubit<TaskFormState> {
  TaskFormCubit({TaskEntity? initialTask})
      : super(TaskFormState.initial(initialTask));

  void setTitle(String title) => emit(state.copyWith(title: title));
  void setDescription(String desc) => emit(state.copyWith(description: desc));
  void setPriority(TaskPriority priority) =>
      emit(state.copyWith(priority: priority));
  void setCategory(TaskCategory category) =>
      emit(state.copyWith(category: category));
  void setDueDate(DateTime dueDate) {
    emit(state.copyWith(dueDate: dueDate, dueDateError: () => null));
  }

  void setIsCompleted(bool val) => emit(state.copyWith(isCompleted: val));
  void setSaving(bool saving) => emit(state.copyWith(isSaving: saving));

  bool validateDueDate(bool isEditing) {
    if (!isEditing &&
        state.dueDate
            .isBefore(DateTime.now().subtract(const Duration(minutes: 1)))) {
      emit(state.copyWith(dueDateError: () => 'Due date must be in the future'));
      return false;
    }
    if (state.dueDateError != null) {
      emit(state.copyWith(dueDateError: () => null));
    }
    return true;
  }
}
