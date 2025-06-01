import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/providers.dart' as old_providers;
import 'home_screen.dart';
import 'memo_home_screen.dart';

class DualViewScreen extends StatefulWidget {
  const DualViewScreen({Key? key}) : super(key: key);

  @override
  State<DualViewScreen> createState() => _DualViewScreenState();
}

class _DualViewScreenState extends State<DualViewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pageController = PageController();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _pageController.animateToPage(
          _tabController.index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _tabController.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<old_providers.ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'Memo' : 'Todo List'),
        backgroundColor: _currentIndex == 0 ? Colors.blue : Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
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
                case 'about':
                  _showAboutDialog();
                  break;
                case 'switch_view':
                  _switchToOtherView();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'switch_view',
                child: Row(
                  children: [
                    Icon(_currentIndex == 0 ? Icons.task_alt : Icons.event_note),
                    const SizedBox(width: 8),
                    Text(_currentIndex == 0 ? 'switch to Todo List' : 'switch to Memo'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info),
                    SizedBox(width: 8),
                    Text('關於'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.event_note),
              text: '備忘錄',
            ),
            Tab(
              icon: Icon(Icons.task_alt),
              text: 'Todo List',
            ),
          ],
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: const [
          // 左側：新的備忘錄系統
          MemoHomeScreen(),
          // 右側：舊的 Todo List 系統
          HomeScreen(),
        ],
      ),
      // 根據當前頁面顯示不同的指示器
      bottomNavigationBar: Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _currentIndex == 0
                ? [Colors.blue.shade400, Colors.blue.shade600]
                : [Colors.indigo.shade400, Colors.indigo.shade600],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 頁面指示器
            Row(
              children: List.generate(2, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? Colors.white
                        : Colors.white54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(width: 16),
            // 當前頁面說明
            Text(
              _currentIndex == 0 ? '滑動切換到 Todo List →' : '← 滑動切換到備忘錄',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _switchToOtherView() {
    final targetIndex = _currentIndex == 0 ? 1 : 0;
    _pageController.animateToPage(
      targetIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('關於此 App'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '�️ 備忘錄 & Todo List',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text('這是一個結合兩種管理系統的應用程式：'),
            const SizedBox(height: 8),
            const Text('� 左側：行事曆備忘錄'),
            const Text('  • 時間導向的備忘錄系統'),
            const Text('  • 支援地點和地圖功能'),
            const Text('  • 專注於當日行程'),
            const SizedBox(height: 8),
            const Text('✅ 右側：Todo List'),
            const Text('  • 任務導向的管理系統'),
            const Text('  • 支援優先級分類'),
            const Text('  • 完整的任務管理'),
            const SizedBox(height: 8),
            const Text('� 使用方式：'),
            const Text('  • 左右滑動切換系統'),
            const Text('  • 點擊標籤頁切換'),
            const Text('  • 各系統獨立運作'),
          ],
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
}