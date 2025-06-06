package com.example.ottr

import io.flutter.app.FlutterApplication
import com.google.firebase.FirebaseApp
import com.google.firebase.crashlytics.FirebaseCrashlytics
import androidx.multidex.MultiDex
import android.content.Context

class Application : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        
        // Initialize Firebase
        FirebaseApp.initializeApp(this)
        
        // Enable Crashlytics in non-debug builds
        FirebaseCrashlytics.getInstance().setCrashlyticsCollectionEnabled(!BuildConfig.DEBUG)
    }

    override fun attachBaseContext(base: Context) {
        super.attachBaseContext(base)
        // Initialize MultiDex for devices running Android API level < 21
        MultiDex.install(this)
    }
}
