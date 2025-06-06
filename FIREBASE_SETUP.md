# Firebase Setup Instructions for Ottr

This document provides step-by-step instructions for setting up Firebase services for the Ottr Android app.

## 1. Create a Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter "Ottr" as the project name
4. Enable Google Analytics (recommended)
5. Follow the setup wizard to complete project creation

## 2. Register the Android App

1. In the Firebase project dashboard, click the Android icon to add an Android app
2. Enter package name: `com.example.ottr` (or your custom package name)
3. Enter app nickname: "Ottr"
4. Enter SHA-1 certificate fingerprint (required for Google Sign-in):
   ```
   Run this command in your project directory to get the debug SHA-1:
   ./gradlew signingReport
   ```
5. Click "Register app"
6. Download the `google-services.json` file
7. Place the file in the `android/app/` directory of your Flutter project

## 3. Configure Firebase Services

### Authentication

1. In the Firebase Console, go to "Authentication"
2. Click "Get started"
3. Enable "Google" sign-in method
4. Add support email
5. Save changes

### Firestore Database

1. Go to "Firestore Database"
2. Click "Create database"
3. Start in production mode
4. Choose a location closest to your users
5. Create the database

### Create Firestore Collections and Indexes

Create the following collections with appropriate indexes:

1. `users` collection:
   - Index on `username` field (for username availability checks)
   - Index on `fcmToken` field (for push notifications)

2. `chats` collection:
   - Index on `participants` array (for finding user's chats)
   - Index on `lastMessageTime` field (for sorting)

### Cloud Messaging

1. Go to "Cloud Messaging"
2. Configure Android credentials if needed

## 4. Security Rules

Add the following security rules to Firestore:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User profiles are readable by anyone but only writable by the user
    match /users/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Chats are accessible by participants
    match /chats/{chatId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.participantIds;
      
      // Messages in a chat are accessible by chat participants
      match /messages/{messageId} {
        allow read, write: if request.auth != null && 
          request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participantIds;
      }
    }
  }
}
```

## 5. Update Android Configuration

1. Ensure the `google-services.json` file is in the correct location
2. Check that the package name in your Android manifest matches the one registered in Firebase
3. Verify the dependencies in `build.gradle` files are correctly configured

## 6. Test Firebase Integration

1. Run the app and check the logs for successful Firebase initialization
2. Test Google Sign-in functionality
3. Verify database operations are working
4. Test push notifications (may require a physical device)

## Common Issues

- SHA-1 mismatch: Ensure the SHA-1 fingerprint in Firebase matches your app signing key
- Push notification issues: Check for proper configuration in AndroidManifest.xml
- Google Sign-in failures: Verify OAuth client ID in Firebase console
- Firestore permission denied: Check security rules and authentication state

---

If you encounter any issues, refer to the [Firebase documentation](https://firebase.google.com/docs) or the Flutter Firebase plugins documentation.
