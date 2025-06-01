import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as notifications;
import 'package:shared_preferences/shared_preferences.dart';
import 'models/task_repository.dart';
import 'providers.dart';
import 'screens/home_screen.dart';


final notifications.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
notifications.FlutterLocalNotificationsPlugin();

// 是否已經發送過資訊的標記
const String _kHasSentDeviceInfoKey = 'has_sent_device_info';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  // 獲取 SharedPreferences 實例
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;
  // Create repository
  final taskRepository = TaskRepository();

  runApp(MyApp(
    isDarkMode: isDarkMode,
    taskRepository: taskRepository,
  ));
}

class MyApp extends StatelessWidget {
  final bool isDarkMode;
  final TaskRepository taskRepository;

  const MyApp({
    Key? key,
    required this.isDarkMode,
    required this.taskRepository,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TaskProvider(repository: taskRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(isDarkMode: isDarkMode),
        ),
      ],
      child: Builder(
        builder: (context) {
          final themeProvider = Provider.of<ThemeProvider>(context);

          return MaterialApp(
            title: 'To-Do List',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.indigo,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.indigo,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            themeMode: themeProvider.themeMode,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}