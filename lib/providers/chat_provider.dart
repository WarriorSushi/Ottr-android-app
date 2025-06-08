// Dart imports
import 'dart:async';

// Flutter imports
import 'package:flutter/foundation.dart';

// Package imports
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports
import 'package:ottr/models/chat_model.dart';
import 'package:ottr/models/message_model.dart';
import 'package:ottr/models/user_model.dart';
import 'package:ottr/providers/auth_provider.dart';
import 'package:ottr/providers/user_provider.dart';
import 'package:ottr/services/database_service.dart';

/// Provider for database service
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

/// Provider for current chat ID
final currentChatIdProvider = FutureProvider<String?>((ref) async {
  final dbService = ref.watch(databaseServiceProvider);
  return await dbService.getCurrentChatId();
});

/// Provider for current chat
final currentChatProvider = StreamProvider<ChatModel?>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  final chatIdAsync = ref.watch(currentChatIdProvider);
  
  return chatIdAsync.when(
    data: (chatId) {
      if (chatId == null) return Stream.value(null);
      
      return dbService.streamChatById(chatId);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

/// Provider for chat messages
final chatMessagesProvider = StreamProvider.family<List<MessageModel>, String>((ref, chatId) {
  final dbService = ref.watch(databaseServiceProvider);
  return dbService.getChatMessages(chatId);
});

/// Provider for user chats
final userChatsProvider = StreamProvider<List<ChatModel>>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  final usernameAsync = ref.watch(currentUsernameProvider);
  
  return usernameAsync.when(
    data: (username) {
      if (username == null) return Stream.value([]);
      return dbService.getUserChats(username);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Connection request status enum
enum ConnectionRequestStatus {
  none,
  pending,
  accepted,
  rejected,
  canceled
}

/// State notifier for managing chat connection
class ChatConnectionState {
  final bool isConnecting;
  final bool isConnected;
  final ChatModel? currentChat;
  final String? error;
  final UserModel? otherUser;
  final ConnectionRequestStatus requestStatus;
  final String? pendingRequestId;
  
  ChatConnectionState({
    this.isConnecting = false,
    this.isConnected = false,
    this.currentChat,
    this.error,
    this.otherUser,
    this.requestStatus = ConnectionRequestStatus.none,
    this.pendingRequestId,
  });
  
  ChatConnectionState copyWith({
    bool? isConnecting,
    bool? isConnected,
    ChatModel? currentChat,
    String? error,
    UserModel? otherUser,
    ConnectionRequestStatus? requestStatus,
    String? pendingRequestId,
  }) {
    return ChatConnectionState(
      isConnecting: isConnecting ?? this.isConnecting,
      isConnected: isConnected ?? this.isConnected,
      currentChat: currentChat ?? this.currentChat,
      error: error,
      otherUser: otherUser ?? this.otherUser,
      requestStatus: requestStatus ?? this.requestStatus,
      pendingRequestId: pendingRequestId ?? this.pendingRequestId,
    );
  }
}

class ChatConnectionNotifier extends StateNotifier<ChatConnectionState> {
  final Ref _ref;
  StreamSubscription<ChatModel?>? _chatSubscription;
  StreamSubscription? _requestSubscription;
  
  ChatConnectionNotifier(this._ref) : super(ChatConnectionState());
  
  /// Send a connection request to another user
  Future<void> connectWithUser(UserModel otherUser) async {
    if (state.isConnecting) {
      debugPrint('Already connecting, ignoring request');
      return;
    }
    
    debugPrint('Connecting with user: ${otherUser.username}');
    
    state = state.copyWith(
      isConnecting: true,
      error: null,
      otherUser: otherUser,
      requestStatus: ConnectionRequestStatus.none,
    );
    
    try {
      final dbService = _ref.read(databaseServiceProvider);
      final currentProfile = await _ref.read(userProfileProvider.future);
      
      if (currentProfile == null) {
        debugPrint('Current user profile is null');
        state = state.copyWith(
          isConnecting: false,
          error: 'You must be logged in to connect',
        );
        return;
      }
      
      debugPrint('Current user: ${currentProfile.username}, connecting to: ${otherUser.username}');
      
      // Check if already connected to someone else
      if (currentProfile.currentChatId != null) {
        debugPrint('Already connected to a chat, disconnecting first');
        await disconnectFromChat();
      }
      
      // Check for existing requests
      debugPrint('Checking for existing requests between ${currentProfile.username} and ${otherUser.username}');
      final existingRequest = await dbService.checkExistingRequest(
        currentUsername: currentProfile.username,
        otherUsername: otherUser.username,
      );
      
      if (existingRequest != null) {
        debugPrint('Found existing request: ${existingRequest['id']} with status: ${existingRequest['status']}');
        
        // If there's an existing request from the other user to us, accept it
        if (existingRequest['toUsername'].toLowerCase() == currentProfile.username.toLowerCase()) {
          debugPrint('Existing request is from other user to us, accepting it');
          await acceptConnectionRequest(existingRequest['id']);
          return;
        } else {
          // If we already sent a request to this user
          debugPrint('We already sent a request to this user, updating state');
          state = state.copyWith(
            isConnecting: false,
            requestStatus: ConnectionRequestStatus.pending,
            pendingRequestId: existingRequest['id'],
          );
          
          // Listen for request status changes
          _listenToRequest(existingRequest['id']);
          return;
        }
      }
      
      // Send new connection request
      debugPrint('Sending new connection request from ${currentProfile.username} to ${otherUser.username}');
      final requestId = await dbService.sendConnectionRequest(
        fromUserId: currentProfile.uid,
        fromUsername: currentProfile.username,
        toUserId: otherUser.uid,
        toUsername: otherUser.username,
      );
      
      debugPrint('Connection request sent with ID: $requestId');
      
      // Listen for request status changes
      _listenToRequest(requestId);
      
      state = state.copyWith(
        isConnecting: false,
        isConnected: false,
        requestStatus: ConnectionRequestStatus.pending,
        pendingRequestId: requestId,
      );
    } catch (e, stackTrace) {
      debugPrint('Error connecting with user: $e');
      debugPrintStack(stackTrace: stackTrace);
      
      state = state.copyWith(
        isConnecting: false,
        isConnected: false,
        error: 'Failed to connect: $e',
        requestStatus: ConnectionRequestStatus.none,
      );
    }
  }
  
  /// Listen for changes to a connection request
  void _listenToRequest(String requestId) {
    debugPrint('Setting up listener for request ID: $requestId');
    
    // Cancel previous subscription if any
    _requestSubscription?.cancel();
    
    final dbService = _ref.read(databaseServiceProvider);
    _requestSubscription = dbService
        .streamConnectionRequest(requestId)
        .listen(
          (request) async {
            debugPrint('Received request update: ${request?.toString() ?? 'null'}');
            
            if (request == null) {
              // Request was deleted
              debugPrint('Request was deleted or not found');
              state = state.copyWith(
                requestStatus: ConnectionRequestStatus.canceled,
                pendingRequestId: null,
              );
              return;
            }
            
            final status = request['status'];
            debugPrint('Request status: $status');
            
            if (status == 'accepted') {
              // Request was accepted, create chat
              final chatId = request['chatId'];
              debugPrint('Request accepted with chatId: $chatId');
              
              // Trigger connection animation by updating state first
              state = state.copyWith(
                requestStatus: ConnectionRequestStatus.accepted,
                pendingRequestId: null,
              );
              
              // Then handle the chat connection
              if (chatId != null) {
                try {
                  final chat = await dbService.getChatById(chatId);
                  if (chat != null) {
                    debugPrint('Chat found, updating state');
                    
                    // Short delay to ensure animation is visible
                    await Future.delayed(const Duration(milliseconds: 500));
                    
                    state = state.copyWith(
                      isConnected: true,
                      currentChat: chat,
                      // Keep the accepted status
                      requestStatus: ConnectionRequestStatus.accepted,
                    );
                    
                    // Listen for chat updates
                    _listenToChat(chatId);
                    
                    debugPrint('Connection complete, ready for chat screen navigation');
                  } else {
                    debugPrint('Chat not found for ID: $chatId');
                    state = state.copyWith(
                      error: 'Chat not found',
                    );
                  }
                } catch (e, stackTrace) {
                  debugPrint('Error getting chat by ID: $e');
                  debugPrintStack(stackTrace: stackTrace);
                  state = state.copyWith(
                    error: 'Error getting chat: $e',
                  );
                }
              }
            } else if (status == 'rejected') {
              debugPrint('Request was rejected');
              state = state.copyWith(
                requestStatus: ConnectionRequestStatus.rejected,
                pendingRequestId: null,
              );
            } else if (status == 'canceled') {
              debugPrint('Request was canceled');
              state = state.copyWith(
                requestStatus: ConnectionRequestStatus.canceled,
                pendingRequestId: null,
              );
            } else {
              debugPrint('Unknown request status: $status');
            }
          },
          onError: (e, stackTrace) {
            debugPrint('Error listening to request: $e');
            debugPrintStack(stackTrace: stackTrace);
            state = state.copyWith(
              error: 'Connection error: $e',
            );
          },
        );
  }
  
  /// Accept a connection request
  Future<void> acceptConnectionRequest(String requestId) async {
    debugPrint('Accepting connection request with ID: $requestId');
    
    try {
      final dbService = _ref.read(databaseServiceProvider);
      final currentProfile = await _ref.read(userProfileProvider.future);
      
      if (currentProfile == null) {
        debugPrint('Current user profile is null, cannot accept request');
        return;
      }
      
      debugPrint('Current user: ${currentProfile.username} accepting request: $requestId');
      
      // Check if already connected to someone else
      if (currentProfile.currentChatId != null) {
        debugPrint('Already connected to chat: ${currentProfile.currentChatId}, disconnecting first');
        await disconnectFromChat();
      }
      
      // Accept the request and create a chat
      debugPrint('Calling database service to accept connection request');
      final chatId = await dbService.acceptConnectionRequest(requestId);
      
      if (chatId != null) {
        debugPrint('Connection accepted, chat created with ID: $chatId');
        
        final chat = await dbService.getChatById(chatId);
        final request = await dbService.getConnectionRequest(requestId);
        
        if (chat != null && request != null) {
          debugPrint('Got chat and request details');
          
          // Get the other user
          final otherUsername = request['fromUsername'].toLowerCase() == currentProfile.username.toLowerCase() 
              ? request['toUsername'] 
              : request['fromUsername'];
          
          debugPrint('Other username determined: $otherUsername');
          final otherUser = await _ref.read(authServiceProvider).getUserByUsername(otherUsername);
          
          if (otherUser != null) {
            debugPrint('Other user found: ${otherUser.username}, updating state');
            
            state = state.copyWith(
              isConnected: true,
              currentChat: chat,
              otherUser: otherUser,
              requestStatus: ConnectionRequestStatus.accepted,
              pendingRequestId: null,
            );
            
            // Listen for chat updates
            _listenToChat(chatId);
          } else {
            debugPrint('Could not find other user with username: $otherUsername');
            state = state.copyWith(
              error: 'Could not find the other user',
            );
          }
        } else {
          debugPrint('Failed to get chat or request details');
          state = state.copyWith(
            error: 'Failed to get chat details',
          );
        }
      } else {
        debugPrint('Failed to create chat when accepting request');
        state = state.copyWith(
          error: 'Failed to create chat',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error accepting connection request: $e');
      debugPrintStack(stackTrace: stackTrace);
      
      state = state.copyWith(
        error: 'Failed to accept request: $e',
      );
    }
  }
  
  /// Reject a connection request
  Future<void> rejectConnectionRequest(String requestId) async {
    debugPrint('Rejecting connection request with ID: $requestId');
    
    try {
      final dbService = _ref.read(databaseServiceProvider);
      
      // Get the request details for logging
      try {
        final request = await dbService.getConnectionRequest(requestId);
        if (request != null) {
          debugPrint('Rejecting request from ${request['fromUsername']} to ${request['toUsername']}');
        }
      } catch (e) {
        // Just for logging, don't interrupt the flow
        debugPrint('Could not get request details: $e');
      }
      
      // Reject the request
      await dbService.rejectConnectionRequest(requestId);
      debugPrint('Connection request rejected successfully');
      
      state = state.copyWith(
        requestStatus: ConnectionRequestStatus.rejected,
        pendingRequestId: null,
      );
    } catch (e, stackTrace) {
      debugPrint('Error rejecting connection request: $e');
      debugPrintStack(stackTrace: stackTrace);
      
      state = state.copyWith(
        error: 'Failed to reject request: $e',
      );
    }
  }
  
  /// Cancel a sent connection request
  Future<void> cancelConnectionRequest() async {
    if (state.pendingRequestId == null) return;
    
    try {
      final dbService = _ref.read(databaseServiceProvider);
      await dbService.cancelConnectionRequest(state.pendingRequestId!);
      
      state = state.copyWith(
        requestStatus: ConnectionRequestStatus.canceled,
        pendingRequestId: null,
        otherUser: null,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to cancel request: $e',
      );
    }
  }
  
  void _listenToChat(String chatId) {
    // Cancel previous subscription if any
    _chatSubscription?.cancel();
    
    final dbService = _ref.read(databaseServiceProvider);
    _chatSubscription = dbService
        .streamChatById(chatId)
        .listen(
          (chat) {
            state = state.copyWith(currentChat: chat);
          },
          onError: (e) {
            debugPrint('Error listening to chat: $e');
          },
        );
  }
  
  /// Load a chat by ID and update state
  Future<void> loadChatById(String chatId) async {
    debugPrint('Loading chat by ID: $chatId');
    
    try {
      final dbService = _ref.read(databaseServiceProvider);
      final chat = await dbService.getChatById(chatId);
      
      if (chat != null) {
        debugPrint('Chat loaded successfully');
        state = state.copyWith(
          isConnected: true,
          currentChat: chat,
        );
        
        // Start listening for updates
        _listenToChat(chatId);
      } else {
        debugPrint('Chat not found with ID: $chatId');
        state = state.copyWith(
          error: 'Chat not found',
        );
      }
    } catch (e) {
      debugPrint('Error loading chat: $e');
      state = state.copyWith(
        error: 'Failed to load chat: $e',
      );
    }
  }
  
  Future<void> disconnectFromChat() async {
    if (state.currentChat == null) return;
    
    try {
      final dbService = _ref.read(databaseServiceProvider);
      final currentProfile = await _ref.read(userProfileProvider.future);
      
      if (currentProfile == null || state.currentChat == null) return;
      
      await dbService.disconnectFromChat(
        currentProfile.uid,
        state.currentChat!.id,
      );
      
      // Cancel subscriptions
      await _chatSubscription?.cancel();
      _chatSubscription = null;
      
      await _requestSubscription?.cancel();
      _requestSubscription = null;
      
      state = ChatConnectionState();
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to disconnect: $e',
      );
    }
  }
  
  Future<void> sendMessage(String text) async {
    if (state.currentChat == null || text.isEmpty) return;
    
    try {
      final dbService = _ref.read(databaseServiceProvider);
      final username = await _ref.read(currentUsernameProvider.future);
      
      if (username == null) return;
      
      await dbService.sendMessage(
        chatId: state.currentChat!.id,
        text: text,
        senderUsername: username,
      );
    } catch (e) {
      debugPrint('Error sending message: $e');
      // We don't update state here as we don't want to disrupt the UI
    }
  }
  
  Future<void> updateTypingStatus(bool isTyping) async {
    if (state.currentChat == null) return;
    
    try {
      final dbService = _ref.read(databaseServiceProvider);
      final username = await _ref.read(currentUsernameProvider.future);
      
      if (username == null) return;
      
      await dbService.updateTypingStatus(
        state.currentChat!.id,
        username,
        isTyping,
      );
    } catch (e) {
      debugPrint('Error updating typing status: $e');
    }
  }
  
  @override
  void dispose() {
    _chatSubscription?.cancel();
    _requestSubscription?.cancel();
    super.dispose();
  }
}

/// Provider for chat connection state
final chatConnectionProvider = StateNotifierProvider<ChatConnectionNotifier, ChatConnectionState>((ref) {
  return ChatConnectionNotifier(ref);
});
