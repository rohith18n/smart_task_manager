import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class GetTasksUseCase {
  final TaskRepository repository;

  GetTasksUseCase(this.repository);

  Future<List<TaskEntity>> call({String? userId, int skip = 0, int limit = 10}) async {
    return await repository.getTasks(userId: userId, skip: skip, limit: limit);
  }
}
