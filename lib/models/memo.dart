import 'dart:convert';

class Memo {
  String id;
  String title;
  DateTime dateTime;
  String? location;
  String? description;
  bool hasReminder;

  Memo({
    required this.id,
    required this.title,
    required this.dateTime,
    this.location,
    this.description,
    this.hasReminder = false,
  });

  // Convert Memo object to a map for storing in SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'dateTime': dateTime.toIso8601String(),
      'location': location,
      'description': description,
      'hasReminder': hasReminder ? 1 : 0,
    };
  }

  // Create a Memo object from a map retrieved from SQLite
  static Memo fromMap(Map<String, dynamic> map) {
    return Memo(
      id: map['id'] as String,
      title: map['title'] as String,
      dateTime: DateTime.parse(map['dateTime'] as String),
      location: map['location'] as String?,
      description: map['description'] as String?,
      hasReminder: (map['hasReminder'] as int) == 1,
    );
  }

  // Create a copy of the Memo with optional updated fields
  Memo copyWith({
    String? id,
    String? title,
    DateTime? dateTime,
    String? location,
    String? description,
    bool? hasReminder,
  }) {
    return Memo(
      id: id ?? this.id,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      description: description ?? this.description,
      hasReminder: hasReminder ?? this.hasReminder,
    );
  }

  // Check if memo is for today
  bool get isToday {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  // Format time for display
  String get formattedTime {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Format date for display
  String get formattedDate {
    return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'Memo{id: $id, title: $title, dateTime: $dateTime, location: $location}';
  }
}