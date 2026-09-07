import '../../domain/entities/task_entity.dart';
import '../../domain/enums/task_category.dart';
import '../../domain/enums/task_priority.dart';

class TaskModel extends TaskEntity {
  const TaskModel({
    required super.id,
    required super.title,
    super.description,
    super.priority = TaskPriority.medium,
    super.category = TaskCategory.work,
    super.dueDate,
    super.isCompleted = false,
    required super.createdAt,
    required super.updatedAt,
    super.isSynced = true,
    super.syncAction = 'NONE',
    required super.userId,
  });

  factory TaskModel.fromEntity(TaskEntity entity) {
    return TaskModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      priority: entity.priority,
      category: entity.category,
      dueDate: entity.dueDate,
      isCompleted: entity.isCompleted,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isSynced: entity.isSynced,
      syncAction: entity.syncAction,
      userId: entity.userId,
    );
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: (json['id'] is num) ? (json['id'] as num).toInt() : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      isCompleted: json['is_completed'] as bool? ?? (json['isCompleted'] as bool? ?? false),
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'].toString())
          : (json['dueDate'] != null ? DateTime.tryParse(json['dueDate'].toString()) : null),
      priority: TaskPriority.fromString(json['priority'] as String?),
      category: TaskCategory.fromString(json['category'] as String?),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : (json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now() : DateTime.now()),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : (json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now() : DateTime.now()),
      isSynced: json['is_synced'] as bool? ?? (json['isSynced'] as bool? ?? true),
      syncAction: json['sync_action'] as String? ?? (json['syncAction'] as String? ?? 'NONE'),
      userId: json['user_id'] as String? ?? (json['userId'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'is_completed': isCompleted,
      'due_date': dueDate?.toIso8601String(),
      'priority': priority.displayName,
      'category': category.displayName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced,
      'sync_action': syncAction,
    };
  }

  Map<String, dynamic> toApiJson() {
    return {
      'title': title,
      'description': description,
      'is_completed': isCompleted,
      'due_date': dueDate?.toIso8601String(),
      'priority': priority.displayName,
      'category': category.displayName,
    };
  }

  factory TaskModel.fromSqflite(Map<String, dynamic> map) {
    return TaskModel(
      id: (map['id'] as num).toInt(),
      userId: map['user_id'] as String? ?? '',
      title: map['title'] as String,
      description: map['description'] as String?,
      priority: TaskPriority.fromString(map['priority'] as String?),
      category: TaskCategory.fromString(map['category'] as String?),
      dueDate: map['due_date'] != null ? DateTime.tryParse(map['due_date'].toString()) : null,
      isCompleted: (map['is_completed'] as int) == 1,
      createdAt: DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now(),
      isSynced: (map['is_synced'] as int) == 1,
      syncAction: map['sync_action'] as String? ?? 'NONE',
    );
  }

  Map<String, dynamic> toSqflite() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'priority': priority.displayName,
      'category': category.displayName,
      'due_date': dueDate?.toIso8601String(),
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'sync_action': syncAction,
    };
  }

  @override
  TaskModel copyWith({
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
    return TaskModel(
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
}
