// Flutter imports
import 'package:flutter/foundation.dart';

// Package imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports
import 'package:ottr/models/chat_model.dart';
import 'package:ottr/models/message_model.dart';
import 'package:ottr/models/user_model.dart';
import 'package:ottr/utils/constants.dart';

/// Service responsible for database operations
class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create or get existing chat between two users
  Future<ChatModel> createOrGetChat({
    required String currentUsername,
    required String otherUsername,
    required String currentUserId,
    required String otherUserId,
  }) async {
    try {
      // Create chat ID by sorting usernames alphabetically
      final List<String> usernames = [
        currentUsername.toLowerCase(),
        otherUsername.toLowerCase()
      ];
      usernames.sort();
      final chatId = usernames.join('_');

      // Check if chat already exists
      final chatDoc = await _firestore
          .collection(CHATS_COLLECTION)
          .doc(chatId)
          .get();

      if (chatDoc.exists) {
        // Update isActive to true if it's false
        if (!(chatDoc.data()?['isActive'] ?? true)) {
          await chatDoc.reference.update({'isActive': true});
        }
        
        final chatModel = ChatModel.fromFirestore(chatDoc);
        await _updateCurrentChat(currentUserId, chatId);
        return chatModel;
      }

      // Create new chat
      final now = DateTime.now();
      final chatModel = ChatModel(
        id: chatId,
        participants: usernames,
        participantIds: [currentUserId, otherUserId],
        createdAt: now,
        lastMessage: '',
        lastMessageTime: now,
        lastMessageSender: '',
        isActive: true,
      );

      // Save to Firestore
      await _firestore
          .collection(CHATS_COLLECTION)
          .doc(chatId)
          .set(chatModel.toFirestore());
      
      // Update current chat ID for both users
      await _updateCurrentChat(currentUserId, chatId);
      
      return chatModel;
    } catch (e, stackTrace) {
      debugPrint('Error creating/getting chat: $e');
      debugPrintStack(stackTrace: stackTrace);
      throw 'Failed to create chat. Please try again.';
    }
  }

  /// Update current chat ID for a user
  Future<void> _updateCurrentChat(String userId, String chatId) async {
    try {
      // Update in Firestore
      await _firestore
          .collection(USERS_COLLECTION)
          .doc(userId)
          .update({'currentChatId': chatId});
      
      // Save to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(PREF_CURRENT_CHAT_ID, chatId);
    } catch (e, stackTrace) {
      debugPrint('Error updating current chat: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Get current chat ID from shared preferences
  Future<String?> getCurrentChatId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(PREF_CURRENT_CHAT_ID);
    } catch (e) {
      debugPrint('Error getting current chat ID: $e');
      return null;
    }
  }

  /// Send a message in a chat
  Future<MessageModel> sendMessage({
    required String chatId,
    required String text,
    required String senderUsername,
  }) async {
    try {
      final now = DateTime.now();
      
      // Create message
      final messageRef = _firestore
          .collection(CHATS_COLLECTION)
          .doc(chatId)
          .collection(MESSAGES_SUBCOLLECTION)
          .doc();
      
      final messageModel = MessageModel(
        id: messageRef.id,
        text: text,
        senderUsername: senderUsername.toLowerCase(),
        timestamp: now,
        status: MessageStatus.sending,
      );
      
      // Save message
      await messageRef.set(messageModel.toFirestore());
      
      // Update chat with last message info
      await _firestore
          .collection(CHATS_COLLECTION)
          .doc(chatId)
          .update({
            'lastMessage': text,
            'lastMessageTime': Timestamp.fromDate(now),
            'lastMessageSender': senderUsername.toLowerCase(),
          });
      
      // Update message status to sent
      final updatedMessage = messageModel.copyWith(status: MessageStatus.sent);
      await messageRef.update({
        'status': 'sent',
      });
      
      return updatedMessage;
    } catch (e, stackTrace) {
      debugPrint('Error sending message: $e');
      debugPrintStack(stackTrace: stackTrace);
      throw 'Failed to send message. Please try again.';
    }
  }

  /// Get chat by ID
  Future<ChatModel?> getChatById(String chatId) async {
    try {
      final chatDoc = await _firestore
          .collection(CHATS_COLLECTION)
          .doc(chatId)
          .get();
      
      if (chatDoc.exists) {
        return ChatModel.fromFirestore(chatDoc);
      }
      
      return null;
    } catch (e, stackTrace) {
      debugPrint('Error getting chat by ID: $e');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  /// Get all chats for a user
  Stream<List<ChatModel>> getUserChats(String username) {
    return _firestore
        .collection(CHATS_COLLECTION)
        .where('participants', arrayContains: username.toLowerCase())
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Get messages for a chat
  Stream<List<MessageModel>> getChatMessages(String chatId) {
    return _firestore
        .collection(CHATS_COLLECTION)
        .doc(chatId)
        .collection(MESSAGES_SUBCOLLECTION)
        .orderBy('timestamp', descending: true)
        .limit(MAX_MESSAGES_PER_FETCH)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MessageModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Disconnect from current chat
  Future<void> disconnectFromChat(String userId, String chatId) async {
    try {
      // Update current chat ID to null
      await _firestore
          .collection(USERS_COLLECTION)
          .doc(userId)
          .update({'currentChatId': null});
      
      // Set chat as inactive
      await _firestore
          .collection(CHATS_COLLECTION)
          .doc(chatId)
          .update({'isActive': false});
      
      // Clear from shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(PREF_CURRENT_CHAT_ID);
    } catch (e, stackTrace) {
      debugPrint('Error disconnecting from chat: $e');
      debugPrintStack(stackTrace: stackTrace);
      throw 'Failed to disconnect from chat. Please try again.';
    }
  }

  /// Update typing status
  Future<void> updateTypingStatus(String chatId, String username, bool isTyping) async {
    try {
      final chat = await getChatById(chatId);
      
      if (chat != null) {
        final index = chat.participants.indexOf(username.toLowerCase());
        
        if (index == 0) {
          await _firestore
              .collection(CHATS_COLLECTION)
              .doc(chatId)
              .update({'user1Typing': isTyping});
        } else if (index == 1) {
          await _firestore
              .collection(CHATS_COLLECTION)
              .doc(chatId)
              .update({'user2Typing': isTyping});
        }
      }
    } catch (e) {
      debugPrint('Error updating typing status: $e');
    }
  }
}
