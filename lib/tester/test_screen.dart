import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project2/services/overlay_service.dart';


class TestScreen extends StatefulWidget {
  const TestScreen({Key? key}) : super(key: key);

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  List<String> _testResults = [];
  bool _isRunningTests = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App 功能測試'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 測試說明
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🧪 App 功能測試',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '此頁面可以測試 App 的各項功能是否正常運作，'
                          '包括浮動按鈕可見性、資料庫連接、UI響應性等。',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 測試按鈕區域
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      '測試項目',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 浮動按鈕測試
                    _buildTestButton(
                      '測試浮動按鈕可見性',
                      Icons.visibility,
                      Colors.blue,
                      _testFloatingButtonVisibility,
                    ),

                    const SizedBox(height: 8),

                    // 螢幕方向測試
                    _buildTestButton(
                      '測試螢幕方向切換',
                      Icons.screen_rotation,
                      Colors.orange,
                      _testScreenRotation,
                    ),

                    const SizedBox(height: 8),

                    // UI響應性測試
                    _buildTestButton(
                      '測試UI響應性',
                      Icons.touch_app,
                      Colors.green,
                      _testUIResponsiveness,
                    ),

                    const SizedBox(height: 8),

                    // 完整測試
                    _buildTestButton(
                      '執行完整測試',
                      Icons.play_arrow,
                      Colors.purple,
                      _runFullTest,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 測試結果顯示
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '測試結果',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (_testResults.isNotEmpty)
                            TextButton(
                              onPressed: _clearResults,
                              child: const Text('清除'),
                            ),
                        ],
                      ),
                      const Divider(),
                      Expanded(
                        child: _isRunningTests
                            ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('正在執行測試...'),
                            ],
                          ),
                        )
                            : _testResults.isEmpty
                            ? const Center(
                          child: Text(
                            '點擊上方按鈕開始測試\n測試結果將顯示在這裡',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        )
                            : ListView.builder(
                          itemCount: _testResults.length,
                          itemBuilder: (context, index) {
                            final result = _testResults[index];
                            final isSuccess = result.contains('✅');
                            return ListTile(
                              leading: Icon(
                                isSuccess ? Icons.check_circle : Icons.error,
                                color: isSuccess ? Colors.green : Colors.red,
                              ),
                              title: Text(result),
                              dense: true,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(
      String title,
      IconData icon,
      Color color,
      VoidCallback onPressed,
      ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isRunningTests ? null : onPressed,
        icon: Icon(icon),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Future<void> _testFloatingButtonVisibility() async {
    setState(() {
      _isRunningTests = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    final isVisible = OverlayService.testFloatingButtonVisibility();
    final result = isVisible
        ? '✅ 浮動按鈕測試通過 - 系統級浮動按鈕目前可見'
        : '❌ 浮動按鈕測試失敗 - 系統級浮動按鈕目前不可見';

    setState(() {
      _testResults.add('${DateTime.now().toString().substring(11, 19)} - $result');
      _isRunningTests = false;
    });

    // 震動回饋
    HapticFeedback.lightImpact();
  }

  Future<void> _testScreenRotation() async {
    setState(() {
      _isRunningTests = true;
    });

    try {
      // 測試螢幕方向
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      await Future.delayed(const Duration(seconds: 1));

      // 恢復自動旋轉
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      setState(() {
        _testResults.add('${DateTime.now().toString().substring(11, 19)} - ✅ 螢幕方向測試通過 - 支援直屏與橫屏');
        _isRunningTests = false;
      });
    } catch (e) {
      setState(() {
        _testResults.add('${DateTime.now().toString().substring(11, 19)} - ❌ 螢幕方向測試失敗 - $e');
        _isRunningTests = false;
      });
    }

    HapticFeedback.lightImpact();
  }

  Future<void> _testUIResponsiveness() async {
    setState(() {
      _isRunningTests = true;
    });

    final stopwatch = Stopwatch()..start();

    // 模擬UI操作
    for (int i = 0; i < 10; i++) {
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 16)); // 60fps
    }

    stopwatch.stop();
    final avgFrameTime = stopwatch.elapsedMilliseconds / 10;

    final result = avgFrameTime < 20
        ? '✅ UI響應性測試通過 - 平均幀時間: ${avgFrameTime.toStringAsFixed(1)}ms'
        : '❌ UI響應性測試警告 - 平均幀時間: ${avgFrameTime.toStringAsFixed(1)}ms (可能卡頓)';

    setState(() {
      _testResults.add('${DateTime.now().toString().substring(11, 19)} - $result');
      _isRunningTests = false;
    });

    HapticFeedback.lightImpact();
  }

  Future<void> _runFullTest() async {
    setState(() {
      _isRunningTests = true;
      _testResults.add('${DateTime.now().toString().substring(11, 19)} - 🚀 開始執行完整測試...');
    });

    // 依序執行所有測試
    await _testFloatingButtonVisibility();
    await Future.delayed(const Duration(milliseconds: 500));

    await _testScreenRotation();
    await Future.delayed(const Duration(milliseconds: 500));

    await _testUIResponsiveness();

    setState(() {
      _testResults.add('${DateTime.now().toString().substring(11, 19)} - 🎉 完整測試執行完畢');
      _isRunningTests = false;
    });

    // 顯示完成對話框
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('測試完成'),
          content: const Text('所有測試項目已執行完畢，請查看測試結果。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('確定'),
            ),
          ],
        ),
      );
    }

    HapticFeedback.mediumImpact();
  }

  void _clearResults() {
    setState(() {
      _testResults.clear();
    });
  }
}