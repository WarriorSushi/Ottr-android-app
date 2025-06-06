// Package imports
import 'package:cloud_firestore/cloud_firestore.dart';

/// Chat model class representing a conversation between two users
class ChatModel {
  final String id;
  final List<String> participants;
  final List<String> participantIds;
  final DateTime createdAt;
  String lastMessage;
  DateTime lastMessageTime;
  String lastMessageSender;
  bool isActive;
  bool user1Typing;
  bool user2Typing;

  ChatModel({
    required this.id,
    required this.participants,
    required this.participantIds,
    required this.createdAt,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.lastMessageSender,
    this.isActive = true,
    this.user1Typing = false,
    this.user2Typing = false,
  });

  /// Create a ChatModel from Firestore document
  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ChatModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      participantIds: List<String>.from(data['participantIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp).toDate(),
      lastMessageSender: data['lastMessageSender'] ?? '',
      isActive: data['isActive'] ?? true,
      user1Typing: data['user1Typing'] ?? false,
      user2Typing: data['user2Typing'] ?? false,
    );
  }

  /// Convert ChatModel to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'participantIds': participantIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastMessageSender': lastMessageSender,
      'isActive': isActive,
      'user1Typing': user1Typing,
      'user2Typing': user2Typing,
    };
  }

  /// Check if a user is a participant in this chat
  bool hasParticipant(String username) {
    return participants.contains(username.toLowerCase());
  }

  /// Check if a user is typing in this chat
  bool isUserTyping(String username) {
    final index = participants.indexOf(username.toLowerCase());
    if (index == 0) {
      return user1Typing;
    } else if (index == 1) {
      return user2Typing;
    }
    return false;
  }

  /// Update typing status for a user
  void updateTypingStatus(String username, bool isTyping) {
    final index = participants.indexOf(username.toLowerCase());
    if (index == 0) {
      user1Typing = isTyping;
    } else if (index == 1) {
      user2Typing = isTyping;
    }
  }

  /// Create a copy of ChatModel with updated fields
  ChatModel copyWith({
    String? id,
    List<String>? participants,
    List<String>? participantIds,
    DateTime? createdAt,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSender,
    bool? isActive,
    bool? user1Typing,
    bool? user2Typing,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      participantIds: participantIds ?? this.participantIds,
      createdAt: createdAt ?? this.createdAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSender: lastMessageSender ?? this.lastMessageSender,
      isActive: isActive ?? this.isActive,
      user1Typing: user1Typing ?? this.user1Typing,
      user2Typing: user2Typing ?? this.user2Typing,
    );
  }
}
