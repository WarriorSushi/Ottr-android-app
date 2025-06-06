// Package imports
import 'package:cloud_firestore/cloud_firestore.dart';

/// Message status enum
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
}

/// Message type enum
enum MessageType {
  text,
  // Future types: image, voice
}

/// Message model class representing a single message in a chat
class MessageModel {
  final String id;
  final String text;
  final String senderUsername;
  final DateTime timestamp;
  final MessageStatus status;
  final MessageType type;

  MessageModel({
    required this.id,
    required this.text,
    required this.senderUsername,
    required this.timestamp,
    this.status = MessageStatus.sending,
    this.type = MessageType.text,
  });

  /// Create a MessageModel from Firestore document
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return MessageModel(
      id: doc.id,
      text: data['text'] ?? '',
      senderUsername: data['senderUsername'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      status: _stringToMessageStatus(data['status'] ?? 'sent'),
      type: _stringToMessageType(data['type'] ?? 'text'),
    );
  }

  /// Convert MessageModel to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'senderUsername': senderUsername,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': _messageStatusToString(status),
      'type': _messageTypeToString(type),
    };
  }

  /// Create a copy of MessageModel with updated fields
  MessageModel copyWith({
    String? id,
    String? text,
    String? senderUsername,
    DateTime? timestamp,
    MessageStatus? status,
    MessageType? type,
  }) {
    return MessageModel(
      id: id ?? this.id,
      text: text ?? this.text,
      senderUsername: senderUsername ?? this.senderUsername,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      type: type ?? this.type,
    );
  }

  /// Convert MessageStatus enum to string
  static String _messageStatusToString(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return 'sending';
      case MessageStatus.sent:
        return 'sent';
      case MessageStatus.delivered:
        return 'delivered';
      case MessageStatus.read:
        return 'read';
    }
  }

  /// Convert string to MessageStatus enum
  static MessageStatus _stringToMessageStatus(String status) {
    switch (status) {
      case 'sending':
        return MessageStatus.sending;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      // If not matching any case, default to sent
      case _:
        return MessageStatus.sent;
    }
  }

  /// Convert MessageType enum to string
  static String _messageTypeToString(MessageType type) {
    switch (type) {
      case MessageType.text:
        return 'text';
    }
  }

  /// Convert string to MessageType enum
  static MessageType _stringToMessageType(String type) {
    switch (type) {
      case 'text':
        return MessageType.text;
      default:
        return MessageType.text;
    }
  }
}
