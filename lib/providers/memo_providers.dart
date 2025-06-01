import 'package:flutter/material.dart';
import 'package:project2/models/memo_repository.dart';
import 'package:project2/models/memo.dart';
class MemoProvider extends ChangeNotifier {
  final MemoRepository _repository;
  List<Memo> _allMemos = [];
  List<Memo> _todayMemos = [];
  bool _isLoading = true;
  String _searchQuery = '';

  MemoProvider({required MemoRepository repository}) : _repository = repository {
    _loadMemos();
  }

  bool get isLoading => _isLoading;
  List<Memo> get allMemos => _allMemos;
  List<Memo> get todayMemos => _todayMemos;
  String get searchQuery => _searchQuery;

  List<Memo> get displayMemos {
    if (_searchQuery.isNotEmpty) {
      return _allMemos.where((memo) =>
      memo.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (memo.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (memo.location?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
      ).toList();
    }
    return _todayMemos;
  }

  Future<void> _loadMemos() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allMemos = await _repository.getAllMemos();
      _todayMemos = await _repository.getTodayMemos();
    } catch (e) {
      _allMemos = [];
      _todayMemos = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> addMemo(Memo memo) async {
    await _repository.addMemo(memo);
    await _loadMemos();
  }

  Future<void> updateMemo(Memo memo) async {
    await _repository.updateMemo(memo);
    await _loadMemos();
  }

  Future<void> deleteMemo(String id) async {
    await _repository.deleteMemo(id);
    await _loadMemos();
  }

  Future<Memo?> getMemoById(String id) async {
    return await _repository.getMemoById(id);
  }

  Future<void> deleteAllMemos() async {
    await _repository.deleteAllMemos();
    await _loadMemos();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }
}