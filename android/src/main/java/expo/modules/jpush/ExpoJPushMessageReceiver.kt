package expo.modules.jpush

import android.content.Context
import android.util.Log
import cn.jpush.android.api.CustomMessage
import cn.jpush.android.api.NotificationMessage
import cn.jpush.android.service.JPushMessageReceiver
import org.json.JSONObject

class ExpoJPushMessageReceiver : JPushMessageReceiver() {

  private fun parseExtras(raw: String?): Map<String, Any?>? {
    if (raw.isNullOrBlank()) return null
    return runCatching {
      val json = JSONObject(raw)
      json.keys().asSequence().associateWith { key -> json.opt(key) }
    }.getOrNull()
  }

  override fun onRegister(context: Context, registrationId: String) {
    Log.d(TAG, "onRegister: $registrationId")
    ExpoJpushModule.emitOrQueue(ExpoJpushEvents.REGISTRATION, mapOf("registrationId" to registrationId))
  }

  override fun onMessage(context: Context, message: CustomMessage) {
    Log.d(TAG, "onMessage: ${message.message}")
    ExpoJpushModule.emitOrQueue(
      ExpoJpushEvents.MESSAGE_RECEIVED,
      mapOf(
        "message" to message.message,
        "title" to message.title,
        "extras" to parseExtras(message.extra)
      )
    )
  }

  override fun onNotifyMessageArrived(context: Context, message: NotificationMessage) {
    Log.d(TAG, "onNotifyMessageArrived: ${message.notificationTitle}")
    ExpoJpushModule.emitOrQueue(
      ExpoJpushEvents.NOTIFICATION_RECEIVED,
      mapOf(
        "title" to message.notificationTitle,
        "content" to message.notificationContent,
        "extras" to parseExtras(message.notificationExtras)
      )
    )
  }

  override fun onNotifyMessageOpened(context: Context, message: NotificationMessage) {
    Log.d(TAG, "onNotifyMessageOpened: ${message.notificationTitle}")
    ExpoJpushModule.emitOrQueue(
      ExpoJpushEvents.NOTIFICATION_OPENED,
      mapOf(
        "title" to message.notificationTitle,
        "content" to message.notificationContent,
        "extras" to parseExtras(message.notificationExtras)
      )
    )
  }

  override fun onConnected(context: Context, isConnected: Boolean) {
    Log.d(TAG, "onConnected: $isConnected")
    ExpoJpushModule.emitOrQueue(
      ExpoJpushEvents.CONNECTION_CHANGE,
      mapOf("connected" to isConnected)
    )
  }
}

