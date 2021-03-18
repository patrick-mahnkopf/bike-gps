package de.luh.kbs.bike_gps

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.os.Parcelable
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import java.io.File

class MainActivity: FlutterActivity() {
  private val uriPathHelper = URIPathHelper()
  private var permissions = arrayOf(
          Manifest.permission.READ_CONTACTS,
          Manifest.permission.WRITE_CONTACTS,
          Manifest.permission.WRITE_EXTERNAL_STORAGE,
          Manifest.permission.READ_SMS,
          Manifest.permission.CAMERA
  )

  override fun onCreate(savedInstanceState: Bundle?) {
    if (!hasPermissions(this, *permissions)) {
      ActivityCompat.requestPermissions(this, permissions, 1)
    }
    handleIntent()
      super.onCreate(savedInstanceState)
  }

  private fun hasPermissions(context: Context, vararg permissions: String): Boolean = permissions.all {
    ActivityCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED
  }

  private fun handleIntent() {
    when (intent?.action) {
      Intent.ACTION_SEND, Intent.ACTION_VIEW -> {
        handleSingleFile(intent)
      }
      Intent.ACTION_SEND_MULTIPLE -> {
        handleMultipleFiles(intent)
      }
    }
  }

  private fun handleSingleFile(intent: Intent) {
    val fileURI = intent.getParcelableExtra<Parcelable>(Intent.EXTRA_STREAM) as? Uri
    if (fileURI != null) {
      copyFileToAppStorage(fileURI)
    }
  }

  private fun handleMultipleFiles(intent: Intent) {
    val fileURIList = intent.getParcelableArrayListExtra<Parcelable>(Intent.EXTRA_STREAM) ?: arrayListOf()
    for (fileURI in fileURIList) {
      if (fileURI != null) {
        copyFileToAppStorage(fileURI as Uri)
      }
    }
  }

  private fun copyFileToAppStorage(fileURI: Uri) {
    val originalPath = uriPathHelper.getPath(this, fileURI)
    if (originalPath != null) {
      print("Kotlin: originalPath: $originalPath")
      val originalFile = File(originalPath)
      val newFile = File(context.filesDir.resolve("tours"), originalFile.name)
      originalFile.copyTo(target = newFile)
    }
  }
}