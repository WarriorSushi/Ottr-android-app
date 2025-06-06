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
    
    if (username.length < MIN_USERNAME_LENGTH) {
      return 'Username must be at least $MIN_USERNAME_LENGTH characters';
    }
    
    if (username.length > MAX_USERNAME_LENGTH) {
      return 'Username cannot exceed $MAX_USERNAME_LENGTH characters';
    }
    
    final RegExp usernameRegex = RegExp(USERNAME_PATTERN);
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
    
    if (message.length > MAX_MESSAGE_LENGTH) {
      return 'Message cannot exceed $MAX_MESSAGE_LENGTH characters';
    }
    
    return null;
  }
}
