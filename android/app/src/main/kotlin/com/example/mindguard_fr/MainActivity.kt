package com.example.mindguard_fr

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.util.*

class MainActivity : FlutterActivity() {
    private val DNS_MONITORING_CHANNEL = "com.example.mindguard_fr/dns_monitoring"
    private val APP_USAGE_CHANNEL = "com.example.mindguard_fr/app_usage"
    private val PERMISSION_REQUEST_USAGE_STATS = 1001

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // DNS Monitoring channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DNS_MONITORING_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startDNSMonitoring" -> {
                    val userId = call.argument<String>("userId") ?: ""
                    startDNSMonitoring(userId)
                    result.success(true)
                }
                "stopDNSMonitoring" -> {
                    stopDNSMonitoring()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // App Usage channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_USAGE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasUsageStatsPermission" -> {
                    result.success(hasUsageStatsPermission())
                }
                "requestUsageStatsPermission" -> {
                    requestUsageStatsPermission()
                    result.success(true)
                }
                "getAppUsage" -> {
                    val daysBack = call.argument<Int>("daysBack") ?: 7
                    val usageData = getAppUsageStats(daysBack)
                    result.success(usageData)
                }
                "startAppUsageMonitoring" -> {
                    val userId = call.argument<String>("userId") ?: ""
                    startAppUsageMonitoring(userId)
                    result.success(true)
                }
                "stopAppUsageMonitoring" -> {
                    stopAppUsageMonitoring()
                    result.success(true)
                }
                "getTopApps" -> {
                    val limit = call.argument<Int>("limit") ?: 10
                    val topApps = getTopAppsByUsage(limit)
                    result.success(topApps)
                }
                else -> result.notImplemented()
            }
        }
    }

    // DNS monitoring methods
    private fun startDNSMonitoring(userId: String) {
        val intent = Intent(this, DNSMonitoringService::class.java).apply {
            putExtra("userId", userId)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
        Log.d("MainActivity", "DNS monitoring started for user: $userId")
    }

    private fun stopDNSMonitoring() {
        val intent = Intent(this, DNSMonitoringService::class.java)
        stopService(intent)
        Log.d("MainActivity", "DNS monitoring stopped")
    }

    // App Usage methods
    private fun hasUsageStatsPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val appOpsManager = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                appOpsManager.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    android.os.Process.myUid(),
                    packageName
                )
            } else {
                appOpsManager.checkOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    android.os.Process.myUid(),
                    packageName
                )
            }
            mode == AppOpsManager.MODE_ALLOWED
        } else {
            false
        }
    }

    private fun requestUsageStatsPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            startActivity(intent)
        }
    }

    private fun getAppUsageStats(daysBack: Int): String {
        return try {
            if (!hasUsageStatsPermission()) {
                return JSONArray().toString()
            }

            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val calendar = Calendar.getInstance()
            calendar.add(Calendar.DAY_OF_YEAR, -daysBack)
            
            val stats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                calendar.timeInMillis,
                System.currentTimeMillis()
            )

            val usageArray = JSONArray()
            
            for (stat in stats) {
                if (stat.totalTimeInForeground > 0 && !isSystemApp(stat.packageName)) {
                    val appInfo = try {
                        packageManager.getApplicationInfo(stat.packageName, 0)
                    } catch (e: Exception) {
                        null
                    }
                    
                    val appName = appInfo?.let { 
                        packageManager.getApplicationLabel(it).toString() 
                    } ?: stat.packageName
                    
                    val usageData = JSONObject().apply {
                        put("packageName", stat.packageName)
                        put("appName", appName)
                        put("usageTimeSeconds", stat.totalTimeInForeground / 1000)
                        put("lastUsed", stat.lastTimeUsed)
                        put("firstTimestamp", stat.firstTimeStamp)
                        put("lastTimestamp", stat.lastTimeStamp)
                        put("date", java.text.SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
                            .format(Date(stat.lastTimeStamp)))
                    }
                    usageArray.put(usageData)
                }
            }
            
            usageArray.toString()
        } catch (e: Exception) {
            Log.e("MainActivity", "Error getting app usage stats", e)
            JSONArray().toString()
        }
    }

    private fun getTopAppsByUsage(limit: Int): String {
        return try {
            if (!hasUsageStatsPermission()) {
                return JSONArray().toString()
            }

            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val calendar = Calendar.getInstance()
            calendar.add(Calendar.DAY_OF_YEAR, -1) // Last 24 hours
            
            val stats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                calendar.timeInMillis,
                System.currentTimeMillis()
            )

            // Group by package name and sum usage time
            val appUsage = mutableMapOf<String, Pair<String, Long>>() // packageName to (appName, totalTime)
            
            for (stat in stats) {
                if (stat.totalTimeInForeground > 0 && !isSystemApp(stat.packageName)) {
                    val appName = try {
                        val appInfo = packageManager.getApplicationInfo(stat.packageName, 0)
                        packageManager.getApplicationLabel(appInfo).toString()
                    } catch (e: Exception) {
                        stat.packageName
                    }
                    
                    val currentUsage = appUsage[stat.packageName]?.second ?: 0L
                    appUsage[stat.packageName] = Pair(appName, currentUsage + stat.totalTimeInForeground)
                }
            }

            // Sort by usage time and take top apps
            val topApps = appUsage.values
                .sortedByDescending { it.second }
                .take(limit)
                .map { (appName, usageTime) ->
                    JSONObject().apply {
                        put("appName", appName)
                        put("usageTimeSeconds", usageTime / 1000)
                        put("usageTimeMinutes", (usageTime / 1000 / 60).toInt())
                    }
                }

            JSONArray(topApps).toString()
        } catch (e: Exception) {
            Log.e("MainActivity", "Error getting top apps", e)
            JSONArray().toString()
        }
    }

    private fun isSystemApp(packageName: String): Boolean {
        return try {
            val appInfo = packageManager.getApplicationInfo(packageName, 0)
            (appInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0
        } catch (e: Exception) {
            true // Treat non-existent packages as system apps
        }
    }

    private fun startAppUsageMonitoring(userId: String) {
        val intent = Intent(this, AppUsageService::class.java).apply {
            action = "START_MONITORING"
            putExtra("userId", userId)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
        Log.d("MainActivity", "App usage monitoring started for user: $userId")
    }

    private fun stopAppUsageMonitoring() {
        val intent = Intent(this, AppUsageService::class.java).apply {
            action = "STOP_MONITORING"
        }
        startService(intent)
        Log.d("MainActivity", "App usage monitoring stopped")
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        when (requestCode) {
            PERMISSION_REQUEST_USAGE_STATS -> {
                // Usage stats permission is handled via Settings, not runtime permission
                // This is just for completeness
            }
        }
    }
}
