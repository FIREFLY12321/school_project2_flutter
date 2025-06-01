import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project2/models/memo_repository.dart';
import 'package:project2/models/task_repository.dart';
import 'package:project2/providers/memo_providers.dart';
import 'package:project2/providers/providers.dart' as old_providers;


import 'package:project2/screens/dual_view_screen.dart';

class DualViewApp extends StatelessWidget {
  final bool isDarkMode;
  final MemoRepository memoRepository;
  final TaskRepository taskRepository;

  const DualViewApp({
    Key? key,
    required this.isDarkMode,
    required this.memoRepository,
    required this.taskRepository,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 新的備忘錄系統 Providers
        ChangeNotifierProvider(
          create: (_) => MemoProvider(repository: memoRepository),
        ),
        // 舊的 Todo List 系統 Providers
        ChangeNotifierProvider(
          create: (_) => old_providers.TaskProvider(repository: taskRepository),
        ),
        // 共用的主題 Provider
        ChangeNotifierProvider(
          create: (_) => old_providers.ThemeProvider(isDarkMode: isDarkMode),
        ),
      ],
      child: Builder(
        builder: (context) {
          final themeProvider = Provider.of<old_providers.ThemeProvider>(context);

          return MaterialApp(
            title: 'Memo & Todo List',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 2,
              ),
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              cardTheme: CardTheme(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 2,
              ),
              cardTheme: CardTheme(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            themeMode: themeProvider.themeMode,
            home: const DualViewScreen(),
            // 支援直屏與橫屏
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}