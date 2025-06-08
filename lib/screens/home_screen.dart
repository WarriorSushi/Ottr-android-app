// Dart imports
import 'dart:async';

// Flutter imports
import 'package:flutter/material.dart';

// Package imports
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';

// Project imports
import 'package:ottr/providers/providers.dart';
import 'package:ottr/screens/auth_screen.dart';
import 'package:ottr/screens/chat_screen.dart';
import 'package:ottr/utils/constants.dart';
import 'package:ottr/utils/extensions.dart';
import 'package:ottr/utils/validators.dart';

/// Home screen showing current connection status and allowing new connections
class HomeScreen extends ConsumerStatefulWidget {
  static const String routeName = '/home';
  
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isLoading = false;
  bool _hasUsername = false;
  bool _isCheckingUsername = false;
  String? _usernameStatus; // 'valid', 'invalid', 'self', or null
  ConnectionRequestStatus? _pendingRequestStatus;
  Timer? _debounceTimer;
  
  // Audio player for connection sound
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Subscription for incoming connection requests
  StreamSubscription? _requestSubscription;
  
  // Connection request handling
  Map<String, dynamic>? _incomingRequest;
  bool _showConnectionAnimation = false;
  bool _processingRequest = false;

  @override
  void initState() {
    super.initState();
    // Add listener to update button state when text changes
    _usernameController.addListener(_updateUsernameState);
    
    // Initialize audio player
    _audioPlayer.setReleaseMode(ReleaseMode.release);
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Start listening for incoming connection requests
    _listenForIncomingRequests();
  }
  
  @override
  void dispose() {
    // Clean up controllers and subscriptions
    _usernameController.dispose();
    _debounceTimer?.cancel();
    _requestSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _updateUsernameState() {
    final text = _usernameController.text.trim();
    final hasText = text.isNotEmpty;
    
    if (hasText != _hasUsername) {
      setState(() {
        _hasUsername = hasText;
        if (!hasText) {
          _usernameStatus = null;
        }
      });
    }
    
    // Cancel previous timer if it exists
    _debounceTimer?.cancel();
    
    // If text is not empty, check if username exists after a short delay
    if (hasText) {
      // Set a debounce timer to avoid too many API calls
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted && !_isCheckingUsername) {
          _checkUsername(text);
        }
      });
    }
  }
  
  Future<void> _checkUsername(String username) async {
    // Don't check very short usernames
    if (username.length < 3) return;
    
    // Set checking state
    setState(() {
      _isCheckingUsername = true;
      _usernameStatus = null;
    });
    
    try {
      // Check if trying to connect to self
      final currentProfile = ref.read(userProfileProvider).value;
      if (currentProfile?.username.toLowerCase() == username.toLowerCase()) {
        setState(() {
          _usernameStatus = 'self';
          _isCheckingUsername = false;
        });
        return;
      }
      
      // Check if username exists
      final authService = ref.read(authServiceProvider);
      final otherUser = await authService.getUserByUsername(username.toLowerCase());
      
      if (!mounted) return;
      
      setState(() {
        _usernameStatus = otherUser != null ? 'valid' : 'invalid';
        _isCheckingUsername = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _usernameStatus = null;
          _isCheckingUsername = false;
        });
      }
    }
  }

  /// Listen for incoming connection requests
  void _listenForIncomingRequests() {
    // Get the current user profile - use read instead of watch in methods
    final userProfileAsync = ref.read(userProfileProvider);
    
    // Handle all AsyncValue states properly
    userProfileAsync.when(
      data: (userProfile) {
        if (userProfile != null && mounted) {
          debugPrint('Setting up request listener for user: ${userProfile.username}');
          
          // Start listening for incoming requests
          final dbService = ref.read(databaseServiceProvider);
          _requestSubscription = dbService.streamIncomingRequests(userProfile.username).listen(
            (requests) {
              if (!mounted) return;
              
              debugPrint('Received ${requests.length} incoming requests');
              
              setState(() {
                _incomingRequest = requests.isNotEmpty ? requests.first : null;
                if (_incomingRequest != null) {
                  debugPrint('Showing incoming request from: ${_incomingRequest!["fromUsername"]}');
                }
              });
            },
            onError: (error) {
              debugPrint('Error in request stream: $error');
            },
          );
        } else {
          debugPrint('User profile is null or widget not mounted');
        }
      },
      loading: () => debugPrint('Loading user profile...'),
      error: (error, stackTrace) {
        debugPrint('Error getting user profile: $error');
        debugPrintStack(stackTrace: stackTrace);
      },
    );
  }

  /// Connect to a user by username
  Future<void> _connectToUser(String username) async {
    final trimmedUsername = username.trim();
    if (trimmedUsername.isEmpty) return;

    setState(() {
      _isLoading = true;
      _usernameStatus = null; // Reset status while connecting
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
      
      debugPrint('Attempting to connect with user: ${otherUser.username}');
      
      // Check for existing connection or request
      final dbService = ref.read(databaseServiceProvider);
      final existingRequest = await dbService.checkExistingRequest(
        currentUsername: currentProfile!.username,
        otherUsername: otherUser.username
      );
      
      if (existingRequest != null) {
        debugPrint('Found existing request: ${existingRequest.toString()}');
        
        if (existingRequest['status'] == 'pending') {
          // Check if this is our outgoing request or their incoming request
          if (existingRequest['fromUsername'].toLowerCase() == currentProfile.username.toLowerCase()) {
            // We already sent a request to this user
            _showInfoMessage('You already sent a request to this user. Please wait for a response.');
            return;
          } else {
            // This is an incoming request from the user we're trying to connect with
            debugPrint('Found incoming request from the user we want to connect with. Auto-accepting.');
            _showInfoMessage('${otherUser.username} already sent you a connection request. Accepting...');
            
            // Auto-accept their request
            await _acceptConnectionRequest(existingRequest);
            return;
          }
        } else if (existingRequest['status'] == 'accepted') {
          // Already connected, go to chat
          debugPrint('Already connected with this user. Going to chat.');
          _showSuccessMessage('You are already connected with ${otherUser.username}!');
          
          // Show animation briefly
          setState(() {
            _showConnectionAnimation = true;
          });
          
          // Play sound
          try {
            await _audioPlayer.play(AssetSource('sound/connect.mp3'));
          } catch (e) {
            debugPrint('Error playing sound: $e');
          }
          
          // Get the chatId from the request
          final chatId = existingRequest['chatId'];
          if (chatId != null) {
            debugPrint('Found existing chat ID: $chatId');
            // Ensure chat is loaded in provider
            final chatConnectionNotifier = ref.read(chatConnectionProvider.notifier);
            // Load the chat instead of listening to it directly
            await chatConnectionNotifier.loadChatById(chatId);
            
            // Wait briefly for animation and chat state to update
            await Future.delayed(const Duration(milliseconds: 1000));
            
            if (!mounted) return;
            
            // Check if chat state is ready
            final chatConnection = ref.read(chatConnectionProvider);
            if (chatConnection.isConnected && chatConnection.currentChat != null) {
              // Navigate to chat screen
              context.pushNamed(ChatScreen.routeName);
            } else {
              debugPrint('Chat state not ready, waiting a bit longer');
              // Wait a bit longer
              await Future.delayed(const Duration(milliseconds: 500));
              
              if (!mounted) return;
              
              // Try again
              final updatedChatConnection = ref.read(chatConnectionProvider);
              if (updatedChatConnection.isConnected && updatedChatConnection.currentChat != null) {
                context.pushNamed(ChatScreen.routeName);
              } else {
                _showErrorMessage('Chat not found. Please try again.');
              }
            }
          } else {
            _showErrorMessage('Chat not found. Please try again.');
          }
        }
      }

      // Send new connection request
      debugPrint('Sending new connection request to: ${otherUser.username}');
      await ref.read(chatConnectionProvider.notifier).connectWithUser(otherUser);
      
      // Check the connection request status
      final connectionState = ref.read(chatConnectionProvider);
      debugPrint('Connection request status: ${connectionState.requestStatus}');
      
      if (connectionState.requestStatus == ConnectionRequestStatus.accepted) {
        setState(() {
          _showConnectionAnimation = true;
        });
        
        // Play connection sound
        try {
          await _audioPlayer.play(AssetSource('sound/connect.mp3'));
          debugPrint('Connection sound played');
        } catch (e) {
          debugPrint('Error playing sound: $e');
        }
        
        // Wait for animation to complete
        await Future.delayed(const Duration(seconds: 2));
        
        if (!mounted) return;
        
        // Navigate to chat screen
        _showSuccessMessage('Connected successfully with ${otherUser.username}!');
        context.pushNamed(ChatScreen.routeName);
      } else if (connectionState.requestStatus == ConnectionRequestStatus.pending) {
        _showSuccessMessage('Connection request sent to ${otherUser.username}. Waiting for response...');
        setState(() {
          _pendingRequestStatus = connectionState.requestStatus;
        });
      } else {
        debugPrint('Unexpected connection status: ${connectionState.requestStatus}');
        setState(() {
          _pendingRequestStatus = connectionState.requestStatus;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error in _connectToUser: $e');
      debugPrintStack(stackTrace: stackTrace);
      _showErrorMessage('Failed to connect: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Reset animation state if it was somehow left on
          if (_showConnectionAnimation) {
            _showConnectionAnimation = false;
          }
        });
      }
    }
  }

  /// Show error message
  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  /// Show success message
  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  /// Show info message
  void _showInfoMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
      ),
    );
  }
  
  /// Accept a connection request
  Future<void> _acceptConnectionRequest(dynamic request) async {
    setState(() {
      _processingRequest = true;
    });
    
    try {
      // Handle both string requestId and request object
      final String requestId = request is String ? request : request['id'];
      debugPrint('Accepting connection request with ID: $requestId');
      
      // Get request details for better logging
      String fromUsername = '';
      if (request is! String && request['fromUsername'] != null) {
        fromUsername = request['fromUsername'];
        debugPrint('Request from user: $fromUsername');
      }
      
      final chatConnectionNotifier = ref.read(chatConnectionProvider.notifier);
      
      // Accept the connection request
      await chatConnectionNotifier.acceptConnectionRequest(requestId);
      debugPrint('Connection request accepted successfully');
      
      // Show connection animation and play sound
      setState(() {
        _showConnectionAnimation = true;
        _incomingRequest = null;
      });
      
      // Play connection sound
      try {
        await _audioPlayer.play(AssetSource('sound/connect.mp3'));
        debugPrint('Connection sound played');
      } catch (e) {
        debugPrint('Error playing sound: $e');
        // Don't rethrow - sound is not critical
      }
      
      // Wait for animation to be visible
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Start waiting for chat state to be updated (max 5 attempts)
      int attempts = 0;
      bool chatReady = false;
      
      while (attempts < 5 && !chatReady && mounted) {
        final chatConnection = ref.read(chatConnectionProvider);
        chatReady = chatConnection.isConnected && chatConnection.currentChat != null;
        
        if (chatReady) {
          debugPrint('Chat state ready after $attempts attempts');
          break;
        }
        
        debugPrint('Waiting for chat state to update (attempt ${attempts + 1}/5)');
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
      }
      
      // Show animation for at least 2 seconds total regardless of chat state
      final remainingAnimationTime = 2000 - (500 * (attempts + 1));
      if (remainingAnimationTime > 0) {
        await Future.delayed(Duration(milliseconds: remainingAnimationTime));
      }
      
      if (!mounted) return;
      
      // Navigate to chat screen if ready
      final chatConnection = ref.read(chatConnectionProvider);
      if (chatConnection.isConnected && chatConnection.currentChat != null) {
        _showSuccessMessage('Connected successfully with ${fromUsername.isNotEmpty ? fromUsername : 'user'}!');
        debugPrint('Navigating to chat screen with chat: ${chatConnection.currentChat?.id}');
        context.pushNamed(ChatScreen.routeName);
      } else {
        debugPrint('Chat state not ready after waiting, showing error');
        _showErrorMessage('Connection established but chat could not be loaded. Please try again.');
      }
    } catch (e) {
      debugPrint('Error accepting connection request: $e');
      if (mounted) {
        _showErrorMessage('Failed to accept connection: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingRequest = false;
          _showConnectionAnimation = false;
        });
      }
    }
  }
  
  /// Reject an incoming connection request
  Future<void> _rejectConnectionRequest(dynamic request) async {
    if (_processingRequest) return;
    
    setState(() {
      _processingRequest = true;
    });
    
    try {
      // Handle both string requestId and request object
      final String requestId = request is String ? request : request['id'];
      debugPrint('Rejecting connection request with ID: $requestId');
      
      // Get request details for better logging
      String fromUsername = '';
      if (request is! String && request['fromUsername'] != null) {
        fromUsername = request['fromUsername'];
        debugPrint('Rejecting request from user: $fromUsername');
      }
      
      final chatConnectionNotifier = ref.read(chatConnectionProvider.notifier);
      
      // Reject the connection request
      await chatConnectionNotifier.rejectConnectionRequest(requestId);
      debugPrint('Connection request rejected successfully');
      
      setState(() {
        _incomingRequest = null;
      });
      
      _showSuccessMessage('Connection request ${fromUsername.isNotEmpty ? "from $fromUsername " : ""}rejected.');
    } catch (e) {
      debugPrint('Error rejecting connection request: $e');
      if (mounted) {
        _showErrorMessage('Failed to reject connection request');
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingRequest = false;
        });
      }
    }
  }
  
  /// Handle sign out
  Future<void> _handleSignOut() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
      
      if (!mounted) return;
      
      // Navigate to auth screen and remove all previous routes
      Navigator.of(context).pushNamedAndRemoveUntil(
        AuthScreen.routeName,
        (route) => false, // Remove all previous routes
      );
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Error signing out: ${e.toString()}');
        setState(() {
          _isLoading = false;
        });
      }
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
        title: const Text(appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _handleSignOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          userProfile.when(
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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome message
                  Text(
                    'Welcome, ${profile.username}!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your unique ID: ${profile.username}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Current connection status
                  connectionState.when(
                    data: (isConnected) {
                      if (isConnected) {
                        // Show current connection
                        return _buildCurrentConnection(chatConnection);
                      } else {
                        // Show no connection UI
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildNoConnection(),
                            
                            // Only show username input if there's no pending request
                            if (chatConnection.requestStatus != ConnectionRequestStatus.pending)
                            Container(
                              margin: const EdgeInsets.only(top: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person_add_rounded,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Connect to Someone',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Enter the username of the person you want to connect with:',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  TextField(
                                    controller: _usernameController,
                                    decoration: InputDecoration(
                                      hintText: 'Username',
                                      prefixIcon: const Icon(Icons.person),
                                      suffixIcon: _isCheckingUsername 
                                          ? const SizedBox(
                                              height: 16,
                                              width: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : _usernameStatus == 'valid'
                                              ? const Icon(Icons.check_circle, color: Colors.green)
                                              : _usernameStatus == 'invalid'
                                                  ? const Icon(Icons.error, color: Colors.red)
                                                  : _usernameStatus == 'self'
                                                      ? const Icon(Icons.person, color: Colors.orange)
                                                      : null,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true,
                                      fillColor: Theme.of(context).colorScheme.surface,
                                      contentPadding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                        horizontal: 16,
                                      ),
                                      helperText: _usernameStatus == 'valid'
                                          ? 'User found! Ready to connect.'
                                          : _usernameStatus == 'invalid'
                                              ? 'User not found. Check the username.'
                                              : _usernameStatus == 'self'
                                                  ? 'This is your username.'
                                                  : null,
                                      helperStyle: TextStyle(
                                        color: _usernameStatus == 'valid'
                                            ? Colors.green
                                            : _usernameStatus == 'invalid' || _usernameStatus == 'self'
                                                ? Colors.red
                                                : null,
                                      ),
                                    ),
                                    textInputAction: TextInputAction.go,
                                    onSubmitted: (value) {
                                      if (_usernameStatus == 'valid') {
                                        _connectToUser(value.trim());
                                      }
                                    },
                                    enabled: !_isLoading,
                                    autocorrect: false,
                                    autofocus: true,
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton.icon(
                                      onPressed: _isLoading || _usernameStatus != 'valid'
                                          ? null
                                          : () => _connectToUser(_usernameController.text.trim()),
                                      icon: const Icon(Icons.connect_without_contact),
                                      label: _isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : const Text('Connect'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context).colorScheme.primary,
                                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                        elevation: 3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
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
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
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
        
        // Incoming connection request overlay
        if (_incomingRequest != null)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(24),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_add_rounded,
                          size: 48,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Connection Request',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_incomingRequest!['fromUsername']} wants to connect with you',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _processingRequest ? null : () => _rejectConnectionRequest(_incomingRequest!),
                              icon: const Icon(Icons.close),
                              label: const Text('Reject'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade100,
                                foregroundColor: Colors.red.shade700,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _processingRequest ? null : () => _acceptConnectionRequest(_incomingRequest!),
                              icon: const Icon(Icons.check),
                              label: const Text('Accept'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade100,
                                foregroundColor: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        if (_processingRequest)
                          const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: CircularProgressIndicator(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        
        // Connection animation overlay
        if (_showConnectionAnimation)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: Lottie.asset(
                        'assets/lottie/tick.json',
                        repeat: false,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Connected!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
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
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: const Icon(Icons.person, color: Colors.white),
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
                  backgroundColor: Theme.of(context).colorScheme.error,
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
    final chatConnection = ref.watch(chatConnectionProvider);
    final requestStatus = chatConnection.requestStatus;
    final otherUser = chatConnection.otherUser;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
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
            
            // Show connection request status if there's a pending request
            if (requestStatus == ConnectionRequestStatus.pending && otherUser != null) ...[              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.pending_outlined, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Connection request sent to ${otherUser.username}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Waiting for them to accept your request...'),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          setState(() {
                            _isLoading = true;
                          });
                          try {
                            await ref.read(chatConnectionProvider.notifier).cancelConnectionRequest();
                            setState(() {
                              _pendingRequestStatus = null;
                              _usernameController.clear();
                            });
                          } catch (e) {
                            _showErrorMessage('Failed to cancel request: $e');
                          } finally {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        },
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Cancel Request'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else if (requestStatus == ConnectionRequestStatus.rejected) ...[              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Connection request rejected',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('The user declined your connection request.'),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _pendingRequestStatus = null;
                            _usernameController.clear();
                          });
                        },
                        child: const Text('OK'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else if (requestStatus == ConnectionRequestStatus.canceled) ...[              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Connection request canceled',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Your connection request has been canceled.'),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _pendingRequestStatus = null;
                            _usernameController.clear();
                          });
                        },
                        child: const Text('OK'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
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
