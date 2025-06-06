# Ottr Implementation Steps - Detailed Build Guide

## Phase 1: Project Setup and Configuration (45 minutes)

### Step 1.1: Create Flutter Project
```bash
# Create project with proper organization
flutter create ottr --org com.yourcompany --platforms android

# Navigate to project
cd ottr

# Open in IDE
code . # VS Code
# or
studio . # Android Studio
```

### Step 1.2: Configure Dependencies
Update `pubspec.yaml`:
```yaml
name: ottr
description: Minimalist one-to-one messenger
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^2.27.0
  firebase_auth: ^4.17.0
  cloud_firestore: ^4.15.0
  firebase_messaging: ^14.7.0
  firebase_analytics: ^10.8.0
  firebase_crashlytics: ^3.4.0
  
  # Authentication
  google_sign_in: ^6.2.0
  
  # State Management
  flutter_riverpod: ^2.5.0
  
  # UI/UX
  flutter_animate: ^4.5.0
  shimmer: ^3.0.0
  
  # Utilities
  shared_preferences: ^2.2.2
  intl: ^0.19.0
  connectivity_plus: ^5.0.2
  package_info_plus: ^5.0.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  
  # Add fonts if needed
  # fonts:
  #   - family: Roboto
  #     fonts:
  #       - asset: fonts/Roboto-Regular.ttf
  #       - asset: fonts/Roboto-Bold.ttf
  #         weight: 700
```

### Step 1.3: Create Project Structure
```bash
# Create all directories
mkdir -p lib/{screens,widgets,services,models,providers,utils,config}

# Create initial files
touch lib/main.dart
touch lib/app.dart
touch lib/config/theme.dart
touch lib/config/routes.dart
touch lib/utils/constants.dart
touch lib/utils/validators.dart
touch lib/utils/extensions.dart
```

### Step 1.4: Firebase Project Setup
1. Go to https://console.firebase.google.com
2. Create new project: "ottr-production"
3. Enable Google Analytics (optional)
4. Add Android app:
   - Package name: `com.yourcompany.ottr`
   - App nickname: Ottr Android
   - Debug signing certificate SHA-1 (get via `./gradlew signingReport`)
5. Download `google-services.json` to `android/app/`

### Step 1.5: Firebase Services Configuration
In Firebase Console, enable:

1. **Authentication**
   - Go to Authentication → Sign-in method
   - Enable Google provider
   - Add support email
   - Copy Web client ID for later

2. **Cloud Firestore**
   - Go to Firestore Database
   - Create database in production mode
   - Choose location: `asia-south1` (Mumbai)
   
3. **Cloud Messaging**
   - Automatically enabled
   - Note the Server Key for future use

### Step 1.6: Android Configuration
Update `android/build.gradle`:
```gradle
buildscript {
    ext.kotlin_version = '1.9.0'
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
        classpath 'com.google.gms:google-services:4.4.0'
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
```

Update `android/app/build.gradle`:
```gradle
apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'
apply plugin: 'com.google.gms.google-services'

android {
    compileSdkVersion 34
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = '1.8'
    }

    sourceSets {
        main.java.srcDirs += 'src/main/kotlin'
    }

    defaultConfig {
        applicationId "com.yourcompany.ottr"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
        multiDexEnabled true
    }

    buildTypes {
        release {
            signingConfig signingConfigs.debug
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}

dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version"
    implementation 'androidx.multidex:multidex:2.0.1'
}
```

## Phase 2: Core Implementation (2 hours)

### Step 2.1: Main Entry Point
Create `lib/main.dart`:
```dart
// Tell Windsurf:
// Create main.dart with:
// - Firebase initialization
// - Error handling setup
// - Crashlytics configuration
// - ProviderScope wrapper
// - MaterialApp with theme
```

### Step 2.2: App Configuration
Create `lib/app.dart`:
```dart
// Tell Windsurf:
// Create app.dart with:
// - MaterialApp configuration
// - Theme setup (Material 3)
// - Route configuration
// - Responsive breakpoints
// - System UI overlay style
```

### Step 2.3: Theme Configuration
Create `lib/config/theme.dart`:
```dart
// Tell Windsurf:
// Create comprehensive theme with:
// - Light theme only (dark mode later)
// - Color scheme from PRD
// - Text themes with Roboto
// - Component themes (buttons, inputs, cards)
// - Consistent spacing (8dp grid)
```

### Step 2.4: Constants Definition
Create `lib/utils/constants.dart`:
```dart
// Tell Windsurf:
// Define all app constants:
// - Username constraints (3-20 chars, alphanumeric + underscore)
// - Message pagination limit (50)
// - FCM topic names
// - Firestore collection names
// - Error messages
// - Animation durations
```

### Step 2.5: Input Validators
Create `lib/utils/validators.dart`:
```dart
// Tell Windsurf:
// Create validators for:
// - Username format (lowercase, alphanumeric + underscore)
// - Username length (3-20 characters)
// - Display name (1-50 characters)
// - Message content (not empty, max 1000 chars)
// Return user-friendly error messages
```

## Phase 3: Authentication Implementation (1.5 hours)

### Step 3.1: Auth Service
Create `lib/services/auth_service.dart`:
```dart
// Tell Windsurf:
// Implement AuthService with:
// - Google Sign-In flow
// - Sign out functionality
// - Current user getter
// - Auth state changes stream
// - Error handling with user-friendly messages
// - FCM token update after sign in
```

### Step 3.2: Auth Providers
Create `lib/providers/auth_provider.dart`:
```dart
// Tell Windsurf:
// Create Riverpod providers:
// - authStateProvider (StreamProvider for auth changes)
// - currentUserProvider (watch auth state)
// - authServiceProvider (singleton service)
// - signInProvider (FutureProvider for sign in)
// - signOutProvider (FutureProvider for sign out)
```

### Step 3.3: Splash Screen
Create `lib/screens/splash_screen.dart`:
```dart
// Tell Windsurf:
// Create splash screen with:
// - Centered Ottr logo/text
// - Fade in animation
// - Auth state check after 2 seconds
// - Navigation logic:
//   - Signed in + has username → HomeScreen
//   - Signed in + no username → UsernameScreen
//   - Not signed in → AuthScreen
// - Error handling
```

### Step 3.4: Auth Screen
Create `lib/screens/auth_screen.dart`:
```dart
// Tell Windsurf:
// Create auth screen with:
// - Clean white background
// - Ottr logo at 25% from top
// - "Connect with one person at a time" tagline
// - Google Sign-In button (Material spec)
// - Loading state during sign in
// - Error snackbar
// - Privacy policy link at bottom
```

### Step 3.5: User Model
Create `lib/models/user_model.dart`:
```dart
// Tell Windsurf:
// Create UserModel with:
// - All fields from PRD
// - fromMap factory constructor
// - toMap method
// - copyWith method
// - Null safety
// - Default values where appropriate
```

## Phase 4: Username System (1 hour)

### Step 4.1: Database Service
Create `lib/services/database_service.dart`:
```dart
// Tell Windsurf:
// Implement DatabaseService with:
// - checkUsernameAvailability(String username)
// - createUserProfile(UserModel user)
// - getUserByUsername(String username)
// - updateUserProfile(String uid, Map<String, dynamic> data)
// - Error handling
// - Firestore references as getters
```

### Step 4.2: Username Screen
Create `lib/screens/username_screen.dart`:
```dart
// Tell Windsurf:
// Create username screen with:
// - "Choose your username" header
// - Username text field with:
//   - Real-time validation
//   - Lowercase enforcement
//   - Character restrictions
//   - Debounced availability check (500ms)
// - Display name text field
// - Availability indicator (green check/red x)
// - Continue button (disabled until valid)
// - Loading states
// - Error handling
```

### Step 4.3: Username Input Widget
Create `lib/widgets/username_input.dart`:
```dart
// Tell Windsurf:
// Create reusable username input with:
// - Custom text field decoration
// - Real-time validation feedback
// - Availability check indicator
// - Loading state
// - Error state
// - Success state with checkmark
```

## Phase 5: FCM Implementation (1.5 hours)

### Step 5.1: Notification Service
Create `lib/services/notification_service.dart`:
```dart
// Tell Windsurf:
// Implement NotificationService with:
// - FCM initialization
// - Permission request (Android 13+)
// - Token retrieval and storage
// - Foreground message handling
// - Background message handling
// - Notification channel setup
// - Token refresh listener
// - Local notification display
```

### Step 5.2: Android Native Setup
Create `android/app/src/main/kotlin/com/yourcompany/ottr/MainActivity.kt`:
```kotlin
// Tell Windsurf:
// Create MainActivity with:
// - Notification channel creation
// - Channel ID: "ottr_messages"
// - Channel name: "Messages"
// - High importance
// - Vibration enabled
// - Sound enabled
```

### Step 5.3: AndroidManifest Configuration
Update `android/app/src/main/AndroidManifest.xml`:
```xml
<!-- Tell Windsurf to add: -->
<!-- Permissions -->
<!-- FCM default icon meta-data -->
<!-- FCM default channel meta-data -->
<!-- Intent filters for FCM -->
```

### Step 5.4: FCM Testing
1. Build and run app
2. Get FCM token from logs
3. Send test notification from Firebase Console
4. Verify notification received in:
   - Foreground (in-app display)
   - Background (system notification)
   - App killed (system notification)

## Phase 6: Chat Implementation (2 hours)

### Step 6.1: Chat Model
Create `lib/models/chat_model.dart`:
```dart
// Tell Windsurf:
// Create ChatModel with:
// - All fields from PRD
// - ID generation method (sorted usernames)
// - fromMap/toMap methods
// - Participant checking methods
// - Last message update method
```

### Step 6.2: Message Model
Create `lib/models/message_model.dart`:
```dart
// Tell Windsurf:
// Create MessageModel with:
// - All fields from PRD
// - Status enum (sending, sent, delivered, read)
// - fromMap/toMap methods
// - Timestamp handling
// - ID generation
```

### Step 6.3: Chat Service Extension
Update `lib/services/database_service.dart`:
```dart
// Tell Windsurf to add:
// - createOrGetChat(username1, username2)
// - sendMessage(chatId, message)
// - streamMessages(chatId, limit)
// - streamUserChats(username)
// - markMessagesAsRead(chatId, username)
// - updateTypingStatus(chatId, username, isTyping)
```

### Step 6.4: Home Screen
Create `lib/screens/home_screen.dart`:
```dart
// Tell Windsurf:
// Create home screen with:
// - App bar with username and profile picture
// - "Connect with someone" card
// - Username input field
// - Connect button
// - Active chat display (if exists)
// - Disconnect option
// - Settings menu (sign out)
// - Pull to refresh
// - Empty state
```

### Step 6.5: Chat Screen
Create `lib/screens/chat_screen.dart`:
```dart
// Tell Windsurf:
// Create chat screen with:
// - App bar with recipient name
// - Message list (reverse ListView)
// - Message bubbles (sent/received)
// - Text input with send button
// - Keyboard handling
// - Auto-scroll to bottom
// - Loading states
// - Empty state
// - Pull to load more messages
```

### Step 6.6: Message Bubble Widget
Create `lib/widgets/message_bubble.dart`:
```dart
// Tell Windsurf:
// Create message bubble with:
// - Different styles for sent/received
// - Timestamp display
// - Status indicator (sent/delivered/read)
// - Long press to copy
// - Smooth appear animation
// - Maximum width constraint
```

## Phase 7: State Management (1 hour)

### Step 7.1: User Provider
Create `lib/providers/user_provider.dart`:
```dart
// Tell Windsurf:
// Create providers for:
// - currentUserProfileProvider
// - usernameAvailabilityProvider
// - userByUsernameProvider
// - userProfileUpdateProvider
```

### Step 7.2: Chat Provider
Create `lib/providers/chat_provider.dart`:
```dart
// Tell Windsurf:
// Create providers for:
// - activeChatProvider
// - chatMessagesProvider
// - sendMessageProvider
// - typingStatusProvider
// - unreadCountProvider
```

### Step 7.3: Provider Exports
Create `lib/providers/providers.dart`:
```dart
// Tell Windsurf:
// Export all providers from single file
// Add documentation for each provider
```

## Phase 8: Polish and Error Handling (1 hour)

### Step 8.1: Loading States
```dart
// Tell Windsurf to add throughout app:
// - Shimmer loading for lists
// - Circular progress for buttons
// - Skeleton screens for data
// - Disable interactions during loading
```

### Step 8.2: Error Handling
```dart
// Tell Windsurf to implement:
// - Global error boundary
// - User-friendly error messages
// - Retry mechanisms
// - Offline detection
// - Network error handling
```

### Step 8.3: Empty States
```dart
// Tell Windsurf to create:
// - No messages yet illustration
// - No active chat illustration
// - User not found message
// - Connection failed message
```

### Step 8.4: Animations
```dart
// Tell Windsurf to add:
// - Page transitions (slide)
// - Button press effects (scale)
// - Message appear animation
// - Loading animations
// - Success animations
```

## Phase 9: Testing and Optimization (1 hour)

### Step 9.1: Manual Testing
Test these flows thoroughly:
1. Fresh install → Sign in → Username → Connect → Chat
2. Send 100+ messages (pagination)
3. Disconnect and reconnect
4. Username validation edge cases
5. Network disconnection scenarios
6. App background/foreground
7. Notification delivery
8. Different screen sizes

### Step 9.2: Performance Optimization
- Implement message pagination
- Add image caching
- Optimize rebuilds with const
- Dispose controllers properly
- Cache user profiles locally

### Step 9.3: Build Optimization
```bash
# Clean build
flutter clean
flutter pub get

# Build release APK
flutter build apk --release --split-per-abi

# Build app bundle
flutter build appbundle --release
```

## Phase 10: Production Preparation (30 minutes)

### Step 10.1: App Icons
Generate app icons:
- Create 1024x1024 icon
- Use flutter_launcher_icons package
- Include notification icon

### Step 10.2: Splash Screen
Configure native splash:
- Use flutter_native_splash package
- Match brand colors
- Add logo

### Step 10.3: ProGuard Rules
Create `android/app/proguard-rules.pro`:
```
-keep class com.google.** { *; }
-keep class io.flutter.** { *; }
-keep class com.yourcompany.ottr.** { *; }
```

### Step 10.4: Final Checklist
- [ ] Remove all debug prints
- [ ] Test on Android 5.0 device
- [ ] Test on latest Android
- [ ] Verify all permissions needed
- [ ] Update version in pubspec.yaml
- [ ] Create signed APK
- [ ] Test signed APK thoroughly

## Troubleshooting Guide

### Common Issues During Development

1. **Gradle Build Failures**
   - Run `cd android && ./gradlew clean`
   - Update Gradle wrapper version
   - Check Java version (needs 11+)

2. **Flutter Doctor Issues**
   - Accept Android licenses
   - Install missing dependencies
   - Update Flutter SDK

3. **Hot Reload Not Working**
   - Stop and restart app
   - Check for syntax errors
   - Clean and rebuild

4. **Firestore Index Errors**
   - Click link in error message
   - Create composite index
   - Wait 2-3 minutes

5. **FCM Token Null**
   - Check Google Play Services
   - Test on real device
   - Check internet connection

Remember: Build incrementally, test each feature before moving to the next!