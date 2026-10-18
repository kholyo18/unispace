package dz.fachub.fachub

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.AtomicFile
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.security.KeyStore
import java.util.concurrent.Executors
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/** App-private, backup-excluded storage. Private payloads and retained media are
 * encrypted with a non-exportable Android Keystore key, authenticated per slot. */
class ChatLocalStoreBridge(private val context: Context, engine: FlutterEngine) {
    private val channel = MethodChannel(engine.dartExecutor.binaryMessenger, "unispace/chat_local_store")
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val root = File(context.noBackupFilesDir, "chat_local_v1")
    private val restored = File(context.cacheDir, "chat_local_restored_v1")
    private val preferences = context.getSharedPreferences("chat_local_scope_v1", Context.MODE_PRIVATE)
    private val alias = "unispace_chat_local_v1"
    private val maxBlob = 128L * 1024 * 1024
    private val maxTotal = 512L * 1024 * 1024

    init {
        // One bridge per engine: remove plaintext restore remnants after process death.
        worker.execute { restored.deleteRecursively() }
        channel.setMethodCallHandler { call, result ->
            worker.execute {
                try {
                    val scope = call.argument<String>("scope") ?: error("Scope required")
                    require(scope.matches(Regex("[a-f0-9]{64}")))
                    val active = preferences.getString("active", null)
                    val answer: Any? = when (call.method) {
                        "activate" -> {
                            if (active != scope) {
                                root.deleteRecursively(); restored.deleteRecursively()
                                check(preferences.edit().putString("active", scope).commit())
                            }
                            root.mkdirs(); restored.mkdirs(); null
                        }
                        "purge" -> {
                            if (active == scope) {
                                root.deleteRecursively(); restored.deleteRecursively()
                                check(preferences.edit().remove("active").commit())
                            }
                            null
                        }
                        else -> {
                            check(active == scope) { "Chat session changed" }
                            val key = call.argument<String>("key") ?: error("Key required")
                            require(key.matches(Regex("[a-z0-9_-]{1,100}")))
                            val file = File(root, key)
                            when (call.method) {
                                "read" -> if (!file.exists()) null else {
                                    require(file.length() <= 2L * 1024 * 1024 + 64)
                                    decryptBytes(file, scope, key).toString(Charsets.UTF_8)
                                }
                                "write" -> {
                                    val value = call.argument<String>("value") ?: error("Value required")
                                    val bytes = value.toByteArray(Charsets.UTF_8)
                                    require(bytes.size <= 2 * 1024 * 1024)
                                    checkQuota(file, bytes.size.toLong())
                                    encrypt(file, scope, key, bytes.inputStream()); null
                                }
                                "keepFile" -> {
                                    val source = File(call.argument<String>("path") ?: error("Path required"))
                                    require(source.isFile && source.length() <= maxBlob)
                                    checkQuota(file, source.length())
                                    source.inputStream().use { encrypt(file, scope, key, it) }; null
                                }
                                "restoreFile" -> {
                                    if (!file.exists()) null else {
                                        val extension = call.argument<String>("extension") ?: "bin"
                                        require(extension.matches(Regex("[a-zA-Z0-9]{1,8}")))
                                        restored.mkdirs()
                                        val target = File(restored, "$key.$extension")
                                        decryptFile(file, target, scope, key)
                                        target.absolutePath
                                    }
                                }
                                "delete" -> {
                                    AtomicFile(file).delete()
                                    // Restored files may belong to an active send after draft handoff.
                                    // Dart owns their lifetime; startup/session purge clears leftovers.
                                    null
                                }
                                else -> error("Unknown storage operation")
                            }
                        }
                    }
                    main.post { result.success(answer) }
                } catch (error: Exception) {
                    main.post { result.error("chat-storage-unavailable", "Private chat storage unavailable", null) }
                }
            }
        }
    }

    private fun checkQuota(replacing: File, bytes: Long) {
        root.mkdirs()
        val used = root.listFiles()?.sumOf { it.length() } ?: 0
        check(used - replacing.length() + bytes + 64 <= maxTotal) { "Private storage full" }
    }
    private fun secret(): SecretKey {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (store.getKey(alias, null) as? SecretKey)?.let { return it }
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM).setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(256).build())
        return generator.generateKey()
    }
    private fun cipher(mode: Int, scope: String, key: String, iv: ByteArray? = null): Cipher {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        if (iv == null) cipher.init(mode, secret()) else cipher.init(mode, secret(), GCMParameterSpec(128, iv))
        cipher.updateAAD("$scope:$key".toByteArray(Charsets.UTF_8))
        return cipher
    }
    private fun encrypt(target: File, scope: String, key: String, input: java.io.InputStream) {
        val atomic = AtomicFile(target)
        var output: FileOutputStream? = null
        try {
            val crypt = cipher(Cipher.ENCRYPT_MODE, scope, key)
            output = atomic.startWrite()
            output.write(1); output.write(crypt.iv.size); output.write(crypt.iv)
            transfer(input, output, crypt)
            atomic.finishWrite(output)
        } catch (error: Exception) { atomic.failWrite(output); throw error }
    }
    private fun decryptBytes(file: File, scope: String, key: String): ByteArray = file.inputStream().use { input ->
        val crypt = readCipher(input, scope, key)
        crypt.doFinal(input.readBytes())
    }
    private fun readCipher(input: FileInputStream, scope: String, key: String): Cipher {
        require(input.read() == 1)
        val size = input.read(); require(size == 12)
        val iv = ByteArray(size)
        require(input.read(iv) == size)
        return cipher(Cipher.DECRYPT_MODE, scope, key, iv)
    }
    private fun decryptFile(file: File, target: File, scope: String, key: String) {
        require(file.length() <= maxBlob + 64)
        val atomic = AtomicFile(target)
        var output: FileOutputStream? = null
        try {
            file.inputStream().use { input ->
                val crypt = readCipher(input, scope, key)
                output = atomic.startWrite()
                transfer(input, output!!, crypt)
            }
            atomic.finishWrite(output)
        } catch (error: Exception) { atomic.failWrite(output); target.delete(); throw error }
    }
    private fun transfer(input: java.io.InputStream, output: FileOutputStream, crypt: Cipher) {
        val buffer = ByteArray(64 * 1024)
        var total = 0L
        while (true) {
            val count = input.read(buffer); if (count < 0) break
            total += count; require(total <= maxBlob + 64)
            crypt.update(buffer, 0, count)?.let { output.write(it) }
        }
        output.write(crypt.doFinal())
    }
    fun dispose() { channel.setMethodCallHandler(null); worker.shutdown() }
}

