import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class TaskListItem extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;

  const TaskListItem({
    Key? key,
    required this.task,
    required this.onTap,
    required this.onToggleComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color priorityColor;

    switch (task.priority) {
      case Priority.high:
        priorityColor = Colors.red;
        break;
      case Priority.medium:
        priorityColor = Colors.orange;
        break;
      case Priority.low:
        priorityColor = Colors.green;
        break;
    }

    final isOverdue = task.dueDate != null &&
        !task.isCompleted &&
        task.dueDate!.isBefore(DateTime.now());

    return ListTile(
      onTap: onTap,
      leading: Checkbox(
        value: task.isCompleted,
        onChanged: (_) => onToggleComplete(),
        activeColor: theme.colorScheme.primary,
      ),
      title: Text(
        task.name,
        style: TextStyle(
          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          color: task.isCompleted ? theme.disabledColor : null,
          fontWeight: task.priority == Priority.high ? FontWeight.bold : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (task.dueDate != null)
            Text(
              'Due: ${DateFormat('MMM d, h:mm a').format(task.dueDate!)}',
              style: TextStyle(
                color: isOverdue ? Colors.red : null,
                fontWeight: isOverdue ? FontWeight.bold : null,
              ),
            ),
          if (task.tags.isNotEmpty)
            Wrap(
              spacing: 4,
              children: task.tags.map((tag) => Chip(
                label: Text(tag, style: const TextStyle(fontSize: 10)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              )).toList(),
            ),
        ],
      ),
      trailing: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: priorityColor,
          shape: BoxShape.circle,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}