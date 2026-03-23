package expo.modules.jpush

const val TAG = "EXPO_JPUSH"

internal object ExpoJpushEvents {
  const val REGISTRATION = "registration"
  const val MESSAGE_RECEIVED = "messageReceived"
  const val NOTIFICATION_RECEIVED = "notificationReceived"
  const val NOTIFICATION_OPENED = "notificationOpened"
  const val CONNECTION_CHANGE = "connectionChange"
  const val LOCAL_NOTIFICATION_RECEIVED = "localNotificationReceived"
  const val INAPP_MESSAGE = "inAppMessage"
  const val TAG_ALIAS_RESULT = "tagAliasResult"
  const val MOBILE_NUMBER_RESULT = "mobileNumberResult"
  const val BADGE_NUMBER = "badge"

  val ALL = arrayOf(
    REGISTRATION, MESSAGE_RECEIVED, NOTIFICATION_RECEIVED, NOTIFICATION_OPENED,
    CONNECTION_CHANGE, LOCAL_NOTIFICATION_RECEIVED, INAPP_MESSAGE,
    TAG_ALIAS_RESULT, MOBILE_NUMBER_RESULT
  )
}

