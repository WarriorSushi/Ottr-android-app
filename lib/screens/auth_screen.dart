// Flutter imports
import 'package:flutter/material.dart';

// Package imports
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports
import 'package:ottr/providers/providers.dart';
import 'package:ottr/screens/username_screen.dart';
import 'package:ottr/utils/constants.dart';
import 'package:ottr/utils/extensions.dart';

/// Authentication screen for Google Sign-in
class AuthScreen extends ConsumerStatefulWidget {
  static const String routeName = '/auth';
  
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  /// Handle Google Sign-in
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();
      
      // Successfully signed in - navigation is handled in the auth state listener
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes
    ref.listen<AsyncValue<bool>>(isLoggedInProvider.select((user) => AsyncValue.data(user)), 
      (_, next) {
        next.maybeWhen(
          data: (isLoggedIn) {
            if (isLoggedIn) {
              context.pushReplacementNamed(UsernameScreen.routeName);
            }
          },
          orElse: () {},
        );
      },
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              
              // App logo and title
              const Center(
                child: Icon(
                  Icons.chat_bubble_outline,
                  size: 80,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  APP_NAME,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Meaningful one-to-one conversations',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Error message if any
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Sign-in button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleGoogleSignIn,
                icon: Image.asset(
                  'assets/images/google_logo.png',
                  height: 24,
                  width: 24,
                ),
                label: Text(_isLoading ? 'Signing in...' : 'Continue with Google'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Terms and privacy
              const Center(
                child: Text(
                  'By continuing, you agree to our Terms of Service and Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
