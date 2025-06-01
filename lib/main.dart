import 'package:flutter/material.dart';
import 'package:project2/services/notification_service.dart';
import 'package:project2/widgets/dual_view_application.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 新的備忘錄系統
import 'models/memo_repository.dart';


// 舊的 Todo List 系統
import 'models/task_repository.dart';

import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化通知服務
  await NotificationService().initialize();

  // 獲取主題設定
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;

  // 創建兩個系統的倉庫
  final memoRepository = MemoRepository();     // 新的備忘錄系統
  final taskRepository = TaskRepository();     // 舊的 Todo List 系統

  runApp(DualViewApp(
    isDarkMode: isDarkMode,
    memoRepository: memoRepository,
    taskRepository: taskRepository,
  ));
}