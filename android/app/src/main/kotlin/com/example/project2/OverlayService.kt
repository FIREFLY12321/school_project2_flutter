// 檔案位置: android/app/src/main/kotlin/com/example/project2/OverlayService.kt

package com.example.project2

import android.app.*
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.Button
import androidx.core.app.NotificationCompat

class OverlayService : Service() {

    companion object {
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "overlay_service_channel"
        private var isServiceRunning = false

        fun startService(context: Context) {
            if (!isServiceRunning) {
                val intent = Intent(context, OverlayService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            }
        }

        fun stopService(context: Context) {
            val intent = Intent(context, OverlayService::class.java)
            context.stopService(intent)
        }

        fun isRunning(): Boolean = isServiceRunning
    }

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var overlayParams: WindowManager.LayoutParams? = null

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        createNotificationChannel()
        isServiceRunning = true
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // 啟動前台通知
        startForeground(NOTIFICATION_ID, createNotification())

        // 顯示 Overlay
        showOverlay()

        // 返回 START_STICKY 讓服務在被殺死後重啟
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        hideOverlay()
        isServiceRunning = false
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "浮動按鈕服務",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "保持浮動按鈕在背景運行"
                setSound(null, null)
                enableVibration(false)
                setShowBadge(false)
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("浮動按鈕已啟用")
            .setContentText("點擊通知返回應用")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setShowWhen(false)
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "關閉",
                createStopServicePendingIntent()
            )
            .build()
    }

    private fun createStopServicePendingIntent(): PendingIntent {
        val intent = Intent(this, OverlayService::class.java).apply {
            action = "STOP_SERVICE"
        }

        return PendingIntent.getService(
            this, 0, intent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
        )
    }

    private fun showOverlay() {
        if (!Settings.canDrawOverlays(this)) {
            return
        }

        try {
            // 如果已存在，先移除
            hideOverlay()

            // 創建浮動按鈕
            val overlayButton = Button(this).apply {
                text = "+"
                setBackgroundColor(Color.parseColor("#2196F3"))
                setTextColor(Color.WHITE)
                textSize = 18f

                setOnClickListener {
                    openMainActivity()
                }
            }

            // 設置布局參數
            overlayParams = WindowManager.LayoutParams().apply {
                width = 150
                height = 150

                type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                } else {
                    @Suppress("DEPRECATION")
                    WindowManager.LayoutParams.TYPE_PHONE
                }

                flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                        WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                        WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN

                format = PixelFormat.TRANSLUCENT
                gravity = Gravity.TOP or Gravity.START

                x = 100
                y = 200
            }

            // 添加觸摸事件處理
            overlayButton.setOnTouchListener(OverlayTouchListener())

            // 添加到窗口
            windowManager?.addView(overlayButton, overlayParams)
            overlayView = overlayButton

        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun hideOverlay() {
        try {
            overlayView?.let { view ->
                windowManager?.removeView(view)
                overlayView = null
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun openMainActivity() {
        try {
            val intent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra("action", "add_memo")
            }
            startActivity(intent)

            // 震動反饋
            val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as? android.os.Vibrator
            vibrator?.let {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    it.vibrate(android.os.VibrationEffect.createOneShot(100, android.os.VibrationEffect.DEFAULT_AMPLITUDE))
                } else {
                    @Suppress("DEPRECATION")
                    it.vibrate(100)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    /**
     * 觸摸事件監聽器（用於拖拽）
     */
    private inner class OverlayTouchListener : View.OnTouchListener {
        private var initialX = 0
        private var initialY = 0
        private var initialTouchX = 0f
        private var initialTouchY = 0f

        override fun onTouch(view: View, event: MotionEvent): Boolean {
            try {
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        initialX = overlayParams?.x ?: 0
                        initialY = overlayParams?.y ?: 0
                        initialTouchX = event.rawX
                        initialTouchY = event.rawY
                        return true
                    }

                    MotionEvent.ACTION_MOVE -> {
                        if (overlayParams != null) {
                            overlayParams?.x = initialX + (event.rawX - initialTouchX).toInt()
                            overlayParams?.y = initialY + (event.rawY - initialTouchY).toInt()
                            windowManager?.updateViewLayout(view, overlayParams)
                        }
                        return true
                    }

                    MotionEvent.ACTION_UP -> {
                        val deltaX = event.rawX - initialTouchX
                        val deltaY = event.rawY - initialTouchY

                        // 如果移動距離很小，視為點擊
                        if (kotlin.math.abs(deltaX) < 10 && kotlin.math.abs(deltaY) < 10) {
                            view.performClick()
                        }

                        // 邊緣吸附效果
                        snapToEdge()
                        return true
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
            return false
        }

        private fun snapToEdge() {
            try {
                overlayParams?.let { params ->
                    val displayMetrics = resources.displayMetrics
                    val screenWidth = displayMetrics.widthPixels

                    // 自動吸附到最近的邊緣
                    if (params.x > screenWidth / 2) {
                        params.x = screenWidth - 150 - 20  // 右邊緣
                    } else {
                        params.x = 20  // 左邊緣
                    }

                    windowManager?.updateViewLayout(overlayView, params)
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}