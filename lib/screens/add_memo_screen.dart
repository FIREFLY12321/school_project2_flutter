import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as notifications;

import 'package:project2/models/memo.dart';
import 'package:project2/providers/memo_providers.dart';
import 'package:project2/services/notification_service.dart';

class AddMemoScreen extends StatefulWidget {
  const AddMemoScreen({Key? key}) : super(key: key);

  @override
  State<AddMemoScreen> createState() => _AddMemoScreenState();
}

class _AddMemoScreenState extends State<AddMemoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _timeController = TextEditingController();

  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
  bool _hasReminder = false;

  @override
  void initState() {
    super.initState();
    // 日期固定為今天且不可改
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  String? _validateTime(String? value) {
    if (value == null || value.isEmpty) {
      return '請輸入時間';
    }

    // 檢查時間格式 HH:mm
    final timeRegex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
    if (!timeRegex.hasMatch(value)) {
      return '時間格式錯誤，請使用 HH:mm 格式 (例如: 14:30)';
    }

    final parts = value.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    if (hour < 0 || hour > 23) {
      return '小時必須在 00-23 之間';
    }

    if (minute < 0 || minute > 59) {
      return '分鐘必須在 00-59 之間';
    }

    return null;
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() {
        _selectedTime = time;
        _timeController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _scheduleNotification(Memo memo) async {
    if (!memo.hasReminder) return;

    final notificationService = NotificationService();

    // 顯示建立確認通知


    // 如果時間是未來時間，也可以在這裡設置定時提醒
    // 注意：這裡只是即時通知，真正的定時通知需要更複雜的實作
    if (memo.dateTime.isAfter(DateTime.now())) {
      print('備忘錄已設定提醒：${memo.title} at ${memo.formattedTime}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final memoProvider = Provider.of<MemoProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('新增備忘錄'),
        elevation: 2,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 日期顯示 (不可編輯)
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.blue),
                title: const Text('日期'),
                subtitle: Text(
                  '${_selectedDate.year}年${_selectedDate.month}月${_selectedDate.day}日',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: const Text(
                  '(今天)',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 時間輸入
            TextFormField(
              controller: _timeController,
              decoration: InputDecoration(
                labelText: '時間*',
                hintText: '例如: 14:30',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.access_time),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.schedule),
                  onPressed: _selectTime,
                ),
              ),
              validator: _validateTime,
              keyboardType: TextInputType.datetime,
            ),

            const SizedBox(height: 16),

            // 標題輸入
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '標題*',
                hintText: '請輸入備忘錄標題',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '請輸入標題';
                }
                return null;
              },
              maxLength: 100,
            ),

            const SizedBox(height: 16),

            // 地點輸入
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: '地點',
                hintText: '請輸入地點 (選填)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLength: 100,
            ),

            const SizedBox(height: 16),

            // 說明輸入
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '說明',
                hintText: '請輸入詳細說明 (選填)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              maxLength: 500,
            ),

            const SizedBox(height: 16),

            // 提醒設定
            Card(
              child: SwitchListTile(
                title: const Text('設定提醒'),
                subtitle: const Text('時間到時會收到通知'),
                value: _hasReminder,
                onChanged: (value) {
                  setState(() {
                    _hasReminder = value;
                  });
                },
                secondary: const Icon(Icons.notifications),
              ),
            ),

            const SizedBox(height: 24),

            // 儲存按鈕
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  // 解析時間
                  final timeParts = _timeController.text.split(':');
                  final hour = int.parse(timeParts[0]);
                  final minute = int.parse(timeParts[1]);

                  final memoDateTime = DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                    hour,
                    minute,
                  );

                  final memo = Memo(
                    id: const Uuid().v4(),
                    title: _titleController.text.trim(),
                    dateTime: memoDateTime,
                    location: _locationController.text.trim().isEmpty
                        ? null
                        : _locationController.text.trim(),
                    description: _descriptionController.text.trim().isEmpty
                        ? null
                        : _descriptionController.text.trim(),
                    hasReminder: _hasReminder,
                  );

                  await memoProvider.addMemo(memo);

                  if (_hasReminder) {
                    await _scheduleNotification(memo);
                  }

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('備忘錄已新增'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                '儲存',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 16),

            // 提示文字
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: const Text(
                '💡 提示：\n'
                    '• 日期固定為今天，無法修改\n'
                    '• 時間格式為 24 小時制 (例如: 14:30)\n'
                    '• 如果有填寫地點，可以在主頁面點擊地點查看地圖',
                style: TextStyle(fontSize: 12, color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}