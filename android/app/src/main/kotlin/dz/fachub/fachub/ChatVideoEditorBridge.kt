package dz.fachub.fachub

import android.content.Context
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.ScaleAndRotateTransformation
import androidx.media3.transformer.Composition
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.Effects
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.ProgressHolder
import androidx.media3.transformer.Transformer
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.UUID
import java.util.concurrent.Executors

@UnstableApi
class ChatVideoEditorBridge(context: Context, engine: FlutterEngine) {
    private val context = context.applicationContext
    private val channel = MethodChannel(engine.dartExecutor.binaryMessenger, "unispace/video_editor")
    private var transformer: Transformer? = null
    private var pending: MethodChannel.Result? = null
    private var output: File? = null
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var closed = false

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "export" -> {
                    if (pending != null) { result.error("busy", "Video export already running", null) }
                    else {
                        try {
                            val input = File(requireNotNull(call.argument<String>("path"))).canonicalFile
                            require(input.isFile) { "Missing video" }
                            val start = requireNotNull(call.argument<Number>("startMs")).toLong()
                            val end = requireNotNull(call.argument<Number>("endMs")).toLong()
                            val turns = call.argument<Number>("quarterTurns")?.toInt() ?: 0
                            require(start >= 0 && end > start && end - start <= 60000 && turns in 0..3) { "Invalid video selection" }
                            val muted = call.argument<Boolean>("muted") ?: false
                            val target = File(context.cacheDir, "chat_edit_${UUID.randomUUID()}.mp4")
                            val item = MediaItem.Builder().setUri(Uri.fromFile(input)).setClippingConfiguration(
                                MediaItem.ClippingConfiguration.Builder().setStartPositionMs(start).setEndPositionMs(end).build()
                            ).build()
                            // Media3 uses counter-clockwise positive rotation; Flutter preview rotates clockwise.
                            val effects = if (turns == 0) Effects(emptyList(), emptyList()) else Effects(emptyList(), listOf(
                                ScaleAndRotateTransformation.Builder().setRotationDegrees(-90f * turns).build()
                            ))
                            val edited = EditedMediaItem.Builder(item).setRemoveAudio(muted).setEffects(effects).build()
                            val active = Transformer.Builder(context)
                                .setVideoMimeType(MimeTypes.VIDEO_H264)
                                .setAudioMimeType(MimeTypes.AUDIO_AAC)
                                .addListener(object : Transformer.Listener {
                                    override fun onCompleted(composition: Composition, exportResult: ExportResult) {
                                        if (output != target) { target.delete(); return }
                                        val callback = pending
                                        pending = null; transformer = null; output = null
                                        if (target.isFile && target.length() > 0) callback?.success(target.absolutePath)
                                        else { target.delete(); callback?.error("empty-output", "No video exported", null) }
                                    }
                                    override fun onError(composition: Composition, exportResult: ExportResult, exportException: ExportException) {
                                        if (output != target) { target.delete(); return }
                                        val callback = pending
                                        pending = null; transformer = null; output = null
                                        target.delete()
                                        callback?.error("export-failed", "Video could not be exported", exportException.errorCode)
                                    }
                                }).build()
                            output = target; pending = result; transformer = active
                            active.start(edited, target.absolutePath)
                        } catch (error: Exception) {
                            transformer?.cancel(); transformer = null
                            output?.delete(); output = null
                            pending = null
                            result.error("export-failed", "Video could not be exported", null)
                        }
                    }
                }
                "cancel" -> { cancel(); result.success(null) }
                "progress" -> {
                    val holder = ProgressHolder()
                    val progress = transformer?.getProgress(holder)
                    result.success(if (progress == Transformer.PROGRESS_STATE_AVAILABLE) holder.progress else null)
                }
                "thumbnail", "metadata" -> {
                    val path = call.argument<String>("path")
                    if (path.isNullOrEmpty()) { result.error("invalid-path", "Missing local video path", null) }
                    else worker.execute {
                        var thumbnail: File? = null
                        val retriever = MediaMetadataRetriever()
                        try {
                            val input = File(path).canonicalFile
                            require(input.isFile) { "Missing local video" }
                            retriever.setDataSource(input.absolutePath)
                            val duration = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull() ?: 0L
                            val width = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toIntOrNull() ?: 0
                            val height = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toIntOrNull() ?: 0
                            if (call.method == "metadata") {
                                val metadata = mapOf("durationMs" to duration, "width" to width, "height" to height)
                                main.post { if (!closed) result.success(metadata) }
                            } else {
                                require(width > 0 && height > 0)
                                val scale = minOf(1.0, 480.0 / maxOf(width, height))
                                val targetWidth = maxOf(1, (width * scale).toInt())
                                val targetHeight = maxOf(1, (height * scale).toInt())
                                val raw = if (Build.VERSION.SDK_INT >= 27) retriever.getScaledFrameAtTime(0, MediaMetadataRetriever.OPTION_CLOSEST_SYNC, targetWidth, targetHeight)
                                    else retriever.getFrameAtTime(0, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
                                requireNotNull(raw) { "No video frame" }
                                val scaled = Bitmap.createScaledBitmap(raw, targetWidth, targetHeight, true)
                                val target = File(context.cacheDir, "chat_thumb_${UUID.randomUUID()}.jpg")
                                thumbnail = target
                                try { target.outputStream().use { require(scaled.compress(Bitmap.CompressFormat.JPEG, 80, it)) } }
                                finally { if (scaled !== raw) scaled.recycle(); raw.recycle() }
                                main.post { if (closed) target.delete() else result.success(target.absolutePath) }
                            }
                        } catch (_: Exception) {
                            thumbnail?.delete()
                            main.post { if (!closed) result.error("video-read-failed", "Cannot read local video", null) }
                        } finally { retriever.release() }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
    private fun cancel() {
        transformer?.cancel(); transformer = null
        output?.delete(); output = null
        val callback = pending; pending = null
        callback?.error("cancelled", "Video export cancelled", null)
    }
    fun dispose() {
        closed = true
        cancel()
        channel.setMethodCallHandler(null)
        worker.shutdown()
    }
}
