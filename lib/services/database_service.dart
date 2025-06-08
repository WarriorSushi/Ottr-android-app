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
  
  // Collection names
  static const String _connectionRequestsCollection = 'connectionRequests';

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
          .collection(chatsCollection)
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
          .collection(chatsCollection)
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
          .collection(usersCollection)
          .doc(userId)
          .update({'currentChatId': chatId});
      
      // Save to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefCurrentChatId, chatId);
    } catch (e, stackTrace) {
      debugPrint('Error updating current chat: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Get current chat ID from shared preferences
  Future<String?> getCurrentChatId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(prefCurrentChatId);
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
          .collection(chatsCollection)
          .doc(chatId)
          .collection(messagesSubcollection)
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
          .collection(chatsCollection)
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
          .collection(chatsCollection)
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
  
  /// Stream chat by ID - get real-time updates
  Stream<ChatModel?> streamChatById(String chatId) {
    return _firestore
        .collection(chatsCollection)
        .doc(chatId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            return ChatModel.fromFirestore(snapshot);
          }
          return null;
        });
  }

  /// Get all chats for a user
  Stream<List<ChatModel>> getUserChats(String username) {
    return _firestore
        .collection(chatsCollection)
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
        .collection(chatsCollection)
        .doc(chatId)
        .collection(messagesSubcollection)
        .orderBy('timestamp', descending: true)
        .limit(maxMessagesPerFetch)
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
          .collection(usersCollection)
          .doc(userId)
          .update({'currentChatId': null});
      
      // Set chat as inactive
      await _firestore
          .collection(chatsCollection)
          .doc(chatId)
          .update({'isActive': false});
      
      // Clear from shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(prefCurrentChatId);
    } catch (e, stackTrace) {
      debugPrint('Error disconnecting from chat: $e');
      debugPrintStack(stackTrace: stackTrace);
      throw 'Failed to disconnect from chat. Please try again.';
    }
  }
  
  /// Check for existing connection requests between two users
  Future<Map<String, dynamic>?> checkExistingRequest({
    required String currentUsername,
    required String otherUsername,
  }) async {
    try {
      // Check for requests from current user to other user
      final sentQuery = await _firestore
          .collection(_connectionRequestsCollection)
          .where('fromUsername', isEqualTo: currentUsername.toLowerCase())
          .where('toUsername', isEqualTo: otherUsername.toLowerCase())
          .where('status', isEqualTo: 'pending')
          .get();
      
      if (sentQuery.docs.isNotEmpty) {
        return {
          'id': sentQuery.docs.first.id,
          ...sentQuery.docs.first.data(),
        };
      }
      
      // Check for requests from other user to current user
      final receivedQuery = await _firestore
          .collection(_connectionRequestsCollection)
          .where('fromUsername', isEqualTo: otherUsername.toLowerCase())
          .where('toUsername', isEqualTo: currentUsername.toLowerCase())
          .where('status', isEqualTo: 'pending')
          .get();
      
      if (receivedQuery.docs.isNotEmpty) {
        return {
          'id': receivedQuery.docs.first.id,
          ...receivedQuery.docs.first.data(),
        };
      }
      
      return null;
    } catch (e, stackTrace) {
      debugPrint('Error checking existing requests: $e');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Send a connection request to another user
  Future<String> sendConnectionRequest({
    required String fromUserId,
    required String fromUsername,
    required String toUserId,
    required String toUsername,
  }) async {
    try {
      final requestRef = _firestore.collection(_connectionRequestsCollection).doc();
      
      final requestData = {
        'fromUserId': fromUserId,
        'fromUsername': fromUsername.toLowerCase(),
        'toUserId': toUserId,
        'toUsername': toUsername.toLowerCase(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'chatId': null,
      };
      
      await requestRef.set(requestData);
      
      return requestRef.id;
    } catch (e, stackTrace) {
      debugPrint('Error sending connection request: $e');
      debugPrintStack(stackTrace: stackTrace);
      throw 'Failed to send connection request. Please try again.';
    }
  }
  
  /// Stream incoming connection requests for a user
  Stream<List<Map<String, dynamic>>> streamIncomingRequests(String username) {
    try {
      debugPrint('Starting to stream incoming requests for username: ${username.toLowerCase()}');
      
      return _firestore
          .collection(_connectionRequestsCollection)
          .where('toUsername', isEqualTo: username.toLowerCase())
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            final requests = snapshot.docs.map((doc) {
              debugPrint('Incoming request found: ${doc.id} from ${doc.data()['fromUsername']}');
              return {
                'id': doc.id,
                ...doc.data(),
              };
            }).toList();
            
            debugPrint('Total incoming requests: ${requests.length}');
            return requests;
          });
    } catch (e, stackTrace) {
      debugPrint('Error streaming incoming requests: $e');
      debugPrintStack(stackTrace: stackTrace);
      return Stream.value([]);
    }
  }
  
  /// Reject a connection request
  Future<void> rejectConnectionRequest(String requestId) async {
    try {
      await _firestore
          .collection(_connectionRequestsCollection)
          .doc(requestId)
          .update({
            'status': 'rejected',
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e, stackTrace) {
      debugPrint('Error rejecting connection request: $e');
      debugPrintStack(stackTrace: stackTrace);
      throw 'Failed to reject connection request. Please try again.';
    }
  }
  
  /// Get a connection request by ID
  Future<Map<String, dynamic>?> getConnectionRequest(String requestId) async {
    try {
      final doc = await _firestore
          .collection(_connectionRequestsCollection)
          .doc(requestId)
          .get();
      
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data()!,
        };
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting connection request: $e');
      return null;
    }
  }
  
  /// Stream a connection request for real-time updates
  Stream<Map<String, dynamic>?> streamConnectionRequest(String requestId) {
    return _firestore
        .collection(_connectionRequestsCollection)
        .doc(requestId)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return {
              'id': doc.id,
              ...doc.data()!,
            };
          }
          return null;
        });
  }
  
  /// Accept a connection request and create a chat
  Future<String?> acceptConnectionRequest(String requestId) async {
    try {
      debugPrint('Starting to accept connection request: $requestId');
      
      // Get the request
      final request = await getConnectionRequest(requestId);
      
      if (request == null) {
        debugPrint('Connection request not found: $requestId');
        throw 'Connection request not found';
      }
      
      debugPrint('Found connection request: ${request.toString()}');
      
      // Create chat between users
      final fromUsername = request['fromUsername'];
      final toUsername = request['toUsername'];
      final fromUserId = request['fromUserId'];
      final toUserId = request['toUserId'];
      
      debugPrint('Creating chat between $fromUsername and $toUsername');
      
      // Create chat ID by sorting usernames alphabetically
      final List<String> usernames = [fromUsername, toUsername];
      usernames.sort();
      final chatId = usernames.join('_');
      
      // Check if chat already exists
      final existingChat = await _firestore
          .collection(chatsCollection)
          .doc(chatId)
          .get();
      
      if (existingChat.exists) {
        debugPrint('Chat already exists with ID: $chatId');
      } else {
        // Create the chat
        debugPrint('Creating new chat with ID: $chatId');
        final now = DateTime.now();
        final chatModel = ChatModel(
          id: chatId,
          participants: usernames,
          participantIds: [fromUserId, toUserId],
          createdAt: now,
          lastMessage: 'Connection established',
          lastMessageTime: now,
          lastMessageSender: 'system',
          isActive: true,
        );
        
        // Save to Firestore
        await _firestore
            .collection(chatsCollection)
            .doc(chatId)
            .set(chatModel.toFirestore());
      }
      
      // Update current chat ID for both users
      debugPrint('Updating current chat for both users');
      await _updateCurrentChat(fromUserId, chatId);
      await _updateCurrentChat(toUserId, chatId);
      
      // Update request status
      debugPrint('Updating request status to accepted');
      await _firestore
          .collection(_connectionRequestsCollection)
          .doc(requestId)
          .update({
            'status': 'accepted',
            'chatId': chatId,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      debugPrint('Connection request accepted successfully, chat ID: $chatId');
      return chatId;
    } catch (e, stackTrace) {
      debugPrint('Error accepting connection request: $e');
      debugPrintStack(stackTrace: stackTrace);
      throw 'Failed to accept connection request. Please try again.';
    }
  }
  
  /// Cancel a connection request
  Future<void> cancelConnectionRequest(String requestId) async {
    try {
      await _firestore
          .collection(_connectionRequestsCollection)
          .doc(requestId)
          .update({
            'status': 'canceled',
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e, stackTrace) {
      debugPrint('Error canceling connection request: $e');
      debugPrintStack(stackTrace: stackTrace);
      throw 'Failed to cancel connection request. Please try again.';
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
              .collection(chatsCollection)
              .doc(chatId)
              .update({'user1Typing': isTyping});
        } else if (index == 1) {
          await _firestore
              .collection(chatsCollection)
              .doc(chatId)
              .update({'user2Typing': isTyping});
        }
      }
    } catch (e) {
      debugPrint('Error updating typing status: $e');
    }
  }
}
