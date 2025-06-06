/// Application constants

// App information
const String APP_NAME = 'Ottr';
const String APP_VERSION = '1.0.0';

// Firebase collection names
const String USERS_COLLECTION = 'users';
const String CHATS_COLLECTION = 'chats';
const String MESSAGES_SUBCOLLECTION = 'messages';

// Shared preferences keys
const String PREF_USER_ID = 'user_id';
const String PREF_USERNAME = 'username';
const String PREF_CURRENT_CHAT_ID = 'current_chat_id';

// Username constraints
const int MIN_USERNAME_LENGTH = 3;
const int MAX_USERNAME_LENGTH = 20;
const String USERNAME_PATTERN = r'^[a-zA-Z0-9_]+$';

// Chat constraints
const int MAX_MESSAGE_LENGTH = 1000;
const int MAX_MESSAGES_PER_FETCH = 50;

// Animation durations
const Duration SPLASH_DURATION = Duration(seconds: 2);
const Duration SHORT_ANIMATION_DURATION = Duration(milliseconds: 200);
const Duration DEFAULT_ANIMATION_DURATION = Duration(milliseconds: 300);
