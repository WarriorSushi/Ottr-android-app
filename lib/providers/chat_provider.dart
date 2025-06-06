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

/// State notifier for managing chat connection
class ChatConnectionState {
  final bool isConnecting;
  final bool isConnected;
  final ChatModel? currentChat;
  final String? error;
  final UserModel? otherUser;
  
  ChatConnectionState({
    this.isConnecting = false,
    this.isConnected = false,
    this.currentChat,
    this.error,
    this.otherUser,
  });
  
  ChatConnectionState copyWith({
    bool? isConnecting,
    bool? isConnected,
    ChatModel? currentChat,
    String? error,
    UserModel? otherUser,
  }) {
    return ChatConnectionState(
      isConnecting: isConnecting ?? this.isConnecting,
      isConnected: isConnected ?? this.isConnected,
      currentChat: currentChat ?? this.currentChat,
      error: error,
      otherUser: otherUser ?? this.otherUser,
    );
  }
}

class ChatConnectionNotifier extends StateNotifier<ChatConnectionState> {
  final Ref _ref;
  StreamSubscription<ChatModel?>? _chatSubscription;
  
  ChatConnectionNotifier(this._ref) : super(ChatConnectionState());
  
  Future<void> connectWithUser(UserModel otherUser) async {
    if (state.isConnecting) return;
    
    state = state.copyWith(
      isConnecting: true,
      error: null,
      otherUser: otherUser,
    );
    
    try {
      final dbService = _ref.read(databaseServiceProvider);
      final currentProfile = await _ref.read(userProfileProvider.future);
      
      if (currentProfile == null) {
        state = state.copyWith(
          isConnecting: false,
          error: 'You must be logged in to connect',
        );
        return;
      }
      
      // Check if already connected to someone else
      if (currentProfile.currentChatId != null) {
        await disconnectFromChat();
      }
      
      // Create or get chat
      final chat = await dbService.createOrGetChat(
        currentUsername: currentProfile.username,
        otherUsername: otherUser.username,
        currentUserId: currentProfile.uid,
        otherUserId: otherUser.uid,
      );
      
      state = state.copyWith(
        isConnecting: false,
        isConnected: true,
        currentChat: chat,
        error: null,
      );
      
      // Listen for chat updates
      _listenToChat(chat.id);
    } catch (e) {
      state = state.copyWith(
        isConnecting: false,
        isConnected: false,
        error: 'Failed to connect: $e',
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
      
      // Cancel subscription
      await _chatSubscription?.cancel();
      _chatSubscription = null;
      
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
    super.dispose();
  }
}

/// Provider for chat connection state
final chatConnectionProvider = StateNotifierProvider<ChatConnectionNotifier, ChatConnectionState>((ref) {
  return ChatConnectionNotifier(ref);
});
