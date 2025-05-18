import 'dart:convert';

enum Priority {
  low,
  medium,
  high
}

class Task {
  String id;
  String name;
  Priority priority;
  DateTime createdAt;
  DateTime? dueDate;
  bool isCompleted;
  List<String> tags;
  String? notes;

  Task({
    required this.id,
    required this.name,
    required this.priority,
    required this.createdAt,
    this.dueDate,
    this.isCompleted = false,
    this.tags = const [],
    this.notes,
  });

  // Convert Task object to a map for storing in SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'priority': priority.index,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
      'tags': jsonEncode(tags), // Convert list to JSON string
      'notes': notes,
    };
  }

  // Create a Task object from a map retrieved from SQLite
  static Task fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      name: map['name'] as String,
      priority: Priority.values[map['priority'] as int],
      createdAt: DateTime.parse(map['createdAt'] as String),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate'] as String) : null,
      isCompleted: (map['isCompleted'] as int) == 1,
      tags: map['tags'] != null
          ? List<String>.from(jsonDecode(map['tags'] as String))
          : [],
      notes: map['notes'] as String?,
    );
  }

  // Create a copy of the Task with optional updated fields
  Task copyWith({
    String? id,
    String? name,
    Priority? priority,
    DateTime? createdAt,
    Object? dueDate = const Object(),
    bool? isCompleted,
    List<String>? tags,
    Object? notes = const Object(),
  }) {
    return Task(
      id: id ?? this.id,
      name: name ?? this.name,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate == const Object() ? this.dueDate : dueDate as DateTime?,
      isCompleted: isCompleted ?? this.isCompleted,
      tags: tags ?? List.from(this.tags),
      notes: notes == const Object() ? this.notes : notes as String?,
    );
  }

  @override
  String toString() {
    return 'Task{id: $id, name: $name, priority: $priority, isCompleted: $isCompleted}';
  }
}