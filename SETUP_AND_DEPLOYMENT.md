# Gamified Productivity App - Setup & Deployment Guide

## 📋 Overview

This is a **production-ready Flutter gamified productivity app** built withFirebase for cross-platform mobile delivery. The app uses gamification principles from HCI and motivational psychology to help adults maintain consistent productivity through points, streaks, badges, levels, and meaningful feedback.

---

## 🚀 Quick Start

### Prerequisites

- **Flutter SDK** 3.9.0 or higher
- **Android Studio** or **Xcode** for mobile development
- **Firebase CLI**: `npm install -g firebase-tools`
- **Google/Apple Developer Account** (for app deployment)

### 1. Clone & Setup Repository

```bash
git clone <repository-url>
cd chimere
flutter pub get
```

### 2. Firebase Project Setup

#### Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click **"Create Project"**
3. Name: `chimere-gamified-app`
4. Location: Select your region
5. Create project

#### Enable Firebase Services

In Firebase Console, go to each tab and enable:

- **Authentication**
  - Sign in with Email/Password
  - Go to "Settings" → "Authorized domains" → Add your domain
  
- **Firestore Database**
  - Start in test mode (or production mode with rules below)
  - Location: Select same region
  
- **Analytics**
  - Enable Firebase Analytics
  
- **Storage**
  - Create a default bucket

#### Firestore Security Rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
      
      // Badges subcollection
      match /badges/{document=**} {
        allow read, write: if request.auth.uid == userId;
      }
      
      // Achievements subcollection
      match /achievements/{document=**} {
        allow read, write: if request.auth.uid == userId;
      }
    }
    
    // Tasks collection
    match /tasks/{document=**} {
      allow read, write: if request.auth.uid == resource.data.userId;
      allow create: if request.auth.uid == request.resource.data.userId;
    }
    
    // Analytics collection (append-only)
    match /analytics_events/{document=**} {
      allow create: if request.auth != null;
      allow read: if false; // Private analytics
    }
  }
}
```

### 3. Configure Firebase in Flutter

#### Download Firebase Configuration Files

**For Android:**
1. In Firebase Console → Project Settings → Your Apps
2. Select Android
3. Enter Package Name: `com.example.chimere` (or your package)
4. Download `google-services.json`
5. Place in: `android/app/`

**For iOS:**
1. Select iOS in Firebase Console
2. Enter Bundle ID: `com.example.chimere`
3. Download `GoogleService-Info.plist`
4. Open iOS project in Xcode: `open ios/Runner.xcworkspace`
5. Add plist to Xcode (check "Copy items if needed")

### 4. Update Firebase Options

Update `lib/services/firebase_options.dart` with your Firebase credentials:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ANDROID_API_KEY',
  appId: '1:YOUR_PROJECT_NUMBER:android:YOUR_ANDROID_APP_ID',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  projectId: 'chimere-gamified-app',
  storageBucket: 'chimere-gamified-app.appspot.com',
);
```

### 5. Update .env File

Create/update `.env` file in project root:

```env
FIREBASE_API_KEY_ANDROID=YOUR_ANDROID_API_KEY
FIREBASE_PROJECT_ID=chimere-gamified-app
FIREBASE_APP_ID_ANDROID=YOUR_ANDROID_APP_ID
FIREBASE_STORAGE_BUCKET=chimere-gamified-app.appspot.com
```

---

## 🔧 Development

### Run Development App

```bash
# Debug mode
flutter run -d <device_id>

# With verbose logging
flutter run -v

# Specific platform
flutter run -d emulator-5554  # Android
flutter run -d E6F88FD6-3FAD-4B2A-90A2-5FA108006D99  # iOS
```

### Android Setup

```bash
# List Android devices
flutter devices

# Create Android emulator if needed
flutter emulators create --name pixel5
flutter emulators launch pixel5
```

### iOS Setup

```bash
cd ios
pod install
cd ..

# List iOS simulators
xcrun simctl list devices

# Run on simulator
flutter run -d bootedsimulator_name
```

---

## 📦 Building for Production

### Android Build

```bash
# Create signed APK
flutter build apk --release \
  --dart-define=flavor=production

# Create Android App Bundle (for Google Play)
flutter build appbundle --release \
  --dart-define=flavor=production
```

**Setup Keystore:**

1. Create keystore (one time):
   ```bash
   keytool -genkey -v -keystore ~/chimere-key.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias chimere-key
   ```

2. Create/update `android/key.properties`:
   ```properties
   storePassword=YOUR_STORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=chimere-key
   storeFile=../chimere-key.jks
   ```

### iOS Build

```bash
# Create release build
flutter build ios --release

# Or use Xcode
open ios/Runner.xcworkspace

# In Xcode:
# 1. Select "Runner" in left panel
# 2. Build Settings → Search "Code Signing"
# 3. Set provisioning profile and team
# 4. Product → Archive
# 5. Validate and upload to App Store
```

---

## 📲 App Store Deployment

### Google Play Store

1. Create Google Play Developer Account (~$25)
2. Create new app:
   - Package name: `com.example.chimere`
   - App name: `Gamified Productivity`
3. Prepare store listing:
   - Screenshots (5-8)
   - Description (up to 4000 chars)
   - Category: Productivity
   - Icon (512x512)
4. Upload signed bundle:
   ```bash
   flutter build appbundle --release
   # Upload generated .aab file to Play Console
   ```
5. Set privacy policy URL
6. Submit for review

### Apple App Store

1. Create Apple Developer Account (~$100/year)
2. Create new app in App Store Connect
3. Configure:
   - Bundle ID: `com.example.chimere`
   - App name and subtitle
   - Category: Productivity
   - Privacy policy
4. Upload build:
   - Create provisioning profiles in Apple Developer
   - Configure in Xcode signing
   - Build and upload via Xcode or `transporter`
5. Version and build info
6. Submit for review

---

## 🎮 Core Features

### Authentication
- Email/Password sign up and sign in
- Firebase Auth with email verification
- Secure password reset

### Task Management
- Create tasks with categories (Work, Study, Health, Personal)
- Set priority levels (Low, Medium, High, Urgent)
- Assign due dates
- Track completion
- Add subtasks

### Gamification
- **Points System**: Awarded based on task priority
- **Levels**: Progress through 10 levels
- **Streaks**: Track consecutive task completion days
- **Badges**: Unlock special badges for milestones
- **Achievements**: Special unlocks for achievements
- **Weekly Analytics**: Visual progress charts

### Analytics & Tracking
- Task completion rates
- Points earned over time
- Streak history
- Category breakdown
- Session tracking

---

## 📊 Database Structure

### Firestore Collections

```
users/
  {userId}/
    - id, name, email, level, totalPoints
    - currentStreak, longestStreak
    - completedTasksCount, totalTasksCreated
    - preferences, createdAt, updatedAt
    badges/
      {badgeId}/
        - type, unlockedAt
    achievements/
      {achievementId}/
        - title, description, unlockedAt, iconEmoji

tasks/
  {taskId}/
    - userId, title, description, category
    - priority, createdAt, dueDate
    - isCompleted, completedAt, pointsAwarded
    - tags, subtasks[], reminders[]

analytics_events/
  {eventId}/
    - userId, name, timestamp
    - payload (event-specific data)
```

---

## 🔐 Security Best Practices

1. **API Keys**: Keep in `.env` file, never commit
2. **Firebase Rules**: Use security rules above
3. **User Data**: End-to-end encrypted in transit
4. **Local Cache**: Clear on sign out
5. **Consent**: Get user consent for analytics
6. **Data Retention**: Delete old analytics after 90 days

---

## 🛠️ Troubleshooting

### Firebase Initialization Failed

```bash
# Clear cache and rebuild
flutter clean
flutter pub get
flutter pub global activate flutterfire_cli
flutterfire configure
```

### App Crashes on Startup

1. Check Logcat:
   ```bash
   flutter logs
   ```
2. Verify Firebase options in `firebase_options.dart`
3. Check Firestore rules and authentication setup

### Emulator Issues

```bash
# Android emulator slow/not starting
flutter clean
flutter emulators launch pixel5  --cold-boot

# iOS simulator issues
xcrun simctl erase all
```

---

## 📈 Monitoring & Analytics

### Firebase Console

Dashboard shows:
- Daily active users
- Crash analytics
- Performance metrics
- Custom events

### Custom Analytics Events Tracked

- `user_signed_up` - New user registration
- `task_created` - Task creation
- `task_completed` - Task completion with points
- `badge_earned` - Badge unlock
- `level_up` - Level progression
- `streak_milestone` - Streak reached
- `app_session_start/end` - Session duration

---

## 💡 Next Steps for Evaluation

### For Research/Evaluation

1. **Participant Testing**:
   - 8-12 adult participants
   - Pre-test questionnaire (motivation, baseline productivity)
   - 2-week trial period
   - Post-test: Usability metrics, analytics data, qualitative interview

2. **Metrics Collection**:
   - Daily active users
   - Task completion rates
   - Streak patterns
   - Badge/achievement unlock rates
   - Session duration and frequency
   - User satisfaction (post-test survey)

3. **Data Export**:
   - Export Firestore data from Firebase Console
   - Export analytics from Analytics tab
   - Local event logs from SharedPreferences

---

## 📚 Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase for Flutter](https://firebase.flutter.dev)
- [Firebase Security Rules](https://firebase.google.com/docs/firestore/security/start)
- [Flutter App Store Deployment](https://flutter.dev/docs/deployment)
- [Gamification Best Practices](https://www.gamification.org)

---

## 📝 License

This project is built for academic purposes under Birmingham City University CMP6200 Individual Honours Project.

---

## 📞 Support

For issues or questions:
1. Check Flutter and Firebase documentation
2. Review GitHub issues in repository
3. Contact: [Your Email]

---

**Version**: 1.0.0  
**Last Updated**: April 2026  
**Status**: Production Ready
