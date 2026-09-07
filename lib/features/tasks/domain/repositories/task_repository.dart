import '../entities/task_entity.dart';

abstract class TaskRepository {
  Future<List<TaskEntity>> getTasks({String? userId, int skip = 0, int limit = 10});
  Future<TaskEntity?> getTaskById(int id);
  Future<TaskEntity> createTask(TaskEntity task);
  Future<TaskEntity> updateTask(TaskEntity task);
  Future<void> deleteTask(int id, {String? userId});
  Future<TaskEntity?> toggleTaskCompletion(int id, {String? userId});
  Future<void> syncPendingTasks({String? userId});
}
