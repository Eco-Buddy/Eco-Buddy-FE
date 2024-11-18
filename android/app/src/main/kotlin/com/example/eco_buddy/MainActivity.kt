package com.example.eco_buddy

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
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.widget.Toast

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.datausage/data"
    private lateinit var dailyPreferences: SharedPreferences
    private lateinit var hourlyPreferences: SharedPreferences

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        dailyPreferences = getSharedPreferences("DailyDataUsage", Context.MODE_PRIVATE)
        hourlyPreferences = getSharedPreferences("HourlyDataUsage", Context.MODE_PRIVATE)

        // 권한이 없으면
        if (!isAccessGranted()) {
            notifyUserAndRedirect()
        } else {
            dailyInitializeBaseline()
            hourlyInitializeBaseline()
        }
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
                else -> {
                    result.notImplemented()
                }
            }
        }
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

        // 시간별 데이터 사용량 초기화
        val hourlyDataJson = hourlyPreferences.getString("hourlyData", "[]")
        val type = object : TypeToken<MutableList<Map<String, Any>>>() {}.type
        val hourlyDataList: MutableList<Map<String, Any>> = Gson().fromJson(hourlyDataJson, type)

        // 시간 세팅
        val networkStatsManager = getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager
        val calendar = Calendar.getInstance()
        val endTime = System.currentTimeMillis()
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        val startTime = calendar.timeInMillis

        // 이전 시간은 삭제
        val todayDate = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
        val filteredHourlyData = hourlyDataList.filterNot { entry ->
            val timestamp = entry["Timestamp"] as String
            timestamp.startsWith(todayDate)
        }.toMutableList()

        // 각 시간 별로 데이터 사용량 저장 (자정까지)
        while (calendar.timeInMillis < endTime) {
            val hourStart = calendar.timeInMillis
            calendar.add(Calendar.HOUR_OF_DAY, 1)
            val hourEnd = minOf(calendar.timeInMillis, endTime)

            val timestamp = SimpleDateFormat("yyyy-MM-dd HH:mm", Locale.getDefault()).format(Date(hourStart))

            // 데이터 사용량 가져오는 부분
            val (mobileRx, mobileTx) = getDataUsageForPeriod(networkStatsManager, ConnectivityManager.TYPE_MOBILE, hourStart, hourEnd)
            val (wifiRx, wifiTx) = getDataUsageForPeriod(networkStatsManager, ConnectivityManager.TYPE_WIFI, hourStart, hourEnd)

            // 업데이트
            val hourlyData = mapOf(
                "Timestamp" to timestamp,
                "MobileReceivedMB" to mobileRx / (1024 * 1024),
                "MobileTransmittedMB" to mobileTx / (1024 * 1024),
                "WiFiReceivedMB" to wifiRx / (1024 * 1024),
                "WiFiTransmittedMB" to wifiTx / (1024 * 1024)
            )

            filteredHourlyData.add(hourlyData)
        }

        // 저장
        hourlyPreferences.edit()
            .putString("hourlyData", Gson().toJson(filteredHourlyData))
            .apply()
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
}
