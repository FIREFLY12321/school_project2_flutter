import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SystemOverlayService {
  static const MethodChannel _channel = MethodChannel('system_overlay');
  static bool _isOverlayVisible = false;
  static bool _hasPermission = false;

  static bool get isOverlayVisible => _isOverlayVisible;
  static bool get hasPermission => _hasPermission;

  /// 初始化系統級 Overlay 服務
  static Future<void> initialize() async {
    _channel.setMethodCallHandler(_handleMethodCall);
    await _checkPermission();
  }

  /// 處理來自原生平台的方法調用
  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onOverlayClicked':
        await _onOverlayClicked();
        break;
      case 'onPermissionResult':
        _hasPermission = call.arguments['granted'] ?? false;
        break;
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details: 'Method ${call.method} not implemented',
        );
    }
  }

  /// 檢查系統級窗口權限
  static Future<bool> checkPermission() async {
    try {
      final bool result = await _channel.invokeMethod('checkPermission');
      _hasPermission = result;
      return result;
    } catch (e) {
      print('檢查權限失敗: $e');
      return false;
    }
  }

  /// 請求系統級窗口權限
  static Future<bool> requestPermission() async {
    try {
      final bool result = await _channel.invokeMethod('requestPermission');
      _hasPermission = result;
      return result;
    } catch (e) {
      print('請求權限失敗: $e');
      return false;
    }
  }

  /// 顯示系統級 Overlay
  static Future<void> showSystemOverlay() async {
    if (!_hasPermission) {
      final granted = await requestPermission();
      if (!granted) {
        throw Exception('沒有系統級窗口權限');
      }
    }

    try {
      await _channel.invokeMethod('showOverlay', {
        'x': 100.0,
        'y': 100.0,
        'width': 56.0,
        'height': 56.0,
        'text': '+',
        'backgroundColor': '#2196F3',
        'textColor': '#FFFFFF',
      });
      _isOverlayVisible = true;
    } catch (e) {
      print('顯示 Overlay 失敗: $e');
      rethrow;
    }
  }

  /// 隱藏系統級 Overlay
  static Future<void> hideSystemOverlay() async {
    try {
      await _channel.invokeMethod('hideOverlay');
      _isOverlayVisible = false;
    } catch (e) {
      print('隱藏 Overlay 失敗: $e');
    }
  }

  /// 更新 Overlay 位置
  static Future<void> updateOverlayPosition(double x, double y) async {
    if (!_isOverlayVisible) return;

    try {
      await _channel.invokeMethod('updatePosition', {
        'x': x,
        'y': y,
      });
    } catch (e) {
      print('更新位置失敗: $e');
    }
  }

  /// 更新 Overlay 外觀
  static Future<void> updateOverlayAppearance({
    String? text,
    String? backgroundColor,
    String? textColor,
  }) async {
    if (!_isOverlayVisible) return;

    try {
      await _channel.invokeMethod('updateAppearance', {
        if (text != null) 'text': text,
        if (backgroundColor != null) 'backgroundColor': backgroundColor,
        if (textColor != null) 'textColor': textColor,
      });
    } catch (e) {
      print('更新外觀失敗: $e');
    }
  }

  /// 切換 Overlay 顯示狀態
  static Future<void> toggleOverlay() async {
    if (_isOverlayVisible) {
      await hideSystemOverlay();
    } else {
      await showSystemOverlay();
    }
  }

  /// 檢查權限（內部方法）
  static Future<void> _checkPermission() async {
    _hasPermission = await checkPermission();
  }

  /// 處理 Overlay 點擊事件
  static Future<void> _onOverlayClicked() async {
    print('系統級 Overlay 被點擊了！');

    // 打開 App 到新增備忘錄頁面
    try {
      await _channel.invokeMethod('openApp', {
        'action': 'add_memo',
      });
    } catch (e) {
      print('打開 App 失敗: $e');
    }
  }

  /// 測試系統級 Overlay 功能
  static Future<bool> testSystemOverlay() async {
    try {
      // 檢查權限
      if (!await checkPermission()) {
        print('❌ 沒有系統級窗口權限');
        return false;
      }

      // 顯示 Overlay
      await showSystemOverlay();
      print('✅ 系統級 Overlay 顯示成功');

      // 等待 3 秒
      await Future.delayed(const Duration(seconds: 3));

      // 隱藏 Overlay
      await hideSystemOverlay();
      print('✅ 系統級 Overlay 隱藏成功');

      return true;
    } catch (e) {
      print('❌ 測試失敗: $e');
      return false;
    }
  }

  /// 獲取 Overlay 狀態資訊
  static Map<String, dynamic> getOverlayInfo() {
    return {
      'isVisible': _isOverlayVisible,
      'hasPermission': _hasPermission,
      'platform': Theme.of(
          WidgetsBinding.instance.platformDispatcher.views.first as BuildContext? ??
              NavigatorState().context
      ).platform.toString(),
    };
  }
}

/// 系統級 Overlay 控制 Widget
class SystemOverlayControlWidget extends StatefulWidget {
  const SystemOverlayControlWidget({Key? key}) : super(key: key);

  @override
  State<SystemOverlayControlWidget> createState() => _SystemOverlayControlWidgetState();
}

class _SystemOverlayControlWidgetState extends State<SystemOverlayControlWidget> {
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeOverlay();
  }

  Future<void> _initializeOverlay() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '正在初始化...';
    });

    try {
      await SystemOverlayService.initialize();
      final hasPermission = await SystemOverlayService.checkPermission();

      setState(() {
        _statusMessage = hasPermission ? '已有權限' : '需要權限';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '初始化失敗: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '正在請求權限...';
    });

    try {
      final granted = await SystemOverlayService.requestPermission();
      setState(() {
        _statusMessage = granted ? '權限已授予' : '權限被拒絕';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '請求權限失敗: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleOverlay() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '正在切換 Overlay...';
    });

    try {
      await SystemOverlayService.toggleOverlay();
      setState(() {
        _statusMessage = SystemOverlayService.isOverlayVisible
            ? 'Overlay 已顯示'
            : 'Overlay 已隱藏';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '操作失敗: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testOverlay() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '正在測試 Overlay...';
    });

    try {
      final success = await SystemOverlayService.testSystemOverlay();
      setState(() {
        _statusMessage = success ? '測試成功' : '測試失敗';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '測試失敗: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '🚀 系統級 Overlay 控制',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 狀態顯示
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('狀態: $_statusMessage'),
                  const SizedBox(height: 4),
                  Text('Overlay 可見: ${SystemOverlayService.isOverlayVisible ? "是" : "否"}'),
                  Text('有權限: ${SystemOverlayService.hasPermission ? "是" : "否"}'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 控制按鈕
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                children: [
                  if (!SystemOverlayService.hasPermission)
                    ElevatedButton.icon(
                      onPressed: _requestPermission,
                      icon: const Icon(Icons.security),
                      label: const Text('請求系統級窗口權限'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),

                  const SizedBox(height: 8),

                  ElevatedButton.icon(
                    onPressed: SystemOverlayService.hasPermission ? _toggleOverlay : null,
                    icon: Icon(SystemOverlayService.isOverlayVisible
                        ? Icons.visibility_off
                        : Icons.visibility),
                    label: Text(SystemOverlayService.isOverlayVisible
                        ? '隱藏 Overlay'
                        : '顯示 Overlay'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 8),

                  ElevatedButton.icon(
                    onPressed: SystemOverlayService.hasPermission ? _testOverlay : null,
                    icon: const Icon(Icons.science),
                    label: const Text('測試 Overlay 功能'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // 說明文字
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Text(
                '💡 說明：\n'
                    '• 系統級 Overlay 需要特殊權限\n'
                    '• 可在 App 外顯示浮動按鈕\n'
                    '• 點擊可快速打開 App\n'
                    '• 支援拖拽移動位置',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}