# Quick Start - Get Running in 5 Minutes

This guide helps you set up and run the **Gamified Productivity App** locally for development and evaluation.

## ⚡ Prerequisites

```bash
# Check versions
flutter --version          # Should be 3.9.0 or higher
dart --version            # Usually included with Flutter
```

## 🚀 Setup Steps

### 1. Get Dependencies

```bash
cd chimere
flutter pub get
```

### 2. One-Time Firebase Setup (FOR FIRST RUN)

Use FlutterFire CLI to auto-configure Firebase (recommended):

```bash
# Install FlutterFire CLI (one time)
dart pub global activate flutterfire_cli

# Configure Firebase (interactive)
flutterfire configure
# Follow prompts to select your Firebase project
# This auto-updates firebase_options.dart
```

**If FlutterFire isn't working**: Manually add Firebase credentials to `lib/services/firebase_options.dart` (see SETUP_AND_DEPLOYMENT.md).

### 3. Run the App

#### Android
```bash
# Ensure emulator is running or device is connected
flutter run

# Or specific device
flutter run -d emulator-5554
```

#### iOS
```bash
cd ios
pod install  # First time only
cd ..

flutter run -d bootedsimulator_name
```

#### Web (Development only)
```bash
flutter run -d web-server
# Opens at http://localhost:5000
```

---

## 🎮 Test the App

### Demo Account
```
Email: demo@example.com
Password: Demo1234!
```

### Test Scenarios

1. **Create Task**
   - Tap (+) button → Fill form → Save
   - Try different categories and priorities

2. **Complete Task**
   - Tap checkbox to mark done
   - Watch points update
   - Points = Priority × Bonuses

3. **Check Dashboard**
   - See level progress
   - View daily stats
   - Track streak

4. **View Progress**
   - Daily completions chart
   - Category breakdown
   - Points history

---

## 🐛 Troubleshooting

### App Won't Start
```bash
# Clean and try again
flutter clean
flutter pub get
flutter run -v   # Verbose for error details
```

### Firebase Auth Errors

**"Initialize Firebase first"**
- Verify `lib/services/firebase_options.dart` has your credentials
- Or run `flutterfire configure` again

**"Firestore denied"**
- Check security rules in Firebase Console
- Ensure user is authenticated

### Emulator Issues

**Android slow/frozen**
```bash
flutter emulators kill all
flutter emulators launch pixel5 --cold-boot
```

**iOS simulator not found**
```bash
xcrun simctl list devices  # Show available
flutter run -d "iPhone 14" # Or specific simulator
```

---

## 📁 Project Structure Quick Reference

```
lib/
├── main.dart              # App entry, Firebase init
├── app.dart              # Routing and theme
├── models/               # Data classes
├── providers/            # State management
├── services/             # Business logic (Firebase, gamification)
├── screens/              # UI screens
├── widgets/              # Reusable components
└── theme/                # Material Design 3 theme
```

---

## 📊 Now What?

### For Development
1. Make code changes
2. Hot reload: `r` in terminal
3. Hot restart: `R` in terminal
4. Full rebuild: `flutter run` again

### For Evaluation/Testing
1. Create multiple test accounts
2. Create different tasks with various priorities
3. Complete tasks and observe gamification
4. Check Firebase Console for analytics events
5. Export data for analysis

### For Deployment (Later)
See [SETUP_AND_DEPLOYMENT.md](./SETUP_AND_DEPLOYMENT.md) for:
- App Store submission
- Google Play deployment
- Build signing
- Release builds

---

## 🎯 Key Features to Test

- ✅ Sign up / Sign in
- ✅ Create tasks (4 categories, 4 priorities)
- ✅ Track completion with points
- ✅ Display level and progress
- ✅ Show streak counter
- ✅ Analytics dashboard
- ✅ Settings & Preferences

---

## 💾 Data Storage

- **Local**: SharedPreferences (cache for offline)
- **Cloud**: Firebase Firestore (authoritative)
- **Events**: Firebase Analytics + local backup

Data auto-syncs when connected.

---

## 🔍 View Logs

```bash
# See app output
flutter logs

# Filter for specific app
flutter logs --tag chimere

# See Firebase debug logs
flutter run -v
```

---

## 🆘 Still Having Issues?

1. Check **Flutter** docs: https://flutter.dev/docs
2. Check **Firebase** docs: https://firebase.flutter.dev
3. See full setup guide: [SETUP_AND_DEPLOYMENT.md](./SETUP_AND_DEPLOYMENT.md)
4. Review architecture: [ARCHITECTURE_AND_FEATURES.md](./ARCHITECTURE_AND_FEATURES.md)

---

**Status**: ✅ Ready to run  
**Last Updated**: April 2026  
**Built with**: Flutter 3.9+ | Firebase | Dart 3.1+
