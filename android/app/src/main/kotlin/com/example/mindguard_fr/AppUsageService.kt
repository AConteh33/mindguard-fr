package com.example.mindguard_fr

import android.app.*
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.*
import org.json.JSONArray
import org.json.JSONObject
import java.util.*
import java.util.concurrent.TimeUnit

class AppUsageService : Service() {
    
    private val serviceScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var isMonitoring = false
    private var monitoringJob: Job? = null
    private var currentUserId: String? = null
    private val handler = Handler(Looper.getMainLooper())
    private var lastUsageData: MutableMap<String, Long> = mutableMapOf()
    
    companion object {
        private const val TAG = "AppUsageService"
        private const val NOTIFICATION_ID = 2001
        private const val CHANNEL_ID = "AppUsageMonitoring"
        private const val CHANNEL_NAME = "App Usage Monitoring"
        private const val MONITORING_INTERVAL = 30000L // 30 seconds
    }
    
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        Log.d(TAG, "AppUsageService created")
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val userId = intent?.getStringExtra("userId")
        
        when (intent?.action) {
            "START_MONITORING" -> {
                if (userId != null) {
                    startMonitoring(userId)
                }
            }
            "STOP_MONITORING" -> {
                stopMonitoring()
            }
        }
        
        return START_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    private fun startMonitoring(userId: String) {
        if (isMonitoring) {
            Log.d(TAG, "Already monitoring")
            return
        }
        
        if (!hasUsageStatsPermission()) {
            Log.e(TAG, "Usage stats permission not granted")
            return
        }
        
        currentUserId = userId
        isMonitoring = true
        
        // Start foreground service
        startForeground(NOTIFICATION_ID, createNotification())
        
        // Start monitoring coroutine
        monitoringJob = serviceScope.launch {
            while (isMonitoring) {
                try {
                    collectUsageData()
                    delay(MONITORING_INTERVAL)
                } catch (e: Exception) {
                    Log.e(TAG, "Error in monitoring loop", e)
                    delay(5000) // Wait 5 seconds before retry
                }
            }
        }
        
        Log.d(TAG, "Started monitoring for user: $userId")
    }
    
    private fun stopMonitoring() {
        if (!isMonitoring) return
        
        isMonitoring = false
        monitoringJob?.cancel()
        stopForeground(true)
        stopSelf()
        
        Log.d(TAG, "Stopped monitoring")
    }
    
    private suspend fun collectUsageData() {
        try {
            val usageStats = getUsageStats()
            val currentTime = System.currentTimeMillis()
            
            // Process each app's usage
            for (stat in usageStats) {
                val packageName = stat.packageName
                val totalTime = stat.totalTimeInForeground
                
                // Skip system apps and very short usage
                if (isSystemApp(packageName) || totalTime < 1000) continue
                
                // Calculate usage since last check
                val lastTime = lastUsageData[packageName] ?: 0L
                val usageSinceLastCheck = totalTime - lastTime
                
                if (usageSinceLastCheck > 0) {
                    // Send to Firebase
                    sendUsageDataToFirebase(packageName, usageSinceLastCheck, stat.lastTimeUsed)
                    lastUsageData[packageName] = totalTime
                }
            }
            
            // Clean up old data (remove apps not used in last hour)
            val oneHourAgo = currentTime - TimeUnit.HOURS.toMillis(1)
            lastUsageData.entries.removeAll { (packageName, lastTime) ->
                val stat = usageStats.find { it.packageName == packageName }
                stat?.lastTimeUsed ?: 0 < oneHourAgo
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error collecting usage data", e)
        }
    }
    
    private fun getUsageStats(): List<UsageStats> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.DAY_OF_YEAR, -1) // Get last 24 hours
        
        return usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            calendar.timeInMillis,
            System.currentTimeMillis()
        ).filter { it.totalTimeInForeground > 0 }
    }
    
    private fun isSystemApp(packageName: String): Boolean {
        return try {
            val appInfo = packageManager.getApplicationInfo(packageName, 0)
            (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
        } catch (e: PackageManager.NameNotFoundException) {
            true // Treat non-existent packages as system apps
        }
    }
    
    private fun getAppName(packageName: String): String {
        return try {
            val appInfo = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(appInfo).toString()
        } catch (e: PackageManager.NameNotFoundException) {
            packageName
        }
    }
    
    private suspend fun sendUsageDataToFirebase(packageName: String, usageTimeMs: Long, lastUsed: Long) {
        try {
            // This would typically be sent to Flutter layer for Firebase upload
            // For now, we'll log it and the Flutter layer will pick it up
            val appName = getAppName(packageName)
            val usageTimeSeconds = (usageTimeMs / 1000).toInt()
            
            Log.d(TAG, "Usage: $appName - $usageTimeSeconds seconds")
            
            // Store in local cache for Flutter to retrieve
            val usageData = JSONObject().apply {
                put("packageName", packageName)
                put("appName", appName)
                put("usageTimeSeconds", usageTimeSeconds)
                put("timestamp", lastUsed)
                put("userId", currentUserId)
            }
            
            // You could store this in SharedPreferences or send via broadcast
            // For now, the Flutter layer will query this data directly
            
        } catch (e: Exception) {
            Log.e(TAG, "Error sending usage data to Firebase", e)
        }
    }
    
    private fun hasUsageStatsPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val calendar = Calendar.getInstance()
            calendar.add(Calendar.DAY_OF_YEAR, -1)
            
            val stats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                calendar.timeInMillis,
                System.currentTimeMillis()
            )
            stats.isNotEmpty()
        } else {
            false
        }
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Monitoring app usage for parental controls"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("App Usage Monitoring")
            .setContentText("Monitoring app usage for parental controls")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setSilent(true)
            .build()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        stopMonitoring()
        serviceScope.cancel()
        Log.d(TAG, "AppUsageService destroyed")
    }
}
