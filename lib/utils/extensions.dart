// Flutter imports
import 'package:flutter/material.dart';

/// Extension methods for BuildContext
extension BuildContextExtensions on BuildContext {
  /// Access the theme directly
  ThemeData get theme => Theme.of(this);
  
  /// Access color scheme directly
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  
  /// Access text theme directly
  TextTheme get textTheme => Theme.of(this).textTheme;
  
  /// Get screen size
  Size get screenSize => MediaQuery.of(this).size;
  
  /// Show a snackbar with custom message
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError 
            ? colorScheme.error 
            : colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  /// Navigate to a named route
  Future<T?> pushNamed<T extends Object?>(String routeName, {Object? arguments}) {
    return Navigator.of(this).pushNamed(routeName, arguments: arguments);
  }
  
  /// Replace current route with a new one
  Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    TO? result,
    Object? arguments,
  }) {
    return Navigator.of(this).pushReplacementNamed(
      routeName,
      arguments: arguments,
      result: result,
    );
  }
  
  /// Clear stack and navigate to a route
  Future<T?> pushNamedAndRemoveUntil<T extends Object?>(
    String newRouteName,
    RoutePredicate predicate, {
    Object? arguments,
  }) {
    return Navigator.of(this).pushNamedAndRemoveUntil(
      newRouteName,
      predicate,
      arguments: arguments,
    );
  }
}

/// String extension methods
extension StringExtensions on String {
  /// Convert string to title case
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : '')
        .join(' ');
  }
  
  /// Convert to chat ID format (sorted usernames)
  String createChatId(String otherUsername) {
    final List<String> usernames = [toLowerCase(), otherUsername.toLowerCase()];
    usernames.sort(); // Sort alphabetically
    return usernames.join('_');
  }
}
