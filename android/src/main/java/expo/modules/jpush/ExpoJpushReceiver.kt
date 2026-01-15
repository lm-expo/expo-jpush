package expo.modules.jpush

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import expo.modules.jpush.TAG

class ExpoJpushReceiver : BroadcastReceiver() {
  override fun onReceive(context: Context?, intent: Intent?) {
    if (intent != null) {
      Log.d(TAG, "onReceive: ${intent.action}")
      ExpoJpushModule.handleBroadcast(intent)
    }
  }
}