import '../domain/task_models.dart';

abstract interface class TaskRepository {
  Future<List<CompletenessTask>> getOpenTasks();

  Future<CompletenessTask?> getTask(String taskId);

  Future<void> resolveTask(String taskId, {String? resolvedValue});
}
