import 'package:equatable/equatable.dart';
import '../enums/task_category.dart';
import '../enums/task_priority.dart';

class TaskEntity extends Equatable {
  final int id;
  final String title;
  final String? description;
  final TaskPriority priority;
  final TaskCategory category;
  final DateTime? dueDate;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final String syncAction;
  final String userId;

  const TaskEntity({
    required this.id,
    required this.title,
    this.description,
    this.priority = TaskPriority.medium,
    this.category = TaskCategory.work,
    this.dueDate,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = true,
    this.syncAction = 'NONE',
    required this.userId,
  });

  TaskEntity copyWith({
    int? id,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskCategory? category,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    String? syncAction,
    String? userId,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      syncAction: syncAction ?? this.syncAction,
      userId: userId ?? this.userId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        priority,
        category,
        dueDate,
        isCompleted,
        createdAt,
        updatedAt,
        isSynced,
        syncAction,
        userId,
      ];
}
