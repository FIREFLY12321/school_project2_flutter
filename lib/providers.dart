import 'package:flutter/material.dart';
import 'models/task.dart';
import 'models/task_repository.dart';

class TaskProvider extends ChangeNotifier {
  final TaskRepository _repository;
  List<Task> _tasks = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Priority? _priorityFilter;

  TaskProvider({required TaskRepository repository}) : _repository = repository {
    _loadTasks();
  }

  bool get isLoading => _isLoading;
  List<Task> get tasks => _getFilteredTasks();
  String get searchQuery => _searchQuery;
  Priority? get priorityFilter => _priorityFilter;

  Future<void> _loadTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      _tasks = await _repository.getAllTasks();
    } catch (e) {
      _tasks = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Task> _getFilteredTasks() {
    List<Task> filteredList = List.from(_tasks);

    // Apply priority filter if set
    if (_priorityFilter != null) {
      filteredList = filteredList.where((task) => task.priority == _priorityFilter).toList();
    }

    // Apply search query if not empty
    if (_searchQuery.isNotEmpty) {
      filteredList = filteredList.where((task) =>
      task.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (task.notes?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          task.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()))
      ).toList();
    }

    return filteredList;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setPriorityFilter(Priority? priority) {
    _priorityFilter = priority;
    notifyListeners();
  }

  Future<void> addTask(Task task) async {
    await _repository.addTask(task);
    await _loadTasks();
  }

  Future<void> updateTask(Task task) async {
    await _repository.updateTask(task);
    await _loadTasks();
  }

  Future<void> deleteTask(String id) async {
    await _repository.deleteTask(id);
    await _loadTasks();
  }

  Future<void> toggleTaskCompletion(String id) async {
    await _repository.toggleTaskCompletion(id);
    await _loadTasks();
  }

  Future<Task?> getTaskById(String id) async {
    return await _repository.getTaskById(id);
  }

  Future<void> deleteAllTasks() async {
    await _repository.deleteAllTasks();
    await _loadTasks();
  }

  void clearFilters() {
    _searchQuery = '';
    _priorityFilter = null;
    notifyListeners();
  }
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode;

  ThemeProvider({required bool isDarkMode})
      : _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark;
}