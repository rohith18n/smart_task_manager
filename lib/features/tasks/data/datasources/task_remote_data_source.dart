import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/task_model.dart';

abstract class TaskRemoteDataSource {
  Future<List<TaskModel>> getTasks({
    required String userId,
    int skip = 0,
    int limit = 10,
  });

  Future<TaskModel> createTask(TaskModel task);

  Future<TaskModel> updateTask(TaskModel task);

  Future<void> deleteTask(int id, {required String userId});
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final ApiClient apiClient;

  TaskRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<TaskModel>> getTasks({
    required String userId,
    int skip = 0,
    int limit = 10,
  }) async {
    try {
      final response = await apiClient.get(
        '/tasks/',
        queryParameters: {
          'user_id': userId,
          'skip': skip,
          'limit': limit,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        final list = data['data'] as List;
        return list.map((item) => TaskModel.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Failed to fetch tasks from server: $e');
    }
  }

  @override
  Future<TaskModel> createTask(TaskModel task) async {
    try {
      final response = await apiClient.post(
        '/tasks/',
        data: task.toApiJson(),
        queryParameters: {'user_id': task.userId},
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return TaskModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      return task;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Failed to create task on server: $e');
    }
  }

  @override
  Future<TaskModel> updateTask(TaskModel task) async {
    try {
      final response = await apiClient.put(
        '/tasks/${task.id}',
        data: task.toApiJson(),
        queryParameters: {'user_id': task.userId},
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return TaskModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      return task;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Failed to update task on server: $e');
    }
  }

  @override
  Future<void> deleteTask(int id, {required String userId}) async {
    try {
      await apiClient.delete(
        '/tasks/$id',
        queryParameters: {'user_id': userId},
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Failed to delete task on server: $e');
    }
  }
}
