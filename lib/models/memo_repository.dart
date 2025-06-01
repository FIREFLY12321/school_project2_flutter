import 'package:uuid/uuid.dart';
import 'memo.dart';
import 'memo_database_helper.dart';

class MemoRepository {
  final _uuid = Uuid();
  final _dbHelper = MemoDatabaseHelper.instance;

  Future<List<Memo>> getAllMemos() async {
    return await _dbHelper.readAllMemos();
  }

  Future<List<Memo>> getTodayMemos() async {
    return await _dbHelper.readTodayMemos();
  }

  Future<Memo?> getMemoById(String id) async {
    return await _dbHelper.readMemo(id);
  }

  Future<void> addMemo(Memo memo) async {
    if (memo.id.isEmpty) {
      memo = memo.copyWith(id: _uuid.v4());
    }
    await _dbHelper.create(memo);
  }

  Future<void> updateMemo(Memo memo) async {
    await _dbHelper.update(memo);
  }

  Future<void> deleteMemo(String id) async {
    await _dbHelper.delete(id);
  }

  Future<void> deleteAllMemos() async {
    await _dbHelper.deleteAllMemos();
  }

  Future<List<Memo>> searchMemos(String query) async {
    return await _dbHelper.searchMemos(query);
  }
}