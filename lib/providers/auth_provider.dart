// Package imports
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports
import 'package:ottr/models/user_model.dart';
import 'package:ottr/services/auth_service.dart';

/// Provider for the AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Stream provider for auth state changes
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Provider for current user
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value;
});

/// Provider for checking if user is logged in
final isLoggedInProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

/// Future provider for user profile data
final userProfileProvider = FutureProvider.autoDispose<UserModel?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final user = ref.watch(currentUserProvider);
  
  if (user == null) return null;
  
  return await authService.getUserById(user.uid);
});

/// State notifier for tracking username setup state
class UsernameState {
  final bool isAvailable;
  final bool isChecking;
  final String? error;
  final String username;
  
  UsernameState({
    this.isAvailable = false,
    this.isChecking = false,
    this.error,
    this.username = '',
  });
  
  UsernameState copyWith({
    bool? isAvailable,
    bool? isChecking,
    String? error,
    String? username,
  }) {
    return UsernameState(
      isAvailable: isAvailable ?? this.isAvailable,
      isChecking: isChecking ?? this.isChecking,
      error: error,
      username: username ?? this.username,
    );
  }
}

class UsernameStateNotifier extends StateNotifier<UsernameState> {
  final AuthService _authService;
  
  UsernameStateNotifier(this._authService) : super(UsernameState());
  
  Future<void> checkUsername(String username) async {
    if (username.isEmpty) {
      state = state.copyWith(
        isAvailable: false,
        isChecking: false,
        error: 'Username cannot be empty',
      );
      return;
    }
    
    state = state.copyWith(
      isChecking: true,
      username: username,
      error: null,
    );
    
    try {
      final isAvailable = await _authService.isUsernameAvailable(username);
      
      state = state.copyWith(
        isAvailable: isAvailable,
        isChecking: false,
        error: isAvailable ? null : 'Username is already taken',
      );
    } catch (e) {
      state = state.copyWith(
        isChecking: false,
        isAvailable: false,
        error: 'Error checking username availability',
      );
    }
  }
  
  void reset() {
    state = UsernameState();
  }
}

/// Provider for username state
final usernameStateProvider = StateNotifierProvider<UsernameStateNotifier, UsernameState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return UsernameStateNotifier(authService);
});
