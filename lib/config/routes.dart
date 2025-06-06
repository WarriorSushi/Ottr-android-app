// Flutter imports
import 'package:flutter/material.dart';

// Project imports
import 'package:ottr/screens/auth_screen.dart';
import 'package:ottr/screens/chat_screen.dart';
import 'package:ottr/screens/home_screen.dart';
import 'package:ottr/screens/splash_screen.dart';
import 'package:ottr/screens/username_screen.dart';

/// App routes
final Map<String, WidgetBuilder> appRoutes = {
  // Define route names as constants
  SplashScreen.routeName: (context) => const SplashScreen(),
  AuthScreen.routeName: (context) => const AuthScreen(),
  UsernameScreen.routeName: (context) => const UsernameScreen(),
  HomeScreen.routeName: (context) => const HomeScreen(),
  ChatScreen.routeName: (context) => const ChatScreen(),
};
