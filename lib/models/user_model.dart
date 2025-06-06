// Package imports
import 'package:cloud_firestore/cloud_firestore.dart';

/// User model class representing a user in the application
class UserModel {
  final String uid;
  final String username;
  final String displayName;
  final String email;
  final String photoUrl;
  String? fcmToken;
  final DateTime createdAt;
  DateTime lastSeen;
  bool isOnline;
  String? currentChatId;

  UserModel({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    this.fcmToken,
    required this.createdAt,
    required this.lastSeen,
    this.isOnline = false,
    this.currentChatId,
  });

  /// Create a UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      uid: data['uid'] ?? '',
      username: data['username'] ?? '',
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      fcmToken: data['fcmToken'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastSeen: (data['lastSeen'] as Timestamp).toDate(),
      isOnline: data['isOnline'] ?? false,
      currentChatId: data['currentChatId'],
    );
  }

  /// Convert UserModel to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'username': username,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastSeen': Timestamp.fromDate(lastSeen),
      'isOnline': isOnline,
      'currentChatId': currentChatId,
    };
  }

  /// Create a copy of UserModel with updated fields
  UserModel copyWith({
    String? uid,
    String? username,
    String? displayName,
    String? email,
    String? photoUrl,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? lastSeen,
    bool? isOnline,
    String? currentChatId,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      currentChatId: currentChatId ?? this.currentChatId,
    );
  }
}
