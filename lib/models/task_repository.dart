import 'package:uuid/uuid.dart';
import 'task.dart';
import 'database_helper.dart';

class TaskRepository {
  final _uuid = Uuid();
  final _dbHelper = DatabaseHelper.instance;

  Future<List<Task>> getAllTasks() async {
    return await _dbHelper.readAllTasks();
  }

  Future<List<Task>> getTasksByPriority(Priority priority) async {
    final tasks = await _dbHelper.readAllTasks();
    return tasks.where((task) => task.priority == priority).toList();
  }

  Future<Task?> getTaskById(String id) async {
    return await _dbHelper.readTask(id);
  }

  Future<void> addTask(Task task) async {
    if (task.id.isEmpty) {
      task = task.copyWith(id: _uuid.v4());
    }
    await _dbHelper.create(task);
  }

  Future<void> updateTask(Task task) async {
    await _dbHelper.update(task);
  }

  Future<void> deleteTask(String id) async {
    await _dbHelper.delete(id);
  }

  Future<void> toggleTaskCompletion(String id) async {
    await _dbHelper.toggleTaskCompletion(id);
  }

  Future<void> deleteAllTasks() async {
    await _dbHelper.deleteAllTasks();
  }

  Future<List<Task>> searchTasks(String query) async {
    final tasks = await _dbHelper.readAllTasks();
    return tasks.where((task) =>
    task.name.toLowerCase().contains(query.toLowerCase()) ||
        (task.notes?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
        task.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()))
    ).toList();
  }
}