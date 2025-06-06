// Package imports
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports
import 'package:ottr/models/user_model.dart';
import 'package:ottr/providers/auth_provider.dart';
import 'package:ottr/services/auth_service.dart';
import 'package:ottr/utils/constants.dart';

/// Provider for current username
final currentUsernameProvider = FutureProvider<String?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(PREF_USERNAME);
});

/// Provider for searching a user by username
final userSearchProvider = FutureProvider.family<UserModel?, String>((ref, username) async {
  if (username.isEmpty) return null;
  
  final authService = ref.watch(authServiceProvider);
  return await authService.getUserByUsername(username);
});

/// Provider for checking connection state
final connectionStateProvider = Provider<AsyncValue<bool>>((ref) {
  final currentUserProfile = ref.watch(userProfileProvider);
  
  return currentUserProfile.when(
    data: (profile) => AsyncValue.data(profile?.currentChatId != null),
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

/// State notifier for managing user search
class UserSearchState {
  final String searchQuery;
  final bool isSearching;
  final UserModel? foundUser;
  final String? error;
  
  UserSearchState({
    this.searchQuery = '',
    this.isSearching = false,
    this.foundUser,
    this.error,
  });
  
  UserSearchState copyWith({
    String? searchQuery,
    bool? isSearching,
    UserModel? foundUser,
    String? error,
  }) {
    return UserSearchState(
      searchQuery: searchQuery ?? this.searchQuery,
      isSearching: isSearching ?? this.isSearching,
      foundUser: foundUser,
      error: error,
    );
  }
}

class UserSearchNotifier extends StateNotifier<UserSearchState> {
  final AuthService _authService;
  
  UserSearchNotifier(this._authService) : super(UserSearchState());
  
  Future<void> searchUser(String username) async {
    if (username.isEmpty) {
      state = UserSearchState(
        error: 'Please enter a username',
      );
      return;
    }
    
    state = UserSearchState(
      searchQuery: username,
      isSearching: true,
    );
    
    try {
      final user = await _authService.getUserByUsername(username);
      
      if (user != null) {
        state = state.copyWith(
          isSearching: false,
          foundUser: user,
          error: null,
        );
      } else {
        state = state.copyWith(
          isSearching: false,
          foundUser: null,
          error: 'User not found',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isSearching: false,
        foundUser: null,
        error: 'Error searching for user',
      );
    }
  }
  
  void reset() {
    state = UserSearchState();
  }
}

/// Provider for user search state
final userSearchStateProvider = StateNotifierProvider<UserSearchNotifier, UserSearchState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return UserSearchNotifier(authService);
});
