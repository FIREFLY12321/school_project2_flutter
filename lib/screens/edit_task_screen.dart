import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers.dart';
import '../widgets/priority_selector.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as notifications;
import 'package:timezone/timezone.dart' as tz;
import '../main.dart';

class EditTaskScreen extends StatefulWidget {
  final String taskId;

  const EditTaskScreen({Key? key, required this.taskId}) : super(key: key);

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final _tagsController = TextEditingController();
  Priority _selectedPriority = Priority.medium;
  DateTime? _selectedDueDate;
  TimeOfDay? _selectedDueTime;
  bool _isLoading = true;
  Task? _task;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  Future<void> _loadTask() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final task = await taskProvider.getTaskById(widget.taskId);

    if (task != null && mounted) {
      setState(() {
        _task = task;
        _nameController.text = task.name;
        _notesController.text = task.notes ?? '';
        _tagsController.text = task.tags.join(', ');
        _selectedPriority = task.priority;
        _selectedDueDate = task.dueDate;

        if (task.dueDate != null) {
          _selectedDueTime = TimeOfDay(
            hour: task.dueDate!.hour,
            minute: task.dueDate!.minute,
          );
        }

        _isLoading = false;
      });
    } else if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _updateNotification(Task task) async {
    // Cancel existing notification first
    await flutterLocalNotificationsPlugin.cancel(task.id.hashCode);

    if (task.dueDate == null) return;

    // Create notification details
    const notifications.AndroidNotificationDetails androidDetails = notifications.AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      importance: notifications.Importance.max,
      priority: notifications.Priority.high,
    );

    const notifications.NotificationDetails notificationDetails = notifications.NotificationDetails(
      android: androidDetails,
    );

    // Using simple show method for compatibility
    await flutterLocalNotificationsPlugin.show(
      task.id.hashCode,
      'Task Reminder: ${task.name}',
      'Your task "${task.name}" is due soon',
      notificationDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Task')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Task'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Task'),
                  content: const Text('Are you sure you want to delete this task?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await taskProvider.deleteTask(widget.taskId);
                        // Cancel notification
                        await flutterLocalNotificationsPlugin.cancel(_task!.id.hashCode);
                        if (mounted) {
                          Navigator.pop(context); // Close dialog
                          Navigator.pop(context); // Close edit screen
                        }
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Task Name*',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a task name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            PrioritySelector(
              selectedPriority: _selectedPriority,
              onPriorityChanged: (priority) {
                setState(() {
                  _selectedPriority = priority;
                });
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Due Date (Optional)'),
              subtitle: _selectedDueDate != null
                  ? Text(DateFormat('EEE, MMM d, yyyy').format(_selectedDueDate!))
                  : const Text('No due date selected'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDueDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );

                      if (date != null) {
                        setState(() {
                          _selectedDueDate = date;
                        });
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _selectedDueTime ?? TimeOfDay.now(),
                      );

                      if (time != null) {
                        setState(() {
                          _selectedDueTime = time;
                        });
                      }
                    },
                  ),
                  if (_selectedDueDate != null || _selectedDueTime != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _selectedDueDate = null;
                          _selectedDueTime = null;
                        });
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (comma separated)',
                border: OutlineInputBorder(),
                hintText: 'work, meeting, project',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        // Combine date and time if both are selected
                        DateTime? dueDateTime;
                        if (_selectedDueDate != null) {
                          dueDateTime = _selectedDueDate!;

                          if (_selectedDueTime != null) {
                            dueDateTime = DateTime(
                              _selectedDueDate!.year,
                              _selectedDueDate!.month,
                              _selectedDueDate!.day,
                              _selectedDueTime!.hour,
                              _selectedDueTime!.minute,
                            );
                          }
                        }

                        final updatedTask = Task(
                          id: _task!.id,
                          name: _nameController.text,
                          priority: _selectedPriority,
                          createdAt: _task!.createdAt,
                          dueDate: dueDateTime,
                          isCompleted: _task!.isCompleted,
                          tags: _tagsController.text.isEmpty
                              ? []
                              : _tagsController.text.split(',').map((tag) => tag.trim()).toList(),
                          notes: _notesController.text.isEmpty ? null : _notesController.text,
                        );

                        await taskProvider.updateTask(updatedTask);
                        await _updateNotification(updatedTask);

                        if (mounted) {
                          Navigator.pop(context);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('SAVE CHANGES'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}