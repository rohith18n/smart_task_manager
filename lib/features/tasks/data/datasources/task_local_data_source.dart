import 'package:sqflite/sqflite.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/error/exceptions.dart';
import '../models/task_model.dart';

abstract class TaskLocalDataSource {
  Future<List<TaskModel>> getTasks({String? userId});
  Future<TaskModel?> getTaskById(int id);
  Future<void> insertTask(TaskModel task);
  Future<void> updateTask(TaskModel task);
  Future<void> deleteTask(int id);
  Future<void> hardDeleteTask(int id);
  Future<List<TaskModel>> getPendingSyncTasks({String? userId});
  Future<void> markAsSynced(int id);
  Future<void> replaceTemporaryId(int temporaryId, TaskModel syncedTask);
  Future<void> saveFromRemote(List<TaskModel> remoteTasks);
}

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  final DatabaseHelper databaseHelper;

  TaskLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<List<TaskModel>> getTasks({String? userId}) async {
    try {
      final db = await databaseHelper.database;
      List<Map<String, dynamic>> results;

      if (userId != null && userId.isNotEmpty) {
        results = await db.query(
          AppConstants.tasksTableName,
          where: 'sync_action != ? AND user_id = ?',
          whereArgs: [AppConstants.syncActionDelete, userId],
          orderBy: 'created_at DESC',
        );
      } else {
        results = await db.query(
          AppConstants.tasksTableName,
          where: 'sync_action != ?',
          whereArgs: [AppConstants.syncActionDelete],
          orderBy: 'created_at DESC',
        );
      }
      return results.map((map) => TaskModel.fromSqflite(map)).toList();
    } catch (e) {
      throw CacheException('Failed to fetch tasks from local database: $e');
    }
  }

  @override
  Future<TaskModel?> getTaskById(int id) async {
    try {
      final db = await databaseHelper.database;
      final results = await db.query(
        AppConstants.tasksTableName,
        where: 'id = ? AND sync_action != ?',
        whereArgs: [id, AppConstants.syncActionDelete],
      );
      if (results.isNotEmpty) {
        return TaskModel.fromSqflite(results.first);
      }
      return null;
    } catch (e) {
      throw CacheException('Failed to fetch task $id from local database: $e');
    }
  }

  @override
  Future<void> insertTask(TaskModel task) async {
    try {
      final db = await databaseHelper.database;
      await db.insert(
        AppConstants.tasksTableName,
        task.toSqflite(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException('Failed to insert task locally: $e');
    }
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    try {
      final db = await databaseHelper.database;
      await db.update(
        AppConstants.tasksTableName,
        task.toSqflite(),
        where: 'id = ?',
        whereArgs: [task.id],
      );
    } catch (e) {
      throw CacheException('Failed to update task locally: $e');
    }
  }

  @override
  Future<void> deleteTask(int id) async {
    try {
      final db = await databaseHelper.database;
      final existing = await getTaskById(id);

      if (existing == null) return;

      // If created offline and not synced yet (negative ID or syncAction INSERT), hard delete
      if (id < 0 || (!existing.isSynced && existing.syncAction == AppConstants.syncActionInsert)) {
        await hardDeleteTask(id);
      } else {
        await db.update(
          AppConstants.tasksTableName,
          {
            'is_synced': 0,
            'sync_action': AppConstants.syncActionDelete,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    } catch (e) {
      throw CacheException('Failed to mark task as deleted locally: $e');
    }
  }

  @override
  Future<void> hardDeleteTask(int id) async {
    try {
      final db = await databaseHelper.database;
      await db.delete(
        AppConstants.tasksTableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw CacheException('Failed to hard delete task: $e');
    }
  }

  @override
  Future<List<TaskModel>> getPendingSyncTasks({String? userId}) async {
    try {
      final db = await databaseHelper.database;
      List<Map<String, dynamic>> results;

      if (userId != null && userId.isNotEmpty) {
        results = await db.query(
          AppConstants.tasksTableName,
          where: 'is_synced = ? AND user_id = ?',
          whereArgs: [0, userId],
        );
      } else {
        results = await db.query(
          AppConstants.tasksTableName,
          where: 'is_synced = ?',
          whereArgs: [0],
        );
      }
      return results.map((map) => TaskModel.fromSqflite(map)).toList();
    } catch (e) {
      throw CacheException('Failed to fetch pending sync tasks: $e');
    }
  }

  @override
  Future<void> markAsSynced(int id) async {
    try {
      final db = await databaseHelper.database;
      await db.update(
        AppConstants.tasksTableName,
        {
          'is_synced': 1,
          'sync_action': AppConstants.syncActionNone,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw CacheException('Failed to mark task as synced: $e');
    }
  }

  @override
  Future<void> replaceTemporaryId(int temporaryId, TaskModel syncedTask) async {
    try {
      final db = await databaseHelper.database;
      await db.transaction((txn) async {
        await txn.delete(
          AppConstants.tasksTableName,
          where: 'id = ?',
          whereArgs: [temporaryId],
        );
        await txn.insert(
          AppConstants.tasksTableName,
          syncedTask.toSqflite(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });
    } catch (e) {
      throw CacheException('Failed to replace temporary ID: $e');
    }
  }

  @override
  Future<void> saveFromRemote(List<TaskModel> remoteTasks) async {
    try {
      final db = await databaseHelper.database;
      await db.transaction((txn) async {
        for (final remoteTask in remoteTasks) {
          final local = await txn.query(
            AppConstants.tasksTableName,
            where: 'id = ?',
            whereArgs: [remoteTask.id],
          );

          if (local.isNotEmpty) {
            final isSynced = (local.first['is_synced'] as int) == 1;
            final localUpdatedAt = DateTime.parse(local.first['updated_at'] as String);

            if (!isSynced && localUpdatedAt.isAfter(remoteTask.updatedAt)) {
              continue;
            }
          }

          await txn.insert(
            AppConstants.tasksTableName,
            remoteTask.toSqflite(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } catch (e) {
      throw CacheException('Failed to save remote tasks to local database: $e');
    }
  }
}
