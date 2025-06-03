import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:project2/models/memo.dart';
import 'package:project2/providers/memo_providers.dart';

import 'package:project2/services/notification_service.dart';


class EditMemoScreen extends StatefulWidget {
  final String memoId;

  const EditMemoScreen({Key? key, required this.memoId}) : super(key: key);

  @override
  State<EditMemoScreen> createState() => _EditMemoScreenState();
}

class _EditMemoScreenState extends State<EditMemoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _timeController = TextEditingController();

  bool _isLoading = true;
  Memo? _memo;
  TimeOfDay? _selectedTime;
  bool _hasReminder = false;

  @override
  void initState() {
    super.initState();
    _loadMemo();
  }

  Future<void> _loadMemo() async {
    final memoProvider = Provider.of<MemoProvider>(context, listen: false);
    final memo = await memoProvider.getMemoById(widget.memoId);

    if (memo != null && mounted) {
      setState(() {
        _memo = memo;
        _titleController.text = memo.title;
        _locationController.text = memo.location ?? '';
        _descriptionController.text = memo.description ?? '';
        _timeController.text = memo.formattedTime;
        _selectedTime = TimeOfDay(
          hour: memo.dateTime.hour,
          minute: memo.dateTime.minute,
        );
        _hasReminder = memo.hasReminder;
        _isLoading = false;
      });
    } else if (mounted) {
      Navigator.pop(context);
    }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _memo == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('編輯備忘錄')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final memoProvider = Provider.of<MemoProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('編輯備忘錄'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _showDeleteDialog,
          ),
        ],
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
                  '${_memo!.dateTime.year}年${_memo!.dateTime.month}月${_memo!.dateTime.day}日',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Text(
                  _memo!.isToday ? '(今天)' : '',
                  style: const TextStyle(color: Colors.blue),
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

            // 儲存變更按鈕
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final timeParts = _timeController.text.split(':');
                  final hour = int.parse(timeParts[0]);
                  final minute = int.parse(timeParts[1]);

                  final updatedDateTime = DateTime(
                    _memo!.dateTime.year,
                    _memo!.dateTime.month,
                    _memo!.dateTime.day,
                    hour,
                    minute,
                  );

                  final updatedMemo = _memo!.copyWith(
                    title: _titleController.text.trim(),
                    dateTime: updatedDateTime,
                    location: _locationController.text.trim().isEmpty
                        ? null
                        : _locationController.text.trim(),
                    description: _descriptionController.text.trim().isEmpty
                        ? null
                        : _descriptionController.text.trim(),
                    hasReminder: _hasReminder,
                  );

                  await memoProvider.updateMemo(updatedMemo);

                  // 更新通知
                  final notificationService = NotificationService();
                  if (_hasReminder) {
                    //await notificationService.showMemoCreated(updatedMemo);
                  } else {
                    // 如果關閉提醒，取消通知
                    await notificationService.cancelMemoNotification(updatedMemo.id);
                  }

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('備忘錄已更新'),
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
                '儲存變更',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 16),

            // 刪除按鈕
            OutlinedButton(
              onPressed: _showDeleteDialog,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              child: const Text(
                '刪除備忘錄',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('確定要刪除備忘錄「${_memo!.title}」嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final memoProvider = Provider.of<MemoProvider>(context, listen: false);
              await memoProvider.deleteMemo(widget.memoId);

              // 取消通知
              final notificationService = NotificationService();
              await notificationService.cancelMemoNotification(_memo!.id);

              if (mounted) {
                Navigator.pop(context); // 關閉對話框
                Navigator.pop(context); // 關閉編輯頁面
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('備忘錄已刪除'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('刪除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}