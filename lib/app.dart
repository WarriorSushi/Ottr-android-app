// Flutter imports
import 'package:flutter/material.dart';

// Package imports
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports
import 'package:ottr/config/routes.dart';
import 'package:ottr/config/theme.dart';
import 'package:ottr/screens/splash_screen.dart';

/// Main application widget
class OttrApp extends ConsumerWidget {
  const OttrApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Ottr',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      routes: appRoutes,
      home: const SplashScreen(),
    );
  }
}
