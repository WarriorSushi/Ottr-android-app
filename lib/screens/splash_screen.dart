// Flutter imports
import 'package:flutter/material.dart';

// Package imports
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports
import 'package:ottr/providers/providers.dart';
import 'package:ottr/screens/auth_screen.dart';
import 'package:ottr/screens/home_screen.dart';
import 'package:ottr/screens/username_screen.dart';
import 'package:ottr/utils/constants.dart';
import 'package:ottr/utils/extensions.dart';

/// Splash screen shown during app startup
class SplashScreen extends ConsumerStatefulWidget {
  static const String routeName = '/splash';
  
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  /// Determine the next screen based on auth state
  Future<void> _navigateToNextScreen() async {
    await Future.delayed(SPLASH_DURATION);
    
    if (!mounted) return;
    
    // Watch for auth state changes
    ref.listen(authStateProvider, (_, next) {
      next.maybeWhen(
        data: (user) async {
          if (user != null) {
            // User is logged in, check if username is set
            final userProfile = await ref.read(userProfileProvider.future);
            
            if (userProfile != null && userProfile.username.isNotEmpty) {
              // Username is set, navigate to home screen
              if (!mounted) return;
              context.pushReplacementNamed(HomeScreen.routeName);
            } else {
              // Username is not set, navigate to username screen
              if (!mounted) return;
              context.pushReplacementNamed(UsernameScreen.routeName);
            }
          } else {
            // User is not logged in, navigate to auth screen
            if (!mounted) return;
            context.pushReplacementNamed(AuthScreen.routeName);
          }
        },
        error: (_, __) {
          // Error occurred, navigate to auth screen
          if (!mounted) return;
          context.pushReplacementNamed(AuthScreen.routeName);
        },
        orElse: () {},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            const Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: primaryColor,
            ),
            const SizedBox(height: 24),
            // App name
            const Text(
              APP_NAME,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 48),
            // Loading indicator
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
