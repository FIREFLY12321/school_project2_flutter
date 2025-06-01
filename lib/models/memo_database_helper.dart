import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'memo.dart';

class MemoDatabaseHelper {
  static final MemoDatabaseHelper instance = MemoDatabaseHelper._init();
  static Database? _database;

  MemoDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('memo_calendar.db');
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
    CREATE TABLE memos (
      id $idType,
      title $textType,
      dateTime $textType,
      location TEXT,
      description TEXT,
      hasReminder $intType
    )
    ''');
  }

  Future<void> create(Memo memo) async {
    final db = await instance.database;
    await db.insert('memos', memo.toMap());
  }

  Future<List<Memo>> readAllMemos() async {
    final db = await instance.database;
    final result = await db.query('memos', orderBy: 'dateTime ASC');
    return result.map((map) => Memo.fromMap(map)).toList();
  }

  Future<List<Memo>> readTodayMemos() async {
    final db = await instance.database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final result = await db.query(
      'memos',
      where: 'dateTime >= ? AND dateTime < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'dateTime ASC',
    );

    return result.map((map) => Memo.fromMap(map)).toList();
  }

  Future<Memo?> readMemo(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      'memos',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Memo.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<void> update(Memo memo) async {
    final db = await instance.database;
    await db.update(
      'memos',
      memo.toMap(),
      where: 'id = ?',
      whereArgs: [memo.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await instance.database;
    await db.delete(
      'memos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAllMemos() async {
    final db = await instance.database;
    await db.delete('memos');
  }

  Future<List<Memo>> searchMemos(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'memos',
      where: 'title LIKE ? OR description LIKE ? OR location LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'dateTime ASC',
    );

    return result.map((map) => Memo.fromMap(map)).toList();
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}