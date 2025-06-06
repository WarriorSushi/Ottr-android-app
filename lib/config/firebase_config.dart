import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase configuration for the Ottr app.
/// Contains initialization and configuration methods for all Firebase services.
class FirebaseConfig {
  /// Initialize all Firebase services required for the app
  static Future<void> initializeApp() async {
    try {
      // Initialize Firebase Core
      await Firebase.initializeApp();
      
      // Initialize Crashlytics and disable in debug mode
      await _initializeCrashlytics();
      
      // Analytics configuration (optional)
      // await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(!kDebugMode);
    } catch (e, stack) {
      // Even if Firebase fails, we still want to run the app
      // Log error locally in this case
      print('Firebase initialization failed: $e');
      print('Stack trace: $stack');
    }
  }
  
  /// Setup Crashlytics with proper configuration
  static Future<void> _initializeCrashlytics() async {
    // Disable collection in debug mode
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);
    
    // Pass all uncaught Flutter errors to Crashlytics in non-debug mode
    if (!kDebugMode) {
      // Handle Flutter framework errors
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
      
      // Handle Dart errors outside of the Flutter framework
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
  }
  
  /// Log a non-fatal error to Crashlytics
  static void logError(dynamic error, StackTrace? stack, String reason) {
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        reason: reason,
        fatal: false,
      );
    } else {
      // In debug mode, print to console
      print('ERROR: $reason');
      print('$error');
      if (stack != null) print('$stack');
    }
  }
}
