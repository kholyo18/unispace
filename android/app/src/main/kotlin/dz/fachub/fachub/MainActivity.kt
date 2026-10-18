package dz.fachub.fachub

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var chatLocalStore: ChatLocalStoreBridge? = null
    private var attachments: ChatAttachmentsBridge? = null
    private var videoEditor: ChatVideoEditorBridge? = null
    private var privateMedia: MethodChannel? = null
    private var secureViews = 0
    private var transferBridge: ChatTransferBridge? = null
    private var resumed = false
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        chatLocalStore = ChatLocalStoreBridge(this, flutterEngine)
        videoEditor = ChatVideoEditorBridge(this, flutterEngine)
        attachments = ChatAttachmentsBridge(this, flutterEngine)
        transferBridge = ChatTransferBridge(this, flutterEngine) { resumed }
        privateMedia = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "unispace/private_media").also { channel ->
            channel.setMethodCallHandler { call, result ->
                if (call.method != "setSecure" || call.arguments !is Boolean) {
                    result.notImplemented()
                } else {
                    secureViews = (secureViews + if (call.arguments == true) 1 else -1).coerceAtLeast(0)
                    if (secureViews > 0) window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    else window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(null)
                }
            }
        }
    }
    override fun onResume() { super.onResume(); resumed = true }
    override fun onPause() { resumed = false; super.onPause() }
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: android.content.Intent?) {
        if (attachments?.onActivityResult(requestCode, resultCode, data) == true) return
        super.onActivityResult(requestCode, resultCode, data)
    }
    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        transferBridge?.dispose()
        transferBridge = null
        chatLocalStore?.dispose()
        chatLocalStore = null
        privateMedia?.setMethodCallHandler(null)
        videoEditor?.dispose()
        attachments?.dispose()
        attachments = null
        privateMedia = null
        videoEditor = null
        secureViews = 0
        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
