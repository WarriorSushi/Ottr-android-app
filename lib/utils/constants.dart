library ottr.constants;

/// Application constants
import 'package:flutter/material.dart';

// App information
const String appName = 'Ottr';
const String appVersion = '1.0.0';

// Firebase collection names
const String usersCollection = 'users';
const String chatsCollection = 'chats';
const String messagesSubcollection = 'messages';

// Shared preferences keys
const String prefUserId = 'user_id';
const String prefUsername = 'username';
const String prefCurrentChatId = 'current_chat_id';

// Username constraints
const int minUsernameLength = 3;
const int maxUsernameLength = 20;
const String usernamePattern = r'^[a-zA-Z0-9_]+$';

// Chat constraints
const int maxMessageLength = 500;
const int maxMessagesPerFetch = 50;

// Animation durations
const Duration splashDuration = Duration(seconds: 2);
const Duration shortAnimationDuration = Duration(milliseconds: 150);
const Duration defaultAnimationDuration = Duration(milliseconds: 300);

// Colors - as required in design rules
const Color primaryColor = Color(0xFF2196F3);
const Color primaryVariant = Color(0xFF1976D2);
const Color secondaryColor = Color(0xFF4CAF50);
const Color errorColor = Color(0xFFF44336);
const Color backgroundColor = Color(0xFFFFFFFF);
const Color surfaceColor = Color(0xFFF5F5F5);
const Color messageSentColor = Color(0xFFE3F2FD);
const Color messageReceivedColor = Color(0xFFF5F5F5);
