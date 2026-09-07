import 'package:flutter_test/flutter_test.dart';
import 'package:smart_task_manager/features/tasks/data/models/task_model.dart';
import 'package:smart_task_manager/features/tasks/domain/entities/task_entity.dart';
import 'package:smart_task_manager/features/tasks/domain/enums/task_category.dart';
import 'package:smart_task_manager/features/tasks/domain/enums/task_priority.dart';

void main() {
  final testDateTime = DateTime(2026, 8, 20, 10, 0, 0);

  final tTaskModel = TaskModel(
    id: 123,
    userId: 'user-1',
    title: 'Audit Financial Statement',
    description: 'Quarterly review of compliance and risk metrics',
    priority: TaskPriority.high,
    category: TaskCategory.work,
    dueDate: testDateTime,
    isCompleted: false,
    createdAt: testDateTime,
    updatedAt: testDateTime,
    isSynced: true,
    syncAction: 'NONE',
  );

  test('should be a subclass of TaskEntity', () {
    expect(tTaskModel, isA<TaskEntity>());
  });

  group('JSON serialization', () {
    test('toJson returns correct Map', () {
      final json = tTaskModel.toJson();

      expect(json['id'], 123);
      expect(json['user_id'], 'user-1');
      expect(json['title'], 'Audit Financial Statement');
      expect(json['priority'], 'High');
      expect(json['category'], 'Work');
      expect(json['is_completed'], false);
      expect(json['due_date'], testDateTime.toIso8601String());
      expect(json['is_synced'], true);
    });

    test('fromJson constructs valid TaskModel', () {
      final json = {
        'id': 123,
        'user_id': 'user-1',
        'title': 'Audit Financial Statement',
        'description': 'Quarterly review of compliance and risk metrics',
        'priority': 'High',
        'category': 'Work',
        'due_date': testDateTime.toIso8601String(),
        'is_completed': false,
        'created_at': testDateTime.toIso8601String(),
        'updated_at': testDateTime.toIso8601String(),
        'is_synced': true,
        'sync_action': 'NONE',
      };

      final result = TaskModel.fromJson(json);

      expect(result, equals(tTaskModel));
      expect(result.priority, TaskPriority.high);
      expect(result.category, TaskCategory.work);
    });

    test('toApiJson outputs valid payload for REST API', () {
      final apiJson = tTaskModel.toApiJson();

      expect(apiJson['title'], 'Audit Financial Statement');
      expect(apiJson['priority'], 'High');
      expect(apiJson['category'], 'Work');
      expect(apiJson['is_completed'], false);
    });
  });

  group('SQLite serialization', () {
    test('toSqflite returns proper integer and string format for SQLite', () {
      final map = tTaskModel.toSqflite();

      expect(map['id'], 123);
      expect(map['user_id'], 'user-1');
      expect(map['title'], 'Audit Financial Statement');
      expect(map['priority'], 'High');
      expect(map['category'], 'Work');
      expect(map['is_completed'], 0);
      expect(map['is_synced'], 1);
      expect(map['sync_action'], 'NONE');
      expect(map['due_date'], testDateTime.toIso8601String());
    });

    test('fromSqflite reconstructs TaskModel accurately', () {
      final map = {
        'id': 123,
        'user_id': 'user-1',
        'title': 'Audit Financial Statement',
        'description': 'Quarterly review of compliance and risk metrics',
        'priority': 'High',
        'category': 'Work',
        'due_date': testDateTime.toIso8601String(),
        'is_completed': 0,
        'created_at': testDateTime.toIso8601String(),
        'updated_at': testDateTime.toIso8601String(),
        'is_synced': 1,
        'sync_action': 'NONE',
      };

      final result = TaskModel.fromSqflite(map);

      expect(result, equals(tTaskModel));
      expect(result.isCompleted, false);
      expect(result.isSynced, true);
    });
  });
}
