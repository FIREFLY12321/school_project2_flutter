package com.example.project2

// 檔案位置: android/app/src/main/kotlin/com/example/project2/MainActivity.kt



import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.widget.Toast
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "system_overlay"
    private val OVERLAY_PERMISSION_REQUEST_CODE = 1000

    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 初始化 MethodChannel
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            handleMethodCall(call, result)
        }
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "checkPermission" -> {
                    result.success(checkOverlayPermission())
                }
                "requestPermission" -> {
                    requestOverlayPermission()
                    result.success(true)
                }
                "showOverlay" -> {
                    if (showSystemOverlay()) {
                        result.success(true)
                    } else {
                        result.error("PERMISSION_DENIED", "沒有系統級窗口權限", null)
                    }
                }
                "hideOverlay" -> {
                    hideSystemOverlay()
                    result.success(true)
                }
                "isServiceRunning" -> {
                    result.success(OverlayService.isRunning())
                }
                "openApp" -> {
                    val args = call.arguments as? Map<String, Any>
                    openApp(args)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        } catch (e: Exception) {
            result.error("ERROR", "操作失敗: ${e.message}", e.toString())
        }
    }

    /**
     * 檢查系統級窗口權限
     */
    private fun checkOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    /**
     * 請求系統級窗口權限
     */
    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.canDrawOverlays(this)) {
                try {
                    val intent = Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:$packageName")
                    )
                    startActivityForResult(intent, OVERLAY_PERMISSION_REQUEST_CODE)
                } catch (e: Exception) {
                    // 備用方案：打開設定頁面
                    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                    intent.data = Uri.parse("package:$packageName")
                    startActivity(intent)
                }
            }
        }
    }

    /**
     * 顯示系統級 Overlay (使用前台服務)
     */
    private fun showSystemOverlay(): Boolean {
        if (!checkOverlayPermission()) {
            return false
        }

        try {
            // 啟動前台服務來保持 Overlay 運行
            OverlayService.startService(this)
            return true
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }

    /**
     * 隱藏系統級 Overlay (停止前台服務)
     */
    private fun hideSystemOverlay() {
        try {
            OverlayService.stopService(this)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    /**
     * 打開 App
     */
    private fun openApp(args: Map<String, Any>?) {
        try {
            val intent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("action", args?.get("action") as? String ?: "")
            }
            startActivity(intent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    /**
     * 處理權限請求結果
     */
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == OVERLAY_PERMISSION_REQUEST_CODE) {
            val granted = checkOverlayPermission()
            methodChannel?.invokeMethod("onPermissionResult", mapOf("granted" to granted))

            if (granted) {
                Toast.makeText(this, "系統級窗口權限已授予", Toast.LENGTH_SHORT).show()
            } else {
                Toast.makeText(this, "需要系統級窗口權限才能使用此功能", Toast.LENGTH_LONG).show()
            }
        }
    }

    override fun onResume() {
        super.onResume()

        // 檢查是否從 Overlay 點擊進入
        val action = intent.getStringExtra("action")
        if (action == "add_memo") {
            // 可以在這裡直接導航到新增備忘錄頁面
            methodChannel?.invokeMethod("onOverlayClicked", mapOf("action" to action))
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        // 當 App 完全關閉時才停止服務
        if (isFinishing) {
            OverlayService.stopService(this)
        }
    }
}