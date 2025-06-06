# Ottr - Minimalist One-to-One Messenger

## Overview
Ottr is a unique messaging app where users connect through usernames and can only maintain one active conversation at a time. Built with Flutter for Android, focusing on simplicity and meaningful connections.

## Key Features
- 🔐 Google Sign-in authentication
- 👤 Unique username system
- 💬 Real-time messaging
- 📱 Push notifications
- 🚀 Minimal and fast

## Tech Stack
- **Frontend**: Flutter (Dart)
- **State Management**: Riverpod 2.0
- **Backend**: Firebase
  - Authentication (Google Sign-in)
  - Cloud Firestore (Database)
  - Cloud Messaging (Push Notifications)
- **Architecture**: Feature-first organization

## Prerequisites
- Flutter SDK (3.0 or higher)
- Android Studio / VS Code with Flutter extensions
- Firebase account
- Android device/emulator (API 21+)

## Project Setup

### 1. Clone and Initialize
```bash
# Create new Flutter project
flutter create ottr --org com.yourcompany

# Navigate to project
cd ottr

# Open in your IDE
code . # for VS Code
# or
studio . # for Android Studio
```

### 2. Add Dependencies
Update `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^2.27.0
  firebase_auth: ^4.17.0
  cloud_firestore: ^4.15.0
  firebase_messaging: ^14.7.0
  
  # Google Sign In
  google_sign_in: ^6.2.0
  
  # State Management
  flutter_riverpod: ^2.5.0
  
  # Utilities
  shared_preferences: ^2.2.2
  intl: ^0.19.0
```

### 3. Firebase Setup
1. Create project at https://console.firebase.google.com
2. Add Android app with package name: `com.yourcompany.ottr`
3. Download `google-services.json` to `android/app/`
4. Enable:
   - Authentication (Google provider)
   - Cloud Firestore
   - Cloud Messaging

### 4. Android Configuration

#### android/build.gradle
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

#### android/app/build.gradle
```gradle
apply plugin: 'com.google.gms.google-services'

android {
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "com.yourcompany.ottr"
        minSdkVersion 21
        targetSdkVersion 34
        multiDexEnabled true
    }
}
```

#### android/app/src/main/AndroidManifest.xml
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.VIBRATE" />

<application>
    <!-- FCM Notification Icon -->
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_icon"
        android:resource="@drawable/ic_notification" />
    
    <!-- FCM Notification Channel -->
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_channel_id"
        android:value="ottr_messages" />
</application>
```

## Project Structure
```
lib/
├── main.dart                    # App entry point
├── app.dart                     # MaterialApp configuration
├── screens/                     # UI screens
│   ├── splash_screen.dart       # Initial loading screen
│   ├── auth_screen.dart         # Google sign-in
│   ├── username_screen.dart     # Username selection
│   ├── home_screen.dart         # Main screen with connections
│   └── chat_screen.dart         # Messaging interface
├── widgets/                     # Reusable UI components
│   ├── message_bubble.dart      # Chat message widget
│   ├── loading_button.dart      # Button with loading state
│   └── username_input.dart      # Username input field
├── services/                    # Business logic layer
│   ├── auth_service.dart        # Authentication handling
│   ├── database_service.dart    # Firestore operations
│   └── notification_service.dart # FCM handling
├── models/                      # Data models
│   ├── user_model.dart          # User data structure
│   ├── chat_model.dart          # Chat data structure
│   └── message_model.dart       # Message data structure
├── providers/                   # Riverpod state management
│   ├── auth_provider.dart       # Auth state
│   ├── user_provider.dart       # User data state
│   ├── chat_provider.dart       # Chat state
│   └── providers.dart           # Provider exports
├── utils/                       # Utility functions
│   ├── constants.dart           # App constants
│   ├── validators.dart          # Input validation
│   └── extensions.dart          # Dart extensions
└── config/                      # App configuration
    ├── theme.dart               # Material theme
    └── routes.dart              # Route definitions
```

## Database Schema

### Firestore Collections

#### users
```javascript
users/{userId} {
  uid: string,              // Firebase Auth UID
  username: string,         // Unique, lowercase
  displayName: string,      // Shown in chat
  email: string,
  photoUrl: string,
  fcmToken: string,         // For push notifications
  createdAt: timestamp,
  lastSeen: timestamp,
  isOnline: boolean,
  currentChatId: string?    // Active chat reference
}
```

#### chats
```javascript
chats/{chatId} {
  id: string,               // username1_username2 (sorted)
  participants: string[],   // [username1, username2]
  participantIds: string[], // [userId1, userId2]
  createdAt: timestamp,
  lastMessage: string,
  lastMessageTime: timestamp,
  lastMessageSender: string,
  isActive: boolean,
  user1Typing: boolean,
  user2Typing: boolean
}
```

#### messages
```javascript
chats/{chatId}/messages/{messageId} {
  id: string,
  text: string,
  senderUsername: string,
  timestamp: timestamp,
  status: string,          // 'sending', 'sent', 'delivered', 'read'
  type: string            // 'text' (future: 'image', 'voice')
}
```

### Firestore Indexes
Create these composite indexes:
1. Collection: `users`
   - Fields: `username` (Ascending)
   
2. Collection: `chats`
   - Fields: `participants` (Array Contains) + `lastMessageTime` (Descending)

3. Collection: `messages` (in chats subcollection)
   - Fields: `timestamp` (Descending)

### Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read any user but write only their own
    match /users/{userId} {
      allow read: if request.auth != null;
      allow create: if request.auth.uid == userId;
      allow update: if request.auth.uid == userId;
      allow delete: if false; // Prevent deletion
    }
    
    // Chat access only for participants
    match /chats/{chatId} {
      allow read: if request.auth != null && (
        request.auth.uid in resource.data.participantIds ||
        request.auth.uid in resource.data.participantIds
      );
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
        request.auth.uid in resource.data.participantIds;
      allow delete: if false;
    }
    
    // Messages access for chat participants only
    match /chats/{chatId}/messages/{messageId} {
      allow read: if request.auth != null && 
        request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participantIds;
      allow create: if request.auth != null && 
        request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participantIds;
      allow update: if false; // Messages are immutable
      allow delete: if false;
    }
  }
}
```

## Development Guide

### Running the App
```bash
# Get dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Run with verbose logging
flutter run -v
```

### Building for Release
```bash
# Clean build artifacts
flutter clean

# Get dependencies
flutter pub get

# Build APK
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

## Testing

### Manual Testing Checklist
- [ ] Google Sign-in flow
- [ ] Username creation and validation
- [ ] Finding user by username
- [ ] Sending and receiving messages
- [ ] Push notifications (background/foreground)
- [ ] Offline behavior
- [ ] Error handling
- [ ] Different screen sizes
- [ ] Android versions (5.0 to latest)

### Automated Testing
```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test

# Run with coverage
flutter test --coverage
```

## Common Issues & Solutions

### Issue: Google Sign-In not working
**Solution**: 
1. Add SHA-1 certificate to Firebase:
   ```bash
   cd android
   ./gradlew signingReport
   ```
2. Copy SHA-1 from debug variant
3. Add to Firebase Console → Project Settings → Android app
4. Re-download `google-services.json`

### Issue: FCM notifications not receiving
**Solution**:
1. Ensure testing on real device (not emulator)
2. Check notification permissions granted
3. Verify FCM token is saved to Firestore
4. Test via Firebase Console → Cloud Messaging

### Issue: Firestore permission denied
**Solution**:
1. Check Security Rules are properly set
2. Verify user is authenticated
3. Check document paths are correct
4. Enable Firestore in Firebase Console

### Issue: App crashes on launch
**Solution**:
1. Check `google-services.json` is in `android/app/`
2. Verify Firebase initialization in `main()`
3. Run `flutter clean && flutter pub get`
4. Check minimum SDK version is 21

### Issue: Messages not appearing in real-time
**Solution**:
1. Check internet connection
2. Verify Firestore listeners are active
3. Check chat ID generation is consistent
4. Look for errors in debug console

## Performance Optimization

### App Size
- Use `--split-per-abi` for smaller APKs
- Remove unused dependencies
- Optimize images and assets
- Enable ProGuard/R8

### Runtime Performance
- Implement message pagination (50 per load)
- Use `const` constructors where possible
- Dispose controllers and streams properly
- Cache user data locally

### Battery Usage
- Minimize background operations
- Use FCM for push instead of polling
- Implement proper lifecycle handling
- Reduce unnecessary rebuilds

## Deployment

### Play Store Preparation
1. **App Details**
   - App name: Ottr
   - Category: Communication
   - Content rating: Everyone
   
2. **Store Listing**
   - Short description (80 chars max)
   - Full description
   - Screenshots (minimum 2)
   - Feature graphic (1024x500)
   - App icon (512x512)

3. **Release Management**
   - Start with internal testing
   - Move to closed beta (100 users)
   - Open beta (500 users)
   - Production release

### Version Management
Follow semantic versioning:
- **1.0.0** - Initial release (MVP)
- **1.1.0** - Typing indicators, read receipts
- **1.2.0** - Online status, message deletion
- **2.0.0** - iOS support

### Privacy Policy Requirements
Must include:
- What data is collected (email, name, messages)
- How data is used (authentication, messaging)
- Data retention policy
- User rights (deletion, export)
- Contact information

## Monitoring & Analytics

### Firebase Analytics Events
Track these key events:
- `sign_in_success`
- `username_created`
- `connection_initiated`
- `message_sent`
- `notification_opened`
- `app_error`

### Crashlytics Setup
```dart
// In main.dart
await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
```

### Performance Monitoring
- App start time
- Screen rendering time
- Network request duration
- Message delivery latency

## Future Roadmap

### Phase 1 - Stability (Month 1)
- Bug fixes from user feedback
- Performance improvements
- UI polish
- Crash rate < 0.5%

### Phase 2 - Engagement (Month 2-3)
- Typing indicators
- Read receipts
- Online/last seen status
- Message deletion (for self)
- Export chat feature

### Phase 3 - Growth (Month 4-6)
- iOS support
- Voice messages
- Image sharing
- End-to-end encryption
- Web version

### Phase 4 - Monetization (Month 7+)
- Premium features
- Ad-free experience
- Custom themes
- Multiple chat support
- Priority support

## Contributing
Currently not accepting external contributions. For bug reports or feature requests, please email: support@ottr.app

## License
Copyright © 2024 Ottr. All rights reserved.

## Support
- Email: support@ottr.app
- Twitter: @ottrapp
- Website: https://ottr.app

---

Built with ❤️ using Flutter and Firebase