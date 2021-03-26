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
import java.util.zip.ZipFile

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
    val file = getFileFromUri(fileURI)
    handleFile(file)
  }

  private fun handleMultipleFiles(intent: Intent) {
    val fileURIList = intent.getParcelableArrayListExtra<Parcelable>(Intent.EXTRA_STREAM) ?: arrayListOf()
    for (fileURI in fileURIList) {
      val file = getFileFromUri(fileURI as Uri)
      handleFile(file)
    }
  }

  private fun getFileFromUri(fileURI: Uri?): File? {
    if (fileURI != null) {
      val filePath: String? = uriPathHelper.getPath(this, fileURI)
      if (filePath != null) {
        return File(filePath)
      }
    }
    return null
  }

  private fun handleFile(file: File?) {
    if (file != null) {
      if (file.extension == "zip") {
        handleZip(file)
      } else {
        copyFileToAppStorage(file)
      }
    }
  }

  private fun handleZip(zipFile: File) {
    ZipFile(zipFile).use { zip ->
      zip.entries().asSequence().forEach { entry ->
        zip.getInputStream(entry).use { input ->
          File(context.filesDir.resolve("tours"), entry.name).outputStream().use { output ->
            input.copyTo(output)
          }
        }
      }
    }
  }

  private fun copyFileToAppStorage(file: File) {
      print("Kotlin: originalPath: ${file.absolutePath}")
      val newFile = File(context.filesDir.resolve("tours"), file.name)
      file.copyTo(target = newFile, overwrite = true)
  }
}