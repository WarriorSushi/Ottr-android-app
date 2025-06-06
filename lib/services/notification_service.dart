// Flutter imports
import 'package:flutter/foundation.dart';

// Package imports
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Project imports
import 'package:ottr/services/auth_service.dart';

/// Service responsible for handling push notifications
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotifications = 
      FlutterLocalNotificationsPlugin();
  final AuthService _authService = AuthService();

  /// Initialize notification services
  Future<void> init() async {
    try {
      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      debugPrint('Notification permission status: ${settings.authorizationStatus}');
      
      // Initialize local notifications
      const initializationSettingsAndroid = AndroidInitializationSettings('ic_notification');
      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );
      
      await _flutterLocalNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _handleNotificationTap,
      );
      
      // Configure notification channel for Android
      const androidChannel = AndroidNotificationChannel(
        'ottr_messages',
        'Ottr Messages',
        description: 'This channel is used for important notifications from Ottr.',
        importance: Importance.high,
      );
      
      await _flutterLocalNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
      
      // Configure FCM
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
      
      // Get FCM token and save it
      await updateFcmToken();
    } catch (e, stackTrace) {
      debugPrint('Error initializing notification service: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Update FCM token
  Future<void> updateFcmToken() async {
    try {
      final token = await _messaging.getToken();
      
      if (token != null) {
        debugPrint('FCM Token: $token');
        
        // Save token to user profile if logged in
        final currentUser = _authService.currentUser;
        if (currentUser != null) {
          await _authService.updateFcmToken(currentUser.uid, token);
        }
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  /// Handle foreground message
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Received foreground message: ${message.messageId}');
    
    // Extract notification data
    final notification = message.notification;
    final android = message.notification?.android;
    
    // Show local notification
    if (notification != null && android != null) {
      final androidDetails = AndroidNotificationDetails(
        'ottr_messages',
        'Ottr Messages',
        icon: android.smallIcon,
        importance: Importance.high,
        priority: Priority.high,
      );
      
      final notificationDetails = NotificationDetails(android: androidDetails);
      
      await _flutterLocalNotifications.show(
        notification.hashCode,
        notification.title,
        // Don't show message content for privacy
        'New message received',
        notificationDetails,
        payload: message.data['chatId'],
      );
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(NotificationResponse notificationResponse) {
    // Handle navigation based on payload (chatId)
    final chatId = notificationResponse.payload;
    if (chatId != null && chatId.isNotEmpty) {
      // Navigation will be handled by the ChatProvider
      debugPrint('Notification tapped with chatId: $chatId');
    }
  }
  
  /// Clean up resources when service is no longer needed
  void dispose() {
    // Cancel any active subscriptions or listeners if needed
    debugPrint('NotificationService disposed');
  }
}

/// Handle background message
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  // No need to show notification as system will do it automatically
}
