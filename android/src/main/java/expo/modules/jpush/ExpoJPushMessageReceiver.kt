package expo.modules.jpush

import android.content.Context
import android.util.Log
import cn.jpush.android.api.CustomMessage
import cn.jpush.android.api.JPushMessage
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
    Log.d(TAG, "onNotifyMessageArrived: ${message.notificationTitle} type=${message.notificationType}")
    val payload = mapOf(
      "title" to message.notificationTitle,
      "content" to message.notificationContent,
      "extras" to parseExtras(message.notificationExtras)
    )
    if (message.notificationType == 1) {
      ExpoJpushModule.emitOrQueue(ExpoJpushEvents.LOCAL_NOTIFICATION_RECEIVED, payload)
    } else {
      ExpoJpushModule.emitOrQueue(ExpoJpushEvents.NOTIFICATION_RECEIVED, payload)
    }
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

  // ---- Tag/Alias 回调 ----
  override fun onTagOperatorResult(context: Context, jPushMessage: JPushMessage) {
    Log.d(TAG, "onTagOperatorResult: $jPushMessage")
    ExpoJpushModule.emitOrQueue(
      ExpoJpushEvents.TAG_ALIAS_RESULT,
      mapOf(
        "code" to jPushMessage.errorCode,
        "sequence" to jPushMessage.sequence,
        "tags" to jPushMessage.tags?.toList()
      )
    )
  }

  override fun onCheckTagOperatorResult(context: Context, jPushMessage: JPushMessage) {
    Log.d(TAG, "onCheckTagOperatorResult: $jPushMessage")
    ExpoJpushModule.emitOrQueue(
      ExpoJpushEvents.TAG_ALIAS_RESULT,
      mapOf(
        "code" to jPushMessage.errorCode,
        "sequence" to jPushMessage.sequence,
        "tags" to jPushMessage.tags?.toList(),
        "isBind" to jPushMessage.tagCheckStateResult
      )
    )
  }

  override fun onAliasOperatorResult(context: Context, jPushMessage: JPushMessage) {
    Log.d(TAG, "onAliasOperatorResult: $jPushMessage")
    ExpoJpushModule.emitOrQueue(
      ExpoJpushEvents.TAG_ALIAS_RESULT,
      mapOf(
        "code" to jPushMessage.errorCode,
        "sequence" to jPushMessage.sequence,
        "alias" to jPushMessage.alias
      )
    )
  }

  // ---- 手机号码回调 ----
  override fun onMobileNumberOperatorResult(context: Context, jPushMessage: JPushMessage) {
    Log.d(TAG, "onMobileNumberOperatorResult: $jPushMessage")
    ExpoJpushModule.emitOrQueue(
      ExpoJpushEvents.MOBILE_NUMBER_RESULT,
      mapOf(
        "code" to jPushMessage.errorCode,
        "sequence" to jPushMessage.sequence
      )
    )
  }

  // ---- 应用内消息回调 ----
  override fun onInAppMessageShow(context: Context, message: NotificationMessage) {
    Log.d(TAG, "onInAppMessageShow: ${message.notificationTitle}")
    ExpoJpushModule.emitOrQueue(
      ExpoJpushEvents.INAPP_MESSAGE,
      mapOf(
        "eventType" to "show",
        "title" to message.notificationTitle,
        "content" to message.notificationContent,
        "extras" to parseExtras(message.notificationExtras)
      )
    )
  }

  override fun onInAppMessageClick(context: Context, message: NotificationMessage) {
    Log.d(TAG, "onInAppMessageClick: ${message.notificationTitle}")
    ExpoJpushModule.emitOrQueue(
      ExpoJpushEvents.INAPP_MESSAGE,
      mapOf(
        "eventType" to "click",
        "title" to message.notificationTitle,
        "content" to message.notificationContent,
        "extras" to parseExtras(message.notificationExtras)
      )
    )
  }
}
