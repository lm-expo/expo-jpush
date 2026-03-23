package expo.modules.jpush

import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import cn.jpush.android.api.JPushInterface
import android.util.Log
import android.content.Intent
import java.lang.ref.WeakReference
import org.json.JSONObject

class ExpoJpushModule : Module() {

  init {
    currentModule = WeakReference(this)
  }

  override fun definition() = ModuleDefinition {
    Name("ExpoJpush")

    Events(*ExpoJpushEvents.ALL)

    // ---- 基础 ----
    AsyncFunction("init") { options: Map<String, Any>? ->
      val context = appContext.reactContext?.applicationContext
      requireNotNull(context) { "react application context is not available yet." }

      val debug = options?.get("debug") as? Boolean ?: false
      JPushInterface.setDebugMode(debug)
      JPushInterface.init(context)
      Log.d(TAG, "init called (debug=$debug)")
      flushPendingEvents()
      val registrationId = JPushInterface.getRegistrationID(context) ?: ""
      if (registrationId.isNotEmpty()) {
        emitOrQueue(ExpoJpushEvents.REGISTRATION, mapOf("registrationId" to registrationId))
      }
      registrationId
    }

    AsyncFunction("getRegistrationID") { ->
      val context = appContext.reactContext?.applicationContext
      requireNotNull(context) { "react application context is not available yet." }
      JPushInterface.getRegistrationID(context) ?: ""
    }

    AsyncFunction("setBadgeNumber") { params: Map<String, Any?>? ->
      val context = appContext.reactContext
      requireNotNull(context) { "React application context is not available yet." }
      val number = (params?.get(ExpoJpushEvents.BADGE_NUMBER) as? Number)?.toInt()
      if (number != null) {
        JPushInterface.setBadgeNumber(context, number)
      }
    }

    // ---- Tag 操作 ----
    AsyncFunction("setTags") { params: Map<String, Any?> ->
      val context = appContext.reactContext
      requireNotNull(context) { "React application context is not available yet." }
      val tags = (params["tags"] as? List<*>)?.filterIsInstance<String>()?.toSet() ?: return@AsyncFunction
      val seq = (params["seq"] as? Number)?.toInt() ?: 0
      JPushInterface.setTags(context, seq, tags)
    }

    AsyncFunction("addTags") { params: Map<String, Any?> ->
      val context = appContext.reactContext
      requireNotNull(context) { "React application context is not available yet." }
      val tags = (params["tags"] as? List<*>)?.filterIsInstance<String>()?.toSet() ?: return@AsyncFunction
      val seq = (params["seq"] as? Number)?.toInt() ?: 0
      JPushInterface.addTags(context, seq, tags)
    }

    AsyncFunction("deleteTags") { params: Map<String, Any?> ->
      val context = appContext.reactContext
      requireNotNull(context) { "React application context is not available yet." }
      val tags = (params["tags"] as? List<*>)?.filterIsInstance<String>()?.toSet() ?: return@AsyncFunction
      val seq = (params["seq"] as? Number)?.toInt() ?: 0
      JPushInterface.deleteTags(context, seq, tags)
    }

    AsyncFunction("cleanTags") { params: Map<String, Any?> ->
      val context = appContext.reactContext
      requireNotNull(context) { "React application context is not available yet." }
      val seq = (params["seq"] as? Number)?.toInt() ?: 0
      JPushInterface.cleanTags(context, seq)
    }

    AsyncFunction("getAllTags") { params: Map<String, Any?> ->
      val context = appContext.reactContext
      requireNotNull(context) { "React application context is not available yet." }
      val seq = (params["seq"] as? Number)?.toInt() ?: 0
      JPushInterface.getAllTags(context, seq)
    }

    // ---- Alias 操作 ----
    AsyncFunction("setAlias") { params: Map<String, Any?> ->
      val context = appContext.reactContext
      requireNotNull(context) { "React application context is not available yet." }
      val alias = params["alias"] as? String ?: return@AsyncFunction
      val seq = (params["seq"] as? Number)?.toInt() ?: 0
      JPushInterface.setAlias(context, seq, alias)
    }

    AsyncFunction("deleteAlias") { params: Map<String, Any?> ->
      val context = appContext.reactContext
      requireNotNull(context) { "React application context is not available yet." }
      val seq = (params["seq"] as? Number)?.toInt() ?: 0
      JPushInterface.deleteAlias(context, seq)
    }

    AsyncFunction("getAlias") { params: Map<String, Any?> ->
      val context = appContext.reactContext
      requireNotNull(context) { "React application context is not available yet." }
      val seq = (params["seq"] as? Number)?.toInt() ?: 0
      JPushInterface.getAlias(context, seq)
    }

    // ---- 手机号码 ----
    AsyncFunction("setMobileNumber") { params: Map<String, Any?> ->
      val context = appContext.reactContext
      requireNotNull(context) { "React application context is not available yet." }
      val mobileNumber = params["mobileNumber"] as? String ?: return@AsyncFunction
      val seq = (params["seq"] as? Number)?.toInt() ?: 0
      JPushInterface.setMobileNumber(context, seq, mobileNumber)
    }

    // ---- 应用内消息页面追踪 ----
    // Android SDK 没有 pageEnterTo/pageLeave，这是 iOS 独有 API。
    // Android 应用内消息通过 JPushMessageReceiver 的 onInAppMessageShow/Click 自动触发。
    AsyncFunction("pageEnterTo") { _: Map<String, Any?> -> }

    AsyncFunction("pageLeave") { _: Map<String, Any?> -> }

    // ---- 本地通知 ----
    AsyncFunction("addLocalNotification") { params: Map<String, Any?> ->
      val context = appContext.reactContext
      requireNotNull(context) { "React application context is not available yet." }
      val id = (params["id"] as? Number)?.toLong() ?: 0L
      val title = params["title"] as? String ?: context.packageName
      val content = params["content"] as? String ?: context.packageName
      val fireTime = (params["fireTime"] as? Number)?.toLong() ?: 0L
      val extras = params["extras"] as? Map<*, *>

      val notification = cn.jpush.android.data.JPushLocalNotification()
      notification.notificationId = id
      notification.title = title
      notification.content = content
      notification.broadcastTime = if (fireTime > 0) System.currentTimeMillis() + fireTime else System.currentTimeMillis()
      if (extras != null) {
        notification.extras = JSONObject(extras).toString()
      }

      val builderName = params["builderName"] as? String
      if (!builderName.isNullOrEmpty()) {
        val builderId = context.resources.getIdentifier(builderName, "layout", context.packageName)
        if (builderId != 0) {
          notification.builderId = builderId.toLong()
        }
      }

      val category = params["category"] as? String
      if (!category.isNullOrEmpty()) {
        notification.category = category
      }

      val priority = (params["priority"] as? Number)?.toInt()
      if (priority != null) {
        notification.priority = priority
      }

      JPushInterface.addLocalNotification(context, notification)
    }

    AsyncFunction("removeLocalNotification") { params: Map<String, Any?> ->
      val context = appContext.reactContext
      requireNotNull(context) { "React application context is not available yet." }
      val id = (params["id"] as? String)?.toLongOrNull() ?: return@AsyncFunction
      JPushInterface.removeLocalNotification(context, id)
    }

    AsyncFunction("clearLocalNotifications") { ->
      val context = appContext.reactContext
      requireNotNull(context) { "React application context is not available yet." }
      JPushInterface.clearLocalNotifications(context)
    }
  }

  private fun parseExtras(raw: String?): Map<String, Any?>? {
    if (raw == null) return null
    return runCatching {
      val json = JSONObject(raw)
      json.keys().asSequence().associateWith { key -> json.opt(key) }
    }.getOrElse {
      Log.w(TAG, "Failed to parse JPush extras: ${it.message}")
      null
    }
  }

  private fun buildNotificationPayload(intent: Intent): Map<String, Any?> {
    val title = intent.getStringExtra(JPushInterface.EXTRA_NOTIFICATION_TITLE)
    val alert = intent.getStringExtra(JPushInterface.EXTRA_ALERT)
    val extras = parseExtras(intent.getStringExtra(JPushInterface.EXTRA_EXTRA))
    return mapOf(
      "title" to title,
      "content" to alert,
      "extras" to extras
    )
  }

  private fun handleIndent(intent: Intent) {
    Log.d(TAG, "handleIndent: ${intent.action}")
    when (intent.action) {
      JPushInterface.ACTION_REGISTRATION_ID -> {
        val registrationId = intent.getStringExtra(JPushInterface.EXTRA_REGISTRATION_ID) ?: return
        emitOrQueue(ExpoJpushEvents.REGISTRATION, mapOf("registrationId" to registrationId))
      }
      JPushInterface.ACTION_NOTIFICATION_RECEIVED -> {
        emitOrQueue(ExpoJpushEvents.NOTIFICATION_RECEIVED, buildNotificationPayload(intent))
      }
      JPushInterface.ACTION_MESSAGE_RECEIVED -> {
        val message = intent.getStringExtra(JPushInterface.EXTRA_MESSAGE) ?: return
        val extras = parseExtras(intent.getStringExtra(JPushInterface.EXTRA_EXTRA))
        emitOrQueue(
          ExpoJpushEvents.MESSAGE_RECEIVED,
          mapOf("message" to message, "extras" to extras)
        )
      }
      JPushInterface.ACTION_NOTIFICATION_OPENED -> {
        emitOrQueue(ExpoJpushEvents.NOTIFICATION_OPENED, buildNotificationPayload(intent))
      }
      JPushInterface.ACTION_CONNECTION_CHANGE -> {
        val connected = intent.getBooleanExtra(JPushInterface.EXTRA_CONNECTION_CHANGE, false)
        emitOrQueue(ExpoJpushEvents.CONNECTION_CHANGE, mapOf("connected" to connected))
      }
    }
  }

  private fun emitOrQueue(name: String, payload: Map<String, Any?>) {
    if (appContext.reactContext == null) {
      synchronized(pendingEvents) {
        pendingEvents.add(Pair(name, payload))
      }
    } else {
      sendEvent(name, payload)
    }
  }

  private fun flushPendingEvents() {
    synchronized(pendingEvents) {
      pendingEvents.forEach { (name, payload) ->
        sendEvent(name, payload)
      }
      pendingEvents.clear()
    }
  }

  companion object {
    private var currentModule: WeakReference<ExpoJpushModule>? = null
    private val pendingEvents = mutableListOf<Pair<String, Map<String, Any?>>>()

    internal fun handleBroadcast(intent: Intent) {
      currentModule?.get()?.handleIndent(intent)
    }

    internal fun emitOrQueue(name: String, payload: Map<String, Any?>) {
      currentModule?.get()?.emitOrQueue(name, payload)
    }
  }
}
