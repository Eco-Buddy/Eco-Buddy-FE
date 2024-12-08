package com.example.eco_buddy

import android.app.AlarmManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
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

import android.app.usage.NetworkStatsManager
import android.provider.Settings
import android.app.AppOpsManager
import android.app.PendingIntent
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.widget.Toast
import com.google.gson.JsonObject

import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import java.io.IOException

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.datausage/data"
    private lateinit var dailyPreferences: SharedPreferences
    private lateinit var hourlyPreferences: SharedPreferences

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        dailyPreferences = getSharedPreferences("DailyDataUsage", Context.MODE_PRIVATE)
        hourlyPreferences = getSharedPreferences("HourlyDataUsage", Context.MODE_PRIVATE)

        val sharedPreferences = getSharedPreferences("AppData", Context.MODE_PRIVATE)
        // 플래그 초기화
        if (!sharedPreferences.contains("backend_failed")) {
            sharedPreferences.edit().putBoolean("backend_failed", false).apply()
        }

        // 권한이 없으면
        if (!isAccessGranted()) {
            notifyUserAndRedirect()
        } else {
            dailyInitializeBaseline()
            hourlyInitializeBaseline()

//            scheduleHourlyAlarm(immediate = true)
            scheduleHourlyAlarm(immediate = false)

        }
    }

    private fun testOnReceiveFunction() {
        val receiver = DataUsageReceiver()
        val intent = Intent(this, DataUsageReceiver::class.java).apply {
            action = "SEND_HOURLY_DATA"
        }

        // Log for debugging
        Log.d("TestOnReceive", "Manually invoking onReceive...")
        receiver.onReceive(this, intent)
    }


    // 이거 수정 해야 함.
    override fun onResume() {
        super.onResume()
        if (!isAccessGranted()) {
            Toast.makeText(this, "권한 설정 후 다시 시작해주세요.", Toast.LENGTH_LONG).show()
            finish()
        }
    }

    private fun notifyUserAndRedirect() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        startActivity(intent)
    }

    // 권한 설정
    private fun isAccessGranted(): Boolean {
        return try {
            val packageManager = packageManager
            val applicationInfo = packageManager.getApplicationInfo(packageName, 0)
            val appOpsManager = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                appOpsManager.checkOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    applicationInfo.uid,
                    applicationInfo.packageName
                )
            } else {
                AppOpsManager.MODE_IGNORED
            }
            mode == AppOpsManager.MODE_ALLOWED
        } catch (e: PackageManager.NameNotFoundException) {
            Log.e("PermissionCheck", "ApplicationInfo not found", e)
            false
        }
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
                "sendData" -> {
                    val arguments = call.arguments as? Map<*, *>
                    if (arguments != null) {
                        val accessToken = arguments["access_token"] as? String ?: ""
                        val deviceId = arguments["device_id"] as? String ?: ""
                        val userId = arguments["user_id"] as? String ?: ""

                        val sharedPreferences = getSharedPreferences("AppData", Context.MODE_PRIVATE)
                        sharedPreferences.edit().apply {
                            putString("access_token", accessToken)
                            putString("device_id", deviceId)
                            putString("user_id", userId)
                            apply()
                        }

                        // 플래그 확인 후 재시도
                        val backendFailed = sharedPreferences.getBoolean("backend_failed", false)
                        if (backendFailed) {
                            Log.d("SendData", "Previous operation failed. Retrying using testOnReceiveFunction...")
                            testOnReceiveFunction()
                        }

                        result.success("Data received successfully.")
                    } else {
                        result.error("INVALID_ARGUMENTS", "Invalid arguments passed", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun scheduleHourlyAlarm(immediate: Boolean = false) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager

        val hourlyIntent = Intent(this, DataUsageReceiver::class.java).apply {
            action = "SEND_HOURLY_DATA"
        }
        val hourlyPendingIntent = PendingIntent.getBroadcast(
            this, 1, hourlyIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val hourlyCalendar = Calendar.getInstance().apply {
            if (immediate) {
                add(Calendar.MINUTE, 5) // Trigger after 1 minute for debugging
            } else {
                add(Calendar.HOUR_OF_DAY, 1)
                set(Calendar.MINUTE, 2)
                set(Calendar.SECOND, 0)
            }
        }

        Log.d("Alarmcheck", "Performing periodic task at: ${hourlyCalendar.time}")

        alarmManager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            hourlyCalendar.timeInMillis,
            hourlyPendingIntent
        )
    }

    @RequiresApi(Build.VERSION_CODES.M)
    private fun dailyInitializeBaseline() {
        val networkStatsManager = getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager

        // 일주일 데이터 초기화
        val weeklyDataUsageJson = dailyPreferences.getString("weeklyDataUsage", "{}")
        val type = object : TypeToken<MutableMap<String, Map<String, Any>>>() {}.type
        val weeklyDataUsageMap: MutableMap<String, Map<String, Any>> = Gson().fromJson(weeklyDataUsageJson, type)

        // 일주일 치 데이터 계산
        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis
        calendar.add(Calendar.DAY_OF_MONTH, -7) // 7일 전부터 시작
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        var startTime = calendar.timeInMillis

        while (startTime < endTime) {
            val dateKey = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(calendar.time)
            calendar.add(Calendar.DAY_OF_MONTH, 1)
            val dayEnd = calendar.timeInMillis

            // 데이터 사용량 가져오는 부분
            val (mobileRx, mobileTx) = getDataUsageForPeriod(networkStatsManager, ConnectivityManager.TYPE_MOBILE, startTime, dayEnd)
            val (wifiRx, wifiTx) = getDataUsageForPeriod(networkStatsManager, ConnectivityManager.TYPE_WIFI, startTime, dayEnd)

            // 업데이트
            weeklyDataUsageMap[dateKey] = mapOf(
                "MobileReceivedMB" to mobileRx / (1024 * 1024),
                "MobileTransmittedMB" to mobileTx / (1024 * 1024),
                "WiFiReceivedMB" to wifiRx / (1024 * 1024),
                "WiFiTransmittedMB" to wifiTx / (1024 * 1024)
            )

            // 시작시간 업데이트
            startTime = dayEnd
        }

        // 7일 이상의 데이터를 받았을 때 오래된 것 삭제
        while (weeklyDataUsageMap.size > 7) {
            val oldestDate = weeklyDataUsageMap.keys.sorted().first()
            weeklyDataUsageMap.remove(oldestDate)
        }

        // 저장
        dailyPreferences.edit()
            .putString("weeklyDataUsage", Gson().toJson(weeklyDataUsageMap))
            .apply()
    }


    @RequiresApi(Build.VERSION_CODES.M)
    private fun hourlyInitializeBaseline() {
        val hourlyPreferences = getSharedPreferences("HourlyDataUsage", Context.MODE_PRIVATE)

        // Clear all existing data
        hourlyPreferences.edit().clear().apply()

        // Initialize new data list
        val filteredHourlyData = mutableListOf<Map<String, Any>>()

        // Set up the calendar to start from 00:00
        val networkStatsManager = getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager
        val calendar = Calendar.getInstance()
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)

        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()

        // Iterate over each hour starting from 00:00
        while (calendar.timeInMillis <= endTime) {
            val hourEnd = calendar.timeInMillis // Set the end of the current hour
            val timestamp = SimpleDateFormat("yyyy-MM-dd HH:mm", Locale.getDefault()).format(Date(hourEnd))

            // Fetch cumulative data usage from start of the day to the current hour
            val (mobileRx, mobileTx) = getDataUsageForPeriod(networkStatsManager, ConnectivityManager.TYPE_MOBILE, startTime, hourEnd)
            val (wifiRx, wifiTx) = getDataUsageForPeriod(networkStatsManager, ConnectivityManager.TYPE_WIFI, startTime, hourEnd)

            // Add the data to the list
            val hourlyData = mapOf(
                "Timestamp" to timestamp,
                "MobileReceivedMB" to mobileRx / (1024 * 1024),
                "MobileTransmittedMB" to mobileTx / (1024 * 1024),
                "WiFiReceivedMB" to wifiRx / (1024 * 1024),
                "WiFiTransmittedMB" to wifiTx / (1024 * 1024)
            )
            filteredHourlyData.add(hourlyData)

            // Move to the next hour
            calendar.add(Calendar.HOUR_OF_DAY, 1)
        }

        // Save the updated data to preferences
        hourlyPreferences.edit()
            .putString("hourlyData", Gson().toJson(filteredHourlyData))
            .apply()

        Log.d("HourlyData", "Initialized hourly data: ${Gson().toJson(filteredHourlyData)}")
    }




    // 계속 networkUsage 선언이 힘들어서
    @RequiresApi(Build.VERSION_CODES.M)
    private fun getDataUsageForPeriod(
        networkStatsManager: NetworkStatsManager,
        networkType: Int,
        startTime: Long,
        endTime: Long
    ): Pair<Long, Long> {
        var receivedBytes = 0L
        var transmittedBytes = 0L

        try {
            val bucket = networkStatsManager.querySummaryForDevice(networkType, null, startTime, endTime)
            if (bucket != null) {
                receivedBytes = bucket.rxBytes
                transmittedBytes = bucket.txBytes
            }
        } catch (e: Exception) {
            Log.e("NetworkStatsError", "Error fetching data usage: ${e.message}")
        }

        return Pair(receivedBytes, transmittedBytes)
    }

    // 초기화 부분 [디버깅]
    private fun resetPreferences() {
        dailyPreferences.edit().clear().apply()
        hourlyPreferences.edit().clear().apply()
        Log.d("MainActivity", "Preferences have been reset.")
    }

    // 앱을 킬때 마다 일일 데이터 사용량 갱신
    @RequiresApi(Build.VERSION_CODES.M)
    private fun getDailyDataUsage(): Map<String, Map<String, Any>> {
        val dateString = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
        val weeklyDataUsageJson = dailyPreferences.getString("weeklyDataUsage", "{}")
        val type = object : TypeToken<MutableMap<String, Map<String, Any>>>() {}.type
        val weeklyDataUsageMap: MutableMap<String, Map<String, Any>> = Gson().fromJson(weeklyDataUsageJson, type)

        val networkStatsManager = getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager
        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        val startTime = calendar.timeInMillis

        // 데이터 사용량 가져오는 부분
        val (mobileRx, mobileTx) = getDataUsageForPeriod(networkStatsManager, ConnectivityManager.TYPE_MOBILE, startTime, endTime)
        val (wifiRx, wifiTx) = getDataUsageForPeriod(networkStatsManager, ConnectivityManager.TYPE_WIFI, startTime, endTime)

        weeklyDataUsageMap[dateString] = mapOf(
            "MobileReceivedMB" to mobileRx / (1024 * 1024),
            "MobileTransmittedMB" to mobileTx / (1024 * 1024),
            "WiFiReceivedMB" to wifiRx / (1024 * 1024),
            "WiFiTransmittedMB" to wifiTx / (1024 * 1024)
        )

        // 7일 이상일 때 데이터 삭제
        if (weeklyDataUsageMap.size > 7) {
            val oldestDate = weeklyDataUsageMap.keys.sorted().first()
            weeklyDataUsageMap.remove(oldestDate)
        }

        // 업데이트
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

    class DataUsageReceiver : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent?) {
            if (intent?.action == "SEND_HOURLY_DATA") {
                Log.d("Alarmcheck", "알람 작동함.")
                val sharedPreferences = context.getSharedPreferences("AppData", Context.MODE_PRIVATE)
                val accessToken = sharedPreferences.getString("access_token", "") ?: ""
                val deviceId = sharedPreferences.getString("device_id", "") ?: ""
                val userId = sharedPreferences.getString("user_id", "") ?: ""

                val hourlyPreferences = context.getSharedPreferences("HourlyDataUsage", Context.MODE_PRIVATE)
                val hourlyDataJson = hourlyPreferences.getString("hourlyData", "[]")

                val dailyPreferences = context.getSharedPreferences("DailyDataUsage", Context.MODE_PRIVATE)
                val weeklyDataJson = dailyPreferences.getString("weeklyDataUsage", "{}")

                // daily 값 보내기
                weeklyDataJson?.takeIf { it.isNotBlank() }?.let { json ->
                    Log.d("Debug", "Processing WeeklyDataJson: $json")
                    sendWeeklyDataToBackend(context, json, accessToken, deviceId, userId)
                } ?: Log.e("Debug", "WeeklyDataJson is null, empty, or invalid!")

                val updatedAccessToken = sharedPreferences.getString("access_token", "") ?: ""

                // hourly 값 보내기
                hourlyDataJson?.let {
                    sendHourlyDataToBackend(context, it, updatedAccessToken, deviceId, userId)
                }

                // Reschedule alarm
                scheduleHourlyAlarm(context)
            }
        }

        private fun sendHourlyDataToBackend(context: Context, hourlyDataJson: String, accessToken: String, deviceId: String, userId: String) {
            val sharedPreferences = context.getSharedPreferences("AppData", Context.MODE_PRIVATE)
            val url = "http://ecobuddy.kro.kr:4525/dataUsage/save/hourly"

            // Parse hourly data
            val type = object : TypeToken<List<Map<String, Any>>>() {}.type
            val hourlyDataList: List<Map<String, Any>> = Gson().fromJson(hourlyDataJson, type)

            // Get the current hour
            val currentHourTimestamp = SimpleDateFormat("yyyy-MM-dd HH:00", Locale.getDefault()).format(Date())

            // Filter out the current hour
            val filteredHourlyDataList = hourlyDataList.filter { entry ->
                val timestamp = entry["Timestamp"] as? String ?: ""
                timestamp != currentHourTimestamp // Exclude current hour
            }

            // Avoid sending if the data list is empty
            if (filteredHourlyDataList.isEmpty()) {
                Log.d("DataSender", "No hourly data to send after filtering out the current hour.")
                return
            }

            // Transform data to match the expected backend format
            val formattedHourlyData = filteredHourlyDataList.map { entry ->
                val originalTimestamp = entry["Timestamp"] as? String ?: ""
                val formattedTimestamp = try {
                    val inputFormat = SimpleDateFormat("yyyy-MM-dd HH:mm", Locale.getDefault())
                    val outputFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault())
                    val date = inputFormat.parse(originalTimestamp)
                    outputFormat.format(date ?: Date()) // Convert to ISO-8601 format
                } catch (e: Exception) {
                    Log.e("TimestampConversion", "Error converting timestamp: $originalTimestamp", e)
                    originalTimestamp // Fallback to the original timestamp if conversion fails
                }

                mapOf(
                    "usageTime" to formattedTimestamp, // Ensure timestamp is properly formatted
                    "dataUsed" to ((entry["MobileReceivedMB"] as? Double ?: 0.0) + (entry["MobileTransmittedMB"] as? Double ?: 0.0)),
                    "wifiUsed" to ((entry["WiFiReceivedMB"] as? Double ?: 0.0) + (entry["WiFiTransmittedMB"] as? Double ?: 0.0))
                )
            }

            // Serialize payload to JSON
            val jsonString = Gson().toJson(formattedHourlyData)

            // Log the JSON string to confirm structure
            Log.d("DataSender", "Sending hourly data: $jsonString")

            // Build and send the HTTP request
            val request = Request.Builder()
                .url(url)
                .addHeader("authorization", accessToken)
                .addHeader("deviceId", deviceId)
                .addHeader("userId", userId)
                .post(jsonString.toRequestBody("application/json".toMediaType()))
                .build()

            val client = OkHttpClient()
            client.newCall(request).enqueue(object : Callback {
                override fun onFailure(call: Call, e: IOException) {
                    Log.e("responseDataSender", "Failed to send data: ${e.message}")
                }

                override fun onResponse(call: Call, response: Response) {
                    if (response.isSuccessful) {
                        val responseBody = response.body?.string()
                        val newAccessToken = extractAccessToken(responseBody)

                        if (newAccessToken.isNotBlank()) {
                            // Save the token to SharedPreferences
                            sharedPreferences.edit().putString("access_token", newAccessToken).apply()
                            Log.d("NewToken", "Hourly new access token saved: $newAccessToken")
                        }

                        Log.d("HourlyDataSender", "Hourly data sent successfully.")
                        // 작업 성공 시 플래그 초기화
                        sharedPreferences.edit().putBoolean("backend_failed", false).apply()
                    } else {
                        Log.e("responseDataSender Hourly", "Failed with code: ${response.code}, message: ${response.message}")
                        sharedPreferences.edit().putBoolean("backend_failed", true).apply()
                    }
                }
            })
        }

        @RequiresApi(Build.VERSION_CODES.M)
        private fun sendWeeklyDataToBackend(context: Context, weeklyDataJson: String, accessToken: String, deviceId: String, userId: String) {
            val sharedPreferences = context.getSharedPreferences("AppData", Context.MODE_PRIVATE)
            val url = "http://ecobuddy.kro.kr:4525/dataUsage/save/daily"

            // Parse weekly data
            val type = object : TypeToken<Map<String, Map<String, Any>>>() {}.type
            val weeklyDataMap: Map<String, Map<String, Any>> = Gson().fromJson(weeklyDataJson, type)

            // Get the current day
            val currentDateString = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
            // Filter out the current day
            val filteredWeeklyDataMap = weeklyDataMap.filterKeys { date -> date != currentDateString }

            // Format weekly data
            val formattedWeeklyData = filteredWeeklyDataMap.map { (date, data) ->
                val formattedDate = try {
                    val inputFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
                    val outputFormat = SimpleDateFormat("yyyy-MM-dd'T'00:00:00", Locale.getDefault())
                    val parsedDate = inputFormat.parse(date)
                    outputFormat.format(parsedDate ?: Date())
                } catch (e: Exception) {
                    Log.e("TimestampConversion", "Error formatting date: $date", e)
                    date // Fallback to original if conversion fails
                }

                mapOf(
                    "usageTime" to formattedDate,
                    "dataUsed" to ((data["MobileReceivedMB"] as? Double ?: 0.0) + (data["MobileTransmittedMB"] as? Double ?: 0.0)),
                    "wifiUsed" to ((data["WiFiReceivedMB"] as? Double ?: 0.0) + (data["WiFiTransmittedMB"] as? Double ?: 0.0))
                )
            }

            // Avoid sending if the data list is empty
            if (formattedWeeklyData.isEmpty()) {
                Log.d("DataSender", "No weekly data to send after filtering out the current day.")
                return
            }

            // Serialize payload to JSON
            val jsonString = Gson().toJson(formattedWeeklyData)
            // Log the JSON string to confirm structure
            Log.d("DataSender", "Sending weekly data: $jsonString")

            // Build and send the HTTP request
            val request = Request.Builder()
                .url(url)
                .addHeader("authorization", accessToken)
                .addHeader("deviceId", deviceId)
                .addHeader("userId", userId)
                .post(jsonString.toRequestBody("application/json".toMediaType()))
                .build()

            val client = OkHttpClient()
            client.newCall(request).enqueue(object : Callback {
                override fun onFailure(call: Call, e: IOException) {
                    Log.e("responseDataSender", "Failed to send weekly data: ${e.message}")
                }

                override fun onResponse(call: Call, response: Response) {
                    if (response.isSuccessful) {
                        val responseBody = response.body?.string()
                        val newAccessToken = extractAccessToken(responseBody)

                        if (newAccessToken.isNotBlank()) {
                            // Save the token to SharedPreferences
                            sharedPreferences.edit().putString("access_token", newAccessToken).apply()
                            Log.d("NewToken", "Daily new access token saved: $newAccessToken")
                        }

                        Log.d("WeeklyDataSender", "Weekly data sent successfully.")
                        sharedPreferences.edit().putBoolean("backend_failed", false).apply()
                    } else {
                        Log.e("responseDataSender weekly", "Failed with code: ${response.code}, message: ${response.message}")
                        sharedPreferences.edit().putBoolean("backend_failed", true).apply()
                    }
                }
            })
        }


        private fun scheduleHourlyAlarm(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, DataUsageReceiver::class.java).apply {
                action = "SEND_HOURLY_DATA"
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context, 1, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val calendar = Calendar.getInstance().apply {
                add(Calendar.HOUR_OF_DAY, 1)
                set(Calendar.MINUTE, 2)
                set(Calendar.SECOND, 0)
            }

            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                calendar.timeInMillis,
                pendingIntent
            )
        }

        private fun extractAccessToken(responseBody: String?): String {
            return try {
                val jsonObject = Gson().fromJson(responseBody, JsonObject::class.java)
                jsonObject.get("new_accessToken")?.asString ?: ""
            } catch (e: Exception) {
                Log.e("TokenParsing", "Error parsing access token: ${e.message}")
                ""
            }
        }
    }

}
