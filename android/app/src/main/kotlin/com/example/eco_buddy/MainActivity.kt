package com.example.eco_buddy

import android.annotation.SuppressLint
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.TrafficStats
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import java.text.SimpleDateFormat
import java.util.*

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.datausage/data"
    private lateinit var dailyPreferences: SharedPreferences
    private lateinit var hourlyPreferences: SharedPreferences

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        dailyPreferences = getSharedPreferences("DailyDataUsage", Context.MODE_PRIVATE)
        hourlyPreferences = getSharedPreferences("HourlyDataUsage", Context.MODE_PRIVATE)

        initializeBaseline()
        // 목 데이터
//        insertMockData()
        scheduleAlarms()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getDailyDataUsage" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        result.success(getDailyDataUsage())
                    } else {
                        result.error("UNSUPPORTED_VERSION", "Android version not supported", null)
                    }
                }
                "getHourlyDataUsage" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        result.success(getHourlyDataUsage())
                    } else {
                        result.error("UNSUPPORTED_VERSION", "Android version not supported", null)
                    }
                }
                "resetPreferences" -> {
                    resetPreferences()
                    result.success("Preferences reset.")
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    // 초기 값 설정
    private fun initializeBaseline() {
        if (!dailyPreferences.contains("dailyMobileRxBytes")) {
            dailyPreferences.edit()
                .putLong("dailyMobileRxBytes", TrafficStats.getMobileRxBytes())
                .putLong("dailyMobileTxBytes", TrafficStats.getMobileTxBytes())
                .putLong("dailyTotalRxBytes", TrafficStats.getTotalRxBytes())
                .putLong("dailyTotalTxBytes", TrafficStats.getTotalTxBytes())
                .apply()
        }
        if (!hourlyPreferences.contains("hourlyMobileRxBytes")) {
            hourlyPreferences.edit()
                .putLong("hourlyMobileRxBytes", TrafficStats.getMobileRxBytes())
                .putLong("hourlyMobileTxBytes", TrafficStats.getMobileTxBytes())
                .putLong("hourlyTotalRxBytes", TrafficStats.getTotalRxBytes())
                .putLong("hourlyTotalTxBytes", TrafficStats.getTotalTxBytes())
                .apply()
        }
    }

    private fun resetPreferences() {
        dailyPreferences.edit().clear().apply()
        hourlyPreferences.edit().clear().apply()
        Log.d("MainActivity", "Preferences have been reset.")
    }

    // 목 데이터
    private fun insertMockData() {
        // Insert mock daily data
        val mockDailyData = mapOf(
            "2024-11-15" to mapOf(
                "MobileReceivedMB" to 500.0,
                "MobileTransmittedMB" to 100.0,
                "WiFiReceivedMB" to 200.0,
                "WiFiTransmittedMB" to 50.0
            ),
        )
        dailyPreferences.edit()
            .putString("weeklyDataUsage", Gson().toJson(mockDailyData))
            .apply()

        // Insert mock hourly data
        val mockHourlyData = listOf(
            mapOf(
                "Timestamp" to "2024-11-16 00:00",
                "MobileReceivedMB" to 140.0,
                "MobileTransmittedMB" to 50.0,
                "WiFiReceivedMB" to 12.0,
                "WiFiTransmittedMB" to 3.0
            ),
            mapOf(
                "Timestamp" to "2024-11-16 01:00",
                "MobileReceivedMB" to 200.0,
                "MobileTransmittedMB" to 5.0,
                "WiFiReceivedMB" to 80.0,
                "WiFiTransmittedMB" to 20.0
            ),
            mapOf(
                "Timestamp" to "2024-11-16 02:00",
                "MobileReceivedMB" to 890.0,
                "MobileTransmittedMB" to 80.0,
                "WiFiReceivedMB" to 70.0,
                "WiFiTransmittedMB" to 23.0
            ),
            mapOf(
                "Timestamp" to "2024-11-16 03:00",
                "MobileReceivedMB" to 0.0,
                "MobileTransmittedMB" to 50.0,
                "WiFiReceivedMB" to 12.0,
                "WiFiTransmittedMB" to 3.0
            ),
            mapOf(
                "Timestamp" to "2024-11-16 04:00",
                "MobileReceivedMB" to 0.0,
                "MobileTransmittedMB" to 5.0,
                "WiFiReceivedMB" to 80.0,
                "WiFiTransmittedMB" to 20.0
            ),
            mapOf(
                "Timestamp" to "2024-11-16 05:00",
                "MobileReceivedMB" to 0.0,
                "MobileTransmittedMB" to 80.0,
                "WiFiReceivedMB" to 70.0,
                "WiFiTransmittedMB" to 23.0
            ),
            mapOf(
                "Timestamp" to "2024-11-16 06:00",
                "MobileReceivedMB" to 30.0,
                "MobileTransmittedMB" to 50.0,
                "WiFiReceivedMB" to 12.0,
                "WiFiTransmittedMB" to 3.0
            ),
            mapOf(
                "Timestamp" to "2024-11-16 07:00",
                "MobileReceivedMB" to 30.0,
                "MobileTransmittedMB" to 5.0,
                "WiFiReceivedMB" to 80.0,
                "WiFiTransmittedMB" to 20.0
            ),
            mapOf(
                "Timestamp" to "2024-11-16 08:00",
                "MobileReceivedMB" to 390.0,
                "MobileTransmittedMB" to 80.0,
                "WiFiReceivedMB" to 70.0,
                "WiFiTransmittedMB" to 23.0
            ),
            mapOf(
                "Timestamp" to "2024-11-16 09:00",
                "MobileReceivedMB" to 800.0,
                "MobileTransmittedMB" to 50.0,
                "WiFiReceivedMB" to 12.0,
                "WiFiTransmittedMB" to 3.0
            ),
            mapOf(
                "Timestamp" to "2024-11-16 10:00",
                "MobileReceivedMB" to 150.0,
                "MobileTransmittedMB" to 5.0,
                "WiFiReceivedMB" to 80.0,
                "WiFiTransmittedMB" to 20.0
            ),
            mapOf(
                "Timestamp" to "2024-11-16 11:00",
                "MobileReceivedMB" to 170.0,
                "MobileTransmittedMB" to 80.0,
                "WiFiReceivedMB" to 70.0,
                "WiFiTransmittedMB" to 23.0
            ),
            mapOf(
                "Timestamp" to "2024-11-16 12:00",
                "MobileReceivedMB" to 240.0,
                "MobileTransmittedMB" to 50.0,
                "WiFiReceivedMB" to 12.0,
                "WiFiTransmittedMB" to 3.0
            ),
            mapOf(
                "Timestamp" to "2024-11-16 13:00",
                "MobileReceivedMB" to 10.0,
                "MobileTransmittedMB" to 5.0,
                "WiFiReceivedMB" to 80.0,
                "WiFiTransmittedMB" to 20.0
            ),
            mapOf(
                "Timestamp" to "2024-11-16 14:00",
                "MobileReceivedMB" to 80.0,
                "MobileTransmittedMB" to 80.0,
                "WiFiReceivedMB" to 70.0,
                "WiFiTransmittedMB" to 23.0
            ),
            mapOf(
                "Timestamp" to "2024-11-16 15:00",
                "MobileReceivedMB" to 80.0,
                "MobileTransmittedMB" to 80.0,
                "WiFiReceivedMB" to 70.0,
                "WiFiTransmittedMB" to 23.0
            ),
            mapOf(
                "Timestamp" to "2024-11-16 16:00",
                "MobileReceivedMB" to 100.0,
                "MobileTransmittedMB" to 80.0,
                "WiFiReceivedMB" to 90.0,
                "WiFiTransmittedMB" to 23.0
            ),

        )
        hourlyPreferences.edit()
            .putString("hourlyData", Gson().toJson(mockHourlyData))
            .apply()

        Log.d("MainActivity", "Mock data inserted into preferences.")
    }


    @SuppressLint("ScheduleExactAlarm")
    private fun scheduleAlarms() {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager

        // 자정 일일 알람 설정
        val midnightIntent = Intent(this, DataUsageReceiver::class.java).apply {
            action = "DAILY_RESET"
        }
        val midnightPendingIntent = PendingIntent.getBroadcast(
            this, 0, midnightIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val midnightCalendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            if (before(Calendar.getInstance())) {
                add(Calendar.DAY_OF_MONTH, 1)
            }
        }

        Log.d("Alarmcheck", "Setting initial 10-minute alarm for: ${midnightCalendar.time}")

        alarmManager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            midnightCalendar.timeInMillis,
            midnightPendingIntent
        )

        // 알림 재설정
        scheduleHourlyAlarm(alarmManager)
    }

    private fun scheduleHourlyAlarm(alarmManager: AlarmManager) {
        val hourlyIntent = Intent(this, DataUsageReceiver::class.java).apply {
            action = "HOURLY_UPDATE"
        }
        val hourlyPendingIntent = PendingIntent.getBroadcast(
            this, 1, hourlyIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val hourlyCalendar = Calendar.getInstance().apply {
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            add(Calendar.HOUR_OF_DAY, 1)
        }

        Log.d("Alarmcheck", "Performing periodic task at: ${hourlyCalendar.time}")

        alarmManager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            hourlyCalendar.timeInMillis,
            hourlyPendingIntent
        )
    }


    // 앱을 킬때 마다 일일 데이터 사용량 갱신
    @RequiresApi(Build.VERSION_CODES.M)
    private fun getDailyDataUsage(): Map<String, Map<String, Any>> {
        val dateString = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
        val weeklyDataUsageJson = dailyPreferences.getString("weeklyDataUsage", "{}")
        val type = object : TypeToken<MutableMap<String, Map<String, Any>>>() {}.type
        val weeklyDataUsageMap: MutableMap<String, Map<String, Any>> = Gson().fromJson(weeklyDataUsageJson, type)

        val dailyMobileRxBytes = dailyPreferences.getLong("dailyMobileRxBytes", 0L)
        val dailyMobileTxBytes = dailyPreferences.getLong("dailyMobileTxBytes", 0L)
        val dailyTotalRxBytes = dailyPreferences.getLong("dailyTotalRxBytes", 0L)
        val dailyTotalTxBytes = dailyPreferences.getLong("dailyTotalTxBytes", 0L)

        val currentMobileRxBytes = TrafficStats.getMobileRxBytes()
        val currentMobileTxBytes = TrafficStats.getMobileTxBytes()
        val currentTotalRxBytes = TrafficStats.getTotalRxBytes()
        val currentTotalTxBytes = TrafficStats.getTotalTxBytes()

        val mobileRx = (currentMobileRxBytes - dailyMobileRxBytes) / (1024 * 1024)
        val mobileTx = (currentMobileTxBytes - dailyMobileTxBytes) / (1024 * 1024)
        val wifiRx = (currentTotalRxBytes - dailyTotalRxBytes - (currentMobileRxBytes - dailyMobileRxBytes)) / (1024 * 1024)
        val wifiTx = (currentTotalTxBytes - dailyTotalTxBytes - (currentMobileTxBytes - dailyMobileTxBytes)) / (1024 * 1024)

        weeklyDataUsageMap[dateString] = mapOf(
            "MobileReceivedMB" to mobileRx,
            "MobileTransmittedMB" to mobileTx,
            "WiFiReceivedMB" to wifiRx,
            "WiFiTransmittedMB" to wifiTx
        )

        if (weeklyDataUsageMap.size > 7) {
            val oldestDate = weeklyDataUsageMap.keys.sorted().first()
            weeklyDataUsageMap.remove(oldestDate)
        }

        dailyPreferences.edit().putString("weeklyDataUsage", Gson().toJson(weeklyDataUsageMap)).apply()

        return weeklyDataUsageMap
    }

    // 앱을 킬 때 시간별 데이터 사용량 가져오기
    @RequiresApi(Build.VERSION_CODES.M)
    private fun getHourlyDataUsage(): List<Map<String, Any>> {
        val hourlyDataJson = hourlyPreferences.getString("hourlyData", "[]")
        val type = object : TypeToken<List<Map<String, Any>>>() {}.type
        val hourlyDataList: List<Map<String, Any>> = Gson().fromJson(hourlyDataJson, type)

        // 오늘 날짜 가져오기
        val todayDate = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())

        // 전날 데이터는 지우기
        val filteredData = hourlyDataList.filter { entry ->
            val timestamp = entry["Timestamp"] as String
            timestamp.startsWith(todayDate)
        }

        return filteredData
    }


    // 자정(일일), 시간별 데이터 사용량 측정
    class DataUsageReceiver : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                "DAILY_RESET" -> {
                    resetDailyData(context)
                    rescheduleDailyAlarm(context)
                }
                "HOURLY_UPDATE" -> {
                    calculateHourlyData(context)
                    rescheduleHourlyAlarm(context)
                }
            }
        }

        // 자정이 되면 이 함수 실행
        private fun resetDailyData(context: Context) {
            Log.d("Alarmcheck", "Performing periodic task at: ${Calendar.getInstance().time}")
            val dailyPreferences = context.getSharedPreferences("DailyDataUsage", Context.MODE_PRIVATE)

            // 현재 값 가져오기
            val currentMobileRxBytes = TrafficStats.getMobileRxBytes()
            val currentMobileTxBytes = TrafficStats.getMobileTxBytes()
            val currentTotalRxBytes = TrafficStats.getTotalRxBytes()
            val currentTotalTxBytes = TrafficStats.getTotalTxBytes()

            // 이전 값 가져오기
            val previousMobileRxBytes = dailyPreferences.getLong("dailyMobileRxBytes", currentMobileRxBytes)
            val previousMobileTxBytes = dailyPreferences.getLong("dailyMobileTxBytes", currentMobileTxBytes)
            val previousTotalRxBytes = dailyPreferences.getLong("dailyTotalRxBytes", currentTotalRxBytes)
            val previousTotalTxBytes = dailyPreferences.getLong("dailyTotalTxBytes", currentTotalTxBytes)

            // 일일 데이터 사용량 계산
            val mobileRx = (currentMobileRxBytes - previousMobileRxBytes) / (1024 * 1024) // MB
            val mobileTx = (currentMobileTxBytes - previousMobileTxBytes) / (1024 * 1024) // MB
            val wifiRx = (currentTotalRxBytes - previousTotalRxBytes - (currentMobileRxBytes - previousMobileRxBytes)) / (1024 * 1024) // MB
            val wifiTx = (currentTotalTxBytes - previousTotalTxBytes - (currentMobileTxBytes - previousMobileTxBytes)) / (1024 * 1024) // MB

            // 현재 날짜 저장
            val calendar = Calendar.getInstance().apply { add(Calendar.DAY_OF_MONTH, -1) }
            val dateString = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(calendar.time)


            val weeklyDataUsageJson = dailyPreferences.getString("weeklyDataUsage", "{}")
            val type = object : TypeToken<MutableMap<String, Map<String, Any>>>() {}.type
            val weeklyDataUsageMap: MutableMap<String, Map<String, Any>> = Gson().fromJson(weeklyDataUsageJson, type)

            weeklyDataUsageMap[dateString] = mapOf(
                "MobileReceivedMB" to mobileRx,
                "MobileTransmittedMB" to mobileTx,
                "WiFiReceivedMB" to wifiRx,
                "WiFiTransmittedMB" to wifiTx
            )

            // 오래된 데이터는 삭제 (일주일 단위)
            if (weeklyDataUsageMap.size > 7) {
                val oldestDate = weeklyDataUsageMap.keys.sorted().first()
                weeklyDataUsageMap.remove(oldestDate)
            }

            dailyPreferences.edit()
                .putString("weeklyDataUsage", Gson().toJson(weeklyDataUsageMap))
                .apply()

            // 오늘 날 데이터 사용량 초기화
            dailyPreferences.edit()
                .putLong("dailyMobileRxBytes", currentMobileRxBytes)
                .putLong("dailyMobileTxBytes", currentMobileTxBytes)
                .putLong("dailyTotalRxBytes", currentTotalRxBytes)
                .putLong("dailyTotalTxBytes", currentTotalTxBytes)
                .apply()
        }

        // 시간(정각)이 되면 계산
        private fun calculateHourlyData(context: Context) {
            Log.d("Alarmcheck", "Performing periodic task at: ${Calendar.getInstance().time}")
            val hourlyPreferences = context.getSharedPreferences("HourlyDataUsage", Context.MODE_PRIVATE)

            val previousMobileRxBytes = hourlyPreferences.getLong("hourlyMobileRxBytes", TrafficStats.getMobileRxBytes())
            val previousMobileTxBytes = hourlyPreferences.getLong("hourlyMobileTxBytes", TrafficStats.getMobileTxBytes())
            val previousTotalRxBytes = hourlyPreferences.getLong("hourlyTotalRxBytes", TrafficStats.getTotalRxBytes())
            val previousTotalTxBytes = hourlyPreferences.getLong("hourlyTotalTxBytes", TrafficStats.getTotalTxBytes())

            val currentMobileRxBytes = TrafficStats.getMobileRxBytes()
            val currentMobileTxBytes = TrafficStats.getMobileTxBytes()
            val currentTotalRxBytes = TrafficStats.getTotalRxBytes()
            val currentTotalTxBytes = TrafficStats.getTotalTxBytes()

            val mobileRx = (currentMobileRxBytes - previousMobileRxBytes) / (1024 * 1024)
            val mobileTx = (currentMobileTxBytes - previousMobileTxBytes) / (1024 * 1024)
            val wifiRx = (currentTotalRxBytes - previousTotalRxBytes - (currentMobileRxBytes - previousMobileRxBytes)) / (1024 * 1024)
            val wifiTx = (currentTotalTxBytes - previousTotalTxBytes - (currentMobileTxBytes - previousMobileTxBytes)) / (1024 * 1024)

            val timestamp = SimpleDateFormat("yyyy-MM-dd HH:mm", Locale.getDefault()).format(Date())
            val hourlyData = mapOf(
                "Timestamp" to timestamp,
                "MobileReceivedMB" to mobileRx,
                "MobileTransmittedMB" to mobileTx,
                "WiFiReceivedMB" to wifiRx,
                "WiFiTransmittedMB" to wifiTx
            )

            val hourlyDataJson = hourlyPreferences.getString("hourlyData", "[]")
            val type = object : TypeToken<MutableList<Map<String, Any>>>() {}.type
            val hourlyDataList: MutableList<Map<String, Any>> = Gson().fromJson(hourlyDataJson, type)

            hourlyDataList.add(hourlyData)
            hourlyPreferences.edit()
                .putString("hourlyData", Gson().toJson(hourlyDataList))
                .putLong("hourlyMobileRxBytes", currentMobileRxBytes)
                .putLong("hourlyMobileTxBytes", currentMobileTxBytes)
                .putLong("hourlyTotalRxBytes", currentTotalRxBytes)
                .putLong("hourlyTotalTxBytes", currentTotalTxBytes)
                .apply()
        }

        // 알림 재설정
        private fun rescheduleDailyAlarm(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val dailyIntent = Intent(context, DataUsageReceiver::class.java).apply {
                action = "DAILY_RESET"
            }
            val dailyPendingIntent = PendingIntent.getBroadcast(
                context, 0, dailyIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // 다음 날 자정으로 재설정
            val midnightCalendar = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                add(Calendar.DAY_OF_MONTH, 1)
            }

            Log.d("Alarmcheck ", "Rescheduling 10-minute alarm for: ${midnightCalendar.time}")

            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                midnightCalendar.timeInMillis,
                dailyPendingIntent
            )
        }

        // 알림 재설정
        private fun rescheduleHourlyAlarm(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val hourlyIntent = Intent(context, DataUsageReceiver::class.java).apply {
                action = "HOURLY_UPDATE"
            }
            val hourlyPendingIntent = PendingIntent.getBroadcast(
                context, 1, hourlyIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            val nextHour = Calendar.getInstance().apply {
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                add(Calendar.HOUR_OF_DAY, 1)
            }

            Log.d("Alarmcheck ", "Rescheduling 10-minute alarm for: ${nextHour.time}")

            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                nextHour.timeInMillis,
                hourlyPendingIntent
            )
        }
    }
}
