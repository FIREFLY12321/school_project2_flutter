import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/task.dart';
import '../providers/providers.dart';
import 'add_task_screen.dart';
import 'edit_task_screen.dart';
import '../widgets/task_list_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _tabController.addListener(() {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);

      switch (_tabController.index) {
        case 0:
          taskProvider.setPriorityFilter(null); // All tasks
          break;
        case 1:
          taskProvider.setPriorityFilter(Priority.high);
          break;
        case 2:
          taskProvider.setPriorityFilter(Priority.medium);
          break;
        case 3:
          taskProvider.setPriorityFilter(Priority.low);
          break;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final tasks = taskProvider.tasks;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search tasks...',
            border: InputBorder.none,
          ),
          onChanged: (value) {
            taskProvider.setSearchQuery(value);
          },
          autofocus: true,
        )
            : const Text('To-Do List'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  taskProvider.setSearchQuery('');
                }
              });
            },
          ),
          IconButton(
            icon: Icon(themeProvider.isDarkMode
                ? Icons.light_mode
                : Icons.dark_mode),
            onPressed: () async {
              themeProvider.toggleTheme();

              // Save preference
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isDarkMode', themeProvider.isDarkMode);
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear_all') {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear All Tasks'),
                    content: const Text('Are you sure you want to delete all tasks?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          taskProvider.deleteAllTasks();
                          Navigator.pop(context);
                        },
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: Text('Clear All Tasks'),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'High'),
            Tab(text: 'Medium'),
            Tab(text: 'Low'),
          ],
        ),
      ),
      body: taskProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : tasks.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt,
              size: 80,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _isSearching
                  ? 'No matching tasks found'
                  : 'No tasks yet. Tap + to add a new task',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.withOpacity(0.8),
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return Slidable(
            key: ValueKey(task.id),
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              dismissible: DismissiblePane(
                onDismissed: () {
                  final deletedTask = task;
                  taskProvider.deleteTask(task.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${task.name} deleted'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () {
                          taskProvider.addTask(deletedTask);
                        },
                      ),
                    ),
                  );
                },
              ),
              children: [
                SlidableAction(
                  onPressed: (context) {
                    taskProvider.deleteTask(task.id);
                  },
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  label: 'Delete',
                ),
              ],
            ),
            child: TaskListItem(
              task: task,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditTaskScreen(taskId: task.id),
                  ),
                );
              },
              onToggleComplete: () {
                taskProvider.toggleTaskCompletion(task.id);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTaskScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}