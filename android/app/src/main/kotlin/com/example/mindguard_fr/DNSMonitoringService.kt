package com.example.mindguard_fr

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.os.Build
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.*
import com.google.firebase.firestore.FirebaseFirestore
import java.io.BufferedReader
import java.io.InputStreamReader
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.ConcurrentHashMap

/**
 * DNS Monitoring Service - Captures all DNS queries made by the device
 * This is more comprehensive than browser history as it captures ALL network activity
 * including apps, browsers, and any other network requests
 */
class DNSMonitoringService : Service() {
    companion object {
        private const val TAG = "DNSMonitoringService"
        private const val NOTIFICATION_ID = 1002
        private const val CHANNEL_ID = "dns_monitoring"
    }

    private val serviceScope = CoroutineScope(Dispatchers.Default + Job())
    private val dnsCache = ConcurrentHashMap<String, Long>()
    private val firestore = FirebaseFirestore.getInstance()
    private var userId: String? = null
    private var isMonitoring = false

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        userId = intent?.getStringExtra("userId")

        if (userId != null && !isMonitoring) {
            isMonitoring = true
            startForeground(NOTIFICATION_ID, createNotification())
            startDNSMonitoring()
        }

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun startDNSMonitoring() {
        serviceScope.launch {
            while (isMonitoring) {
                try {
                    monitorDNSQueries()
                    delay(10000) // Check every 10 seconds
                } catch (e: Exception) {
                    println("$TAG: Error monitoring DNS: ${e.message}")
                }
            }
        }
    }

    private suspend fun monitorDNSQueries() {
        try {
            // Read DNS queries from system logs
            val dnsQueries = readDNSQueries()

            for (query in dnsQueries) {
                recordDNSQuery(query)
            }
        } catch (e: Exception) {
            println("$TAG: Error in monitorDNSQueries: ${e.message}")
        }
    }

    private fun readDNSQueries(): List<DNSQuery> {
        val queries = mutableListOf<DNSQuery>()

        try {
            // Method 1: Read from /proc/net/udp (DNS uses UDP port 53)
            val udpFile = java.io.File("/proc/net/udp")
            if (udpFile.exists()) {
                udpFile.readLines().drop(1).forEach { line ->
                    try {
                        val parts = line.trim().split(Regex("\\s+"))
                        if (parts.size >= 4) {
                            val remoteAddr = parts[2]
                            val remotePort = hexToPort(remoteAddr.split(":").getOrNull(1) ?: "0")

                            // DNS queries use port 53
                            if (remotePort == 53) {
                                val remoteIp = hexToIp(remoteAddr.split(":")[0])
                                queries.add(DNSQuery(
                                    dnsServer = remoteIp,
                                    timestamp = System.currentTimeMillis()
                                ))
                            }
                        }
                    } catch (e: Exception) {
                        // Skip malformed lines
                    }
                }
            }

            // Method 2: Read from logcat for DNS resolution attempts
            val logcatProcess = Runtime.getRuntime().exec("logcat -d *:V")
            val reader = BufferedReader(InputStreamReader(logcatProcess.inputStream))
            var line: String?

            while (reader.readLine().also { line = it } != null) {
                line?.let {
                    // Look for DNS resolution patterns
                    if (it.contains("getaddrinfo") || it.contains("DNS") || it.contains("resolve")) {
                        try {
                            val domain = extractDomainFromLog(it)
                            if (domain != null && !dnsCache.containsKey(domain)) {
                                dnsCache[domain] = System.currentTimeMillis()
                                queries.add(DNSQuery(
                                    domain = domain,
                                    timestamp = System.currentTimeMillis()
                                ))
                            }
                        } catch (e: Exception) {
                            // Skip parsing errors
                        }
                    }
                }
            }
            reader.close()
        } catch (e: Exception) {
            println("$TAG: Error reading DNS queries: ${e.message}")
        }

        return queries
    }

    private fun extractDomainFromLog(logLine: String): String? {
        return try {
            // Extract domain patterns from logcat output
            val patterns = listOf(
                Regex("""getaddrinfo\s+([a-zA-Z0-9.-]+)"""),
                Regex("""resolving\s+([a-zA-Z0-9.-]+)"""),
                Regex("""DNS\s+query\s+([a-zA-Z0-9.-]+)"""),
                Regex("""host\s+([a-zA-Z0-9.-]+)""")
            )

            for (pattern in patterns) {
                val match = pattern.find(logLine)
                if (match != null) {
                    return match.groupValues[1]
                }
            }
            null
        } catch (e: Exception) {
            null
        }
    }

    private fun recordDNSQuery(query: DNSQuery) {
        if (userId == null) return

        serviceScope.launch {
            try {
                val timestamp = System.currentTimeMillis()
                val dateFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())
                val dateString = dateFormat.format(Date(timestamp))

                val dnsRecord = mapOf(
                    "childId" to userId,
                    "domain" to (query.domain ?: query.dnsServer),
                    "dnsServer" to query.dnsServer,
                    "timestamp" to timestamp,
                    "date" to dateString,
                    "type" to "DNS_QUERY"
                )

                val docId = "${userId}_${timestamp}_${query.domain?.hashCode() ?: query.dnsServer.hashCode()}"
                firestore.collection("dns_queries")
                    .document(docId)
                    .set(dnsRecord)
                    .addOnSuccessListener {
                        println("$TAG: Recorded DNS query for ${query.domain ?: query.dnsServer}")
                    }
                    .addOnFailureListener { e ->
                        println("$TAG: Error recording DNS query: ${e.message ?: "Unknown error"}")
                    }
            } catch (e: Exception) {
                println("$TAG: Error in recordDNSQuery: ${e.message ?: "Unknown error"}")
            }
        }
    }

    private fun hexToIp(hex: String): String {
        return try {
            val bytes = hex.chunked(2).map { it.toInt(16).toByte() }
            bytes.reversed().joinToString(".") { (it.toInt() and 0xFF).toString() }
        } catch (e: Exception) {
            hex
        }
    }

    private fun hexToPort(hex: String): Int {
        return try {
            hex.toInt(16)
        } catch (e: Exception) {
            0
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "DNS Monitoring",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Monitoring DNS queries for digital wellness"
                setShowBadge(false)
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): android.app.Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("MindGuard DNS Monitor")
            .setContentText("Monitoring network activity...")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()
    }

    override fun onDestroy() {
        super.onDestroy()
        isMonitoring = false
        serviceScope.cancel()
    }

    data class DNSQuery(
        val domain: String? = null,
        val dnsServer: String = "8.8.8.8",
        val timestamp: Long = System.currentTimeMillis()
    )
}