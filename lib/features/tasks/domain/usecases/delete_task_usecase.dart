import '../repositories/task_repository.dart';

class DeleteTaskUseCase {
  final TaskRepository repository;

  DeleteTaskUseCase(this.repository);

  Future<void> call(int id, {String? userId}) async {
    await repository.deleteTask(id, userId: userId);
  }
}
