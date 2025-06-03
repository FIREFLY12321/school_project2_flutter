import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_file.dart';
import 'package:project2/services/notification_service.dart';
import 'package:project2/services/system_overlay_service.dart';
import 'package:project2/widgets/dual_view_application.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 新的備忘錄系統
import 'models/memo_repository.dart';

// 舊的 Todo List 系統
import 'models/task_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化通知服務（使用 Awesome Notifications）
  await NotificationService().initialize();

  // 初始化系統級 Overlay 服務
  await SystemOverlayService.initialize();

  // 獲取主題設定
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;

  // 創建兩個系統的倉庫
  final memoRepository = MemoRepository();
  final taskRepository = TaskRepository();

  runApp(DualViewApp(
    isDarkMode: isDarkMode,
    memoRepository: memoRepository,
    taskRepository: taskRepository,
  ));
}