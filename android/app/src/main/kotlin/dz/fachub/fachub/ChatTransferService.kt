package dz.fachub.fachub

import android.app.*
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** Keeps an already user-started Dart transfer eligible while the app is backgrounded.
 * Does not restart transfers, retain credentials, or survive force-stop. */
class ChatTransferService : Service() {
    companion object { @Volatile var running = false; private const val CHANNEL = "chat_transfers" }
    override fun onCreate() {
        super.onCreate()
        val language = if (Build.VERSION.SDK_INT >= 24) resources.configuration.locales[0].language else resources.configuration.locale.language
        val title = when (language) { "ar" -> "جارٍ إرسال الوسائط"; "fr" -> "Envoi des médias"; else -> "Sending media" }
        if (Build.VERSION.SDK_INT >= 26) {
            getSystemService(NotificationManager::class.java).createNotificationChannel(
                NotificationChannel(CHANNEL, title, NotificationManager.IMPORTANCE_LOW))
        }
        val open = PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(this, CHANNEL) else Notification.Builder(this)
        val notification = builder.setSmallIcon(android.R.drawable.stat_sys_upload)
            .setContentTitle(title).setContentIntent(open).setOngoing(true).setOnlyAlertOnce(true).build()
        if (Build.VERSION.SDK_INT >= 29) startForeground(7712, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
        else startForeground(7712, notification)
        running = true
    }
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int) = START_NOT_STICKY
    override fun onBind(intent: Intent?): IBinder? = null
    override fun onTimeout(startId: Int, fgsType: Int) { stopSelf() }
    override fun onDestroy() { running = false; super.onDestroy() }
}

class ChatTransferBridge(private val activity: Activity, engine: FlutterEngine, private val foreground: () -> Boolean) {
    private val channel = MethodChannel(engine.dartExecutor.binaryMessenger, "unispace/chat_transfers")
    init {
        channel.setMethodCallHandler { call, result ->
            if (call.method != "setActive" || call.arguments !is Boolean) { result.notImplemented(); return@setMethodCallHandler }
            val intent = Intent(activity, ChatTransferService::class.java)
            if (call.arguments == false) { activity.stopService(intent); result.success(null); return@setMethodCallHandler }
            if (ChatTransferService.running) { result.success(null); return@setMethodCallHandler }
            if (!foreground()) { result.error("background-start-not-allowed", "Start the transfer while the app is open.", null); return@setMethodCallHandler }
            try {
                if (Build.VERSION.SDK_INT >= 26) activity.startForegroundService(intent) else activity.startService(intent)
                result.success(null)
            } catch (error: IllegalStateException) {
                result.error("transfer-service-unavailable", "Android did not allow the transfer service.", null)
            } catch (error: SecurityException) {
                result.error("transfer-service-unavailable", "Android did not allow the transfer service.", null)
            }
        }
    }
    fun dispose() { channel.setMethodCallHandler(null); activity.stopService(Intent(activity, ChatTransferService::class.java)) }
}
