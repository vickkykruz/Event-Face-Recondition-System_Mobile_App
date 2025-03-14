package com.event_face_recondition_system.event_face_recondition_system_mobile_app

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
//import android.os.Bundle
//import android.webkit.PermissionRequest
import android.webkit.WebChromeClient
import android.webkit.WebView
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity


class MainActivity: FlutterActivity() {
    //override fun onCreate(savedInstanceState: Bundle?) {
    //    super.onCreate(savedInstanceState)

    //     // Request Camera Permission
    //    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
    //        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
    //            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.CAMERA), 1)
    //        }
    //    }


        // Enable Camera & Mic for WebView
    //    val webView = WebView(this)
    //    webView.webChromeClient = object : WebChromeClient() {
    //        override fun onPermissionRequest(request: PermissionRequest) {
    //            request.grant(request.resources) // Grant requested permissions
    //        }
    //    }
    //}

    override fun onResume() {
        super.onResume()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.CAMERA), 1)
            }
        }
    }
}

