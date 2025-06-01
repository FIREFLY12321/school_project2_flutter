import 'package:flutter/cupertino.dart'              ;

import 'package:project2/models/task_repository.dart';
import 'package:project2/main.dart'                  ;
import 'package:project2/models/memo_repository.dart';

import 'dual_view_application.dart';

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
    // 這是為了保持與舊代碼的相容性
    return DualViewApp(
      isDarkMode: isDarkMode,
      memoRepository: MemoRepository(),
      taskRepository: taskRepository,
    );
  }
}