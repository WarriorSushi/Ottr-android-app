// Project imports
import 'package:ottr/utils/constants.dart';

/// Utility class for input validation
class Validators {
  /// Validates username
  /// Returns null if valid, error message if invalid
  static String? validateUsername(String? username) {
    if (username == null || username.isEmpty) {
      return 'Username cannot be empty';
    }
    
    if (username.length < minUsernameLength) {
      return 'Username must be at least $minUsernameLength characters';
    }
    
    if (username.length > maxUsernameLength) {
      return 'Username cannot exceed $maxUsernameLength characters';
    }
    
    final RegExp usernameRegex = RegExp(usernamePattern);
    if (!usernameRegex.hasMatch(username)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    
    return null;
  }
  
  /// Validates message text
  /// Returns null if valid, error message if invalid
  static String? validateMessageText(String? message) {
    if (message == null || message.isEmpty) {
      return 'Message cannot be empty';
    }
    
    if (message.length > maxMessageLength) {
      return 'Message cannot exceed $maxMessageLength characters';
    }
    
    return null;
  }
}
