package app.anlage.anlageappgame

import android.os.Bundle
import android.provider.Settings

import io.flutter.app.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {

  private val CHANNEL = "app.anlage.anlageappgame/SystemSetting"

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    GeneratedPluginRegistrant.registerWith(this)

    MethodChannel(flutterView, CHANNEL).setMethodCallHandler { call, result ->
      when (call.method) {
        "getString" ->
          result.success(Settings.System.getString(contentResolver, call.argument("name")))
        else ->
          result.notImplemented()
      }
    }
  }
}
