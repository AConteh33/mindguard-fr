package com.example.mindguard_fr

import android.content.Intent
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val DNS_MONITORING_CHANNEL = "com.example.mindguard_fr/dns_monitoring"

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
        println("DNS monitoring started for user: $userId")
    }

    private fun stopDNSMonitoring() {
        val intent = Intent(this, DNSMonitoringService::class.java)
        stopService(intent)
        println("DNS monitoring stopped")
    }
}
