// Flutter imports
import 'package:flutter/material.dart';

// Package imports
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports
import 'package:ottr/providers/providers.dart';
import 'package:ottr/screens/home_screen.dart';
import 'package:ottr/utils/constants.dart';
import 'package:ottr/utils/extensions.dart';
import 'package:ottr/utils/validators.dart';
import 'package:ottr/widgets/loading_button.dart';

/// Screen for setting up username
class UsernameScreen extends ConsumerStatefulWidget {
  static const String routeName = '/username';
  
  const UsernameScreen({super.key});

  @override
  ConsumerState<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends ConsumerState<UsernameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  // Debounce timer for real-time username availability check
  int _debounceTimeout = 0;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _usernameController.removeListener(_onUsernameChanged);
    _usernameController.dispose();
    super.dispose();
  }

  /// Check username availability with debounce
  void _onUsernameChanged() {
    final username = _usernameController.text.trim();
    
    // Skip empty usernames
    if (username.isEmpty) {
      return;
    }
    
    // Clear previous debounce timer
    _debounceTimeout++;
    final currentTimeout = _debounceTimeout;
    
    // Set new debounce timer
    Future.delayed(const Duration(milliseconds: 500), () {
      if (currentTimeout == _debounceTimeout && mounted) {
        // Check if username is valid before checking availability
        if (usernameValidator(username) == null) {
          ref.read(usernameStateProvider.notifier).checkUsername(username);
        }
      }
    });
  }

  /// Save username and continue to home screen
  Future<void> _saveUsername() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final username = _usernameController.text.trim().toLowerCase();
    final usernameState = ref.read(usernameStateProvider);
    
    if (!usernameState.isAvailable) {
      setState(() {
        _errorMessage = 'Username is not available. Please try another one.';
      });
      return;
    }
    
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    
    try {
      final authService = ref.read(authServiceProvider);
      final currentUser = ref.read(currentUserProvider);
      
      if (currentUser == null) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'You must be logged in to set a username.';
        });
        return;
      }
      
      // Update user profile with new username
      await authService.updateUserProfile(
        uid: currentUser.uid,
        username: username,
      );
      
      if (!mounted) return;
      
      // Navigate to home screen
      context.pushReplacementNamed(HomeScreen.routeName);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final usernameState = ref.watch(usernameStateProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Username')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Instruction text
              const Text(
                'Choose a unique username that others can use to find you.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              
              // Username input field
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  hintText: 'Enter a unique username',
                  prefixIcon: const Icon(Icons.person_outline),
                  suffixIcon: usernameState.isChecking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : usernameState.username.isNotEmpty && usernameState.isAvailable
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : usernameState.username.isNotEmpty
                              ? const Icon(Icons.error, color: Colors.red)
                              : null,
                ),
                enabled: !_isSubmitting,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _saveUsername(),
                validator: (value) {
                  // Basic validation
                  final error = usernameValidator(value);
                  if (error != null) {
                    return error;
                  }
                  
                  // Availability validation
                  if (usernameState.username == value && !usernameState.isAvailable) {
                    return 'Username is already taken';
                  }
                  
                  return null;
                },
              ),
              const SizedBox(height: 8),
              
              // Username requirements
              const Text(
                'Username must be 3-15 characters, only letters, numbers, and underscores.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              
              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Continue button
              LoadingButton(
                onPressed: 
                    _isSubmitting || usernameState.isChecking || !usernameState.isAvailable
                    ? null 
                    : _saveUsername,
                isLoading: _isSubmitting,
                text: 'Continue',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
