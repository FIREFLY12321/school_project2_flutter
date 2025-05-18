import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'task.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('todo_list.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
    CREATE TABLE tasks (
      id $idType,
      name $textType,
      priority $intType,
      createdAt $textType,
      dueDate TEXT,
      isCompleted $intType,
      tags TEXT,
      notes TEXT
    )
    ''');
  }

  Future<void> create(Task task) async {
    final db = await instance.database;
    await db.insert('tasks', task.toMap());
  }

  Future<List<Task>> readAllTasks() async {
    final db = await instance.database;
    final result = await db.query('tasks');
    return result.map((map) => Task.fromMap(map)).toList();
  }

  Future<Task?> readTask(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Task.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<void> update(Task task) async {
    final db = await instance.database;
    await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await instance.database;
    await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> toggleTaskCompletion(String id) async {
    final db = await instance.database;
    final task = await readTask(id);
    if (task != null) {
      task.isCompleted = !task.isCompleted;
      await update(task);
    }
  }

  Future<void> deleteAllTasks() async {
    final db = await instance.database;
    await db.delete('tasks');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}