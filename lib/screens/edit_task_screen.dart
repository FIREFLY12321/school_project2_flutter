import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/providers.dart';
import '../widgets/priority_selector.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as notifications;
import 'package:timezone/timezone.dart' as tz;

// 在檔案內定義本地通知插件實例
final notifications.FlutterLocalNotificationsPlugin _localNotifications =
notifications.FlutterLocalNotificationsPlugin();

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

  Future<void> _initializeNotifications() async {
    try {
      const androidSettings = notifications.AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = notifications.DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = notifications.InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(initSettings);
    } catch (e) {
      debugPrint('init notification error: $e');
    }
  }

  Future<void> _updateNotification(Task task) async {
    try {
      // 確保通知已初始化
      await _initializeNotifications();

      // 先取消舊的通知
      await _localNotifications.cancel(task.id.hashCode);
      await _localNotifications.cancel(task.id.hashCode + 1000);

      if (task.dueDate == null) return;

      // 設定新的通知
      const androidSettings = notifications.AndroidNotificationDetails(
        'task_reminders',
        'Task Reminders',
        channelDescription: 'Notifications for task reminders',
        importance: notifications.Importance.max,
        priority: notifications.Priority.high,
      );

      const iosSettings = notifications.DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = notifications.NotificationDetails(
        android: androidSettings,
        iOS: iosSettings,
      );

      // 顯示任務更新通知
      await _localNotifications.show(
        task.id.hashCode + 1000,
        'Task Updated: ${task.name}',
        'Task has been updated with due date ${DateFormat('MMM d, h:mm a').format(task.dueDate!)}',
        notificationDetails,
      );
    } catch (e) {
      print('更新通知時發生錯誤: $e');
    }
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

                        // 取消通知
                        try {
                          await _initializeNotifications();
                          await _localNotifications.cancel(_task!.id.hashCode);
                          await _localNotifications.cancel(_task!.id.hashCode + 1000);
                        } catch (e) {
                          print('取消通知時發生錯誤: $e');
                        }

                        if (mounted) {
                          Navigator.pop(context); // 關閉對話框
                          Navigator.pop(context); // 關閉編輯頁面
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
                        // 組合日期和時間
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