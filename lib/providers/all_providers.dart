// Package imports
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports
import 'package:ottr/services/notification_service.dart';

/// Provider for notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final notificationService = NotificationService();
  
  ref.onDispose(() {
    notificationService.dispose();
  });
  
  return notificationService;
});
