import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/memo.dart';

import '../providers/memo_providers.dart';
import '../providers/providers.dart' as old_providers;
import '../services/notification_service.dart';
import '../services/system_overlay_service.dart';
import '../tester/test_screen.dart';
import 'add_memo_screen.dart';
import 'edit_memo_screen.dart';
import '../services/overlay_service.dart';


class MemoHomeScreen extends StatefulWidget {
  const MemoHomeScreen({Key? key}) : super(key: key);

  @override
  State<MemoHomeScreen> createState() => _MemoHomeScreenState();
}

class _MemoHomeScreenState extends State<MemoHomeScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  bool _showOverlayFAB = false;

  @override
  void dispose() {
    _searchController.dispose();
    OverlayService.hideOverlay();
    super.dispose();
  }

  String get todayTitle {
    final now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);
    return formattedDate;
  }

  Future<void> _openMap(String location) async {
    final encodedLocation = Uri.encodeComponent(location);
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedLocation');
    final appleMapsUrl = Uri.parse('http://maps.apple.com/?q=$encodedLocation');

    try {
      // 嘗試打開Google Maps
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(appleMapsUrl)) {
        await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('無法打開地圖應用')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('打開地圖時發生錯誤: $e')),
        );
      }
    }
  }

  void _showTestDialog() {
    final isVisible = OverlayService.testFloatingButtonVisibility();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('浮動按鈕測試'),
        content: Text(
            isVisible
                ? '✅ 浮動按鈕目前可見'
                : '❌ 浮動按鈕目前不可見'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  void _openTestScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TestScreen()),
    );
  }

  Future<void> _toggleSystemOverlay() async {
    try {
      await SystemOverlayService.toggleOverlay();

      if (mounted) {
        final isVisible = SystemOverlayService.isOverlayVisible;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isVisible
                ? '🚀 系統級浮動按鈕已顯示\n可以退出 App 後在桌面上看到浮動按鈕'
                : '系統級浮動按鈕已隱藏'),
            duration: const Duration(seconds: 3),
            backgroundColor: isVisible ? Colors.green : Colors.grey,
            action: isVisible ? SnackBarAction(
              label: '最小化 App',
              onPressed: () {
                // 將 App 移到背景
                SystemNavigator.pop();
              },
            ) : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  Future<void> _testNotification() async {
    final success = await NotificationService().testNotification();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '✅ 測試通知已發送' : '❌ 測試通知發送失敗'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _testScheduledNotification() async {
    final success = await NotificationService().testScheduledNotification();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? '⏰ 定時測試通知已設定（1分鐘後）'
              : '❌ 定時測試通知設定失敗'),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final memoProvider = Provider.of<MemoProvider>(context);
    final themeProvider = Provider.of<old_providers.ThemeProvider>(context); // 使用舊的 ThemeProvider
    final memos = memoProvider.displayMemos;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: '搜尋備忘錄...',
            border: InputBorder.none,
          ),
          onChanged: (value) {
            memoProvider.setSearchQuery(value);
          },
          autofocus: true,
        )
            : Text(todayTitle),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  memoProvider.clearSearch();
                }
              });
            },
          ),
          IconButton(
            icon: Icon(themeProvider.isDarkMode
                ? Icons.light_mode
                : Icons.dark_mode),
            onPressed: () async {
              themeProvider.toggleTheme();
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isDarkMode', themeProvider.isDarkMode);
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clear_all':
                  _showClearAllDialog();
                  break;
                case 'toggle_overlay':
                  _toggleOverlayFAB();
                  break;
                case 'test_fab':
                  _showTestDialog();
                  break;
                case 'open_test_screen':
                  _openTestScreen();
                  break;
                case 'toggle_system_overlay':
                  _toggleSystemOverlay();
                  break;
                case 'test_notification':
                  _testNotification();
                  break;
                case 'test_scheduled':
                  _testScheduledNotification();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'toggle_overlay',
                child: Text('切換應用內浮動按鈕'),
              ),
              const PopupMenuItem(
                value: 'toggle_system_overlay',
                child: Text('🚀 切換系統級浮動按鈕'),
              ),
              const PopupMenuItem(
                value: 'test_fab',
                child: Text('測試浮動按鈕'),
              ),
              const PopupMenuItem(
                value: 'open_test_screen',
                child: Text('打開測試頁面'),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Text('清除所有備忘錄'),
              ),
              const PopupMenuItem(
                value: 'test_notification',
                child: Text('🔔 測試即時通知'),
              ),
              const PopupMenuItem(
                value: 'test_scheduled',
                child: Text('⏰ 測試定時通知'),
              ),
            ],
          ),
        ],
      ),
      body: memoProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : memos.isEmpty
          ? _buildEmptyState()
          : _buildMemoList(memos),
      floatingActionButton: !_showOverlayFAB ? FloatingActionButton(
        onPressed: _navigateToAddMemo,
        child: const Icon(Icons.add),
      ) : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _isSearching
                ? '沒有找到符合的備忘錄'
                : '今天還沒有備忘錄\n點擊 + 新增備忘錄',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoList(List<Memo> memos) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: memos.length,
      itemBuilder: (context, index) {
        final memo = memos[index];
        return Slidable(
          key: ValueKey(memo.id),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            dismissible: DismissiblePane(
              onDismissed: () => _deleteMemo(memo),
            ),
            children: [
              SlidableAction(
                onPressed: (context) => _deleteMemo(memo),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: '刪除',
              ),
            ],
          ),
          child: _buildMemoCard(memo),
        );
      },
    );
  }

  Widget _buildMemoCard(Memo memo) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        onTap: () => _navigateToEditMemo(memo.id),
        leading: CircleAvatar(
          backgroundColor: memo.isToday ? Colors.blue : Colors.grey,
          child: Text(
            memo.formattedTime.substring(0, 2), // 顯示小時
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          memo.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('時間: ${memo.formattedTime}'),
            if (memo.location != null && memo.location!.isNotEmpty) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _openMap(memo.location!),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        memo.location!,
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (memo.description != null && memo.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                memo.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _showDeleteConfirmDialog(memo),
        ),
      ),
    );
  }

  void _navigateToAddMemo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddMemoScreen()),
    );
  }

  void _navigateToEditMemo(String memoId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditMemoScreen(memoId: memoId),
      ),
    );
  }

  void _toggleOverlayFAB() {
    setState(() {
      _showOverlayFAB = !_showOverlayFAB;
    });

    if (_showOverlayFAB) {
      OverlayService.showOverlay(context, _navigateToAddMemo);
    } else {
      OverlayService.hideOverlay();
    }
  }

  void _deleteMemo(Memo memo) {
    final memoProvider = Provider.of<MemoProvider>(context, listen: false);
    memoProvider.deleteMemo(memo.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${memo.title} 已刪除'),
        action: SnackBarAction(
          label: '復原',
          onPressed: () {
            memoProvider.addMemo(memo);
          },
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(Memo memo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('確定要刪除備忘錄「${memo.title}」嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMemo(memo);
            },
            child: const Text('刪除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除所有備忘錄'),
        content: const Text('確定要刪除所有備忘錄嗎？此操作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<MemoProvider>(context, listen: false).deleteAllMemos();
            },
            child: const Text('清除全部', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}