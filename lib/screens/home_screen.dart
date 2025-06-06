// Flutter imports
import 'package:flutter/material.dart';

// Package imports
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports
import 'package:ottr/models/user_model.dart';
import 'package:ottr/providers/providers.dart';
import 'package:ottr/screens/chat_screen.dart';
import 'package:ottr/utils/constants.dart';
import 'package:ottr/utils/extensions.dart';
import 'package:ottr/widgets/username_input.dart';

/// Home screen showing current connection status and allowing new connections
class HomeScreen extends ConsumerStatefulWidget {
  static const String routeName = '/home';
  
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _usernameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  /// Connect to a user by username
  Future<void> _connectToUser(String username) async {
    if (username.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get the user by username
      final authService = ref.read(authServiceProvider);
      final otherUser = await authService.getUserByUsername(username.toLowerCase());

      if (!mounted) return;

      if (otherUser == null) {
        // User not found
        _showErrorMessage('User not found. Please check the username and try again.');
        return;
      }

      // Check if trying to connect to self
      final currentProfile = ref.read(userProfileProvider).value;
      if (currentProfile?.username.toLowerCase() == username.toLowerCase()) {
        _showErrorMessage('You cannot connect to yourself.');
        return;
      }

      // Connect to the user
      await ref.read(chatConnectionProvider.notifier).connectWithUser(otherUser);
      
      // Navigate to chat screen
      if (!mounted) return;
      context.pushNamed(ChatScreen.routeName);
    } catch (e) {
      _showErrorMessage('Error connecting to user: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _usernameController.clear();
        });
      }
    }
  }

  /// Show error message
  void _showErrorMessage(String message) {
    if (!mounted) return;
    
    setState(() {
      _isLoading = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: errorColor,
      ),
    );
  }

  /// Handle sign out
  Future<void> _handleSignOut() async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
    } catch (e) {
      _showErrorMessage('Error signing out: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Current user and connection state
    final userProfile = ref.watch(userProfileProvider);
    final connectionState = ref.watch(connectionStateProvider);
    final chatConnection = ref.watch(chatConnectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(APP_NAME),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _handleSignOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: userProfile.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('User not found. Please sign in again.'));
          }
          
          return RefreshIndicator(
            onRefresh: () async {
              // Refresh providers
              ref.invalidate(userProfileProvider);
              ref.invalidate(connectionStateProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Welcome message and username display
                  Text(
                    'Welcome, ${profile.username}!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Current connection status
                  connectionState.when(
                    data: (isConnected) {
                      if (isConnected) {
                        // Show current connection
                        return _buildCurrentConnection(chatConnection);
                      } else {
                        return _buildNoConnection();
                      }
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, _) => Text(
                      'Error: ${err.toString()}',
                      style: const TextStyle(color: errorColor),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Connect to new user section
                  const Text(
                    'Connect to Someone',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  UsernameInput(
                    controller: _usernameController,
                    isLoading: _isLoading,
                    onSubmitted: _connectToUser,
                    buttonLabel: 'Connect',
                  ),
                  
                  const SizedBox(height: 24),
                  const Divider(),
                  
                  // App info section
                  const SizedBox(height: 24),
                  const Text(
                    'About Ottr',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ottr is a minimalist one-to-one messaging app that focuses on meaningful conversations by allowing only one active chat at a time.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Error: ${err.toString()}'),
        ),
      ),
    );
  }

  /// Widget for showing current connection
  Widget _buildCurrentConnection(ChatConnectionState chatConnection) {
    final currentChat = chatConnection.currentChat;
    final otherUser = chatConnection.otherUser;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Connection',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            if (currentChat != null || otherUser != null) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: primaryColor,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  otherUser?.username ?? 'Connected User',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: currentChat?.lastMessage.isNotEmpty == true
                    ? Text(
                        'Last message: ${currentChat!.lastMessage}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : const Text('No messages yet'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => context.pushNamed(ChatScreen.routeName),
              ),
              
              const SizedBox(height: 16),
              
              ElevatedButton.icon(
                onPressed: () async {
                  await ref.read(chatConnectionProvider.notifier).disconnectFromChat();
                },
                icon: const Icon(Icons.close),
                label: const Text('Disconnect'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ] else ...[
              const Text('Something went wrong. Please refresh the page.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(connectionStateProvider);
                  ref.invalidate(chatConnectionProvider);
                },
                child: const Text('Refresh'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Widget for showing no active connection
  Widget _buildNoConnection() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: primaryColor),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'You are not connected with anyone right now.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Enter a username below to start a conversation.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
