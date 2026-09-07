import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class ToggleTaskCompletionUseCase {
  final TaskRepository repository;

  ToggleTaskCompletionUseCase(this.repository);

  Future<TaskEntity?> call(int id, {String? userId}) async {
    return await repository.toggleTaskCompletion(id, userId: userId);
  }
}
