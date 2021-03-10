package de.luh.kbs.bike_gps

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {

  override fun onCreate(savedInstanceState: Bundle?) {
      if (intent.getIntExtra("org.chromium.chrome.extra.TASK_ID", -1) == this.taskId) {
          this.finish();
          intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
          startActivity(intent);
      }
      super.onCreate(savedInstanceState);
  }
}