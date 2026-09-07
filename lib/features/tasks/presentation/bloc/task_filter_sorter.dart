import '../../domain/entities/task_entity.dart';
import '../../domain/enums/task_category.dart';
import '../../domain/enums/task_filter.dart';
import '../../domain/enums/task_priority.dart';
import '../../domain/enums/task_sort.dart';

class TaskFilterSorter {
  static List<TaskEntity> filterAndSort({
    required List<TaskEntity> tasks,
    required String query,
    required TaskFilter filter,
    required TaskPriority? priority,
    required TaskCategory? category,
    required TaskSortBy sortBy,
  }) {
    var result = List<TaskEntity>.from(tasks);

    // Search query (Title and description)
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      result = result.where((t) {
        final titleMatches = t.title.toLowerCase().contains(q);
        final descMatches = t.description?.toLowerCase().contains(q) ?? false;
        return titleMatches || descMatches;
      }).toList();
    }

    // Status filter
    switch (filter) {
      case TaskFilter.pending:
        result = result.where((t) => !t.isCompleted).toList();
        break;
      case TaskFilter.completed:
        result = result.where((t) => t.isCompleted).toList();
        break;
      case TaskFilter.all:
        break;
    }

    // Priority filter
    if (priority != null) {
      result = result.where((t) => t.priority == priority).toList();
    }

    // Category filter
    if (category != null) {
      result = result.where((t) => t.category == category).toList();
    }

    // Sorting
    switch (sortBy) {
      case TaskSortBy.dueDateAsc:
        result.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case TaskSortBy.dueDateDesc:
        result.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return b.dueDate!.compareTo(a.dueDate!);
        });
        break;
      case TaskSortBy.priorityHighToLow:
        result.sort((a, b) => b.priority.rank.compareTo(a.priority.rank));
        break;
      case TaskSortBy.priorityLowToHigh:
        result.sort((a, b) => a.priority.rank.compareTo(b.priority.rank));
        break;
      case TaskSortBy.createdDateDesc:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return result;
  }
}
