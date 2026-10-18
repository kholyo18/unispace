package dz.fachub.fachub

import android.app.Activity
import android.content.Intent
import android.content.ActivityNotFoundException
import android.provider.CalendarContract
import android.provider.ContactsContract
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** Uses system confirmation screens, never reads the address book in bulk. */
class ChatAttachmentsBridge(private val activity: Activity, engine: FlutterEngine) {
    private val channel = MethodChannel(engine.dartExecutor.binaryMessenger, "unispace/attachments")
    private var pending: MethodChannel.Result? = null
    private val contactRequest = 47291

    init {
        channel.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "pickContact" -> {
                        if (pending != null) {
                            result.error("busy", "Contact selection is already open", null)
                        } else {
                            pending = result
                            activity.startActivityForResult(Intent(Intent.ACTION_PICK).apply {
                                type = ContactsContract.CommonDataKinds.Phone.CONTENT_TYPE
                            }, contactRequest)
                        }
                    }
                    "saveContact" -> {
                        val name = call.argument<String>("name")?.trim().orEmpty()
                        val phone = normalizePhone(call.argument<String>("phone").orEmpty())
                        require(name.length in 1..150 && validPhone(phone))
                        activity.startActivity(Intent(Intent.ACTION_INSERT, ContactsContract.Contacts.CONTENT_URI).apply {
                            type = ContactsContract.RawContacts.CONTENT_TYPE
                            putExtra(ContactsContract.Intents.Insert.NAME, name)
                            putExtra(ContactsContract.Intents.Insert.PHONE, phone)
                        })
                        result.success(null)
                    }
                    "addEvent" -> {
                        val title = call.argument<String>("title")?.trim().orEmpty()
                        val time = call.argument<Number>("startsAtMs")?.toLong() ?: 0L
                        require(title.length in 1..200 && time in 1..253402300799999L)
                        activity.startActivity(Intent(Intent.ACTION_INSERT).apply {
                            setDataAndType(CalendarContract.Events.CONTENT_URI, "vnd.android.cursor.dir/event")
                            putExtra(CalendarContract.Events.TITLE, title)
                            putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, time)
                            putExtra(CalendarContract.Events.EVENT_LOCATION, call.argument<String>("place")?.take(300))
                            putExtra(CalendarContract.Events.DESCRIPTION, call.argument<String>("description")?.take(2000))
                        })
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (error: ActivityNotFoundException) {
                if (pending === result) pending = null
                result.error(if (call.method == "addEvent") "no-calendar-app" else "no-contacts-app", "No compatible application is installed", null)
            } catch (error: Exception) {
                if (pending === result) pending = null
                result.error(if (error is IllegalArgumentException) "invalid" else "unavailable", "Unable to open the system application", null)
            }
        }
    }

    private fun normalizePhone(value: String): String = buildString {
        require(value.length <= 80)
        for (character in value.trim()) {
            when (character) {
                in '\u0660'..'\u0669' -> append(('0'.code + character.code - '\u0660'.code).toChar())
                in '\u06F0'..'\u06F9' -> append(('0'.code + character.code - '\u06F0'.code).toChar())
                ' ', '(', ')', '-', '.' -> Unit
                else -> append(character)
            }
        }
    }

    private fun validPhone(value: String) = Regex("^[+]?[0-9]{6,15}$").matches(value)

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != contactRequest) return false
        val result = pending ?: return true
        pending = null
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            result.success(null)
            return true
        }
        try {
            val uri = data.data!!
            require(uri.scheme == "content")
            activity.contentResolver.query(uri, arrayOf(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME, ContactsContract.CommonDataKinds.Phone.NUMBER), null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val name = cursor.getString(0)?.trim().orEmpty().take(150)
                    val phone = normalizePhone(cursor.getString(1).orEmpty())
                    require(validPhone(phone))
                    result.success(mapOf("name" to name.ifEmpty { phone }, "phone" to phone))
                } else result.error("empty", "No phone number was selected", null)
            } ?: result.error("empty", "No contact was selected", null)
        } catch (error: Exception) {
            result.error("unavailable", "Unable to read the selected contact", null)
        }
        return true
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        pending?.error("cancelled", "Contact selection was closed", null)
        pending = null
    }
}


