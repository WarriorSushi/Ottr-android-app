// Dart imports
import 'dart:async';

// Flutter imports
import 'package:flutter/material.dart';

// Package imports
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports
import 'package:ottr/models/chat_model.dart';
import 'package:ottr/models/message_model.dart';
import 'package:ottr/providers/providers.dart';
import 'package:ottr/utils/constants.dart';
import 'package:ottr/utils/extensions.dart';
import 'package:ottr/widgets/message_bubble.dart';

/// Chat screen for messaging with another user
class ChatScreen extends ConsumerStatefulWidget {
  static const String routeName = '/chat';
  
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTypingChanged);
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTypingChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    _setTypingStatus(false);
    super.dispose();
  }

  /// Handle typing indicator with debounce
  void _onTypingChanged() {
    final isCurrentlyTyping = _messageController.text.trim().isNotEmpty;
    
    // Only update if the typing state changed
    if (isCurrentlyTyping != _isTyping) {
      _isTyping = isCurrentlyTyping;
      _setTypingStatus(isCurrentlyTyping);
    }
    
    // Reset the timer
    _typingTimer?.cancel();
    
    // Set a new timer if typing
    if (isCurrentlyTyping) {
      _typingTimer = Timer(const Duration(seconds: 3), () {
        _setTypingStatus(false);
        _isTyping = false;
      });
    }
  }

  /// Set typing status in Firestore
  void _setTypingStatus(bool isTyping) {
    try {
      final chatState = ref.read(chatConnectionProvider);
      if (chatState.currentChat != null) {
        ref.read(chatConnectionProvider.notifier).updateTypingStatus(isTyping);
      }
    } catch (e) {
      debugPrint('Error updating typing status: $e');
    }
  }

  /// Send a message
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    _messageController.clear();
    
    try {
      await ref.read(chatConnectionProvider.notifier).sendMessage(text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: ${e.toString()}'),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  /// Get the other person's username
  String _getOtherUsername(ChatModel chat, String currentUsername) {
    final participants = chat.participants;
    return participants.firstWhere(
      (username) => username.toLowerCase() != currentUsername.toLowerCase(),
      orElse: () => 'Unknown User',
    );
  }

  @override
  Widget build(BuildContext context) {
    // Current chat connection state
    final chatConnectionState = ref.watch(chatConnectionProvider);
    final currentChat = chatConnectionState.currentChat;
    final username = ref.watch(currentUsernameProvider).value;
    
    // If no current chat, go back to home
    if (currentChat == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop();
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              username != null 
                  ? _getOtherUsername(currentChat, username) 
                  : 'Chat',
            ),
            if (_isOtherUserTyping(currentChat, username))
              const Text(
                'Typing...',
                style: TextStyle(fontSize: 12),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _buildMessageList(currentChat.id, username),
          ),
          
          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  /// Build message list
  Widget _buildMessageList(String chatId, String? currentUsername) {
    return StreamBuilder<List<MessageModel>>(
      stream: ref.watch(chatMessagesProvider(chatId)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final messages = snapshot.data ?? [];
        
        if (messages.isEmpty) {
          return const Center(child: Text('No messages yet. Start the conversation!'));
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true,  // Display latest messages at the bottom
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isCurrentUser = currentUsername != null && 
                message.senderUsername.toLowerCase() == currentUsername.toLowerCase();
            
            return MessageBubble(
              message: message,
              isCurrentUser: isCurrentUser,
            );
          },
        );
      },
    );
  }

  /// Build message input box
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Message input field
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: surfaceColor,
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            
            // Send button
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Check if other user is typing
  bool _isOtherUserTyping(ChatModel chat, String? currentUsername) {
    if (currentUsername == null) return false;
    
    final isUser1 = chat.participants.isNotEmpty && 
        chat.participants[0].toLowerCase() == currentUsername.toLowerCase();
    
    return isUser1 ? chat.user2Typing : chat.user1Typing;
  }
}
