import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/services/conflict_resolver.dart';
import '../datasources/task_local_data_source.dart';
import '../datasources/task_remote_data_source.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDataSource localDataSource;
  final TaskRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final ConflictResolver conflictResolver;

  TaskRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.networkInfo,
    ConflictResolver? conflictResolver,
  }) : conflictResolver = conflictResolver ?? const ConflictResolver();

  @override
  Future<List<TaskEntity>> getTasks({
    String? userId,
    int skip = 0,
    int limit = 10,
  }) async {
    final isOnline = await networkInfo.isConnected;

    if (isOnline && userId != null && userId.isNotEmpty && userId != 'guest_user') {
      try {
        final remoteTasks = await remoteDataSource.getTasks(
          userId: userId,
          skip: skip,
          limit: limit,
        );
        if (remoteTasks.isNotEmpty) {
          await localDataSource.saveFromRemote(remoteTasks);
        }
        _syncInBackground(userId: userId);
      } catch (e) {
        debugPrint('Remote getTasks notice: $e');
      }
    }

    return await localDataSource.getTasks(userId: userId);
  }

  void _syncInBackground({String? userId}) {
    syncPendingTasks(userId: userId).catchError((e) {
      debugPrint('Background sync error: $e');
    });
  }

  @override
  Future<TaskEntity?> getTaskById(int id) async {
    return await localDataSource.getTaskById(id);
  }

  @override
  Future<TaskEntity> createTask(TaskEntity task) async {
    final isOnline = await networkInfo.isConnected;
    final int tempId = task.id != 0
        ? task.id
        : -(DateTime.now().millisecondsSinceEpoch % 1000000000);

    final preparedTask = task.copyWith(id: tempId);

    if (isOnline && task.userId.isNotEmpty && task.userId != 'guest_user') {
      try {
        final model = TaskModel.fromEntity(preparedTask);
        final createdRemote = await remoteDataSource.createTask(model);
        final syncedModel = createdRemote.copyWith(
          isSynced: true,
          syncAction: AppConstants.syncActionNone,
        );
        await localDataSource.insertTask(syncedModel);
        return syncedModel;
      } catch (e) {
        debugPrint('Remote task create failed, falling back to local queue: $e');
      }
    }

    // Offline or guest mode
    final localModel = TaskModel.fromEntity(preparedTask).copyWith(
      isSynced: false,
      syncAction: AppConstants.syncActionInsert,
    );
    await localDataSource.insertTask(localModel);
    return localModel;
  }

  @override
  Future<TaskEntity> updateTask(TaskEntity task) async {
    final isOnline = await networkInfo.isConnected;
    final updatedTask = task.copyWith(updatedAt: DateTime.now());

    if (isOnline && task.id > 0 && task.userId.isNotEmpty && task.userId != 'guest_user') {
      try {
        final model = TaskModel.fromEntity(updatedTask);
        final updatedRemote = await remoteDataSource.updateTask(model);
        final syncedModel = updatedRemote.copyWith(
          isSynced: true,
          syncAction: AppConstants.syncActionNone,
        );
        await localDataSource.updateTask(syncedModel);
        return syncedModel;
      } catch (e) {
        debugPrint('Remote task update failed, queuing for sync: $e');
      }
    }

    // Offline mode
    final localModel = TaskModel.fromEntity(updatedTask).copyWith(
      isSynced: false,
      syncAction: AppConstants.syncActionUpdate,
    );
    await localDataSource.updateTask(localModel);
    return localModel;
  }

  @override
  Future<void> deleteTask(int id, {String? userId}) async {
    final isOnline = await networkInfo.isConnected;

    if (isOnline && id > 0 && userId != null && userId.isNotEmpty && userId != 'guest_user') {
      try {
        await remoteDataSource.deleteTask(id, userId: userId);
        await localDataSource.hardDeleteTask(id);
        return;
      } catch (e) {
        debugPrint('Remote delete failed, queuing for sync: $e');
      }
    }

    await localDataSource.deleteTask(id);
  }

  @override
  Future<TaskEntity?> toggleTaskCompletion(int id, {String? userId}) async {
    final task = await localDataSource.getTaskById(id);
    if (task == null) return null;

    final toggled = task.copyWith(
      isCompleted: !task.isCompleted,
      updatedAt: DateTime.now(),
    );
    return await updateTask(toggled);
  }

  @override
  Future<void> syncPendingTasks({String? userId}) async {
    if (!await networkInfo.isConnected) return;
    if (userId == null || userId.isEmpty || userId == 'guest_user') return;

    try {
      final pendingTasks = await localDataSource.getPendingSyncTasks(userId: userId);
      if (pendingTasks.isEmpty) return;

      for (final task in pendingTasks) {
        try {
          if (task.syncAction == AppConstants.syncActionInsert) {
            final created = await remoteDataSource.createTask(task);
            final synced = created.copyWith(
              isSynced: true,
              syncAction: AppConstants.syncActionNone,
            );
            await localDataSource.replaceTemporaryId(task.id, synced);
          } else if (task.syncAction == AppConstants.syncActionUpdate) {
            if (task.id > 0) {
              await remoteDataSource.updateTask(task);
              await localDataSource.markAsSynced(task.id);
            }
          } else if (task.syncAction == AppConstants.syncActionDelete) {
            if (task.id > 0) {
              await remoteDataSource.deleteTask(task.id, userId: task.userId);
            }
            await localDataSource.hardDeleteTask(task.id);
          }
        } catch (err) {
          debugPrint('Sync task ${task.id} failed: $err');
        }
      }

      // Pull remote updates
      try {
        final remoteTasks = await remoteDataSource.getTasks(userId: userId, skip: 0, limit: 50);
        final localTasks = await localDataSource.getTasks(userId: userId);
        final localMap = {for (final t in localTasks) t.id: t};

        final toSave = <TaskModel>[];
        for (final remote in remoteTasks) {
          final local = localMap[remote.id];
          if (local != null) {
            final resolution = conflictResolver.resolve(
              localTask: local,
              remoteTask: remote,
            );
            if (resolution.winner == 'REMOTE') {
              toSave.add(TaskModel.fromEntity(resolution.resolvedTask));
            }
          } else {
            toSave.add(remote);
          }
        }

        if (toSave.isNotEmpty) {
          await localDataSource.saveFromRemote(toSave);
        }
      } catch (err) {
        debugPrint('Pull after sync failed: $err');
      }
    } catch (e) {
      debugPrint('Sync pending tasks error: $e');
    }
  }
}
