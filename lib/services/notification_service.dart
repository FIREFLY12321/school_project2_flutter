import 'package:flutter_local_notifications/flutter_local_notifications.dart' as notifications;
import '../models/memo.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final notifications.FlutterLocalNotificationsPlugin _localNotifications =
  notifications.FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// 初始化通知服務
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const androidSettings = notifications.AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = notifications.DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = notifications.InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = true;
      print('通知服務初始化成功');
    } catch (e) {
      print('通知服務初始化失敗: $e');
    }
  }

  /// 處理通知點擊事件
  void _onNotificationTapped(notifications.NotificationResponse response) {
    print('通知被點擊: ${response.payload}');
    // 可以在這裡添加導航邏輯
  }

  /// 顯示備忘錄提醒通知
  Future<void> showMemoReminder(Memo memo) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      const androidDetails = notifications.AndroidNotificationDetails(
        'memo_reminders',
        'Memo Reminders',
        channelDescription: 'Notifications for memo reminders',
        importance: notifications.Importance.max,
        priority: notifications.Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = notifications.DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        badgeNumber: 1,
      );

      const notificationDetails = notifications.NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final title = '備忘錄提醒: ${memo.title}';
      final body = _buildNotificationBody(memo);

      await _localNotifications.show(
        memo.id.hashCode,
        title,
        body,
        notificationDetails,
        payload: memo.id,
      );
    } catch (e) {
      print('顯示通知時發生錯誤: $e');
    }
  }

  /// 顯示備忘錄建立確認通知
  Future<void> showMemoCreated(Memo memo) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      const androidDetails = notifications.AndroidNotificationDetails(
        'memo_created',
        'Memo Created',
        channelDescription: 'Notifications when memo is created',
        importance: notifications.Importance.defaultImportance,
        priority: notifications.Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = notifications.DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
      );

      const notificationDetails = notifications.NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final title = memo.hasReminder ? '備忘錄提醒已設定' : '備忘錄已建立';
      final body = memo.hasReminder
          ? '將在 ${memo.formattedTime} 提醒您：${memo.title}'
          : '備忘錄「${memo.title}」已成功建立';

      await _localNotifications.show(
        memo.id.hashCode + 1000, // 避免與提醒通知衝突
        title,
        body,
        notificationDetails,
        payload: memo.id,
      );
    } catch (e) {
      print('顯示建立通知時發生錯誤: $e');
    }
  }

  /// 取消指定備忘錄的通知
  Future<void> cancelMemoNotification(String memoId) async {
    try {
      final notificationId = memoId.hashCode;
      await _localNotifications.cancel(notificationId);
      await _localNotifications.cancel(notificationId + 1000); // 取消建立通知
    } catch (e) {
      print('取消通知時發生錯誤: $e');
    }
  }

  /// 取消所有通知
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
    } catch (e) {
      print('取消所有通知時發生錯誤: $e');
    }
  }

  /// 檢查通知權限
  Future<bool> checkPermissions() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final result = await _localNotifications
          .resolvePlatformSpecificImplementation<
          notifications.AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled();
      return result ?? true; // iOS 預設為 true
    } catch (e) {
      print('檢查通知權限時發生錯誤: $e');
      return false;
    }
  }

  /// 請求通知權限 (主要用於 Android 13+)
  Future<bool> requestPermissions() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
          notifications.AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final granted = await androidImplementation.requestNotificationsPermission();
        return granted ?? false;
      }
      return true; // iOS 在初始化時已請求權限
    } catch (e) {
      print('請求通知權限時發生錯誤: $e');
      return false;
    }
  }

  /// 建立通知內容
  String _buildNotificationBody(Memo memo) {
    final parts = <String>[];

    parts.add('時間：${memo.formattedTime}');

    if (memo.location != null && memo.location!.isNotEmpty) {
      parts.add('地點：${memo.location}');
    }

    if (memo.description != null && memo.description!.isNotEmpty) {
      // 限制描述長度
      final description = memo.description!.length > 50
          ? '${memo.description!.substring(0, 50)}...'
          : memo.description!;
      parts.add('說明：$description');
    }

    return parts.join('\n');
  }

  /// 獲取所有待處理的通知
  Future<List<notifications.PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _localNotifications.pendingNotificationRequests();
    } catch (e) {
      print('獲取待處理通知時發生錯誤: $e');
      return [];
    }
  }

  /// 測試通知功能
  Future<void> testNotification() async {
    if (!_isInitialized) {
      await initialize();
    }

    const androidDetails = notifications.AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Test notification channel',
      importance: notifications.Importance.max,
      priority: notifications.Priority.high,
    );

    const iosDetails = notifications.DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = notifications.NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      999999,
      '� 測試通知',
      '這是一個測試通知，確認通知功能正常運作',
      notificationDetails,
    );
  }
}