package expo.modules.jpush

import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import cn.jpush.android.api.JPushInterface
import android.util.Log
import android.content.Intent
import java.lang.ref.WeakReference
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

    var TAG = "EXPO_JPUSH"

    AsyncFunction("init") { options: Map<String, Any>? ->
      var context = appContext.reactContext?.applicationContext
      requireNotNull(context) { "react application context is not available yet." }

      var debug = options?.get("debug") as? Boolean ?: false
      JPushInterface.setDebugMode(debug)
      JPushInterface.init(context)
      Log.d(TAG, "init called (debug=$debug)")
      Log.d(TAG, "registrationId after init: ${JPushInterface.getRegistrationID(context) ?: ""}")
    }

    AsyncFunction("getRegistrationID") { ->
      var context = appContext.reactContext?.applicationContext
      requireNotNull(context) { "react application context is not available yet." }
      var registrationID = JPushInterface.getRegistrationID(context) ?: ""
      Log.d(TAG, "getRegistrationID: $registrationID")
      return@AsyncFunction registrationID
    }
  }

  private fun handleIndent(intent: Intent) {
    Log.d(TAG, "handleIndent: ${intent.action}")
    when (intent.action) {

      JPushInterface.ACTION_NOTIFICATION_RECEIVED -> {
        Log.d(TAG, "ACTION_NOTIFICATION_RECEIVED")
        var registrationId = intent.getStringExtra(JPushInterface.EXTRA_REGISTRATION_ID) ?: return
        Log.d(TAG, "registrationId: $registrationId")
      }
    }
  }

  companion object {

    private var currentModule: WeakReference<ExpoJpushModule>? = null


    fun handleBroadcast(intent: Intent) {
      Log.d(TAG, "handleBroadcast: ${intent.action}")
      currentModule?.get()?.handleIndent(intent)
    }
  }
}
 