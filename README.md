# Ottr - Minimalist One-to-One Messaging

Ottr is a minimalist one-to-one messaging application for Android built with Flutter. It focuses on simplicity, reliability, and clean code.

## Key Features

- **Simple Connections**: Connect with other users via unique usernames
- **One Active Chat**: Focus on one conversation at a time
- **Real-time Messaging**: Instant delivery with typing indicators
- **Push Notifications**: Stay updated when you receive messages
- **Google Sign-in**: Easy and secure authentication
- **Clean UI**: Material Design 3 with smooth animations

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── app.dart                     # MaterialApp widget
├── screens/                     # All screen widgets
│   ├── splash_screen.dart
│   ├── auth_screen.dart
│   ├── username_screen.dart
│   ├── home_screen.dart
│   └── chat_screen.dart
├── widgets/                     # Reusable widgets
│   ├── message_bubble.dart
│   ├── loading_button.dart
│   └── username_input.dart
├── services/                    # Business logic
│   ├── auth_service.dart
│   ├── database_service.dart
│   └── notification_service.dart
├── models/                      # Data models
│   ├── user_model.dart
│   ├── chat_model.dart
│   └── message_model.dart
├── providers/                   # Riverpod providers
│   ├── auth_provider.dart
│   ├── user_provider.dart
│   ├── chat_provider.dart
│   └── providers.dart          # Export file
├── utils/                       # Utilities
│   ├── constants.dart
│   ├── validators.dart
│   └── extensions.dart
└── config/                      # Configuration
    ├── theme.dart
    └── routes.dart
```

## Getting Started

### Prerequisites

- Flutter 3.0.0+ (recommended: latest stable version)
- Android Studio or VS Code with Flutter extensions
- Firebase project (see [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for detailed instructions)
- Android device or emulator (minimum API 21 - Android 5.0)

### Installation

1. Clone this repository
   ```bash
   git clone https://github.com/yourusername/ottr-android-app.git
   cd ottr-android-app
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Set up Firebase
   - Follow instructions in [FIREBASE_SETUP.md](FIREBASE_SETUP.md)
   - Place your `google-services.json` in `android/app/`

4. Run the app
   ```bash
   flutter run
   ```

### Firebase Configuration

This app requires the following Firebase services:

- **Authentication** (Google Sign-In)
- **Cloud Firestore** (Database)
- **Cloud Messaging** (Push Notifications)
- **Analytics** (Optional)
- **Crashlytics** (Optional)

See [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for detailed setup instructions.

## Design Philosophy

### Simplicity First
- MVP features only - no feature creep
- One way to do things, not multiple options
- Clear, obvious UI patterns
- Minimal dependencies

### Android First
- Target Android 5.0+ (API 21)
- Material Design 3 guidelines
- Optimized for multiple screen sizes

## Color Palette

```dart
const primaryColor = Color(0xFF2196F3);
const primaryVariant = Color(0xFF1976D2);
const secondaryColor = Color(0xFF4CAF50);
const errorColor = Color(0xFFF44336);
const backgroundColor = Color(0xFFFFFFFF);
const surfaceColor = Color(0xFFF5F5F5);
const messageSentColor = Color(0xFFE3F2FD);
const messageReceivedColor = Color(0xFFF5F5F5);
```

## State Management

Ottr uses Riverpod 2.0 for state management:

- **auth_provider.dart**: Authentication state and user profile
- **user_provider.dart**: User search and connections
- **chat_provider.dart**: Messages and typing status

## License

This project is licensed under the MIT License - see the LICENSE file for details.
