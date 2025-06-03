import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import '../models/memo.dart';

class GoogleCalendarService {
  static const _scopes = [calendar.CalendarApi.calendarScope];
  static const _clientId = 'YOUR_CLIENT_ID.apps.googleusercontent.com';
  static const _clientSecret = 'YOUR_CLIENT_SECRET';

  static GoogleCalendarService? _instance;
  calendar.CalendarApi? _calendarApi;
  AutoRefreshingAuthClient? _authClient;

  static GoogleCalendarService get instance {
    _instance ??= GoogleCalendarService._();
    return _instance!;
  }

  GoogleCalendarService._();

  /// 初始化 Google Calendar 服務
  Future<bool> initialize() async {
    try {
      final credentials = ClientId(_clientId, _clientSecret);

      _authClient = await clientViaUserConsent(
        credentials,
        _scopes,
        _promptUser,
      );

      _calendarApi = calendar.CalendarApi(_authClient!);

      print('✅ Google Calendar 服務初始化成功');
      return true;
    } catch (e) {
      print('❌ Google Calendar 初始化失敗: $e');
      return false;
    }
  }

  /// 用戶授權提示
  void _promptUser(String url) async {
    print('請在瀏覽器中打開以下 URL 進行授權：');
    print(url);

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// 創建備忘錄事件到 Google Calendar
  Future<bool> createMemoEvent(Memo memo) async {
    if (_calendarApi == null) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    try {
      // 創建事件
      final event = calendar.Event()
        ..summary = memo.title
        ..description = _buildEventDescription(memo)
        ..location = memo.location
        ..start = calendar.EventDateTime()
        ..end = calendar.EventDateTime();

      // 設置開始時間
      event.start!.dateTime = memo.dateTime;
      event.start!.timeZone = 'Asia/Taipei';

      // 設置結束時間（默認1小時後）
      final endTime = memo.dateTime.add(const Duration(hours: 1));
      event.end!.dateTime = endTime;
      event.end!.timeZone = 'Asia/Taipei';

      // 設置提醒
      if (memo.hasReminder) {
        event.reminders = calendar.EventReminders()
          ..useDefault = false
          ..overrides = [
            calendar.EventReminder()
              ..method = 'popup'
              ..minutes = 0, // 準時提醒
            calendar.EventReminder()
              ..method = 'email'
              ..minutes = 15, // 15分鐘前郵件提醒
          ];
      }

      // 添加自定義屬性來標識這是我們的應用創建的
      event.extendedProperties = calendar.EventExtendedProperties()
        ..private = {
          'source': 'flutter_memo_app',
          'memo_id': memo.id,
        };

      // 創建事件到主日曆
      final createdEvent = await _calendarApi!.events.insert(event, 'primary');

      print('✅ 已創建 Google Calendar 事件');
      print('   事件ID: ${createdEvent.id}');
      print('   事件連結: ${createdEvent.htmlLink}');

      return true;
    } catch (e) {
      print('❌ 創建 Google Calendar 事件失敗: $e');
      return false;
    }
  }

  /// 更新備忘錄事件
  Future<bool> updateMemoEvent(Memo memo) async {
    if (_calendarApi == null) return false;

    try {
      // 先查找現有事件
      final existingEventId = await _findEventByMemoId(memo.id);
      if (existingEventId == null) {
        // 如果找不到，創建新事件
        return await createMemoEvent(memo);
      }

      // 獲取現有事件
      final existingEvent = await _calendarApi!.events.get('primary', existingEventId);

      // 更新事件內容
      existingEvent.summary = memo.title;
      existingEvent.description = _buildEventDescription(memo);
      existingEvent.location = memo.location;

      // 更新時間
      existingEvent.start!.dateTime = memo.dateTime;
      existingEvent.end!.dateTime = memo.dateTime.add(const Duration(hours: 1));

      // 更新提醒設置
      if (memo.hasReminder) {
        existingEvent.reminders = calendar.EventReminders()
          ..useDefault = false
          ..overrides = [
            calendar.EventReminder()
              ..method = 'popup'
              ..minutes = 0,
            calendar.EventReminder()
              ..method = 'email'
              ..minutes = 15,
          ];
      } else {
        existingEvent.reminders = calendar.EventReminders()..useDefault = false;
      }

      // 更新事件
      await _calendarApi!.events.update(existingEvent, 'primary', existingEventId);

      print('✅ 已更新 Google Calendar 事件: $existingEventId');
      return true;
    } catch (e) {
      print('❌ 更新 Google Calendar 事件失敗: $e');
      return false;
    }
  }

  /// 刪除備忘錄事件
  Future<bool> deleteMemoEvent(String memoId) async {
    if (_calendarApi == null) return false;

    try {
      final eventId = await _findEventByMemoId(memoId);
      if (eventId == null) {
        print('未找到對應的 Google Calendar 事件');
        return true; // 沒有事件也算成功
      }

      await _calendarApi!.events.delete('primary', eventId);

      print('✅ 已刪除 Google Calendar 事件: $eventId');
      return true;
    } catch (e) {
      print('❌ 刪除 Google Calendar 事件失敗: $e');
      return false;
    }
  }

  /// 根據備忘錄ID查找事件
  Future<String?> _findEventByMemoId(String memoId) async {
    try {
      final events = await _calendarApi!.events.list(
        'primary',
        privateExtendedProperty: ['memo_id=$memoId'],
        maxResults: 1,
      );

      if (events.items?.isNotEmpty == true) {
        return events.items!.first.id;
      }

      return null;
    } catch (e) {
      print('查找事件失敗: $e');
      return null;
    }
  }

  /// 建立事件描述
  String _buildEventDescription(Memo memo) {
    final parts = <String>[];

    parts.add('📱 來自備忘錄應用');

    if (memo.description != null && memo.description!.isNotEmpty) {
      parts.add('');
      parts.add('📝 詳細說明：');
      parts.add(memo.description!);
    }

    parts.add('');
    parts.add('🆔 備忘錄ID: ${memo.id}');

    return parts.join('\n');
  }

  /// 打開 Google Calendar 應用或網頁
  Future<void> openGoogleCalendar() async {
    const calendarUrl = 'https://calendar.google.com/calendar/u/0/r';
    final uri = Uri.parse(calendarUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// 檢查是否已初始化
  bool get isInitialized => _calendarApi != null;

  /// 登出
  Future<void> signOut() async {
    _authClient?.close();
    _authClient = null;
    _calendarApi = null;
    _instance = null;
    print('✅ 已登出 Google Calendar');
  }
}