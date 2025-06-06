// Dart imports
import 'dart:async';

// Flutter imports
import 'package:flutter/material.dart';

// Package imports
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports
import 'package:ottr/app.dart';
import 'package:ottr/config/firebase_config.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Catch all errors in the app
  runZonedGuarded<Future<void>>(() async {
    try {
      // Initialize Firebase with our comprehensive config
      await FirebaseConfig.initializeApp();
      
      // App will initialize notification services via Riverpod provider when needed
      
      // Run the app wrapped in a ProviderScope for Riverpod
      runApp(const ProviderScope(child: OttrApp()));
    } catch (error, stackTrace) {
      // Show error UI if Firebase initialization fails
      debugPrint('Firebase initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      
      // Run the app in error mode
      runApp(const ErrorApp());
    }
  }, (error, stackTrace) {
    // Catch and report any errors outside of the Flutter framework
    debugPrint('Uncaught error: $error');
    FirebaseConfig.logError(error, stackTrace, 'Uncaught app error');
  });
}

/// Error screen shown when Firebase initialization fails
class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ottr - Error',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to initialize app',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Please check your internet connection and try again.'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Simple app restart attempt
                  main();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


