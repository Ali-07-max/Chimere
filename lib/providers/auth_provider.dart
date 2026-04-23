import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/app_user.dart';
import '../services/analytics_service.dart';
import '../services/firestore_service.dart' hide debugPrint;
import '../services/local_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  static final uuid = Uuid();
  
  AppUser? _user;
  firebase_auth.User? _firebaseUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSignedIn = false;

  // Getters
  AppUser? get user => _user;
  firebase_auth.User? get firebaseUser => _firebaseUser;
  bool get isSignedIn => _isSignedIn && _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final FirestoreService _firestoreService = FirestoreService();

  // ==================== INITIALIZATION ====================

  /// Initialize auth state on app startup
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check if user is already signed in
      _firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      
      if (_firebaseUser != null) {
        // Load user data from Firestore
        await _loadUserData(_firebaseUser!.uid);
        _isSignedIn = true;
        
        // Log session start
        if (_user != null) {
          await AnalyticsService.logSessionStart(_user!.id);
        }
      } else {
        // Try to load cached user
        await _loadCachedUser();
      }

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to initialize auth: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load cached user from local storage
  Future<void> _loadCachedUser() async {
    try {
      final data = await LocalStorageService.getMap(LocalStorageService.userKey);
      if (data != null && data.isNotEmpty) {
        _user = AppUser.fromMap(data);
      }
    } catch (e) {
      debugPrint('Error loading cached user: $e');
    }
  }

  /// Load user data from Firestore
  Future<void> _loadUserData(String userId) async {
    try {
      final user = await _firestoreService.getUser(userId);
      if (user != null) {
        _user = user;
        await LocalStorageService.saveMap(LocalStorageService.userKey, _user!.toMap());
      }
    } catch (e) {
      debugPrint('Error loading user from Firestore: $e');
    }
  }

  // ==================== SIGN UP ====================

  /// Sign up with email and password
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Validate inputs
      _validateSignUpInputs(name, email, password);

      // Create Firebase user
      final result = await firebase_auth.FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email.trim().toLowerCase(),
            password: password,
          );

      if (result.user == null) {
        throw 'Failed to create user';
      }

      _firebaseUser = result.user;

      // Create user profile in Firestore
      final userId = result.user!.uid;
      final newUser = AppUser(
        id: userId,
        name: name.trim(),
        email: email.trim().toLowerCase(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.createOrUpdateUser(newUser);
      _user = newUser;

      // Cache user locally
      await LocalStorageService.saveMap(LocalStorageService.userKey, _user!.toMap());

      // Log signup
      await AnalyticsService.logEvent('user_signed_up', payload: {
        'email': email,
      });
      await AnalyticsService.logSessionStart(userId);

      _isSignedIn = true;
      _errorMessage = null;

      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _errorMessage = _getFirebaseAuthErrorMessage(e);
      _isSignedIn = false;
      return false;
    } catch (e) {
      _errorMessage = 'Sign up failed: $e';
      _isSignedIn = false;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== SIGN IN ====================

  /// Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Validate inputs
      if (email.isEmpty || password.isEmpty) {
        throw 'Email and password are required';
      }

      // Sign in with Firebase
      final result = await firebase_auth.FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: email.trim().toLowerCase(),
            password: password,
          );

      if (result.user == null) {
        throw 'Failed to sign in';
      }

      _firebaseUser = result.user;

      // Load user data from Firestore
      await _loadUserData(result.user!.uid);

      // Cache user locally
      if (_user != null) {
        await LocalStorageService.saveMap(LocalStorageService.userKey, _user!.toMap());
        await AnalyticsService.logSignIn(_user!.id, email);
        await AnalyticsService.logSessionStart(_user!.id);
      }

      _isSignedIn = true;
      _errorMessage = null;

      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _errorMessage = _getFirebaseAuthErrorMessage(e);
      _isSignedIn = false;
      return false;
    } catch (e) {
      _errorMessage = 'Sign in failed: $e';
      _isSignedIn = false;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== SIGN OUT ====================

  /// Sign out current user
  Future<bool> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Log session end
      if (_user != null) {
        await AnalyticsService.logSignOut(_user!.id);
      }

      // Sign out from Firebase
      await firebase_auth.FirebaseAuth.instance.signOut();

      // Clear cached data
      await LocalStorageService.saveMap(LocalStorageService.userKey, {});

      _user = null;
      _firebaseUser = null;
      _isSignedIn = false;
      _errorMessage = null;

      return true;
    } catch (e) {
      _errorMessage = 'Sign out failed: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== PASSWORD RESET ====================

  /// Send password reset email
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (email.isEmpty) {
        throw 'Email is required';
      }

      await firebase_auth.FirebaseAuth.instance.sendPasswordResetEmail(
        email: email.trim().toLowerCase(),
      );

      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _errorMessage = _getFirebaseAuthErrorMessage(e);
      return false;
    } catch (e) {
      _errorMessage = 'Failed to send reset email: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== UPDATE PROFILE ====================

  /// Update user profile
  Future<bool> updateProfile({
    String? name,
    String? bio,
    String? photoUrl,
  }) async {
    try {
      if (_user == null) {
        _errorMessage = 'No user logged in';
        return false;
      }

      final updatedUser = _user!.copyWith(
        name: name ?? _user!.name,
        bio: bio ?? _user!.bio,
        photoUrl: photoUrl ?? _user!.photoUrl,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.createOrUpdateUser(updatedUser);
      _user = updatedUser;

      await LocalStorageService.saveMap(LocalStorageService.userKey, _user!.toMap());

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update profile: $e';
      return false;
    }
  }

  // ==================== VALIDATION ====================

  /// Validate sign up inputs
  void _validateSignUpInputs(String name, String email, String password) {
    if (name.trim().isEmpty) {
      throw 'Name cannot be empty';
    }
    if (email.trim().isEmpty) {
      throw 'Email cannot be empty';
    }
    if (!_isValidEmail(email)) {
      throw 'Please enter a valid email';
    }
    if (password.isEmpty) {
      throw 'Password cannot be empty';
    }
    if (password.length < 6) {
      throw 'Password must be at least 6 characters';
    }
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Get Firebase auth error message
  String _getFirebaseAuthErrorMessage(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'operation-not-allowed':
        return 'Operation not allowed. Please try again.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }

  // ==================== CLEANUP ====================

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
