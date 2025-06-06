# Ottr - Product Requirements Document (PRD)

## Executive Summary
Ottr is a minimalist one-to-one messaging application where users connect through unique usernames. Unlike traditional messengers, Ottr focuses on meaningful connections by limiting users to one active conversation at a time.

## Vision Statement
Create the simplest, most intuitive way for two people to connect and chat privately without exchanging phone numbers or social media handles.

## Target Audience
- **Primary**: Young adults (18-35) transitioning from dating apps to private conversations
- **Secondary**: Privacy-conscious users who want anonymous connections
- **Tertiary**: International users who want to chat without sharing WhatsApp numbers

## Core User Journey

### 1. Onboarding Flow
1. **App Launch** → Splash screen with Ottr logo
2. **Authentication** → Google Sign-in (one-tap)
3. **Username Creation** → Choose unique username + display name
4. **Home Screen** → Ready to connect

### 2. Connection Flow
1. **Share Username** → User shares their username (verbally, text, etc.)
2. **Enter Username** → Other user enters username in app
3. **Start Chat** → Instant connection, no approval needed
4. **Real-time Messaging** → Text messages with delivery status

### 3. Messaging Flow
1. **Send Message** → Type and send text
2. **Receive Notification** → Push notification when app backgrounded
3. **Read Message** → Opens directly to chat
4. **Continue Conversation** → Until one user disconnects

## Functional Requirements

### Phase 1 - MVP (Launch Version)

#### Authentication
- **FR1.1**: Google Sign-in only (no email/password)
- **FR1.2**: Automatic session persistence
- **FR1.3**: Sign out functionality
- **FR1.4**: Delete account option (GDPR compliance)

#### Username System
- **FR2.1**: Unique username creation (alphanumeric + underscore)
- **FR2.2**: Real-time availability checking
- **FR2.3**: Display name (shown in chat)
- **FR2.4**: Username cannot be changed after creation
- **FR2.5**: Case-insensitive username search

#### Connection Management
- **FR3.1**: Connect by entering exact username
- **FR3.2**: One active chat at a time
- **FR3.3**: Previous chat history preserved but hidden
- **FR3.4**: Disconnect from current chat
- **FR3.5**: Block user functionality

#### Messaging
- **FR4.1**: Real-time text messaging
- **FR4.2**: Message delivery status (sending → sent)
- **FR4.3**: Push notifications for new messages
- **FR4.4**: Offline message queue
- **FR4.5**: Message persistence in cloud

#### User Interface
- **FR5.1**: Four main screens: Auth, Username, Home, Chat
- **FR5.2**: Material 3 design language
- **FR5.3**: Responsive layout for all Android devices
- **FR5.4**: Smooth animations and transitions
- **FR5.5**: Loading states for all async operations

### Phase 2 - Post Launch Features
- Typing indicators
- Read receipts (optional toggle)
- Online/last seen status
- Message deletion (for self)
- Export chat history
- Report user functionality
- iOS support

### Phase 3 - Growth Features
- Voice messages
- Image sharing
- End-to-end encryption
- Multiple chat support (premium)
- Username change (once per year)
- Verified accounts

## Non-Functional Requirements

### Performance
- **NFR1.1**: App launch time < 2 seconds
- **NFR1.2**: Message delivery < 300ms (online)
- **NFR1.3**: Smooth 60fps animations
- **NFR1.4**: Memory usage < 150MB
- **NFR1.5**: Battery efficient (< 5% daily drain)

### Reliability
- **NFR2.1**: 99.9% uptime for messaging service
- **NFR2.2**: Message delivery guarantee
- **NFR2.3**: Automatic reconnection handling
- **NFR2.4**: Graceful offline mode
- **NFR2.5**: Data consistency across devices

### Security
- **NFR3.1**: All data transmitted over HTTPS
- **NFR3.2**: Firebase Authentication for user management
- **NFR3.3**: Firestore security rules for data access
- **NFR3.4**: No message content in push notifications
- **NFR3.5**: User data deletion within 30 days of request

### Usability
- **NFR4.1**: Maximum 3 taps to send a message
- **NFR4.2**: Intuitive UI without tutorials
- **NFR4.3**: Clear error messages
- **NFR4.4**: Accessibility support (TalkBack)
- **NFR4.5**: Support for Android 5.0+ (API 21+)

### Scalability
- **NFR5.1**: Support 100K concurrent users
- **NFR5.2**: Message history pagination
- **NFR5.3**: Efficient data synchronization
- **NFR5.4**: CDN for static assets
- **NFR5.5**: Regional Firebase deployment

## Technical Architecture

### Frontend
- **Framework**: Flutter (latest stable)
- **State Management**: Riverpod 2.0
- **Navigation**: Declarative routing
- **Local Storage**: SharedPreferences for settings

### Backend
- **Authentication**: Firebase Auth
- **Database**: Cloud Firestore
- **Push Notifications**: Firebase Cloud Messaging
- **Analytics**: Firebase Analytics
- **Crash Reporting**: Firebase Crashlytics

### Data Models

#### User Model
```
users/{userId}
{
  uid: string (Firebase UID)
  username: string (unique, lowercase)
  displayName: string
  email: string
  photoUrl: string (from Google)
  fcmToken: string
  createdAt: timestamp
  lastSeen: timestamp
  isOnline: boolean
  currentChatId: string (nullable)
}
```

#### Chat Model
```
chats/{chatId}
{
  id: string (user1Username_user2Username sorted)
  participants: [username1, username2]
  participantIds: [userId1, userId2]
  createdAt: timestamp
  lastMessage: string
  lastMessageTime: timestamp
  lastMessageSender: string (username)
  isActive: boolean
  user1Typing: boolean
  user2Typing: boolean
}
```

#### Message Model
```
chats/{chatId}/messages/{messageId}
{
  id: string (auto-generated)
  text: string
  senderUsername: string
  timestamp: timestamp
  status: 'sending' | 'sent' | 'delivered' | 'read'
  type: 'text' (future: 'image', 'voice')
}
```

## UI/UX Specifications

### Design Principles
1. **Minimal**: No unnecessary elements
2. **Intuitive**: Self-explanatory interface
3. **Fast**: Instant feedback on all actions
4. **Friendly**: Warm, approachable aesthetic
5. **Accessible**: Clear contrast, readable fonts

### Color Palette
- **Primary**: #2196F3 (Material Blue)
- **Primary Variant**: #1976D2
- **Secondary**: #4CAF50 (Success Green)
- **Error**: #F44336
- **Background**: #FFFFFF
- **Surface**: #F5F5F5
- **On Primary**: #FFFFFF
- **On Background**: #212121
- **Message Sent**: #E3F2FD
- **Message Received**: #F5F5F5

### Typography
- **Font**: Roboto (System default)
- **Display**: 32sp, Medium
- **Headline**: 24sp, Regular
- **Title**: 20sp, Medium
- **Body**: 16sp, Regular
- **Caption**: 14sp, Regular

### Screen Specifications

#### Splash Screen
- Logo centered
- App name below logo
- Subtle fade-in animation
- 2-second duration maximum

#### Auth Screen
- Logo at 25% from top
- Welcome message
- Google Sign-in button (Material spec)
- Privacy policy link at bottom

#### Username Screen
- "Choose your username" header
- Username input with real-time validation
- Display name input
- Availability indicator (green check/red x)
- Continue button (disabled until valid)
- Username rules clearly displayed

#### Home Screen
- App bar with username and profile picture
- Empty state: "Connect with someone"
- Username input field
- Connect button
- Active chat card (if exists)
- Menu: Settings, Sign out

#### Chat Screen
- App bar with recipient's display name
- Message list (reverse chronological)
- Message input with send button
- Delivery status indicators
- Disconnect option in menu

### Animation Specifications
- **Page Transitions**: 300ms slide
- **Button Press**: Scale 0.95, 100ms
- **Message Appear**: Fade + slide up, 200ms
- **Loading Spinner**: Material circular progress
- **Username Check**: 500ms debounce

## Success Metrics

### Launch Metrics (First 30 Days)
- 1,000 downloads
- 40% D1 retention
- 20% D7 retention
- 4.0+ Play Store rating
- < 1% crash rate

### Growth Metrics (6 Months)
- 50,000 MAU
- 25% DAU/MAU ratio
- 3 minutes average session
- 50 messages per user per day
- 60% user referral rate

### Quality Metrics
- < 0.1% message failure rate
- < 500ms message delivery (P95)
- < 5 crash-free sessions per user
- > 95% successful sign-ins
- < 2% uninstall rate in first week

## Risk Mitigation

### Technical Risks
1. **FCM Delivery Issues**: Implement fallback polling
2. **Firestore Costs**: Implement message pagination
3. **Username Squatting**: Reserve common names
4. **Scaling Issues**: Plan sharding strategy
5. **Platform Changes**: Regular dependency updates

### User Experience Risks
1. **Ghost Towns**: Show "quick connect" suggestions
2. **Harassment**: Easy blocking and reporting
3. **Lost Connections**: "Recent chats" recovery
4. **Confusion**: Onboarding tooltips
5. **Platform Lock-in**: Export functionality

## Compliance Requirements
- GDPR compliance (EU users)
- COPPA compliance (13+ age requirement)
- Google Play Store policies
- Firebase terms of service
- User data privacy policy

## Launch Strategy

### Phase 1: Soft Launch (Week 1-2)
- Internal testing (20 users)
- Fix critical bugs
- Performance optimization

### Phase 2: Beta Launch (Week 3-4)
- Open beta (500 users)
- Play Store beta channel
- Gather feedback
- Iterate on UX

### Phase 3: Production Launch (Week 5)
- Full Play Store release
- Product Hunt launch
- Social media announcement
- Press release to tech blogs

## Post-Launch Roadmap

### Month 1
- Bug fixes and stability
- Performance optimization
- User feedback integration

### Month 2
- Typing indicators
- Read receipts
- Online status

### Month 3
- iOS development start
- Voice messages
- Image sharing

### Month 6
- End-to-end encryption
- Premium features
- International expansion