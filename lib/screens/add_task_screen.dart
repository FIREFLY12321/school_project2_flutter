import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers.dart';
import '../widgets/priority_selector.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as notifications;
import '../main.dart';
import 'package:uuid/uuid.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({Key? key}) : super(key: key);

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}


class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final _tagsController = TextEditingController();
  Priority _selectedPriority = Priority.medium;
  DateTime? _selectedDueDate;
  TimeOfDay? _selectedDueTime;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _scheduleNotification(Task task) async {
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

    // Calculate the time difference for scheduling
    final now = DateTime.now();
    final scheduledDate = task.dueDate!;

    // For immediate notification if due date is in the past
    if (scheduledDate.isBefore(now)) {
      await flutterLocalNotificationsPlugin.show(
        task.id.hashCode,
        'Task Reminder: ${task.name}',
        'Your task "${task.name}" is due soon',
        notificationDetails,
      );
    } else {
      // For future notifications

    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a New Task'),
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
            ElevatedButton(
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

                  final task = Task(
                    id: const Uuid().v4(), // Generate a unique ID
                    name: _nameController.text,
                    priority: _selectedPriority,
                    createdAt: DateTime.now(),
                    dueDate: dueDateTime,
                    tags: _tagsController.text.isEmpty
                        ? []
                        : _tagsController.text.split(',').map((tag) => tag.trim()).toList(),
                    notes: _notesController.text.isEmpty ? null : _notesController.text,
                  );

                  await taskProvider.addTask(task);

                  if (dueDateTime != null) {
                    await _scheduleNotification(task);
                  }

                  if (mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('ADD TASK'),
            ),
          ],
        ),
      ),
    );
  }
}

