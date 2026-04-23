Add these dependencies to pubspec.yaml before running:

dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2
  shared_preferences: ^2.2.3

Notes:
- This ZIP contains a complete `lib/` folder for a Flutter MVP aligned with the uploaded project documents.
- It uses local persistence via SharedPreferences so it can run without Firebase setup.
- The structure is Firebase-ready: auth, analytics, consent, settings, and persistence concerns are separated into providers/services.
- If you later want Firebase, swap the local storage/auth/event logic with Firebase Auth + Firestore + Analytics.
