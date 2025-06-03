import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/memo.dart';
import 'dart:io' show Platform;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// 初始化通知服務
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 初始化時區數據
      tz_data.initializeTimeZones();

      // Android 設置
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS 設置
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        requestCriticalPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // 請求 Android 權限
      if (Platform.isAndroid) {
        await _requestAndroidPermissions();
      }

      _isInitialized = true;
      print('✅ 通知服務初始化成功');
    } catch (e) {
      print('❌ 通知服務初始化失敗: $e');
      rethrow;
    }
  }

  /// 請求 Android 權限
  Future<void> _requestAndroidPermissions() async {
    try {
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // 請求通知權限 (Android 13+)
        await androidImplementation.requestNotificationsPermission();

        // 請求精確鬧鐘權限 (Android 12+)
        await androidImplementation.requestExactAlarmsPermission();

        print('✅ Android 權限請求完成');
      }
    } catch (e) {
      print('❌ 請求 Android 權限失敗: $e');
    }
  }

  /// 處理通知點擊事件
  void _onNotificationTapped(NotificationResponse response) {
    print('👆 通知被點擊: ${response.payload}');
    // 這裡可以添加導航邏輯
  }

  /// 設置備忘錄定時提醒
  Future<bool> scheduleMemoReminder(Memo memo) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!memo.hasReminder) {
      print('備忘錄未設置提醒');
      return false;
    }

    // 檢查時間是否為未來時間
    final now = DateTime.now();

    // ⭐ 關鍵修復：添加10秒緩衝時間
    final minimumFutureTime = now.add(const Duration(seconds: 10));

    if (memo.dateTime.isBefore(minimumFutureTime)) {
      print('❌ 備忘錄時間太接近當前時間或已過，無法設置提醒');
      print('   當前時間: $now');
      print('   備忘錄時間: ${memo.dateTime}');
      print('   最小未來時間: $minimumFutureTime');
      return false;
    }

    try {
      // 先取消舊的通知
      await cancelMemoNotification(memo.id);

      final notificationId = memo.id.hashCode.abs() % 2147483647;

      // ⭐ 修復時區和時間精度問題
      final scheduledDate = _createPreciseScheduledTime(memo.dateTime);

      print('📅 設置通知時間:');
      print('   原始時間: ${memo.dateTime}');
      print('   調度時間: $scheduledDate');
      print('   時間差: ${scheduledDate.difference(now).inSeconds} 秒');

      // 簡化版 Android 通知詳情
      const androidDetails = AndroidNotificationDetails(
        'memo_reminders',
        '備忘錄提醒',
        channelDescription: '備忘錄時間到達時的提醒通知',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        autoCancel: true,
        icon: '@mipmap/ic_launcher',
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        onlyAlertOnce: false,
      );

      // iOS 通知詳情
      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        categoryIdentifier: 'memo_reminder',
        threadIdentifier: 'memo_reminders',
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      // 設置定時通知
      await _localNotifications.zonedSchedule(
        notificationId,
        '⏰ 備忘錄提醒',
        _buildReminderBody(memo),
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: memo.id,
      );

      print('✅ 定時提醒設置成功: ${memo.title}');
      print('   通知ID: $notificationId');
      print('   調度時間: $scheduledDate');

      // 顯示確認通知
      await _showConfirmationNotification(memo);

      // 驗證通知是否已排程
      await _verifyScheduledNotification(notificationId);

      return true;
    } catch (e) {
      print('❌ 設置定時提醒失敗: $e');
      return false;
    }
  }

  /// ⭐ 創建精確的調度時間
  tz.TZDateTime _createPreciseScheduledTime(DateTime originalTime) {
    // 確保秒數為0，避免精度問題
    final normalizedTime = DateTime(
      originalTime.year,
      originalTime.month,
      originalTime.day,
      originalTime.hour,
      originalTime.minute,
      0, // 秒數設為0
      0, // 毫秒設為0
    );

    // 轉換為 TZDateTime
    final tzDateTime = tz.TZDateTime.from(normalizedTime, tz.local);

    print('🔧 時間標準化:');
    print('   原始: $originalTime');
    print('   標準化: $normalizedTime');
    print('   TZ時間: $tzDateTime');

    return tzDateTime;
  }

  /// ⭐ 驗證通知是否已正確排程
  Future<void> _verifyScheduledNotification(int notificationId) async {
    try {
      final pendingNotifications = await _localNotifications.pendingNotificationRequests();
      final foundNotification = pendingNotifications
          .where((notification) => notification.id == notificationId)
          .toList();

      if (foundNotification.isNotEmpty) {
        print('✅ 通知已成功排程');
        print('   通知ID: ${foundNotification.first.id}');
        print('   標題: ${foundNotification.first.title}');
      } else {
        print('❌ 警告：通知未在待處理列表中找到');
      }
    } catch (e) {
      print('驗證通知排程失敗: $e');
    }
  }

  /// 顯示備忘錄建立確認通知
  Future<void> _showConfirmationNotification(Memo memo) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'memo_created',
        '備忘錄建立',
        channelDescription: '備忘錄建立確認通知',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        showWhen: false,
        autoCancel: true,
        icon: '@mipmap/ic_launcher',
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      final confirmationId = (memo.id.hashCode + 1000).abs() % 2147483647;
      final timeUntilReminder = memo.dateTime.difference(DateTime.now());

      await _localNotifications.show(
        confirmationId,
        '✅ 備忘錄提醒已設定',
        '將在 ${_formatDateTime(memo.dateTime)} 提醒您：${memo.title}\n(${_formatDuration(timeUntilReminder)}後)',
        notificationDetails,
        payload: memo.id,
      );
    } catch (e) {
      print('顯示確認通知失敗: $e');
    }
  }

  /// ⭐ 格式化時間間隔
  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}天${duration.inHours % 24}小時';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}小時${duration.inMinutes % 60}分鐘';
    } else {
      return '${duration.inMinutes}分鐘';
    }
  }

  /// 取消備忘錄通知
  Future<void> cancelMemoNotification(String memoId) async {
    try {
      final notificationId = memoId.hashCode.abs() % 2147483647;
      final confirmationId = (memoId.hashCode + 1000).abs() % 2147483647;

      await _localNotifications.cancel(notificationId);
      await _localNotifications.cancel(confirmationId);

      print('✅ 已取消備忘錄通知: $memoId (ID: $notificationId)');
    } catch (e) {
      print('取消通知失敗: $e');
    }
  }

  /// 取消所有通知
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      print('✅ 已取消所有通知');
    } catch (e) {
      print('取消所有通知失敗: $e');
    }
  }

  /// 測試即時通知
  Future<bool> testNotification() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        'test_channel',
        '測試通知',
        channelDescription: '測試通知頻道',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _localNotifications.show(
        999999,
        '🔔 測試通知',
        '這是一個測試通知，確認通知功能正常運作',
        notificationDetails,
      );

      print('✅ 測試通知已發送');
      return true;
    } catch (e) {
      print('❌ 測試通知失敗: $e');
      return false;
    }
  }

  /// ⭐ 測試精確定時通知（30秒後）
  Future<bool> testPreciseScheduledNotification() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // 使用30秒後的時間進行更精確的測試
      final testTime = DateTime.now().add(const Duration(seconds: 30));
      final scheduledDate = _createPreciseScheduledTime(testTime);

      const androidDetails = AndroidNotificationDetails(
        'test_scheduled',
        '精確定時測試',
        channelDescription: '精確定時測試通知',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _localNotifications.zonedSchedule(
        666666,
        '⏰ 精確定時測試',
        '這是30秒後的精確定時測試通知\n設定時間: ${_formatDateTime(testTime)}',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      // 顯示確認
      await _localNotifications.show(
        555555,
        '⏰ 精確定時測試已設定',
        '精確定時測試通知將在 30 秒後顯示\n請注意觀察時間精度',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_created',
            '測試確認',
            importance: Importance.defaultImportance,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: false,
          ),
        ),
      );

      print('✅ 精確定時測試通知設置成功');
      print('   當前時間: ${DateTime.now()}');
      print('   目標時間: $testTime');
      print('   調度時間: $scheduledDate');

      return true;
    } catch (e) {
      print('❌ 精確定時測試通知失敗: $e');
      return false;
    }
  }

  /// 測試定時通知（1分鐘後）
  Future<bool> testScheduledNotification() async {
    return await testPreciseScheduledNotification();
  }

  /// 檢查通知權限
  Future<bool> checkPermissions() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      if (Platform.isAndroid) {
        final androidImplementation = _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

        final result = await androidImplementation?.areNotificationsEnabled();
        return result ?? false;
      } else {
        return true; // iOS 在初始化時已請求權限
      }
    } catch (e) {
      print('檢查通知權限失敗: $e');
      return false;
    }
  }

  /// 獲取待處理的通知
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      final pending = await _localNotifications.pendingNotificationRequests();
      print('📋 當前待處理通知數量: ${pending.length}');
      for (var notification in pending) {
        print('   ID: ${notification.id} - ${notification.title}');
      }
      return pending;
    } catch (e) {
      print('獲取待處理通知失敗: $e');
      return [];
    }
  }

  /// 建立提醒通知內容
  String _buildReminderBody(Memo memo) {
    final parts = <String>[];

    parts.add('📝 ${memo.title}');

    if (memo.location != null && memo.location!.isNotEmpty) {
      parts.add('📍 ${memo.location}');
    }

    if (memo.description != null && memo.description!.isNotEmpty) {
      final description = memo.description!.length > 100
          ? '${memo.description!.substring(0, 100)}...'
          : memo.description!;
      parts.add('📋 $description');
    }

    return parts.join('\n');
  }

  /// 格式化日期時間
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}