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

  // Each module class must implement the definition function. The definition consists of components
  // that describes the module's functionality and behavior.
  // See https://docs.expo.dev/modules/module-api for more details about available components.
  override fun definition() = ModuleDefinition {
    // Sets the name of the module that JavaScript code will use to refer to the module. Takes a string as an argument.
    // Can be inferred from module's class name, but it's recommended to set it explicitly for clarity.
    // The module will be accessible from `requireNativeModule('ExpoJpush')` in JavaScript.
    Name("ExpoJpush")
    Events(
      ExpoJpushEvents.REGISTRATION,
      ExpoJpushEvents.MESSAGE_RECEIVED,
      ExpoJpushEvents.NOTIFICATION_RECEIVED,
      ExpoJpushEvents.NOTIFICATION_OPENED,
      ExpoJpushEvents.CONNECTION_CHANGE
    )

    AsyncFunction("init") { options: Map<String, Any>? ->
      var context = appContext.reactContext?.applicationContext
      requireNotNull(context) { "react application context is not available yet." }

      var debug = options?.get("debug") as? Boolean ?: false
      JPushInterface.setDebugMode(debug)
      JPushInterface.init(context)
      Log.d(TAG, "init called (debug=$debug)")
      Log.d(TAG, "registrationId after init: ${JPushInterface.getRegistrationID(context) ?: ""}")
      flushPendingEvents()
      JPushInterface.getRegistrationID(context) ?: ""
    }

    AsyncFunction("getRegistrationID") { ->
      var context = appContext.reactContext?.applicationContext
      requireNotNull(context) { "react application context is not available yet." }
      var registrationID = JPushInterface.getRegistrationID(context) ?: ""
      Log.d(TAG, "getRegistrationID: $registrationID")
      return@AsyncFunction registrationID
    }

    AsyncFunction("setBadgeNumber") { params: Map<String, Any?>? ->
      val context = appContext.reactContext
      requireNotNull(context) { "React application context is not available yet." }
      val number = (params?.get(ExpoJpushEvents.BADGE_NUMBER) as? Number)?.toInt()
      if (number != null) {
        JPushInterface.setBadgeNumber(context, number)
      }
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
        Log.d(TAG, "registrationId: $registrationId")
        emitOrQueue(ExpoJpushEvents.REGISTRATION, mapOf("registrationId" to registrationId))
      }
      JPushInterface.ACTION_NOTIFICATION_RECEIVED -> {
        Log.d(TAG, "ACTION_NOTIFICATION_RECEIVED")
        emitOrQueue(ExpoJpushEvents.NOTIFICATION_RECEIVED, buildNotificationPayload(intent))
      }

      JPushInterface.ACTION_MESSAGE_RECEIVED -> {
        val message = intent.getStringExtra(JPushInterface.EXTRA_MESSAGE) ?: return
        val extras = parseExtras(intent.getStringExtra(JPushInterface.EXTRA_EXTRA))
        Log.d(TAG, "message: $message")
        Log.d(TAG, "extras: $extras")
        emitOrQueue(
          ExpoJpushEvents.MESSAGE_RECEIVED,
          mapOf(
            "message" to message,
            "extras" to extras
          )
        )
      }

      JPushInterface.ACTION_NOTIFICATION_OPENED -> {
        emitOrQueue(ExpoJpushEvents.NOTIFICATION_OPENED, buildNotificationPayload(intent))
      }

      JPushInterface.ACTION_CONNECTION_CHANGE -> {
        val connected = intent.getBooleanExtra(JPushInterface.EXTRA_CONNECTION_CHANGE, false)
        Log.d(TAG, "connected: $connected")
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
      Log.d(TAG, "handleBroadcast: ${intent.action}")
      currentModule?.get()?.handleIndent(intent)
    }

    internal fun emitOrQueue(name: String, payload: Map<String, Any?>) {
      currentModule?.get()?.emitOrQueue(name, payload)
    }
  }
}
 